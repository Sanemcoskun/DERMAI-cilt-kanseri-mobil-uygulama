<?php
require_once __DIR__ . '/../config/database.php';

class CreditsHandler {
    private static $db;
    
    private static function getDB() {
        if (!self::$db) {
            self::$db = Database::getInstance()->getConnection();
        }
        return self::$db;
    }
    
    /**
     * Kullanıcının mevcut kredi bilgisini getir
     */
    public static function getUserCredits() {
        try {
            // Session ID'yi al
            $session_id = '';
            if (function_exists('getallheaders')) {
                $headers = getallheaders();
                $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            if (empty($session_id)) {
                $session_id = $_SERVER['HTTP_X_SESSION_ID'] ?? '';
            }
            
            if (empty($session_id)) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Session ID gereklidir'
                ]);
                return;
            }
            
            $db = self::getDB();
            
            // Session'ı doğrula ve user_id'yi al
            $stmt = $db->prepare("
                SELECT us.user_id 
                FROM user_sessions us
                JOIN users u ON us.user_id = u.id
                WHERE us.session_id = ? AND us.expires_at > NOW() AND u.aktif = 1
            ");
            $stmt->execute([$session_id]);
            $session = $stmt->fetch();
            
            if (!$session) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Geçersiz session'
                ]);
                return;
            }
            
            $user_id = $session['user_id'];
            
            // Kullanıcının kredi bilgisini getir
            $stmt = $db->prepare("
                SELECT id, ad, soyad, email, credits, created_at
                FROM users 
                WHERE id = ? AND aktif = 1
            ");
            $stmt->execute([$user_id]);
            $user = $stmt->fetch();
            
            if (!$user) {
                http_response_code(404);
                echo json_encode([
                    'status' => 404,
                    'message' => 'Kullanıcı bulunamadı'
                ]);
                return;
            }
            
            // Kredi geçmişini getir (son 10 işlem)
            $stmt = $db->prepare("
                SELECT işlem, detay, created_at
                FROM system_logs 
                WHERE user_id = ? AND işlem LIKE '%credit%' 
                ORDER BY created_at DESC
                LIMIT 10
            ");
            $stmt->execute([$user_id]);
            $credit_history = $stmt->fetchAll();
            
            // Log kaydı
            try {
                logActivity($user_id, 'credits_view', 'Kredi bilgileri görüntülendi');
            } catch (Exception $e) {
                error_log("Log activity error: " . $e->getMessage());
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Kredi bilgileri başarıyla getirildi',
                'data' => [
                    'user_info' => [
                        'id' => $user['id'],
                        'ad' => $user['ad'],
                        'soyad' => $user['soyad'],
                        'email' => $user['email'],
                        'uyelik_tarihi' => $user['created_at']
                    ],
                    'credits' => [
                        'current_credits' => (int) $user['credits'],
                        'history' => $credit_history
                    ]
                ]
            ]);
            
        } catch (Exception $e) {
            error_log("Get credits error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Kredi bilgileri getirilirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    /**
     * Kullanıcının kredi bakiyesini güncelle (admin veya sistem kullanımı için)
     */
    public static function updateCredits() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Geçersiz JSON verisi'
                ]);
                return;
            }
            
            // Session ID'yi al
            $session_id = '';
            if (function_exists('getallheaders')) {
                $headers = getallheaders();
                $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            if (empty($session_id)) {
                $session_id = $_SERVER['HTTP_X_SESSION_ID'] ?? '';
            }
            
            if (empty($session_id)) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Session ID gereklidir'
                ]);
                return;
            }
            
            $db = self::getDB();
            
            // Session'ı doğrula ve user_id'yi al
            $stmt = $db->prepare("
                SELECT us.user_id 
                FROM user_sessions us
                JOIN users u ON us.user_id = u.id
                WHERE us.session_id = ? AND us.expires_at > NOW() AND u.aktif = 1
            ");
            $stmt->execute([$session_id]);
            $session = $stmt->fetch();
            
            if (!$session) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Geçersiz session'
                ]);
                return;
            }
            
            $user_id = $session['user_id'];
            
            // Güncelleme verilerini al
            $credit_change = (int) ($input['credit_change'] ?? 0);
            $operation_type = $input['operation_type'] ?? 'add'; // add, subtract, set
            $reason = $input['reason'] ?? 'Manuel güncelleme';
            
            if ($credit_change == 0 && $operation_type !== 'set') {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Kredi değişim miktarı belirtilmelidir'
                ]);
                return;
            }
            
            // Mevcut kredi miktarını al
            $stmt = $db->prepare("SELECT credits FROM users WHERE id = ?");
            $stmt->execute([$user_id]);
            $current_credits = (int) $stmt->fetchColumn();
            
            // Yeni kredi miktarını hesapla
            switch ($operation_type) {
                case 'add':
                    $new_credits = $current_credits + $credit_change;
                    break;
                case 'subtract':
                    $new_credits = max(0, $current_credits - abs($credit_change));
                    break;
                case 'set':
                    $new_credits = max(0, $credit_change);
                    break;
                default:
                    http_response_code(400);
                    echo json_encode([
                        'status' => 400,
                        'message' => 'Geçersiz işlem tipi. Kullanılabilir: add, subtract, set'
                    ]);
                    return;
            }
            
            // Kredileri güncelle
            $stmt = $db->prepare("UPDATE users SET credits = ? WHERE id = ?");
            $stmt->execute([$new_credits, $user_id]);
            
            // Log kaydı
            try {
                $log_detail = json_encode([
                    'operation' => $operation_type,
                    'change' => $credit_change,
                    'old_credits' => $current_credits,
                    'new_credits' => $new_credits,
                    'reason' => $reason
                ]);
                logActivity($user_id, 'credits_update', $log_detail);
            } catch (Exception $e) {
                error_log("Log activity error: " . $e->getMessage());
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Kredi bakiyesi başarıyla güncellendi',
                'data' => [
                    'old_credits' => $current_credits,
                    'new_credits' => $new_credits,
                    'change' => $new_credits - $current_credits,
                    'operation' => $operation_type,
                    'reason' => $reason
                ]
            ]);
            
        } catch (Exception $e) {
            error_log("Update credits error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Kredi güncelleme sırasında hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    /**
     * Kredi kullanımı (analiz, özellik kullanımı vb.)
     */
    public static function useCredits() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Geçersiz JSON verisi'
                ]);
                return;
            }
            
            // Session ID'yi al
            $session_id = '';
            if (function_exists('getallheaders')) {
                $headers = getallheaders();
                $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            if (empty($session_id)) {
                $session_id = $_SERVER['HTTP_X_SESSION_ID'] ?? '';
            }
            
            if (empty($session_id)) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Session ID gereklidir'
                ]);
                return;
            }
            
            $db = self::getDB();
            
            // Session'ı doğrula ve user_id'yi al
            $stmt = $db->prepare("
                SELECT us.user_id 
                FROM user_sessions us
                JOIN users u ON us.user_id = u.id
                WHERE us.session_id = ? AND us.expires_at > NOW() AND u.aktif = 1
            ");
            $stmt->execute([$session_id]);
            $session = $stmt->fetch();
            
            if (!$session) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Geçersiz session'
                ]);
                return;
            }
            
            $user_id = $session['user_id'];
            
            // Kullanım verilerini al
            $credits_to_use = (int) ($input['credits'] ?? 1);
            $service_type = $input['service_type'] ?? 'unknown';
            $description = $input['description'] ?? 'Kredi kullanımı';
            
            if ($credits_to_use <= 0) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Kullanılacak kredi miktarı pozitif olmalıdır'
                ]);
                return;
            }
            
            // Mevcut kredi miktarını kontrol et
            $stmt = $db->prepare("SELECT credits FROM users WHERE id = ?");
            $stmt->execute([$user_id]);
            $current_credits = (int) $stmt->fetchColumn();
            
            if ($current_credits < $credits_to_use) {
                http_response_code(402); // Payment Required
                echo json_encode([
                    'status' => 402,
                    'message' => 'Yetersiz kredi bakiyesi',
                    'data' => [
                        'current_credits' => $current_credits,
                        'required_credits' => $credits_to_use,
                        'missing_credits' => $credits_to_use - $current_credits
                    ]
                ]);
                return;
            }
            
            // Kredileri düş
            $new_credits = $current_credits - $credits_to_use;
            $stmt = $db->prepare("UPDATE users SET credits = ? WHERE id = ?");
            $stmt->execute([$new_credits, $user_id]);
            
            // Log kaydı
            try {
                $log_detail = json_encode([
                    'service_type' => $service_type,
                    'credits_used' => $credits_to_use,
                    'old_credits' => $current_credits,
                    'new_credits' => $new_credits,
                    'description' => $description
                ]);
                logActivity($user_id, 'credits_usage', $log_detail);
            } catch (Exception $e) {
                error_log("Log activity error: " . $e->getMessage());
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Kredi başarıyla kullanıldı',
                'data' => [
                    'credits_used' => $credits_to_use,
                    'remaining_credits' => $new_credits,
                    'service_type' => $service_type,
                    'description' => $description
                ]
            ]);
            
        } catch (Exception $e) {
            error_log("Use credits error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Kredi kullanımı sırasında hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
}

// Debug log fonksiyonu
function debugLog($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] CREDITS DEBUG: $message\n";
    // Windows için log dosyası yolu
    $logFile = __DIR__ . '/../logs/dermai_debug.log';
    if (!file_exists(dirname($logFile))) {
        mkdir(dirname($logFile), 0777, true);
    }
    error_log($logMessage, 3, $logFile);
    error_log("CREDITS DEBUG: $message");
}

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Session-ID');

