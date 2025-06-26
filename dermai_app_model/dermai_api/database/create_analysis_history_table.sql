-- Analiz Geçmişi tablosu
CREATE TABLE IF NOT EXISTS analysis_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    analysis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    region VARCHAR(50) NOT NULL,
    predicted_class VARCHAR(20) NOT NULL,
    class_name VARCHAR(255) NOT NULL,
    confidence DECIMAL(5,4) NOT NULL,
    risk_level VARCHAR(50) NOT NULL,
    risk_color VARCHAR(20) NOT NULL,
    recommendations TEXT NOT NULL,
    all_predictions JSON NULL,
    image_path VARCHAR(500) NULL,
    image_name VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_analysis_date (analysis_date),
    INDEX idx_predicted_class (predicted_class),
    INDEX idx_risk_level (risk_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 