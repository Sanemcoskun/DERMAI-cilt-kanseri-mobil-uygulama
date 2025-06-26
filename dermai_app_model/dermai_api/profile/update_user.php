<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Preflight request için
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Sadece POST isteklerini kabul et
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'status' => false,
        'message' => 'Sadece POST istekleri desteklenir'
    ]);
    exit();
}

// Gerekli dosyaları dahil et
require_once '../config/database.php';

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
    // JSON input'u al
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Geçersiz JSON verisi');
    }
    
    // User ID kontrolü
    if (!isset($input['user_id'])) {
        throw new Exception('Kullanıcı ID gerekli');
    }
    
    $user_id = intval($input['user_id']);
    
    // Veritabanı bağlantısını al
    $pdo = Database::getInstance()->getConnection();
    
    // Güncellenebilir alanları tanımla
    $updateFields = [];
    $params = ['user_id' => $user_id];
    
    // Ad
    if (isset($input['name'])) {
        $updateFields[] = 'ad = :name';
        $params['name'] = trim($input['name']);
    }
    
    // Soyad
    if (isset($input['surname'])) {
        $updateFields[] = 'soyad = :surname';
        $params['surname'] = trim($input['surname']);
    }
    
    // Email
    if (isset($input['email'])) {
        $updateFields[] = 'email = :email';
        $params['email'] = trim($input['email']);
    }
    
    // Telefon
    if (isset($input['phone'])) {
        $updateFields[] = 'telefon = :phone';
        $params['phone'] = trim($input['phone']);
    }
    
    // Yaş
    if (isset($input['age'])) {
        $updateFields[] = 'yas = :age';
        $params['age'] = intval($input['age']);
    }
    
    // Boy
    if (isset($input['height'])) {
        $updateFields[] = 'boy = :height';
        $params['height'] = intval($input['height']);
    }
    
    // Kilo
    if (isset($input['weight'])) {
        $updateFields[] = 'kilo = :weight';
        $params['weight'] = intval($input['weight']);
    }
    
    // Cinsiyet
    if (isset($input['gender'])) {
        $updateFields[] = 'cinsiyet = :gender';
        $params['gender'] = trim($input['gender']);
    }
    
    // Kan grubu
    if (isset($input['blood_type'])) {
        $updateFields[] = 'kan_grubu = :blood_type';
        $params['blood_type'] = trim($input['blood_type']);
    }
    
    // Cilt tipi
    if (isset($input['skin_type'])) {
        $updateFields[] = 'cilt_tipi = :skin_type';
        $params['skin_type'] = trim($input['skin_type']);
    }
    
    // Cilt hassasiyeti
    if (isset($input['skin_sensitivity'])) {
        $updateFields[] = 'cilt_hassasiyeti = :skin_sensitivity';
        $params['skin_sensitivity'] = trim($input['skin_sensitivity']);
    }
    
    // Alerjiler
    if (isset($input['allergies'])) {
        $updateFields[] = 'alerjiler = :allergies';
        $params['allergies'] = trim($input['allergies']);
    }
    
    // İlaçlar
    if (isset($input['medications'])) {
        $updateFields[] = 'ilaclar = :medications';
        $params['medications'] = trim($input['medications']);
    }
    
    // Doğum tarihi
    if (isset($input['birth_date'])) {
        $updateFields[] = 'dogum_tarihi = :birth_date';
        $params['birth_date'] = trim($input['birth_date']);
    }
    
    // Ülke kodu
    if (isset($input['country_code'])) {
        $updateFields[] = 'ulke_kodu = :country_code';
        $params['country_code'] = trim($input['country_code']);
    }
    
    // Güncelleme yapılacak alan yoksa hata döndür
    if (empty($updateFields)) {
        throw new Exception('Güncellenecek alan bulunamadı');
    }
    
    // UPDATE sorgusu hazırla
    $sql = "UPDATE users SET " . implode(', ', $updateFields) . ", updated_at = NOW() WHERE id = :user_id";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute($params);
    
    if (!$result) {
        throw new Exception('Kullanıcı bilgileri güncellenemedi');
    }
    
    // Güncellenen kullanıcı bilgilerini getir
    $stmt = $pdo->prepare("
        SELECT 
            id,
            ad as name,
            soyad as surname,
            email,
            telefon as phone,
            yas as age,
            boy as height,
            kilo as weight,
            cinsiyet as gender,
            kan_grubu as blood_type,
            cilt_tipi as skin_type,
            cilt_hassasiyeti as skin_sensitivity,
            alerjiler as allergies,
            ilaclar as medications,
            dogum_tarihi as birth_date,
            ulke_kodu as country_code,
            profil_foto as profile_photo,
            created_at,
            updated_at
        FROM users 
        WHERE id = :user_id
    ");
    
    $stmt->execute(['user_id' => $user_id]);
    $userData = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$userData) {
        throw new Exception('Güncellenmiş kullanıcı bilgileri alınamadı');
    }
    
    // Başarılı yanıt
    echo json_encode([
        'status' => true,
        'message' => 'Kullanıcı bilgileri başarıyla güncellendi',
        'data' => $userData
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'status' => false,
        'message' => $e->getMessage()
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'message' => 'Veritabanı hatası: ' . $e->getMessage()
    ]);
}
?> 