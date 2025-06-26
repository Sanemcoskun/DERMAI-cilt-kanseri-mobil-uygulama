-- Users tablosuna credits kolonu ekle
USE dermai_db;

-- Credits kolonu ekle (eğer yoksa)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS credits INT DEFAULT 10 NOT NULL;

-- Mevcut kullanıcıların credits değerini 10 olarak ayarla
UPDATE users SET credits = 10 WHERE credits IS NULL OR credits = 0;

-- Tablo yapısını kontrol et
DESCRIBE users; 