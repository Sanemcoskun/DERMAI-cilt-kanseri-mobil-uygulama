<?php
// DermAI - MySQL Database Initialization
// Bu dosyayı çalıştırarak DermAI veritabanını otomatik olarak kurabilirsiniz.
// Güvenlik önlemi yoktur, direkt ziyaret ederek kurabilirsiniz.

header('Content-Type: text/html; charset=utf-8');
echo "<h1>DermAI Veritabanı Kurulum</h1>";
echo "<p>Veritabanı tabloları oluşturuluyor...</p>";

// Veritabanı bağlantı bilgileri
$host = 'localhost';
$dbname = 'dermai_db';
$username = 'root';
$password = '';

try {
    // XAMPP için socket veya standard bağlantı dene
    $socket = "/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock";
    if (file_exists($socket)) {
        $pdo = new PDO("mysql:unix_socket=$socket", $username, $password);
    } else {
        $pdo = new PDO("mysql:host=$host;port=3306", $username, $password);
    }
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<p>✓ MySQL bağlantısı başarılı</p>";
    
    // Veritabanını oluştur
    $pdo->exec("CREATE DATABASE IF NOT EXISTS $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    echo "<p>✓ Veritabanı '$dbname' oluşturuldu</p>";
    
    // Veritabanına bağlan
    if (file_exists($socket)) {
        $pdo = new PDO("mysql:unix_socket=$socket;dbname=$dbname", $username, $password);
    } else {
        $pdo = new PDO("mysql:host=$host;port=3306;dbname=$dbname", $username, $password);
    }
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<p>✓ Veritabanına bağlanıldı</p>";
    
    // 1. Kullanıcılar tablosu (kullanıcı adı olmadan)
    $pdo->exec("DROP TABLE IF EXISTS users");
    $pdo->exec("
        CREATE TABLE users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(100) UNIQUE NOT NULL,
            sifre VARCHAR(255) NOT NULL,
            ad VARCHAR(50) NOT NULL,
            soyad VARCHAR(50) NOT NULL,
            telefon VARCHAR(20),
            dogum_tarihi DATE,
            cinsiyet ENUM('erkek', 'kadın', 'diğer'),
            profil_foto VARCHAR(255),
            email_dogrulandi BOOLEAN DEFAULT FALSE,
            aktif BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_email (email),
            INDEX idx_aktif (aktif)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Kullanıcılar tablosu oluşturuldu</p>";
    
    // 2. Kullanıcı oturumları tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS user_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            session_id VARCHAR(64) UNIQUE NOT NULL,
            device_info TEXT,
            ip_address VARCHAR(45),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            INDEX idx_session_id (session_id),
            INDEX idx_user_id (user_id),
            INDEX idx_expires_at (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Kullanıcı oturumları tablosu oluşturuldu</p>";
    
    // 3. Cilt analizi sonuçları tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS skin_analyses (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            analiz_id VARCHAR(50) UNIQUE NOT NULL,
            fotograf_yolu VARCHAR(255) NOT NULL,
            analiz_sonucu JSON,
            risk_seviyesi ENUM('düşük', 'orta', 'yüksek', 'kritik') NOT NULL,
            güven_skoru DECIMAL(5,2),
            öneriler TEXT,
            doktor_görüşü_gerekli BOOLEAN DEFAULT FALSE,
            analiz_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            INDEX idx_user_id (user_id),
            INDEX idx_analiz_id (analiz_id),
            INDEX idx_risk_seviyesi (risk_seviyesi),
            INDEX idx_analiz_tarihi (analiz_tarihi)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Cilt analizi sonuçları tablosu oluşturuldu</p>";
    
    // 4. Fotoğraflar tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS photos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            analysis_id INT,
            dosya_adi VARCHAR(255) NOT NULL,
            dosya_yolu VARCHAR(255) NOT NULL,
            dosya_boyutu INT,
            mime_type VARCHAR(50),
            genişlik INT,
            yükseklik INT,
            upload_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (analysis_id) REFERENCES skin_analyses(id) ON DELETE CASCADE,
            INDEX idx_user_id (user_id),
            INDEX idx_analysis_id (analysis_id),
            INDEX idx_upload_tarihi (upload_tarihi)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Fotoğraflar tablosu oluşturuldu</p>";
    
    // 5. Doktor tavsiyeleri tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS doctor_recommendations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            analysis_id INT NOT NULL,
            doktor_id INT,
            tavsiye TEXT NOT NULL,
            aciliyet_durumu ENUM('düşük', 'orta', 'yüksek', 'acil') NOT NULL,
            randevu_önerisi BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (analysis_id) REFERENCES skin_analyses(id) ON DELETE CASCADE,
            INDEX idx_analysis_id (analysis_id),
            INDEX idx_aciliyet_durumu (aciliyet_durumu),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Doktor tavsiyeleri tablosu oluşturuldu</p>";
    
    // 6. Bildirimler tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            başlık VARCHAR(200) NOT NULL,
            mesaj TEXT NOT NULL,
            tip ENUM('bilgi', 'uyarı', 'başarı', 'hata') DEFAULT 'bilgi',
            okundu BOOLEAN DEFAULT FALSE,
            analiz_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (analiz_id) REFERENCES skin_analyses(id) ON DELETE SET NULL,
            INDEX idx_user_id (user_id),
            INDEX idx_okundu (okundu),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Bildirimler tablosu oluşturuldu</p>";
    
    // 7. Cilt tipleri referans tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS skin_types (
            id INT AUTO_INCREMENT PRIMARY KEY,
            tip_adi VARCHAR(50) NOT NULL,
            açıklama TEXT,
            özellikler JSON,
            bakım_önerileri TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Cilt tipleri tablosu oluşturuldu</p>";
    
    // 8. Sistem logları tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS system_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            işlem VARCHAR(100) NOT NULL,
            detay TEXT,
            ip_address VARCHAR(45),
            user_agent TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
            INDEX idx_user_id (user_id),
            INDEX idx_işlem (işlem),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Sistem logları tablosu oluşturuldu</p>";
    
    // 9. Blog yazıları tablosu
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS blog_posts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            baslik VARCHAR(255) NOT NULL,
            ozet TEXT,
            icerik LONGTEXT NOT NULL,
            kapak_resmi VARCHAR(255),
            kategori VARCHAR(100) NOT NULL,
            okunma_sayisi INT DEFAULT 0,
            aktif BOOLEAN DEFAULT 1,
            slayt_goster BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_kategori (kategori),
            INDEX idx_aktif (aktif),
            INDEX idx_slayt_goster (slayt_goster),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p>✓ Blog yazıları tablosu oluşturuldu</p>";
    
    // Varsayılan cilt tiplerini ekle
    $pdo->exec("
        INSERT IGNORE INTO skin_types (id, tip_adi, açıklama, özellikler, bakım_önerileri) VALUES
        (1, 'Normal', 'Dengeli, sağlıklı cilt', '{\"yaşlılık\": \"orta\", \"hassaslık\": \"düşük\"}', 'Günlük nemlendirici ve güneş kremi kullanın'),
        (2, 'Kuru', 'Nem eksikliği olan cilt', '{\"yaşlılık\": \"yüksek\", \"hassaslık\": \"orta\"}', 'Yoğun nemlendirici kullanın, uzun sıcak duş almayın'),
        (3, 'Yağlı', 'Sebum üretimi fazla olan cilt', '{\"yaşlılık\": \"düşük\", \"hassaslık\": \"düşük\"}', 'Yağsız ürünler kullanın, günde 2 kez yıkayın'),
        (4, 'Karma', 'T bölgesi yağlı, yanaklar kuru', '{\"yaşlılık\": \"orta\", \"hassaslık\": \"orta\"}', 'Bölgesel bakım yapın, farklı ürünler kullanın'),
        (5, 'Hassas', 'Kolay tahriş olan cilt', '{\"yaşlılık\": \"orta\", \"hassaslık\": \"yüksek\"}', 'Parfümsüz ürünler kullanın, test yapın')
    ");
    echo "<p>✓ Varsayılan cilt tipleri eklendi</p>";
    
    // Örnek blog yazılarını ekle
    $pdo->exec("
        INSERT IGNORE INTO blog_posts (id, baslik, ozet, icerik, kategori, okunma_sayisi, aktif, slayt_goster) VALUES
        (1, 'Cilt Kanseri Belirtileri ve Erken Teşhis', 'Cilt kanserinin erken belirtilerini tanımak hayat kurtarabilir. Bu yazıda en önemli uyarı işaretlerini öğrenin.', 
         'Cilt kanseri, dünyada en yaygın kanser türlerinden biridir. Erken teşhis edildiğinde tedavi şansı oldukça yüksektir. Bu nedenle cildinizde meydana gelen değişiklikleri takip etmek son derece önemlidir.\\n\\nABCDE kuralı:\\n\\n**A - Asimetri:** Benin bir yarısı diğer yarısına benzemiyor\\n**B - Kenar:** Düzensiz, dalgalı veya bulanık kenarlar\\n**C - Renk:** Tek bir ben içinde birden fazla renk tonu\\n**D - Çap:** 6 mm\\'den büyük benler\\n**E - Evrim:** Boyut, şekil veya renkte değişiklik\\n\\nEğer cildinizde bu özelliklerden herhangi birini fark ederseniz, derhal bir dermatoloğa başvurmanız önerilir. Erken müdahale hayat kurtarır.', 
         'Cilt Sağlığı', 245, 1, 1),
        
        (2, 'Güneşten Korunma Yöntemleri', 'Güneşin zararlı etkilerinden korunmak için alabileceğiniz önlemler ve doğru güneş kremi kullanımı.', 
         'Güneş ışınları cildiniz için hem faydalı hem de zararlı olabilir. D vitamini sentezi için gerekli olan güneş ışığı, aşırı maruz kalındığında cilt kanserine neden olabilir.\\n\\n**Güneşten Korunma Yöntemleri:**\\n\\n1. **Güneş Kremi Kullanımı:** En az SPF 30 olan, geniş spektrumlu güneş kremlerini tercih edin\\n2. **Doğru Uygulama:** Güneş kremi, güneşe çıkmadan 30 dakika önce uygulanmalı\\n3. **Yenileme:** Her 2 saatte bir yenileyin, özellikle yüzdükten sonra\\n4. **Giyim:** Uzun kollu, koyu renkli kıyafetler tercih edin\\n5. **Şapka ve Gözlük:** Geniş kenarlı şapka ve UV korumalı gözlük kullanın\\n\\nGüneşin en zararlı olduğu 10:00-16:00 saatleri arasında mümkünse gölgede kalın.', 
         'Koruma', 189, 1, 1),
        
        (3, 'Melanom: En Tehlikeli Cilt Kanseri', 'Melanom hakkında bilmeniz gereken her şey: belirtileri, risk faktörleri ve tedavi seçenekleri.', 
         'Melanom, cilt kanserinin en ölümcül türüdür ancak erken yakalandığında tedavi edilebilir. Melanositlerden (pigment hücrelerinden) gelişir ve hızla yayılabilir.\\n\\n**Risk Faktörleri:**\\n\\n- Aile geçmişi\\n- Çok sayıda ben\\n- Açık renk cilt\\n- Güneş yanığı geçmişi\\n- Solaryum kullanımı\\n\\n**Belirtiler:**\\n\\n- Mevcut bende değişiklik\\n- Yeni çıkan, düzensiz ben\\n- Kaşınan, kanayan ben\\n- Renk değişimi\\n\\n**Tedavi Seçenekleri:**\\n\\n1. **Cerrahi Eksizyon:** Erken evrede en etkili tedavi\\n2. **İmmünoterapi:** İleri evrelerde kullanılır\\n3. **Targeted Therapy:** Spesifik gen mutasyonlarını hedefler\\n4. **Radyoterapi:** Belirli durumlarda destekleyici tedavi\\n\\nDüzenli cilt kontrolü yaptırmayı ihmal etmeyin.', 
         'Kanser Türleri', 156, 1, 1),
        
        (4, 'Bazal Hücreli Karsinom Rehberi', 'En yaygın cilt kanseri türü olan bazal hücreli karsinom hakkında detaylı bilgiler.', 
         'Bazal hücreli karsinom (BCC), en yaygın cilt kanseri türüdür. Neyse ki metastaz yapma riski çok düşüktür ve tedavi edilebilir.\\n\\n**Özellikler:**\\n\\n- Yavaş büyür\\n- Genellikle güneşe maruz kalan bölgelerde çıkar\\n- Metastaz riski çok düşük\\n- Tedavi edilmezse lokal olarak yayılabilir\\n\\n**Görünüm:**\\n\\n- İnci benzeri, parlak yumru\\n- Açık yaralı, iyileşmeyen yara\\n- Pembe veya kırmızı leke\\n- Skar benzeri beyaz alan\\n\\n**Tedavi:**\\n\\n1. **Mohs Cerrahisi:** En etkili yöntem\\n2. **Eksizyon:** Standart cerrahi çıkarma\\n3. **Küretaj ve Elektrokoter:** Küçük lezyonlar için\\n4. **Topikal Tedavi:** Belirli durumlarda\\n\\nErken teşhis ve tedavi ile tam iyileşme mümkündür.', 
         'Kanser Türleri', 98, 1, 0),
        
        (5, 'Cilt Kanseri Risk Faktörleri', 'Cilt kanseri gelişme riskinizi artıran faktörleri öğrenin ve kendinizi koruyun.', 
         'Cilt kanseri riskini etkileyen birçok faktör vardır. Bu faktörleri bilmek, korunma stratejilerinizi geliştirmenize yardımcı olur.\\n\\n**Değiştirilemez Risk Faktörleri:**\\n\\n- **Yaş:** 50 yaş üzeri risk artar\\n- **Cinsiyet:** Erkeklerde daha yaygın\\n- **Cilt Tipi:** Açık renk cilt\\n- **Saç ve Göz Rengi:** Sarı saç, mavi göz\\n- **Genetik:** Aile geçmişi\\n\\n**Değiştirilebilir Risk Faktörleri:**\\n\\n- **Güneş Maruziyeti:** En önemli risk faktörü\\n- **Solaryum Kullanımı:** Riski 75% artırır\\n- **Güneş Yanığı:** Özellikle çocuklukta\\n- **Bağışıklık Sistemi:** Zayıf bağışıklık\\n\\n**Korunma Önerileri:**\\n\\n1. Güneş kremi kullanın (SPF 30+)\\n2. Koruyucu kıyafet giyin\\n3. Gölgede kalın\\n4. Solaryum kullanmayın\\n5. Düzenli cilt kontrolü yaptırın\\n\\nRisk faktörlerinizi değerlendirin ve uygun önlemleri alın.', 
         'Risk Faktörleri', 134, 1, 0)
    ");
    echo "<p>✓ Örnek blog yazıları eklendi</p>";
    
    // Test kullanıcısı ekle (isteğe bağlı)
    $test_password = password_hash('123456', PASSWORD_DEFAULT);
    $pdo->exec("
        INSERT INTO users (email, sifre, ad, soyad) VALUES
        ('test@dermai.com', '$test_password', 'Test', 'Kullanıcı')
    ");
    echo "<p>✓ Test kullanıcısı eklendi (email: test@dermai.com, şifre: 123456)</p>";
    
    echo "<h2 style='color: green;'>✅ DermAI Veritabanı Başarıyla Kuruldu!</h2>";
    echo "<p><strong>Veritabanı Adı:</strong> $dbname</p>";
    echo "<p><strong>Tablolar:</strong></p>";
    echo "<ul>";
    echo "<li>users - Kullanıcı bilgileri</li>";
    echo "<li>user_sessions - Oturum yönetimi</li>";
    echo "<li>skin_analyses - Cilt analizi sonuçları</li>";
    echo "<li>photos - Fotoğraf depolama</li>";
    echo "<li>doctor_recommendations - Doktor tavsiyeleri</li>";
    echo "<li>notifications - Bildirimler</li>";
    echo "<li>skin_types - Cilt tipleri referansı</li>";
    echo "<li>system_logs - Sistem kayıtları</li>";
    echo "<li>blog_posts - Blog yazıları (5 örnek yazı ile)</li>";
    echo "</ul>";
    
    echo "<p><strong>Test Kullanıcısı:</strong></p>";
    echo "<ul>";
    echo "<li>Kullanıcı Adı: test_user</li>";
    echo "<li>E-posta: test@dermai.com</li>";
    echo "<li>Şifre: 123456</li>";
    echo "</ul>";
    
    echo "<p style='margin-top: 30px;'><a href='index.php' style='background: #04A5A4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>API Anasayfasına Git</a></p>";
    
} catch (PDOException $e) {
    echo "<h2 style='color: red;'>❌ Hata Oluştu!</h2>";
    echo "<p style='color: red;'>Hata: " . $e->getMessage() . "</p>";
    echo "<p>Lütfen veritabanı bağlantı bilgilerini kontrol edin.</p>";
}
?> 