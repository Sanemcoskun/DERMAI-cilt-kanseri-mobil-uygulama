import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yardım & Destek',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          tabs: const [
            Tab(text: 'SSS'),
            Tab(text: 'Özellikler'),
            Tab(text: 'Güvenlik'),
            Tab(text: 'İletişim'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildFeaturesTab(),
          _buildSecurityTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFAQItem(
              'DermAI nasıl çalışır?',
              'DermAI, yapay zeka teknolojisi kullanarak cilt fotoğraflarınızı analiz eder. Gelişmiş algoritmalara sahip modelimiz, ciltteki lekeleri, kuruluk, yağlılık ve potansiyel sorunları tespit ederek size öneriler sunar.',
              Icons.psychology,
            ),
            _buildFAQItem(
              'Analiz sonuçları ne kadar güvenilir?',
              'DermAI yüksek doğruluk oranına sahiptir ancak kesin tıbbi teşhis yerine geçmez. Ciddi cilt sorunları için mutlaka bir dermatoloğa başvurun.',
              Icons.verified,
            ),
            _buildFAQItem(
              'Fotoğraflarım güvende mi?',
              'Evet, tüm fotoğraflarınız şifreli olarak saklanır ve sadece analiz için kullanılır. Verileriniz üçüncü taraflarla paylaşılmaz.',
              Icons.security,
            ),
            _buildFAQItem(
              'Günde kaç analiz yapabilirim?',
              'Premium kullanıcılar sınırsız analiz yapabilir. Ücretsiz kullanıcılar günde 3 analiz hakkına sahiptir.',
              Icons.analytics,
            ),
            _buildFAQItem(
              'Hangi cilt tiplerini destekliyorsunuz?',
              'DermAI tüm cilt tiplerini (kuru, yağlı, karma, normal, hassas) destekler ve her cilt tipine özel öneriler sunar.',
              Icons.face,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFeatureCard(
              'Yapay Zeka Analizi',
              'Gelişmiş AI algoritmaları ile cildinizi detaylı analiz eder',
              Icons.psychology,
              const Color(0xFF6366F1),
            ),
            _buildFeatureCard(
              'Kişisel Öneriler',
              'Size özel cilt bakım önerileri ve ürün tavsiyeleri',
              Icons.recommend,
              const Color(0xFF10B981),
            ),
            _buildFeatureCard(
              'İlerleme Takibi',
              'Zaman içindeki cilt sağlığı değişimlerinizi takip edin',
              Icons.trending_up,
              const Color(0xFFF59E0B),
            ),
            _buildFeatureCard(
              'Uzman Konsültasyonu',
              'Premium üyeler için uzman dermatolog görüşmeleri',
              Icons.medical_services,
              const Color(0xFFEF4444),
            ),
            _buildFeatureCard(
              'Blog & İpuçları',
              'Cilt sağlığı hakkında güncel bilgiler ve ipuçları',
              Icons.article,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSecurityCard(
              'Veri Şifreleme',
              'Tüm verileriniz AES-256 şifreleme ile korunur',
              Icons.lock,
            ),
            _buildSecurityCard(
              'İki Faktörlü Doğrulama',
              'Hesabınızı ekstra güvenlik katmanı ile koruyun',
              Icons.security,
            ),
            _buildSecurityCard(
              'Gizlilik',
              'Fotoğraflarınız ve kişisel bilgileriniz tamamen gizlidir',
              Icons.visibility_off,
            ),
            _buildSecurityCard(
              'GDPR Uyumluluğu',
              'Avrupa veri koruma standartlarına tam uyumluyuz',
              Icons.policy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildContactCard(
              'E-posta Desteği',
              'support@dermai.com',
              'En geç 24 saat içinde yanıtlanır',
              Icons.email,
            ),
            _buildContactCard(
              'WhatsApp Destek',
              '+90 555 123 4567',
              '7/24 anlık destek',
              Icons.chat,
            ),
            _buildContactCard(
              'Telefon Desteği',
              '0850 123 45 67',
              'Premium üyeler için öncelikli',
              Icons.phone,
            ),
            const SizedBox(height: 20),
            _buildOfficeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF05a5a5), size: 20),
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF05a5a5).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF05a5a5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF05a5a5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified,
            color: Color(0xFF10B981),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String contact, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF05a5a5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF05a5a5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF05a5a5),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: Color(0xFF05a5a5), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Ofis Bilgileri',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOfficeItem(Icons.location_on, 'Adres', 'Maslak Mahallesi, Bilim Sokak No:5\n34485 Sarıyer/İstanbul'),
          _buildOfficeItem(Icons.access_time, 'Çalışma Saatleri', 'Pazartesi - Cuma: 09:00 - 18:00\nHafta Sonu: Kapalı'),
          _buildOfficeItem(Icons.language, 'Dil Desteği', 'Türkçe, İngilizce'),
        ],
      ),
    );
  }

  Widget _buildOfficeItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 