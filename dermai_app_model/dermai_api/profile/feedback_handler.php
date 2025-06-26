<?php
// Output buffering başlat - hata çıktılarını yakalamak için
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require_once '../config/database.php';
} catch (Exception $e) {
    // Buffer'ı temizle ve JSON error döndür
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Database connection error: ' . $e->getMessage()
    ]);
    exit();
}

session_start();

// Function to log email to file (coskunsanem86@gmail.com için)
function sendFeedbackEmail($feedbackData) {
    try {
        $to = 'coskunsanem86@gmail.com';
        $subject = 'DermAI Geri Bildirim - ' . $feedbackData['category'];
        
        $emailContent = "\n" . str_repeat("=", 80) . "\n";
        $emailContent .= "TARIH: " . date('Y-m-d H:i:s') . "\n";
        $emailContent .= "KIME: " . $to . "\n";
        $emailContent .= "KONU: " . $subject . "\n";
        $emailContent .= str_repeat("-", 80) . "\n";
        $emailContent .= "GÖNDEREN: " . $feedbackData['name'] . " <" . $feedbackData['email'] . ">\n";
        $emailContent .= "KATEGORİ: " . $feedbackData['category'] . "\n";
        $emailContent .= "DEĞERLENDİRME: " . $feedbackData['rating'] . "/5\n";
        $emailContent .= str_repeat("-", 80) . "\n";
        $emailContent .= "GERİ BİLDİRİM:\n" . $feedbackData['feedback'] . "\n";
        $emailContent .= str_repeat("=", 80) . "\n";
        
        // Log dosyasına yaz
        $logFile = '../logs/feedback_emails.log';
        file_put_contents($logFile, $emailContent, FILE_APPEND | LOCK_EX);
        
        return true;
        
    } catch (Exception $e) {
        error_log("Email logging error: " . $e->getMessage());
        return false;
    }
}

// Function to save feedback to database
function saveFeedbackToDatabase($feedbackData, $db) {
    try {
        $stmt = $db->prepare("
            INSERT INTO feedback (user_id, name, email, category, rating, feedback, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, NOW())
        ");
        
        $user_id = isset($_SESSION['user_id']) ? $_SESSION['user_id'] : null;
        
        return $stmt->execute([
            $user_id,
            $feedbackData['name'],
            $feedbackData['email'],
            $feedbackData['category'],
            $feedbackData['rating'],
            $feedbackData['feedback']
        ]);
    } catch (Exception $e) {
        error_log("Feedback database error: " . $e->getMessage());
        return false;
    }
}

// Handle POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        // Validate required fields
        $required_fields = ['name', 'email', 'category', 'rating', 'feedback'];
        foreach ($required_fields as $field) {
            if (!isset($input[$field]) || empty(trim($input[$field]))) {
                ob_clean();
                echo json_encode([
                    'success' => false,
                    'message' => 'Tüm alanları doldurun'
                ]);
                exit();
            }
        }
        
        // Validate email format
        if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
            ob_clean();
            echo json_encode([
                'success' => false,
                'message' => 'Geçerli bir e-posta adresi girin'
            ]);
            exit();
        }
        
        // Validate rating
        if (!is_numeric($input['rating']) || $input['rating'] < 1 || $input['rating'] > 5) {
            ob_clean();
            echo json_encode([
                'success' => false,
                'message' => 'Değerlendirme 1-5 arasında olmalıdır'
            ]);
            exit();
        }
        
        // Sanitize input data
        $feedbackData = [
            'name' => trim($input['name']),
            'email' => trim($input['email']),
            'category' => trim($input['category']),
            'rating' => intval($input['rating']),
            'feedback' => trim($input['feedback'])
        ];
        
        // Save to database first
        $dbSaved = false;
        try {
            $db = Database::getInstance()->getConnection();
            $dbSaved = saveFeedbackToDatabase($feedbackData, $db);
        } catch (Exception $e) {
            error_log("Database connection error: " . $e->getMessage());
        }
        
        // Send email (async - don't wait for result)
        $emailSent = sendFeedbackEmail($feedbackData);
        
        // Buffer'ı temizle ve sadece JSON döndür
        ob_clean();
        
        if ($dbSaved) {
            // E-posta bilgilerini log'a yaz
            error_log("Feedback received: " . json_encode($feedbackData));
            
            echo json_encode([
                'success' => true,
                'message' => 'Geri bildiriminiz başarıyla gönderildi ve coskunsanem86@gmail.com adresine iletildi',
                'data' => [
                    'email_sent' => $emailSent,
                    'database_saved' => $dbSaved,
                    'email_target' => 'coskunsanem86@gmail.com'
                ]
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Geri bildirim kaydedilemedi, lütfen tekrar deneyin'
            ]);
        }
        
    } catch (Exception $e) {
        ob_clean();
        error_log("Feedback handler error: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Bir hata oluştu, lütfen tekrar deneyin'
        ]);
    }
} else {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Sadece POST istekleri kabul edilir'
    ]);
}
?> 