<?php
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'DELETE'])) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Sadece POST/DELETE istekleri kabul edilir'
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
$description = $input['description'] ?? 'Kredi silindi';
$reason = $input['reason'] ?? 'manual'; // penalty, refund, correction, manual

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
    $new_credits = max(0, $current_credits - $amount); // Negatif olmayacak şekilde
    $actual_removed = $current_credits - $new_credits; // Gerçekte silinen miktar
    
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
            VALUES (?, 'remove', ?, ?, NOW())
        ");
        $stmt->execute([$user_id, $actual_removed, $description]);
        
        // Transaction commit
        $db->commit();
        
        ob_clean();
        echo json_encode([
            'success' => true,
            'message' => 'Kredi başarıyla silindi',
            'data' => [
                'requested_amount' => $amount,
                'actual_removed' => $actual_removed,
                'previous_credits' => $current_credits,
                'remaining_credits' => $new_credits,
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
        'message' => 'Kredi silme hatası: ' . $e->getMessage()
    ]);
}
?> 