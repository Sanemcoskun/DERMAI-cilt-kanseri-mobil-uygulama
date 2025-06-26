<?php
include_once '../config/database.php';

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Session-ID');
header('Content-Type: application/json; charset=utf-8');

// Handle OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Sadece POST metodunu kabul et
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'status' => false,
        'message' => 'Sadece POST metodu desteklenir'
    ]);
    exit();
}

try {
    // Input verilerini al
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Geçersiz JSON verisi');
    }

    // Authorization kontrolü
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if (!$authHeader || $authHeader !== 'Bearer dermai-api-2024') {
        http_response_code(401);
        echo json_encode([
            'status' => false,
            'message' => 'Yetkisiz erişim'
        ]);
        exit();
    }

    // Session ID kontrolü
    $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
    
    if (!$session_id) {
        throw new Exception('Session ID gereklidir');
    }

    // Database connection
    $database = Database::getInstance();
    $db = $database->getConnection();

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
        throw new Exception('Geçersiz veya süresi dolmuş session');
    }
    
    $user_id = $session['user_id'];

    // Input verilerini kontrol et
    $current_password = trim($input['current_password'] ?? '');
    $new_password = trim($input['new_password'] ?? '');
    $confirm_password = trim($input['confirm_password'] ?? '');

    // Validation
    if (empty($current_password) || empty($new_password) || empty($confirm_password)) {
        throw new Exception('Tüm alanları doldurun');
    }

    if ($new_password !== $confirm_password) {
        throw new Exception('Yeni şifreler eşleşmiyor');
    }

    if (strlen($new_password) < 6) {
        throw new Exception('Yeni şifre en az 6 karakter olmalı');
    }

    // Mevcut şifreyi kontrol et
    $stmt = $db->prepare("SELECT sifre FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    if (!$user) {
        throw new Exception('Kullanıcı bulunamadı');
    }

    // Mevcut şifreyi doğrula
    if (!password_verify($current_password, $user['sifre'])) {
        throw new Exception('Mevcut şifre yanlış');
    }

    // Aynı şifre kontrolü
    if (password_verify($new_password, $user['sifre'])) {
        throw new Exception('Yeni şifre mevcut şifre ile aynı olamaz');
    }

    // Yeni şifreyi hash'le
    $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

    // Şifreyi güncelle
    $stmt = $db->prepare("UPDATE users SET sifre = ?, updated_at = NOW() WHERE id = ?");
    $result = $stmt->execute([$hashed_password, $user_id]);

    if (!$result) {
        throw new Exception('Şifre güncellenirken hata oluştu');
    }

    // Log kaydı
    try {
        logActivity($user_id, 'password_change', 'Kullanıcı şifresini değiştirdi');
    } catch (Exception $e) {
        // Log hatası sessizce geç
    }

    // Başarılı response
    $response = [
        "status" => true,
        "message" => "Şifre başarıyla değiştirildi"
    ];

} catch (Exception $e) {
    http_response_code(400);
    $response = [
        "status" => false,
        "message" => $e->getMessage()
    ];
}

// Send response
echo json_encode($response);
?> 