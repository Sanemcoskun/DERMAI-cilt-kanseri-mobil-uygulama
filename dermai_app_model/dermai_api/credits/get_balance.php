<?php
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require_once '../config/database.php';
} catch (Exception $e) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Database connection error: ' . $e->getMessage()
    ]);
    exit();
}

session_start();

// Kullanıcı oturum kontrolü
if (!isset($_SESSION['user_id'])) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Oturum bulunamadı, lütfen giriş yapın'
    ]);
    exit();
}

$user_id = $_SESSION['user_id'];

try {
    $db = Database::getInstance()->getConnection();
    
    // Kullanıcının kredi bilgilerini al
    $stmt = $db->prepare("SELECT id, username, email, credits FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    if (!$user) {
        ob_clean();
        echo json_encode([
            'success' => false,
            'message' => 'Kullanıcı bulunamadı'
        ]);
        exit();
    }
    
    // Son kredi işlemini al
    $stmt = $db->prepare("
        SELECT action, amount, description, created_at 
        FROM credit_transactions 
        WHERE user_id = ? 
        ORDER BY created_at DESC 
        LIMIT 1
    ");
    $stmt->execute([$user_id]);
    $last_transaction = $stmt->fetch();
    
    ob_clean();
    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => $user['id'],
            'username' => $user['username'],
            'email' => $user['email'],
            'credits' => intval($user['credits']),
            'last_transaction' => $last_transaction,
            'last_updated' => date('Y-m-d H:i:s')
        ]
    ]);
    
} catch (Exception $e) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Kredi bilgisi alınamadı: ' . $e->getMessage()
    ]);
}
?> 