<?php
// CLI modunda çalıştığımızı belirt
$_SERVER['REQUEST_METHOD'] = 'CLI';
require_once '../config/database.php';

// SQL query to create credit_transactions table
$sql = "CREATE TABLE IF NOT EXISTS credit_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    amount INT NOT NULL,
    description TEXT,
    package_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
)";

try {
    $db = Database::getInstance()->getConnection();
    $result = $db->exec($sql);
    if ($result !== false) {
        echo "Credit transactions table created successfully\n";
    } else {
        $error = $db->errorInfo();
        echo "Error creating credit transactions table: " . implode(', ', $error) . "\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?> 