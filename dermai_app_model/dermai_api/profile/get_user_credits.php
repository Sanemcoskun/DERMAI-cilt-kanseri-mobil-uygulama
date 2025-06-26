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

try {
    // Database connection
    $database = Database::getInstance();
    $db = $database->getConnection();

    // Get session_id from headers
    $session_id = $headers['X-Session-ID'] ?? $headers['x-session-id'] ?? '';
    
    if (!$session_id) {
        throw new Exception('Session ID gereklidir');
    }

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

    // Kullanıcının temel bilgilerini ve kredi bilgisini çek
    $query = "SELECT 
        id,
        ad as name,
        soyad as surname,
        email,
        credits,
        created_at,
        updated_at
    FROM users WHERE id = ? AND aktif = 1";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$user_id]);
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        throw new Exception('Kullanıcı bulunamadı');
    }

    // Kredi kullanım geçmişini al (son 10 işlem)
    $historyQuery = "
        SELECT 
            işlem as action,
            detay as details,
            created_at,
            ip_address
        FROM system_logs 
        WHERE user_id = ? AND işlem LIKE '%credit%' 
        ORDER BY created_at DESC
        LIMIT 10
    ";
    
    $stmt = $db->prepare($historyQuery);
    $stmt->execute([$user_id]);
    $creditHistory = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Kredi istatistikleri
    $statsQuery = "
        SELECT 
            COUNT(*) as total_transactions,
            COUNT(CASE WHEN işlem = 'credits_usage' THEN 1 END) as total_usage,
            COUNT(CASE WHEN işlem = 'credits_usage' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as usage_last_30_days
        FROM system_logs 
        WHERE user_id = ? AND işlem LIKE '%credit%'
    ";
    
    $stmt = $db->prepare($statsQuery);
    $stmt->execute([$user_id]);
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);

    // Başarılı response
    $response = [
        "status" => true,
        "message" => "Kredi bilgileri başarıyla getirildi",
        "data" => [
            "user_info" => [
                "id" => (int)$user['id'],
                "name" => $user['name'],
                "surname" => $user['surname'],
                "email" => $user['email'],
                "member_since" => $user['created_at'],
                "last_updated" => $user['updated_at']
            ],
            "credits" => [
                "current_balance" => (int)$user['credits'],
                "history" => $creditHistory,
                "statistics" => [
                    "total_transactions" => (int)$stats['total_transactions'],
                    "total_usage" => (int)$stats['total_usage'],
                    "usage_last_30_days" => (int)$stats['usage_last_30_days']
                ]
            ]
        ]
    ];

    // Log kaydı
    try {
        logActivity($user_id, 'credits_view', 'Kredi bilgileri görüntülendi');
    } catch (Exception $e) {
        // Log hatası sessizce geç
    }

} catch (Exception $e) {
    http_response_code(500);
    $response = [
        "status" => false,
        "message" => "Hata: " . $e->getMessage()
    ];
}

// Send response
echo json_encode($response);
?> 