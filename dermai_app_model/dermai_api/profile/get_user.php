<?php
include_once '../config/database.php';

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

    // Get user_id from request
    $user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;
    
    if (!$user_id) {
        throw new Exception('User ID is required');
    }

    // Query to fetch user profile
    $query = "SELECT 
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
    FROM users WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$user_id]);
    
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row) {
        $response = [
            "status" => true,
            "data" => $row
        ];
    } else {
        $response = [
            "status" => false,
            "message" => "User not found"
        ];
    }

} catch (Exception $e) {
    http_response_code(500);
    $response = [
        "status" => false,
        "message" => "Error: " . $e->getMessage()
    ];
}

// Send response
echo json_encode($response);
?>
