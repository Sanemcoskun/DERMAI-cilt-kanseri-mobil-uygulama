<?php
// DermAI API - Ana Giriş Noktası
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Session-ID');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config/database.php';

// URL path'i al
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = str_replace('/projeler/dermai/dermai_api', '', $path); // XAMPP path'ini temizle

// API Documentation endpoint
if ($path === '/' || $path === '/index.php' || empty($path)) {
    echo json_encode([
        'status' => 200,
        'message' => 'DermAI API v1.0',
        'description' => 'Cilt Kanseri Tespiti ve Analizi API\'si',
        'endpoints' => [
            'Authentication' => [
                'POST /auth/register - Kullanıcı kaydı',
                'POST /auth/login - Kullanıcı girişi',
                'POST /auth/logout - Kullanıcı çıkışı',
                'GET /auth/validate - Session doğrulama',
                'GET /auth/user - Kullanıcı profil bilgileri'
            ],
            'Analysis' => [
                'POST /analysis/upload - Cilt fotoğrafı yükleme ve analiz',
                'GET /analysis/history - Analiz geçmişi',
                'GET /analysis/{id} - Belirli analiz detayı',
                'DELETE /analysis/{id} - Analiz silme'
            ],
            'Profile' => [
                'GET /profile - Profil bilgileri',
                'PUT /profile - Profil güncelleme',
                'POST /profile/photo - Profil fotoğrafı güncelleme'
            ],
            'Notifications' => [
                'GET /notifications - Bildirimler',
                'PUT /notifications/{id}/read - Bildirimi okundu olarak işaretle',
                'DELETE /notifications/{id} - Bildirimi sil'
            ]
        ],
        'authentication' => [
            'type' => 'Bearer Token',
            'header' => 'Authorization: Bearer dermai-api-2024',
            'session_header' => 'X-Session-ID: {session_id}'
        ],
        'database' => [
            'name' => 'dermai_db',
            'status' => 'active',
            'charset' => 'utf8mb4'
        ],
        'version' => '1.0.0',
        'last_updated' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit();
}

// Auth endpoints'i yönlendir
if (strpos($path, '/auth') === 0) {
    $_SERVER['PATH_INFO'] = str_replace('/auth', '', $path);
    require_once 'auth/auth_handler.php';
    exit();
}

// Future endpoints (placeholder)
if (strpos($path, '/analysis') === 0) {
    http_response_code(501);
    echo json_encode([
        'status' => 501,
        'message' => 'Analysis endpoint henüz geliştirilme aşamasında',
        'coming_soon' => true
    ]);
    exit();
}

if (strpos($path, '/profile') === 0) {
    $_SERVER['PATH_INFO'] = str_replace('/profile', '', $path);
    require_once 'profile/profile_handler.php';
    exit();
}

if (strpos($path, '/notifications') === 0) {
    http_response_code(501);
    echo json_encode([
        'status' => 501,
        'message' => 'Notifications endpoint henüz geliştirilme aşamasında',
        'coming_soon' => true
    ]);
    exit();
}

// Blog endpoints'i yönlendir
if (strpos($path, '/blog') === 0) {
    $_SERVER['PATH_INFO'] = str_replace('/blog', '', $path);
    require_once 'blog/blog_handler.php';
    exit();
}

// 404 - Endpoint bulunamadı
http_response_code(404);
echo json_encode([
    'status' => 404,
    'message' => 'API endpoint bulunamadı',
    'path' => $path,
    'available_paths' => [
        '/ - API dokümantasyonu',
        '/auth/* - Kimlik doğrulama işlemleri',
        '/analysis/* - Cilt analizi işlemleri (yakında)',
        '/profile/* - Profil işlemleri (yakında)', 
        '/notifications/* - Bildirim işlemleri (yakında)'
    ]
]);
?> 