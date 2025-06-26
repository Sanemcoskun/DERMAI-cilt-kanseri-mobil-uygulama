<?php
// Debug dosyası - authorization kontrolü yok
error_reporting(E_ERROR | E_PARSE);

// Direkt bağlantı - auth_handler.php'yi atla
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'dermai_db';

$conn = mysqli_connect($host, $username, $password, $database);
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

$query = "SELECT * FROM analysis_history ORDER BY id DESC LIMIT 1";
$result = mysqli_query($conn, $query);

if ($row = mysqli_fetch_assoc($result)) {
    echo "<h3>Son Analiz:</h3>";
    echo "ID: " . $row['id'] . "<br>";
    echo "User ID: " . $row['user_id'] . "<br>";
    echo "Class Name: " . $row['class_name'] . "<br>";
    echo "Risk Level: " . $row['risk_level'] . "<br>";
    echo "Risk Color: " . $row['risk_color'] . "<br>";
    echo "Image Path: " . ($row['image_path'] ?: 'NULL') . "<br>";
    echo "Image Name: " . ($row['image_name'] ?: 'NULL') . "<br>";
    echo "Confidence: " . $row['confidence'] . "<br>";
    echo "Date: " . $row['analysis_date'] . "<br>";
    
    // Eğer image path varsa, dosyanın gerçekten var olup olmadığını kontrol et
    if ($row['image_path']) {
        $fullPath = __DIR__ . '/' . $row['image_path'];
        echo "Full Image Path: " . $fullPath . "<br>";
        echo "File Exists: " . (file_exists($fullPath) ? 'YES' : 'NO') . "<br>";
        
        if (file_exists($fullPath)) {
            echo "File Size: " . filesize($fullPath) . " bytes<br>";
        }
    }
} else {
    echo "Analiz bulunamadı.";
}

// Uploads klasörünü kontrol et
$uploadDir = __DIR__ . '/uploads/analysis_images';
echo "<br><h3>Upload Directory:</h3>";
echo "Dir: " . $uploadDir . "<br>";
echo "Exists: " . (is_dir($uploadDir) ? 'YES' : 'NO') . "<br>";

if (is_dir($uploadDir)) {
    $files = scandir($uploadDir);
    echo "Files: " . implode(', ', array_filter($files, function($f) { return $f !== '.' && $f !== '..'; })) . "<br>";
}

mysqli_close($conn);
?> 