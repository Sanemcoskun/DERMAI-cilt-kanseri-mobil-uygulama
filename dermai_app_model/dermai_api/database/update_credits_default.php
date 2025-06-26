<?php
require_once '../config/database.php';

try {
    $pdo = Database::getInstance()->getConnection();
    
    // Modify credits column to have a default value of 10
    $sql = "ALTER TABLE users MODIFY COLUMN credits INT DEFAULT 10 NOT NULL";
    $pdo->exec($sql);
    
    // Update existing users that have null credits
    $sql = "UPDATE users SET credits = 10 WHERE credits IS NULL";
    $pdo->exec($sql);
    
    echo "Credits column default value set to 10 successfully.";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
