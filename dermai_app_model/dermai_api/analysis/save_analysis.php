<?php
// Debug modunu aç
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

try {
    require_once '../config/database.php';
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Config yükleme hatası: ' . $e->getMessage()
    ]);
    exit;
}

function saveAnalysisResult() {
    global $pdo;
    
    // PDO bağlantısını kontrol et
    if (!isset($pdo)) {
        $db = Database::getInstance();
        $pdo = $db->getConnection();
    }
    
    try {
        // JSON girdisini al
        $json = file_get_contents('php://input');
        $data = json_decode($json, true);
        
        if (!$data) {
            return [
                'success' => false,
                'message' => 'Geçersiz JSON verisi'
            ];
        }
        
        // Gerekli alanları kontrol et
        $required_fields = ['user_id', 'region', 'predicted_class', 'class_name', 'confidence', 'risk_level', 'risk_color', 'recommendations'];
        foreach ($required_fields as $field) {
            if (!isset($data[$field])) {
                return [
                    'success' => false,
                    'message' => "Eksik alan: $field"
                ];
            }
        }
        
        // Kullanıcının var olduğunu kontrol et
        $user_check = $pdo->prepare("SELECT id FROM users WHERE id = ?");
        $user_check->execute([$data['user_id']]);
        if (!$user_check->fetch()) {
            return [
                'success' => false,
                'message' => 'Geçersiz kullanıcı ID'
            ];
        }
        
        // Analiz sonucunu kaydet
        $sql = "INSERT INTO analysis_history (
            user_id, region, predicted_class, class_name, confidence, 
            risk_level, risk_color, recommendations, all_predictions, 
            image_path, image_name
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        $stmt = $pdo->prepare($sql);
        
        $result = $stmt->execute([
            $data['user_id'],
            $data['region'],
            $data['predicted_class'],
            $data['class_name'],
            $data['confidence'],
            $data['risk_level'],
            $data['risk_color'],
            is_array($data['recommendations']) ? json_encode($data['recommendations']) : $data['recommendations'],
            isset($data['all_predictions']) ? json_encode($data['all_predictions']) : null,
            isset($data['image_path']) ? $data['image_path'] : null,
            isset($data['image_name']) ? $data['image_name'] : null
        ]);
        
        if ($result) {
            return [
                'success' => true,
                'message' => 'Analiz sonucu başarıyla kaydedildi',
                'analysis_id' => $pdo->lastInsertId()
            ];
        } else {
            return [
                'success' => false,
                'message' => 'Veritabanı kayıt hatası'
            ];
        }
        
    } catch (PDOException $e) {
        error_log("Database Error in save_analysis.php: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Veritabanı hatası: ' . $e->getMessage()
        ];
    } catch (Exception $e) {
        error_log("General Error in save_analysis.php: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Genel hata: ' . $e->getMessage()
        ];
    }
}

// POST isteğini işle
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $response = saveAnalysisResult();
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Sadece POST metodu desteklenir'
    ], JSON_UNESCAPED_UNICODE);
}
?> 