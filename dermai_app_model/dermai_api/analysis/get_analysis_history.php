<?php
// Debug modunu aç
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
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

function getAnalysisHistory() {
    global $pdo;
    
    // PDO bağlantısını kontrol et
    if (!isset($pdo)) {
        $db = Database::getInstance();
        $pdo = $db->getConnection();
    }
    
    try {
        // User ID'yi al (GET veya POST'tan)
        $user_id = null;
        
        if ($_SERVER['REQUEST_METHOD'] === 'GET') {
            $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
        } else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $json = file_get_contents('php://input');
            $data = json_decode($json, true);
            $user_id = isset($data['user_id']) ? (int)$data['user_id'] : null;
        }
        
        if (!$user_id) {
            return [
                'success' => false,
                'message' => 'User ID gerekli'
            ];
        }
        
        // Kullanıcının var olduğunu kontrol et
        $user_check = $pdo->prepare("SELECT id FROM users WHERE id = ?");
        $user_check->execute([$user_id]);
        if (!$user_check->fetch()) {
            return [
                'success' => false,
                'message' => 'Geçersiz kullanıcı ID'
            ];
        }
        
        // Analiz geçmişini çek (en yeniden eskiye)
        $sql = "SELECT 
            id,
            analysis_date,
            region,
            predicted_class,
            class_name,
            confidence,
            risk_level,
            risk_color,
            recommendations,
            all_predictions,
            image_path,
            image_name,
            created_at
        FROM analysis_history 
        WHERE user_id = ? 
        ORDER BY analysis_date DESC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$user_id]);
        $analyses = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Recommendations JSON string'ini array'e çevir
        foreach ($analyses as &$analysis) {
            if (isset($analysis['recommendations'])) {
                $recommendations = json_decode($analysis['recommendations'], true);
                $analysis['recommendations'] = is_array($recommendations) ? $recommendations : [$analysis['recommendations']];
            }
            
            if (isset($analysis['all_predictions'])) {
                $analysis['all_predictions'] = json_decode($analysis['all_predictions'], true);
            }
            
            // Tarihi formatla
            $analysis['formatted_date'] = date('d M Y, H:i', strtotime($analysis['analysis_date']));
        }
        
        return [
            'success' => true,
            'message' => 'Analiz geçmişi başarıyla alındı',
            'data' => $analyses,
            'count' => count($analyses)
        ];
        
    } catch (PDOException $e) {
        error_log("Database Error in get_analysis_history.php: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Veritabanı hatası: ' . $e->getMessage()
        ];
    } catch (Exception $e) {
        error_log("General Error in get_analysis_history.php: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Genel hata: ' . $e->getMessage()
        ];
    }
}

// İsteği işle
$response = getAnalysisHistory();
echo json_encode($response, JSON_UNESCAPED_UNICODE);
?> 