<?php
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Sadece POST istekleri kabul edilir'
    ]);
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
$input = json_decode(file_get_contents('php://input'), true);

// Miktar kontrolü
if (!isset($input['amount']) || $input['amount'] <= 0) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Geçerli bir miktar belirtin'
    ]);
    exit();
}

$amount = intval($input['amount']);
$description = $input['description'] ?? 'Kredi eklendi';
$reason = $input['reason'] ?? 'manual'; // bonus, refund, promotion, manual

try {
    $db = Database::getInstance()->getConnection();
    
    // Mevcut kredileri al
    $stmt = $db->prepare("SELECT credits FROM users WHERE id = ?");
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
    
    $current_credits = intval($user['credits']);
    $new_credits = $current_credits + $amount;
    
    // Transaction başlat
    $db->beginTransaction();
    
    try {
        // Kredileri güncelle
        $stmt = $db->prepare("UPDATE users SET credits = ? WHERE id = ?");
        $stmt->execute([$new_credits, $user_id]);
        
        // İşlemi kaydet
        $stmt = $db->prepare("
            INSERT INTO credit_transactions 
            (user_id, action, amount, description, created_at) 
            VALUES (?, 'add', ?, ?, NOW())
        ");
        $stmt->execute([$user_id, $amount, $description]);
        
        // Transaction commit
        $db->commit();
        
        ob_clean();
        echo json_encode([
            'success' => true,
            'message' => 'Kredi başarıyla eklendi',
            'data' => [
                'added_credits' => $amount,
                'previous_credits' => $current_credits,
                'new_credits' => $new_credits,
                'reason' => $reason,
                'description' => $description,
                'transaction_date' => date('Y-m-d H:i:s')
            ]
        ]);
        
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    }
    
} catch (Exception $e) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Kredi ekleme hatası: ' . $e->getMessage()
    ]);
}
?> 