<?php
// Browser GET istekleri için basit HTML sayfa göster
if ($_SERVER['REQUEST_METHOD'] === 'GET' && !isset($_SERVER['HTTP_AUTHORIZATION'])) {
    echo '<!DOCTYPE html>
<html>
<head><title>DermAI Auth API</title></head>
<body>
<h1>DermAI Authentication API</h1>
<p>Bu endpoint sadece mobil uygulama için tasarlanmıştır.</p>
<p>Available endpoints:</p>
<ul>
<li>POST /register - Kullanıcı kaydı</li>
<li>POST /login - Kullanıcı girişi</li>
<li>POST /logout - Kullanıcı çıkışı</li>
<li>POST /validate - Session doğrulama</li>
<li>GET /user - Kullanıcı verileri</li>
</ul>
</body>
</html>';
    exit();
}

require_once __DIR__ . '/../config/database.php';

class AuthHandler {
    private static $db;
    
    private static function getDB() {
        if (!self::$db) {
            self::$db = Database::getInstance()->getConnection();
        }
        return self::$db;
    }
    
    public static function register() {
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
            
            $email = trim($input['email'] ?? '');
            $sifre = $input['sifre'] ?? '';
            $sifre_tekrar = $input['sifre_tekrar'] ?? '';
            $ad = trim($input['ad'] ?? '');
            $soyad = trim($input['soyad'] ?? '');
            
            // Validation
            if (empty($email) || empty($sifre) || empty($ad) || empty($soyad)) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Email, şifre, ad ve soyad alanları zorunludur'
                ]);
                return;
            }
            
            if ($sifre !== $sifre_tekrar) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Şifreler eşleşmiyor'
                ]);
                return;
            }
            
            if (strlen($sifre) < 6) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Şifre en az 6 karakter olmalıdır'
                ]);
                return;
            }
            
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Geçersiz email adresi'
                ]);
                return;
            }
            
            $db = self::getDB();
            
            // Email kontrolü
            $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
            $stmt->execute([$email]);
            if ($stmt->fetch()) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Bu email adresi zaten kullanılıyor'
                ]);
                return;
            }
            
            // Yeni kullanıcı oluştur
            $hashed_password = password_hash($sifre, PASSWORD_DEFAULT);
            $session_id = bin2hex(random_bytes(32));
            
            $db->beginTransaction();
            
            try {
                // Kullanıcı kaydı
                $stmt = $db->prepare("
                    INSERT INTO users (email, sifre, ad, soyad, aktif, created_at) 
                    VALUES (?, ?, ?, ?, 1, NOW())
                ");
                $stmt->execute([$email, $hashed_password, $ad, $soyad]);
                $user_id = $db->lastInsertId();
                
                // Session kaydı
                $stmt = $db->prepare("
                    INSERT INTO user_sessions (user_id, session_id, device_info, ip_address, created_at, expires_at) 
                    VALUES (?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY))
                ");
                $device_info = $_SERVER['HTTP_USER_AGENT'] ?? 'DermAI Mobile App';
                $ip_address = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
                $stmt->execute([$user_id, $session_id, $device_info, $ip_address]);
                
                // Hoşgeldin bildirimi
                $stmt = $db->prepare("
                    INSERT INTO notifications (user_id, başlık, mesaj, tip, created_at) 
                    VALUES (?, ?, ?, 'başarı', NOW())
                ");
                $stmt->execute([
                    $user_id, 
                    'DermAI\'ye Hoşgeldiniz!', 
                    'Cilt sağlığınızı korumak için buradayız. İlk analizinizi yapmaya hazır mısınız?'
                ]);
                
                $db->commit();
                
                // Log kaydı
                logActivity($user_id, 'user_register', 'Yeni kullanıcı kaydı: ' . $ad . ' ' . $soyad);
                
                echo json_encode([
                    'status' => 200,
                    'message' => 'Kayıt başarılı! Hoşgeldin, ' . $ad . ' ' . $soyad,
                    'data' => [
                        'session_id' => $session_id,
                        'user_id' => $user_id,
                        'email' => $email,
                        'ad' => $ad,
                        'soyad' => $soyad
                    ]
                ]);
                
            } catch (Exception $e) {
                $db->rollBack();
                throw $e;
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Kayıt sırasında bir hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function login() {
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
            
            $email = trim($input['email'] ?? '');
            $sifre = $input['sifre'] ?? '';
            
            if (empty($email) || empty($sifre)) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Email ve şifre gereklidir'
                ]);
                return;
            }
            
            $db = self::getDB();
            
            // Email ile kullanıcı arama
            $stmt = $db->prepare("
                SELECT u.id, u.email, u.sifre, u.ad, u.soyad, u.aktif, u.created_at
                FROM users u
                WHERE u.email = ? AND u.aktif = 1
            ");
            $stmt->execute([$email]);
            $user = $stmt->fetch();
            
            if (!$user || !password_verify($sifre, $user['sifre'])) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Email veya şifre hatalı'
                ]);
                return;
            }
            
            // Eski session'ları temizle
            $stmt = $db->prepare("DELETE FROM user_sessions WHERE user_id = ? AND expires_at < NOW()");
            $stmt->execute([$user['id']]);
            
            // Yeni session oluştur
            $session_id = bin2hex(random_bytes(32));
            
            $stmt = $db->prepare("
                INSERT INTO user_sessions (user_id, session_id, device_info, ip_address, created_at, expires_at) 
                VALUES (?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY))
            ");
            $device_info = $_SERVER['HTTP_USER_AGENT'] ?? 'DermAI Mobile App';
            $ip_address = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
            $stmt->execute([$user['id'], $session_id, $device_info, $ip_address]);
            
            // Log kaydı
            logActivity($user['id'], 'user_login', 'Kullanıcı girişi: ' . $user['ad'] . ' ' . $user['soyad']);
            
            echo json_encode([
                'status' => 200,
                'message' => 'Giriş başarılı! Hoşgeldin, ' . $user['ad'] . ' ' . $user['soyad'],
                'data' => [
                    'session_id' => $session_id,
                    'user_id' => $user['id'],
                    'email' => $user['email'],
                    'ad' => $user['ad'],
                    'soyad' => $user['soyad']
                ]
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Giriş sırasında bir hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function logout() {
        try {
            // Header'ları güvenilir şekilde al
            $session_header = '';
            
            // Önce getallheaders() dene
            if (function_exists('getallheaders')) {
                $headers = getallheaders();
                $session_header = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            
            // Eğer bulamazsa $_SERVER'dan dene
            if (empty($session_header)) {
                $session_header = $_SERVER['HTTP_X_SESSION_ID'] ?? '';
            }
            
            if (empty($session_header)) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Session ID gereklidir'
                ]);
                return;
            }
            
            $db = self::getDB();
            
            // Session'ı sil
            $stmt = $db->prepare("DELETE FROM user_sessions WHERE session_id = ?");
            $stmt->execute([$session_header]);
            
            echo json_encode([
                'status' => 200,
                'message' => 'Çıkış başarılı'
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Çıkış sırasında bir hata oluştu'
            ]);
        }
    }
    
    public static function validateSession() {
        try {
            // Header'ları güvenilir şekilde al
            $session_id = '';
            
            // Önce getallheaders() dene
            if (function_exists('getallheaders')) {
                $headers = getallheaders();
                $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            
            // Eğer bulamazsa $_SERVER'dan dene
            if (empty($session_id)) {
                $session_id = $_SERVER['HTTP_X_SESSION_ID'] ?? '';
            }
            
            // Debug için log
            error_log('ValidateSession - Session ID: ' . $session_id);
            error_log('ValidateSession - All headers: ' . print_r(function_exists('getallheaders') ? getallheaders() : [], true));
            error_log('ValidateSession - Server vars: ' . print_r(array_filter($_SERVER, function($key) {
                return strpos($key, 'HTTP_') === 0;
            }, ARRAY_FILTER_USE_KEY), true));
            
            if (empty($session_id)) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Session ID gereklidir',
                    'debug' => [
                        'headers' => function_exists('getallheaders') ? getallheaders() : [],
                        'server_headers' => array_filter($_SERVER, function($key) {
                            return strpos($key, 'HTTP_') === 0;
                        }, ARRAY_FILTER_USE_KEY)
                    ]
                ]);
                return;
            }
            
            // Session kontrolü ve kullanıcı verilerini al
            $db = self::getDB();
            $stmt = $db->prepare("SELECT u.id, u.email, u.ad, u.soyad FROM users u INNER JOIN user_sessions s ON u.id = s.user_id WHERE s.session_id = ? AND s.expires_at > NOW()");
            $stmt->execute([$session_id]);
            $user = $stmt->fetch();
            
            if (!$user) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Geçersiz veya süresi dolmuş session'
                ]);
                return;
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Session geçerli',
                'data' => [
                    'user_id' => $user['id'],
                    'email' => $user['email'],
                    'ad' => $user['ad'],
                    'soyad' => $user['soyad']
                ]
            ]);
            
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Session doğrulama hatası'
            ]);
        }
    }
    
    public static function getUserData() {
        try {
            // Header'ları güvenilir şekilde al
            $session_id = '';
            
            // Önce getallheaders() dene
            if (function_exists('getallheaders')) {
                $headers = getallheaders();
                $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            
            // Eğer bulamazsa $_SERVER'dan dene
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
            
            // Get database connection
            $db = self::getDB();
            
            // Get user data from session
            $stmt = $db->prepare("SELECT u.id, u.email, u.ad, u.soyad FROM users u INNER JOIN user_sessions s ON u.id = s.user_id WHERE s.session_id = ? AND s.expires_at > NOW()");
            $stmt->execute([$session_id]);
            $user = $stmt->fetch();
            
            if (!$user) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Geçersiz session'
                ]);
                return;
            }
            
            // Kullanıcının analiz sayısını al
            $stmt = $db->prepare("
                SELECT COUNT(*) as toplam_analiz,
                       COUNT(CASE WHEN analiz_tarihi >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as son_ay_analiz
                FROM skin_analyses 
                WHERE user_id = ?
            ");
            $stmt->execute([$user['id']]);
            $analytics = $stmt->fetch();
            
            // Son bildirimleri al
            $stmt = $db->prepare("
                SELECT id, başlık, mesaj, tip, okundu, created_at
                FROM notifications 
                WHERE user_id = ? 
                ORDER BY created_at DESC 
                LIMIT 5
            ");
            $stmt->execute([$user['id']]);
            $notifications = $stmt->fetchAll();
            
            echo json_encode([
                'status' => 200,
                'message' => 'Kullanıcı verileri başarıyla alındı',
                'data' => [
                    'user' => $user,
                    'statistics' => [
                        'toplam_analiz' => (int)$analytics['toplam_analiz'],
                        'son_ay_analiz' => (int)$analytics['son_ay_analiz']
                    ],
                    'notifications' => $notifications
                ]
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Kullanıcı verileri alınamadı'
            ]);
        }
    }
}

// API endpoint yönlendirmesi
$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['PATH_INFO'] ?? $_SERVER['REQUEST_URI'] ?? '';

// Action parameter için kontrol (Flutter compatibility)
$input = json_decode(file_get_contents('php://input') ?: '{}', true);
$action = $input['action'] ?? '';

// Eğer action parameter varsa onu kullan
if (!empty($action)) {
    $path = '/' . $action;
}

switch($path) {
    case '/register':
        if ($method === 'POST') {
            AuthHandler::register();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/login':
        if ($method === 'POST') {
            AuthHandler::login();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/logout':
        if ($method === 'POST') {
            AuthHandler::logout();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/validate':
        if ($method === 'GET') {
            AuthHandler::validateSession();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/user':
        if ($method === 'GET') {
            AuthHandler::getUserData();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    default:
        http_response_code(404);
        echo json_encode([
            'status' => 404,
            'message' => 'Endpoint bulunamadı',
            'available_endpoints' => [
                'POST /register - Kullanıcı kaydı',
                'POST /login - Kullanıcı girişi',  
                'POST /logout - Kullanıcı çıkışı',
                'GET /validate - Session doğrulama',
                'GET /user - Kullanıcı verileri'
            ]
        ]);
        break;
}
?>