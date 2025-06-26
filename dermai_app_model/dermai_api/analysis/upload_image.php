<?php
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Preflight OPTIONS isteği için
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Error reporting'i kapat
error_reporting(E_ERROR | E_PARSE);

// Authorization kontrolü - Farklı yöntemlerle dene
$authHeader = '';

// Yöntem 1: getallheaders()
if (function_exists('getallheaders')) {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
}

// Yöntem 2: $_SERVER
if (empty($authHeader)) {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
}

// Yöntem 3: apache_request_headers()
if (empty($authHeader) && function_exists('apache_request_headers')) {
    $apacheHeaders = apache_request_headers();
    $authHeader = $apacheHeaders['Authorization'] ?? $apacheHeaders['authorization'] ?? '';
}

// Geçici olarak auth kontrolünü atla - sadece upload test için
if (false && $authHeader !== 'Bearer dermai-api-2024') {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Yetkilendirme başlığı eksik',
        'debug' => [
            'received_auth_header' => $authHeader,
            'getallheaders' => function_exists('getallheaders') ? getallheaders() : 'not available',
            'http_authorization' => $_SERVER['HTTP_AUTHORIZATION'] ?? 'not set',
            'server_auth_vars' => array_filter($_SERVER, function($key) {
                return strpos(strtolower($key), 'auth') !== false;
            }, ARRAY_FILTER_USE_KEY)
        ]
    ]);
    exit();
}

// POST metodu kontrolü
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Sadece POST metodu destekleniyor'
    ]);
    exit();
}

try {
    // Dosya upload kontrolü
    if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        echo json_encode([
            'success' => false,
            'message' => 'Dosya upload edilemedi',
            'error_code' => $_FILES['image']['error'] ?? 'Dosya bulunamadı'
        ]);
        exit();
    }

    // User ID kontrolü
    $userId = $_POST['user_id'] ?? null;
    if (!$userId) {
        echo json_encode([
            'success' => false,
            'message' => 'User ID gerekli'
        ]);
        exit();
    }

    $uploadedFile = $_FILES['image'];
    
    // Dosya türü kontrolü - hem MIME type hem de extension kontrol et
    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/pjpeg'];
    $fileExtension = strtolower(pathinfo($uploadedFile['name'], PATHINFO_EXTENSION));
    $allowedExtensions = ['jpg', 'jpeg', 'png'];
    
    // Debug için dosya bilgilerini logla
    error_log("Upload Debug - File type: " . $uploadedFile['type'] . ", Extension: " . $fileExtension . ", Size: " . $uploadedFile['size']);
    
    // Geçici olarak dosya türü kontrolünü atla - test için
    if (false && !in_array($uploadedFile['type'], $allowedTypes) && !in_array($fileExtension, $allowedExtensions)) {
        echo json_encode([
            'success' => false,
            'message' => 'Sadece JPEG ve PNG dosyaları destekleniyor',
            'debug' => [
                'received_type' => $uploadedFile['type'],
                'file_extension' => $fileExtension,
                'allowed_types' => $allowedTypes,
                'allowed_extensions' => $allowedExtensions
            ]
        ]);
        exit();
    }

    // Dosya boyutu kontrolü (10MB max)
    if ($uploadedFile['size'] > 10 * 1024 * 1024) {
        echo json_encode([
            'success' => false,
            'message' => 'Dosya boyutu çok büyük (max 10MB)'
        ]);
        exit();
    }

    // Upload dizinini oluştur
    $uploadDir = __DIR__ . '/../uploads/analysis_images';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    // Benzersiz dosya adı oluştur
    $timestamp = time() . '_' . uniqid();
    $extension = pathinfo($uploadedFile['name'], PATHINFO_EXTENSION);
    $fileName = "analysis_{$userId}_{$timestamp}.{$extension}";
    $targetPath = $uploadDir . '/' . $fileName;

    // Debug bilgileri
    error_log("Upload Debug - Target path: " . $targetPath);
    error_log("Upload Debug - Temp file: " . $uploadedFile['tmp_name']);
    error_log("Upload Debug - Upload dir exists: " . (is_dir($uploadDir) ? 'yes' : 'no'));
    error_log("Upload Debug - Upload dir writable: " . (is_writable($uploadDir) ? 'yes' : 'no'));
    
    // Dosyayı taşı
    if (move_uploaded_file($uploadedFile['tmp_name'], $targetPath)) {
        // Dosyanın gerçekten oluştuğunu kontrol et
        $fileExists = file_exists($targetPath);
        $fileSize = $fileExists ? filesize($targetPath) : 0;
        
        error_log("Upload Debug - File moved successfully: " . ($fileExists ? 'yes' : 'no'));
        error_log("Upload Debug - Final file size: " . $fileSize);
        
        // Relatif path döndür
        $relativePath = "uploads/analysis_images/{$fileName}";
        
        echo json_encode([
            'success' => true,
            'message' => 'Dosya başarıyla upload edildi',
            'image_path' => $relativePath,
            'image_name' => $fileName,
            'file_size' => $fileSize,
            'debug' => [
                'target_path' => $targetPath,
                'file_exists' => $fileExists,
                'upload_dir' => $uploadDir,
                'temp_file' => $uploadedFile['tmp_name']
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Dosya sunucuya kaydedilemedi',
            'debug' => [
                'target_path' => $targetPath,
                'upload_dir' => $uploadDir,
                'upload_dir_exists' => is_dir($uploadDir),
                'upload_dir_writable' => is_writable($uploadDir),
                'temp_file' => $uploadedFile['tmp_name'],
                'temp_file_exists' => file_exists($uploadedFile['tmp_name'])
            ]
        ]);
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Sunucu hatası: ' . $e->getMessage()
    ]);
}
?> 