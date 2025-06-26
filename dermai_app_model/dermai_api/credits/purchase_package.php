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

// Paket ID kontrolü
if (!isset($input['package_id'])) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Paket ID gerekli'
    ]);
    exit();
}

// Kredi paketleri
function getCreditPackages() {
    return [
        1 => [
            'id' => 1,
            'name' => 'Başlangıç Paketi',
            'credits' => 10,
            'price' => 9.99,
            'currency' => 'TL',
            'description' => '10 kredi ile temel analizler'
        ],
        2 => [
            'id' => 2,
            'name' => 'Standart Paket',
            'credits' => 25,
            'price' => 19.99,
            'currency' => 'TL',
            'description' => '25 kredi ile detaylı analizler'
        ],
        3 => [
            'id' => 3,
            'name' => 'Premium Paket',
            'credits' => 50,
            'price' => 34.99,
            'currency' => 'TL',
            'description' => '50 kredi ile profesyonel analizler'
        ],
        4 => [
            'id' => 4,
            'name' => 'Süper Paket',
            'credits' => 100,
            'price' => 59.99,
            'currency' => 'TL',
            'description' => '100 kredi ile sınırsız analizler'
        ]
    ];
}

$packages = getCreditPackages();
$package_id = intval($input['package_id']);

if (!isset($packages[$package_id])) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Geçersiz paket ID'
    ]);
    exit();
}

$selected_package = $packages[$package_id];

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
    $new_credits = $current_credits + $selected_package['credits'];
    
    // Transaction başlat
    $db->beginTransaction();
    
    try {
        // Kredileri güncelle
        $stmt = $db->prepare("UPDATE users SET credits = ? WHERE id = ?");
        $stmt->execute([$new_credits, $user_id]);
        
        // İşlemi kaydet
        $stmt = $db->prepare("
            INSERT INTO credit_transactions 
            (user_id, action, amount, description, package_id, created_at) 
            VALUES (?, 'purchase', ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $user_id, 
            $selected_package['credits'], 
            $selected_package['name'] . ' satın alındı',
            $selected_package['id']
        ]);
        
        // Transaction commit
        $db->commit();
        
        ob_clean();
        echo json_encode([
            'success' => true,
            'message' => 'Kredi paketi başarıyla satın alındı',
            'data' => [
                'package' => $selected_package,
                'previous_credits' => $current_credits,
                'new_credits' => $new_credits,
                'added_credits' => $selected_package['credits'],
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
        'message' => 'Satın alma işlemi başarısız: ' . $e->getMessage()
    ]);
}
?> 