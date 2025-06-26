-- DermAI API MySQL Veritabanı İnisiyalizasyon Scripti
-- Auth Handler ile uyumlu tablolar

-- Veritabanını oluştur
CREATE DATABASE IF NOT EXISTS dermai_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE dermai_db;

-- 1. USERS tablosu - Kullanıcı bilgileri
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    sifre VARCHAR(255) NOT NULL,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    telefon VARCHAR(20) NULL,
    dogum_tarihi DATE NULL,
    cinsiyet ENUM('Kadın', 'Erkek', 'Belirtmek İstemiyorum') NULL,
    yas INT NULL,
    boy INT NULL,
    kilo INT NULL,
    kan_grubu VARCHAR(10) NULL,
    cilt_tipi VARCHAR(50) NULL,
    cilt_hassasiyeti VARCHAR(50) NULL,
    alerjiler TEXT NULL,
    ilaclar TEXT NULL,
    ulke_kodu VARCHAR(5) DEFAULT '+90',
    profil_foto VARCHAR(255) NULL,
    aktif TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_aktif (aktif),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. USER_SESSIONS tablosu - Kullanıcı oturumları
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_id VARCHAR(64) NOT NULL UNIQUE,
    device_info TEXT NULL,
    ip_address VARCHAR(45) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. NOTIFICATIONS tablosu - Kullanıcı bildirimleri
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    başlık VARCHAR(255) NOT NULL,
    mesaj TEXT NOT NULL,
    tip ENUM('bilgi', 'başarı', 'uyarı', 'hata') DEFAULT 'bilgi',
    okundu TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_okundu (okundu),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. SKIN_ANALYSES tablosu - Cilt analizleri (getUserData fonksiyonunda kullanılıyor)
CREATE TABLE IF NOT EXISTS skin_analyses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    analiz_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sonuc JSON NULL,
    durum ENUM('tamamlandı', 'işlemde', 'hata') DEFAULT 'tamamlandı',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_analiz_tarihi (analiz_tarihi),
    INDEX idx_durum (durum)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. SYSTEM_LOGS tablosu - Sistem aktivite logları
CREATE TABLE IF NOT EXISTS system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    işlem VARCHAR(255) NOT NULL,
    detay TEXT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_işlem (işlem),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Süresi dolmuş oturumları temizlemek için event scheduler
-- NOT: Event scheduler manual olarak phpMyAdmin'den ayarlanabilir
-- SET GLOBAL event_scheduler = ON;

-- Event tanımı (gerekirse manuel olarak phpMyAdmin'den eklenecek)
-- CREATE EVENT cleanup_expired_sessions
-- ON SCHEDULE EVERY 1 HOUR
-- DO DELETE FROM user_sessions WHERE expires_at < NOW();

-- İndeksleri optimize et (tabloları oluşturduktan sonra çalışacak)
-- OPTIMIZE TABLE users, user_sessions, notifications, skin_analyses, system_logs;

-- Tablo bilgilerini göster (install_database.php'de kontrol edilecek)
-- SHOW TABLES;
-- DESCRIBE users;
-- DESCRIBE user_sessions;
-- DESCRIBE notifications; 