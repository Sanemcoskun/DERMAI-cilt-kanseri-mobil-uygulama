-- DermAI Users tablosunu güncelleme scripti
USE dermai_db;

-- Cinsiyet enum'unu güncelle
ALTER TABLE users MODIFY COLUMN cinsiyet ENUM('Kadın', 'Erkek', 'Belirtmek İstemiyorum') NULL;

-- Yeni alanları ekle (eğer yoklarsa)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS yas INT NULL,
ADD COLUMN IF NOT EXISTS boy INT NULL,
ADD COLUMN IF NOT EXISTS kilo INT NULL,
ADD COLUMN IF NOT EXISTS kan_grubu VARCHAR(10) NULL,
ADD COLUMN IF NOT EXISTS cilt_tipi VARCHAR(50) NULL,
ADD COLUMN IF NOT EXISTS cilt_hassasiyeti VARCHAR(50) NULL,
ADD COLUMN IF NOT EXISTS alerjiler TEXT NULL,
ADD COLUMN IF NOT EXISTS ilaclar TEXT NULL,
ADD COLUMN IF NOT EXISTS ulke_kodu VARCHAR(5) DEFAULT '+90';

-- Tablo yapısını kontrol et
DESCRIBE users; 