debugLog("=== CREDITS REQUEST START ===");
debugLog("Request Method: " . $_SERVER['REQUEST_METHOD']);
debugLog("Request URI: " . ($_SERVER['REQUEST_URI'] ?? 'not set'));

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    debugLog("OPTIONS request - CORS preflight");
    exit(0);
}

// API endpoint yönlendirmesi
$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['PATH_INFO'] ?? $_SERVER['REQUEST_URI'] ?? '';

// URL path'i temizle
$path = parse_url($path, PHP_URL_PATH);
$path = str_replace(['/flutter/dermai_api/credits/credits_handler.php', '/dermai_api/credits/credits_handler.php', '/credits_handler.php'], '', $path);

// Eğer path boşsa, GET request'i /get olarak değerlendir
if (empty($path) && $method === 'GET') {
    $path = '/get';
}

debugLog("Cleaned path: " . $path);

switch($path) {
    case '/get':
    case '/':
        if ($method === 'GET') {
            debugLog("Getting user credits");
            CreditsHandler::getUserCredits();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/update':
        if ($method === 'PUT' || $method === 'POST') {
            debugLog("Updating credits");
            CreditsHandler::updateCredits();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/use':
        if ($method === 'POST') {
            debugLog("Using credits");
            CreditsHandler::useCredits();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    default:
        debugLog("Unknown endpoint: " . $path);
        http_response_code(404);
        echo json_encode([
            'status' => 404,
            'message' => 'Endpoint bulunamadı',
            'available_endpoints' => [
                'GET /get - Kullanıcı kredi bilgilerini getir',
                'PUT /update - Kredi bakiyesini güncelle',
                'POST /use - Kredi kullan'
            ]
        ]);
        break;
}

debugLog("=== CREDITS REQUEST END ===");
?> 