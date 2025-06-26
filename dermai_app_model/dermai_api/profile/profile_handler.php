<?php
require_once __DIR__ . '/../config/database.php';

class ProfileHandler {
    private static $db;
    
    private static function getDB() {
        if (!self::$db) {
            self::$db = Database::getInstance()->getConnection();
        }
        return self::$db;
    }
    
    public static function uploadProfilePhoto() {
        try {
            error_log("=== UPLOAD DEBUG START ===");
            error_log("REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD']);
            error_log("Content-Type: " . ($_SERVER['CONTENT_TYPE'] ?? 'not set'));
            
            // Session ID'yi al - multipart request'ler için özel kontrol
            $session_id = '';
            
            // Önce Apache headers'ından dene
            if (function_exists('apache_request_headers')) {
                $headers = apache_request_headers();
                error_log("Apache headers: " . json_encode($headers));
                foreach ($headers as $key => $value) {
                    if (strtolower($key) === 'x-session-id') {
                        $session_id = $value;
                        break;
                    }
                }
            }
            
            // getallheaders fonksiyonunu dene
            if (empty($session_id) && function_exists('getallheaders')) {
                $headers = getallheaders();
                error_log("getallheaders: " . json_encode($headers));
                $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
            }
            
            // $_SERVER array'inden dene
            if (empty($session_id)) {
                $session_id = $_SERVER['HTTP_X_SESSION_ID'] ?? '';
                error_log("Session ID from HTTP_X_SESSION_ID: " . $session_id);
            }
            
            // Alternatif header isimleri dene
            if (empty($session_id)) {
                foreach ($_SERVER as $key => $value) {
                    if (strtolower($key) === 'http_x_session_id') {
                        $session_id = $value;
                        error_log("Found session ID in: " . $key);
                        break;
                    }
                }
            }
            
            error_log("Final Session ID: '" . $session_id . "'");
            error_log("Session ID length: " . strlen($session_id));
            
            if (empty($session_id)) {
                error_log("No session ID found in any header method");
                error_log("All SERVER vars starting with HTTP_: " . json_encode(array_filter($_SERVER, function($key) {
                    return strpos($key, 'HTTP_') === 0;
                }, ARRAY_FILTER_USE_KEY)));
                
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Session ID gereklidir',
                    'debug' => [
                        'apache_headers' => function_exists('apache_request_headers') ? apache_request_headers() : 'not available',
                        'getallheaders' => function_exists('getallheaders') ? getallheaders() : 'not available',
                        'server_http_vars' => array_filter($_SERVER, function($key) {
                            return strpos($key, 'HTTP_') === 0;
                        }, ARRAY_FILTER_USE_KEY)
                    ]
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
            
            error_log("Session query result: " . json_encode($session));
            
            if (!$session) {
                http_response_code(401);
                echo json_encode([
                    'status' => 401,
                    'message' => 'Geçersiz session',
                    'debug' => [
                        'session_id' => $session_id,
                        'session_id_length' => strlen($session_id),
                        'query_result' => $session
                    ]
                ]);
                return;
            }
            
            $user_id = $session['user_id'];
            error_log("User ID: " . $user_id);
            
            // Dosya yükleme kontrolü
            error_log("FILES array: " . json_encode($_FILES));
            
            if (!isset($_FILES['profile_photo']) || $_FILES['profile_photo']['error'] !== UPLOAD_ERR_OK) {
                $error_code = $_FILES['profile_photo']['error'] ?? 'not set';
                error_log("File upload error code: " . $error_code);
                
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Dosya yükleme hatası',
                    'debug' => [
                        'files' => $_FILES,
                        'error_code' => $error_code,
                        'upload_error_messages' => [
                            UPLOAD_ERR_OK => 'No error',
                            UPLOAD_ERR_INI_SIZE => 'File too large (php.ini)',
                            UPLOAD_ERR_FORM_SIZE => 'File too large (form)',
                            UPLOAD_ERR_PARTIAL => 'Partial upload',
                            UPLOAD_ERR_NO_FILE => 'No file uploaded',
                            UPLOAD_ERR_NO_TMP_DIR => 'No temp directory',
                            UPLOAD_ERR_CANT_WRITE => 'Cannot write to disk',
                            UPLOAD_ERR_EXTENSION => 'PHP extension stopped upload'
                        ][$error_code] ?? 'Unknown error'
                    ]
                ]);
                return;
            }
            
            $file = $_FILES['profile_photo'];
            $file_size = $file['size'];
            $file_tmp = $file['tmp_name'];
            $file_type = $file['type'];
            $file_name = $file['name'];
            
            error_log("File info - Name: $file_name, Size: $file_size, Type: $file_type, Tmp: $file_tmp");
            
            // Dosya boyutu kontrolü (5MB max)
            if ($file_size > 5 * 1024 * 1024) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Dosya boyutu 5MB\'dan büyük olamaz',
                    'debug' => ['file_size' => $file_size]
                ]);
                return;
            }
            
            // Dosya tipi kontrolü - daha esnek hale getirelim
            $allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/heic', 'image/heif'];
            
            // Dosya uzantısından da tip belirlemeye çalış
            $file_extension = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
            $allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'heic', 'heif'];
            
            error_log("File type check - MIME type: '$file_type', Extension: '$file_extension'");
            error_log("Allowed MIME types: " . json_encode($allowed_types));
            error_log("Allowed extensions: " . json_encode($allowed_extensions));
            
            // MIME type veya uzantı kontrolü
            $type_valid = in_array($file_type, $allowed_types) || in_array($file_extension, $allowed_extensions);
            
            if (!$type_valid) {
                error_log("File type validation failed!");
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Sadece JPG, PNG, GIF ve HEIC dosyaları kabul edilir',
                    'debug' => [
                        'file_type' => $file_type, 
                        'file_extension' => $file_extension,
                        'file_name' => $file_name,
                        'allowed_types' => $allowed_types,
                        'allowed_extensions' => $allowed_extensions
                    ]
                ]);
                return;
            }
            
            error_log("File type validation passed!");
            
            // Upload klasörünü oluştur
            $upload_dir = __DIR__ . '/../uploads/profile_photos/';
            error_log("Upload directory: " . $upload_dir);
            error_log("Upload directory exists: " . (file_exists($upload_dir) ? 'yes' : 'no'));
            error_log("Upload directory writable: " . (is_writable($upload_dir) ? 'yes' : 'no'));
            
            if (!file_exists($upload_dir)) {
                $mkdir_result = mkdir($upload_dir, 0755, true);
                error_log("mkdir result: " . ($mkdir_result ? 'success' : 'failed'));
            }
            
            // Eski profil fotoğrafını sil
            $stmt = $db->prepare("SELECT profil_foto FROM users WHERE id = ?");
            $stmt->execute([$user_id]);
            $old_photo = $stmt->fetchColumn();
            
            if ($old_photo && file_exists($upload_dir . $old_photo)) {
                $unlink_result = unlink($upload_dir . $old_photo);
                error_log("Old photo deleted: " . ($unlink_result ? 'success' : 'failed'));
            }
            
            // Yeni dosya adı oluştur
            $new_filename = 'user_' . $user_id . '_' . time() . '.' . $file_extension;
            $upload_path = $upload_dir . $new_filename;
            
            error_log("New filename: " . $new_filename);
            error_log("Upload path: " . $upload_path);
            
            // Dosyayı yükle
            if (move_uploaded_file($file_tmp, $upload_path)) {
                error_log("File uploaded successfully");
                
                // Veritabanını güncelle
                $stmt = $db->prepare("UPDATE users SET profil_foto = ? WHERE id = ?");
                $update_result = $stmt->execute([$new_filename, $user_id]);
                error_log("Database update result: " . ($update_result ? 'success' : 'failed'));
                
                // Log kaydı
                try {
                    logActivity($user_id, 'profile_photo_upload', 'Profil fotoğrafı güncellendi: ' . $new_filename);
                } catch (Exception $e) {
                    error_log("Log activity error: " . $e->getMessage());
                }
                
                error_log("=== UPLOAD DEBUG END - SUCCESS ===");
                
                echo json_encode([
                    'status' => 200,
                    'message' => 'Profil fotoğrafı başarıyla yüklendi',
                    'data' => [
                        'filename' => $new_filename,
                        'url' => '/projeler/dermai/dermai_api/uploads/profile_photos/' . $new_filename
                    ]
                ]);
            } else {
                error_log("move_uploaded_file failed");
                error_log("=== UPLOAD DEBUG END - FAILED ===");
                
                http_response_code(500);
                echo json_encode([
                    'status' => 500,
                    'message' => 'Dosya yükleme hatası',
                    'debug' => [
                        'upload_path' => $upload_path,
                        'temp_file' => $file_tmp,
                        'temp_file_exists' => file_exists($file_tmp)
                    ]
                ]);
            }
            
        } catch (Exception $e) {
            error_log("Upload exception: " . $e->getMessage());
            error_log("=== UPLOAD DEBUG END - EXCEPTION ===");
            
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Profil fotoğrafı yüklenirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function deleteProfilePhoto() {
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
            
            // Mevcut profil fotoğrafını al
            $stmt = $db->prepare("SELECT profil_foto FROM users WHERE id = ?");
            $stmt->execute([$user_id]);
            $current_photo = $stmt->fetchColumn();
            
            if ($current_photo) {
                // Dosyayı sil
                $upload_dir = __DIR__ . '/../uploads/profile_photos/';
                $file_path = $upload_dir . $current_photo;
                
                if (file_exists($file_path)) {
                    unlink($file_path);
                }
                
                // Veritabanından kaldır
                $stmt = $db->prepare("UPDATE users SET profil_foto = NULL WHERE id = ?");
                $stmt->execute([$user_id]);
                
                // Log kaydı
                try {
                    logActivity($user_id, 'profile_photo_delete', 'Profil fotoğrafı silindi');
                } catch (Exception $e) {
                    error_log("Log activity error: " . $e->getMessage());
                }
                
                echo json_encode([
                    'status' => 200,
                    'message' => 'Profil fotoğrafı başarıyla silindi'
                ]);
            } else {
                echo json_encode([
                    'status' => 200,
                    'message' => 'Silinecek profil fotoğrafı bulunamadı'
                ]);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Profil fotoğrafı silinirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function updateProfile() {
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
            $ad = trim($input['ad'] ?? '');
            $soyad = trim($input['soyad'] ?? '');
            $telefon = trim($input['telefon'] ?? '');
            $dogum_tarihi = $input['dogum_tarihi'] ?? null;
            $cinsiyet = $input['cinsiyet'] ?? null;
            
            // Validation
            if (empty($ad) || empty($soyad)) {
                http_response_code(400);
                echo json_encode([
                    'status' => 400,
                    'message' => 'Ad ve soyad alanları zorunludur'
                ]);
                return;
            }
            
            // Profili güncelle
            $stmt = $db->prepare("
                UPDATE users 
                SET ad = ?, soyad = ?, telefon = ?, dogum_tarihi = ?, cinsiyet = ?
                WHERE id = ?
            ");
            $stmt->execute([$ad, $soyad, $telefon, $dogum_tarihi, $cinsiyet, $user_id]);
            
            // Log kaydı
            try {
                logActivity($user_id, 'profile_update', 'Profil bilgileri güncellendi');
            } catch (Exception $e) {
                error_log("Log activity error: " . $e->getMessage());
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Profil bilgileri başarıyla güncellendi'
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Profil güncellenirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
}

// API endpoint yönlendirmesi
$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['PATH_INFO'] ?? $_SERVER['REQUEST_URI'] ?? '';

// Debug log fonksiyonu
function debugLog($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] PROFILE DEBUG: $message\n";
    error_log($logMessage, 3, '/tmp/dermai_debug.log');
    // Aynı zamanda PHP error log'a da yaz
    error_log("PROFILE DEBUG: $message");
}

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Session-ID');

debugLog("=== REQUEST START ===");
debugLog("Request Method: " . $_SERVER['REQUEST_METHOD']);
debugLog("Content-Type: " . ($_SERVER['CONTENT_TYPE'] ?? 'not set'));
debugLog("Request URI: " . ($_SERVER['REQUEST_URI'] ?? 'not set'));
debugLog("HTTP Host: " . ($_SERVER['HTTP_HOST'] ?? 'not set'));

// Tüm header'ları logla
debugLog("=== ALL HEADERS ===");
if (function_exists('getallheaders')) {
    $headers = getallheaders();
    foreach ($headers as $key => $value) {
        debugLog("Header: $key = $value");
    }
} else {
    debugLog("getallheaders() function not available");
}

// $_SERVER'daki HTTP header'ları logla
debugLog("=== SERVER HTTP HEADERS ===");
foreach ($_SERVER as $key => $value) {
    if (strpos($key, 'HTTP_') === 0) {
        debugLog("Server Header: $key = $value");
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    debugLog("OPTIONS request - CORS preflight");
    exit(0);
}

switch($path) {
    case '/upload-photo':
        if ($method === 'POST') {
            ProfileHandler::uploadProfilePhoto();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/delete-photo':
        if ($method === 'DELETE') {
            ProfileHandler::deleteProfilePhoto();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/update':
        if ($method === 'PUT') {
            ProfileHandler::updateProfile();
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
                'POST /upload-photo - Profil fotoğrafı yükleme',
                'DELETE /delete-photo - Profil fotoğrafı silme',
                'PUT /update - Profil bilgileri güncelleme'
            ]
        ]);
        break;
}
?> 