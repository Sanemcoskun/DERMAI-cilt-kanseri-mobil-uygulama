<?php
// PHP warnings'leri kapat (sadece JSON dönmek için)
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 0);

class Database {
    private static $instance = null;
    private $connection;
    
    private $host = "localhost";
    private $db_name = "dermai_db";
    private $username = "root";
    private $password = "";
    
    private function __construct() {
        try {
            // XAMPP için socket veya standard bağlantı dene
            $socket = "/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock";
            if (file_exists($socket)) {
                $dsn = "mysql:unix_socket=" . $socket . ";dbname=" . $this->db_name . ";charset=utf8mb4";
            } else {
                $dsn = "mysql:host=" . $this->host . ";port=3306;dbname=" . $this->db_name . ";charset=utf8mb4";
            }
            
            $this->connection = new PDO(
                $dsn,
                $this->username,
                $this->password,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
                ]
            );
        } catch(PDOException $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Veritabanı bağlantı hatası',
                'error' => $e->getMessage()
            ]);
            exit();
        }
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }
    
    public function getConnection() {
        return $this->connection;
    }
    
    public function __clone() {}
    public function __wakeup() {}
}

// DermAI API güvenlik kontrolü
function validateApiKey() {
    // CLI ortamında (mysql_init.php gibi) API key kontrolü yapma
    if (php_sapi_name() === 'cli') {
        return;
    }
    
    // Feedback handler için API key kontrolü yapma (herkese açık)
    if (isset($_SERVER['SCRIPT_NAME']) && strpos($_SERVER['SCRIPT_NAME'], 'feedback_handler.php') !== false) {
        return;
    }
    
    // Debug test için API key kontrolü yapma
    if (isset($_SERVER['SCRIPT_NAME']) && strpos($_SERVER['SCRIPT_NAME'], 'debug_test.php') !== false) {
        return;
    }
    
    // OPTIONS request için CORS izni ver
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Session-ID');
        header('Access-Control-Max-Age: 86400');
        http_response_code(200);
        exit();
    }
    
    // CORS headers ekle
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Session-ID');
    header('Content-Type: application/json; charset=utf-8');
    
    // Web istekleri için API key kontrolü
    $headers = [];
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
    } else {
        // Apache olmayan serverlar için fallback
        foreach ($_SERVER as $key => $value) {
            if (strpos($key, 'HTTP_') === 0) {
                $header = str_replace(' ', '-', ucwords(str_replace('_', ' ', strtolower(substr($key, 5)))));
                $headers[$header] = $value;
            }
        }
    }
    
    // Debug için headers'ı logla
    error_log('Received headers: ' . print_r($headers, true));
    error_log('Raw $_SERVER: ' . print_r($_SERVER, true));
    
    // Farklı header isimleri dene
    $auth_header = $headers['Authorization'] ?? 
                   $headers['authorization'] ?? 
                   $_SERVER['HTTP_AUTHORIZATION'] ?? 
                   '';
    
    if (!str_starts_with($auth_header, 'Bearer ')) {
        error_log('Missing or invalid Authorization header: ' . $auth_header);
        http_response_code(401);
        echo json_encode([
            'status' => 401,
            'message' => 'Yetkilendirme başlığı eksik',
            'debug' => [
                'received_auth_header' => $auth_header,
                'all_headers' => $headers,
                'server_vars' => array_filter($_SERVER, function($key) {
                    return strpos($key, 'HTTP_') === 0;
                }, ARRAY_FILTER_USE_KEY)
            ]
        ]);
        exit();
    }
    
    $api_key = substr($auth_header, 7);
    if ($api_key !== 'dermai-api-2024') {
        error_log('Invalid API key: ' . $api_key);
        http_response_code(401);
        echo json_encode([
            'status' => 401,
            'message' => 'Geçersiz API anahtarı',
            'debug' => [
                'received_api_key' => $api_key,
                'expected_api_key' => 'dermai-api-2024'
            ]
        ]);
        exit();
    }
}

// Sistem logunu kaydet
function logActivity($action, $user_id = null, $details = null) {
    try {
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("
            INSERT INTO system_logs (user_id, işlem, detay, ip_address, user_agent) 
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $user_id,
            $action,
            $details,
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null
        ]);
    } catch (Exception $e) {
        // Log hatası sessizce geç
    }
}

// Her API çağrısında doğrulama yap (CLI hariç)
validateApiKey();
?> 