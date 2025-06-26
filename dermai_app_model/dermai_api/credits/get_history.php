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

// Sayfalama parametreleri
$page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
$limit = isset($_GET['limit']) ? min(100, max(10, intval($_GET['limit']))) : 20;
$offset = ($page - 1) * $limit;

// Filtreleme parametreleri
$action_filter = isset($_GET['action']) ? $_GET['action'] : '';
$date_from = isset($_GET['date_from']) ? $_GET['date_from'] : '';
$date_to = isset($_GET['date_to']) ? $_GET['date_to'] : '';

try {
    $db = Database::getInstance()->getConnection();
    
    // WHERE koşulları oluştur
    $where_conditions = ['user_id = ?'];
    $params = [$user_id];
    
    if (!empty($action_filter)) {
        $where_conditions[] = 'action = ?';
        $params[] = $action_filter;
    }
    
    if (!empty($date_from)) {
        $where_conditions[] = 'created_at >= ?';
        $params[] = $date_from . ' 00:00:00';
    }
    
    if (!empty($date_to)) {
        $where_conditions[] = 'created_at <= ?';
        $params[] = $date_to . ' 23:59:59';
    }
    
    $where_clause = 'WHERE ' . implode(' AND ', $where_conditions);
    
    // Toplam kayıt sayısını al
    $count_sql = "SELECT COUNT(*) as total FROM credit_transactions $where_clause";
    $stmt = $db->prepare($count_sql);
    $stmt->execute($params);
    $total_records = $stmt->fetch()['total'];
    
    // Kredi geçmişini al
    $history_sql = "
        SELECT 
            id,
            action,
            amount,
            description,
            package_id,
            created_at,
            CASE 
                WHEN action IN ('purchase', 'add', 'bonus') THEN 'credit'
                WHEN action IN ('use', 'remove') THEN 'debit'
                ELSE 'neutral'
            END as transaction_type
        FROM credit_transactions 
        $where_clause
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
    ";
    
    $params[] = $limit;
    $params[] = $offset;
    
    $stmt = $db->prepare($history_sql);
    $stmt->execute($params);
    $history = $stmt->fetchAll();
    
    // İstatistikleri hesapla
    $stats_sql = "
        SELECT 
            SUM(CASE WHEN action IN ('purchase', 'add', 'bonus') THEN amount ELSE 0 END) as total_earned,
            SUM(CASE WHEN action IN ('use', 'remove') THEN amount ELSE 0 END) as total_used,
            COUNT(*) as total_transactions
        FROM credit_transactions 
        $where_clause
    ";
    
    // Son parametreleri kaldır (limit ve offset)
    $stats_params = array_slice($params, 0, -2);
    $stmt = $db->prepare($stats_sql);
    $stmt->execute($stats_params);
    $stats = $stmt->fetch();
    
    // Mevcut kredi bakiyesi
    $stmt = $db->prepare("SELECT credits FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $current_credits = $stmt->fetch()['credits'] ?? 0;
    
    ob_clean();
    echo json_encode([
        'success' => true,
        'data' => [
            'history' => $history,
            'pagination' => [
                'current_page' => $page,
                'per_page' => $limit,
                'total_records' => intval($total_records),
                'total_pages' => ceil($total_records / $limit)
            ],
            'statistics' => [
                'current_credits' => intval($current_credits),
                'total_earned' => intval($stats['total_earned'] ?? 0),
                'total_used' => intval($stats['total_used'] ?? 0),
                'total_transactions' => intval($stats['total_transactions'] ?? 0)
            ],
            'filters' => [
                'action' => $action_filter,
                'date_from' => $date_from,
                'date_to' => $date_to
            ]
        ]
    ]);
    
} catch (Exception $e) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Kredi geçmişi alınamadı: ' . $e->getMessage()
    ]);
}
?> 