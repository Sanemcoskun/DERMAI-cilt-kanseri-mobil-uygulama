import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../localization/app_localizations.dart';
import '../chat/chat_screen.dart';
import '../main_screen.dart';
import '../notifications/notifications_screen.dart';
import '../health/health_tips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userCredits = 10; // Başlangıç değeri 10

  @override
  void initState() {
    super.initState();
    _loadUserCredits();
  }



  Future<void> _loadUserCredits() async {
    print('🏠 Ana sayfa kredi yükleniyor...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      
      print('📱 Session ID: $sessionId');
      
      if (sessionId != null) {
        // API'den gerçek kredi miktarını çek
        print('🌐 API çağrısı yapılıyor...');
        final response = await http.get(
          Uri.parse('http://192.168.1.100/flutter/dermai_api/profile/get_user_credits.php'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer dermai-api-2024',
            'X-Session-ID': sessionId,
          },
        );
        
        print('📊 Response Status: ${response.statusCode}');
        print('📊 Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == true) {
            final credits = data['data']['credits']['current_balance'] ?? 10;
            print('✅ API\'den kredi alındı: $credits');
            setState(() {
              _userCredits = credits;
            });
          } else {
            print('❌ API başarısız: ${data['message']}');
            setState(() {
              _userCredits = 10; // Default credit
            });
          }
        } else {
          print('❌ HTTP hatası: ${response.statusCode}');
          setState(() {
            _userCredits = 10; // Default credit
          });
        }
      } else {
        print('❌ Session ID yok, default kredi kullanılıyor');
        setState(() {
          _userCredits = 10; // Default credit
        });
      }
    } catch (e) {
      print('❌ Kredi yükleme hatası: $e');
      setState(() {
        _userCredits = 10; // Default credit
      });
    }
  }

  // URL açma fonksiyonu - Güvenilir yöntem
  Future<void> _launchMHRS() async {
    const String mhrsUrl = 'https://mhrs.gov.tr/vatandas/';
    
    try {
      final Uri uri = Uri.parse(mhrsUrl);
      
      // Platform varsayılan modunu kullan
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      
      if (!launched) {
        // Eğer platform default çalışmazsa external dene
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      if (!launched) {
        throw 'URL açılamadı';
      }
    } catch (e) {
      if (mounted) {
        _showMHRSErrorDialog();
      }
    }
  }

  // MHRS hata dialog'u
  void _showMHRSErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Link Açılamadı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MHRS sitesi otomatik olarak açılamadı.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF05a5a5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manuel Erişim:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF05a5a5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Tarayıcınızı açın',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2. Aşağıdaki adresi yazın:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'mhrs.gov.tr',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Anladım',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // MHRS randevu bilgilendirmesi
  void _showAppointmentInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF05a5a5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF05a5a5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Randevu Al',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MHRS ile doktor randevusu alın',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF05a5a5),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Devlet hastanelerinden randevu almak için MHRS (Merkezi Hekim Randevu Sistemi) kullanabilirsiniz.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchMHRS();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yönlendir',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Destek butonuna tıklandığında çalışacak fonksiyon
  Future<void> _handleSupportTap() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSupportDialog = prefs.getBool('has_seen_support_dialog') ?? false;
    
    if (!hasSeenSupportDialog) {
      // İlk kez tıklanıyorsa dialog göster
      _showSupportDialog();
      await prefs.setBool('has_seen_support_dialog', true);
    } else {
      // Daha önce görülmüşse direkt chat ekranına git
      _navigateToChat();
    }
  }

  // Chat ekranına yönlendir
  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  // Destek dialog'unu göster
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF05a5a5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Color(0xFF05a5a5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'DermaNova',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akıllı asistanınla konuş',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF05a5a5),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'DermaNova, cilt sağlığı konularında size yardımcı olmak için burada. Sorularınızı sorun, kişiselleştirilmiş tavsiyeleri alın.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF05a5a5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF05a5a5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        '24/7 aktif olan yapay zeka asistanınız',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF05a5a5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Kapat',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
                         ElevatedButton(
               onPressed: () {
                 Navigator.of(context).pop();
                 _navigateToChat();
               },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Konuşmaya Başla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocalizations.instance,
      builder: (context, child) {
        final localizations = AppLocalizations.instance;
        
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFe3f3f2),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Merhaba! 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A202C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sağlığınız bizim önceliğimiz',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/credit'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF05a5a5),
                                  const Color(0xFF059999),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF05a5a5).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_userCredits',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Quick Analysis Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF05a5a5),
                            Color(0xFF37a9a3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF05a5a5).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cilt Analizi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Yapay zeka ile anında analiz',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                                                          width: double.infinity,
                              child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/skin-analysis');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF05a5a5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Analizi Başlat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Quick Actions Grid
                    const Text(
                      'Hızlı İşlemler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          _buildQuickActionCard(
                            icon: Icons.history,
                            title: 'Geçmiş Analizler',
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(initialIndex: 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildQuickActionCard(
                            icon: Icons.support_agent_outlined,
                            title: 'Destek',
                            onTap: () => _handleSupportTap(),
                          ),
                          const SizedBox(width: 16),
                          _buildQuickActionCard(
                            icon: Icons.calendar_today_outlined,
                            title: 'Randevu Al',
                            onTap: () => _showAppointmentInfo(),
                          ),
                          const SizedBox(width: 16),
                          _buildQuickActionCard(
                            icon: Icons.medical_services_outlined,
                            title: 'Sağlık Tavsiyeleri',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HealthTipsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildQuickActionCard(
                            icon: Icons.article_outlined,
                            title: 'Blog',
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(initialIndex: 1),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildQuickActionCard(
                            icon: Icons.notifications_outlined,
                            title: 'Bildirimler',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Health Tips Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sağlık İpuçları',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAllHealthTips(),
                          child: const Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: Color(0xFF05a5a5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Health Tips Cards
                    Column(
                      children: [
                        _buildHealthTipCard(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Güneş Koruması',
                          description: 'SPF 30+ güneş kremi kullanmayı unutmayın',
                          color: const Color(0xFFFFF3CD),
                          iconColor: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 12),
                        _buildHealthTipCard(
                          icon: Icons.local_drink_outlined,
                          title: 'Su İçin',
                          description: 'Günde en az 8 bardak su için',
                          color: const Color(0xFFD1ECF1),
                          iconColor: const Color(0xFF17A2B8),
                        ),
                        const SizedBox(height: 12),
                        _buildHealthTipCard(
                          icon: Icons.spa_outlined,
                          title: 'Cilt Bakımı',
                          description: 'Düzenli temizlik ve nemlendirme',
                          color: const Color(0xFFD4EDDA),
                          iconColor: const Color(0xFF28A745),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF05a5a5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF05a5a5),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tüm sağlık ipuçlarını gösteren modal
  void _showAllHealthTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sağlık İpuçları',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailedHealthTip(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Güneş Koruması',
                          description: 'Cildinizi UV ışınlarından korumak çok önemli. SPF 30 veya daha yüksek faktörlü güneş kremi kullanın.',
                          detailedTips: [
                            'Güneş kreminizi çıkmadan 30 dakika önce sürün',
                            'Her 2 saatte bir yenileyin',
                            'Yüzme veya terledikten sonra tekrar sürün',
                            'Dudaklarınız için SPF\'li dudak balsamı kullanın',
                            'Saat 10-16 arası güneşe çıkmamaya özen gösterin'
                          ],
                          color: const Color(0xFFFFF3CD),
                          iconColor: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailedHealthTip(
                          icon: Icons.local_drink_outlined,
                          title: 'Su İçme Alışkanlığı',
                          description: 'Vücudunuzun %60\'ı sudan oluşur. Günlük su ihtiyacınızı karşılamak hayati önem taşır.',
                          detailedTips: [
                            'Günde en az 8-10 bardak su için',
                            'Sabah uyandığınızda bir bardak su için',
                            'Yemeklerden 30 dakika önce su için',
                            'İdrar renginizle hidratasyon seviyenizi kontrol edin',
                            'Meyve suları yerine saf su tercih edin'
                          ],
                          color: const Color(0xFFD1ECF1),
                          iconColor: const Color(0xFF17A2B8),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailedHealthTip(
                          icon: Icons.spa_outlined,
                          title: 'Günlük Cilt Bakımı',
                          description: 'Düzenli cilt bakımı ile cildinizi sağlıklı ve genç tutabilirsiniz.',
                          detailedTips: [
                            'Sabah ve akşam cildinizi nazikçe temizleyin',
                            'Cilt tipinize uygun nemlendirici kullanın',
                            'Haftada 1-2 kez peeling yapın',
                            'Güneş kremi kullanmayı ihmal etmeyin',
                            'Bol su için ve dengeli beslenin'
                          ],
                          color: const Color(0xFFD4EDDA),
                          iconColor: const Color(0xFF28A745),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailedHealthTip(
                          icon: Icons.bedtime_outlined,
                          title: 'Kaliteli Uyku',
                          description: 'Yeterli ve kaliteli uyku cilt sağlığı için vazgeçilmezdir.',
                          detailedTips: [
                            'Günde 7-9 saat uyumaya özen gösterin',
                            'Yatmadan önce telefonları kapatın',
                            'Yatak odanızı serin ve karanlık tutun',
                            'Düzenli uyku rutini oluşturun',
                            'Kafein alımını öğleden sonra sınırlayın'
                          ],
                          color: const Color(0xFFE2E3FF),
                          iconColor: const Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailedHealthTip(
                          icon: Icons.fitness_center_outlined,
                          title: 'Düzenli Egzersiz',
                          description: 'Egzersiz kan dolaşımını hızlandırarak cilt sağlığını destekler.',
                          detailedTips: [
                            'Haftada en az 150 dakika orta şiddetli egzersiz yapın',
                            'Egzersiz sonrası cildinizi temizleyin',
                            'Ter bezlerinin tıkanmaması için pamuklu giysiler tercih edin',
                            'Egzersiz öncesi ve sonrası bol su için',
                            'Yoga ve meditasyon ile stresi azaltın'
                          ],
                          color: const Color(0xFFFFE2E5),
                          iconColor: const Color(0xFFEC4899),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailedHealthTip(
                          icon: Icons.restaurant_outlined,
                          title: 'Sağlıklı Beslenme',
                          description: 'Cildinizin sağlığı doğru beslenme ile başlar.',
                          detailedTips: [
                            'Omega-3 yağ asitleri açısından zengin besinler tüketin',
                            'Antioksidan içeren meyve ve sebzeleri tercih edin',
                            'İşlenmiş gıdalar ve şekeri sınırlayın',
                            'Probiyotik gıdalar ile bağırsak sağlığını destekleyin',
                            'Yeşil çay gibi antioksidan içecekler tüketin'
                          ],
                          color: const Color(0xFFF0FDF4),
                          iconColor: const Color(0xFF22C55E),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedHealthTip({
    required IconData icon,
    required String title,
    required String description,
    required List<String> detailedTips,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Önemli Noktalar:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 12),
                ...detailedTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kredi bilgi dialog'u
  void _showCreditInfo() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 650),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Premium Kredi Sistemi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Profesyonel özellikler için kredi kullanın',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF05a5a5).withOpacity(0.08),
                                const Color(0xFF059999).withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF05a5a5).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Mevcut Bakiye',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF05a5a5).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF05a5a5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$_userCredits',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF05a5a5),
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Kredi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                
                        // Pricing Section
                        const Text(
                          'Hizmet Fiyatları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A202C),
                            letterSpacing: -0.3,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Service Cards
                        _buildProfessionalServiceCard(
                          icon: Icons.camera_alt_rounded,
                          title: 'Cilt Analizi',
                          description: 'AI destekli profesyonel cilt analizi',
                          cost: 5,
                          color: const Color(0xFF059669),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildProfessionalServiceCard(
                          icon: Icons.psychology_rounded,
                          title: 'AI Danışmanlık',
                          description: 'Dermatoloji uzmanı AI ile konuşma',
                          cost: 3,
                          color: const Color(0xFF7C3AED),
                        ),
                        
                        const SizedBox(height: 28),
                
                        // Earning Credits Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.08),
                                const Color(0xFF059669).withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events_rounded,
                                      color: Color(0xFF059669),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Ücretsiz Kredi Kazan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A202C),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildEarningMethod('İlk üyelik bonus', '+10 kredi', Icons.card_giftcard_rounded),
                              const SizedBox(height: 8),
                              _buildEarningMethod('Günlük kontrol', '+2 kredi', Icons.today_rounded),
                              const SizedBox(height: 8),
                              _buildEarningMethod('Arkadaş davet et', '+5 kredi', Icons.person_add_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF1E293B).withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Kapat',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showProfessionalCreditPurchase();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_card_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Kredi Satın Al',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required int cost,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$cost',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningMethod(String title, String reward, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF059669),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            reward,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF059669),
            ),
          ),
        ),
      ],
    );
  }

  // Profesyonel kredi satın alma dialog'u
  void _showProfessionalCreditPurchase() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_card_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kredi Paketleri',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İhtiyacınıza uygun paketi seçin',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildProfessionalCreditPackage(
                          title: 'Başlangıç',
                          credits: 25,
                          price: 9.99,
                          color: const Color(0xFF059669),
                          popular: false,
                        ),
                        const SizedBox(height: 16),
                        _buildProfessionalCreditPackage(
                          title: 'Popüler',
                          credits: 60,
                          price: 19.99,
                          color: const Color(0xFF7C3AED),
                          popular: true,
                        ),
                        const SizedBox(height: 16),
                        _buildProfessionalCreditPackage(
                          title: 'Premium',
                          credits: 120,
                          price: 34.99,
                          color: const Color(0xFFEF4444),
                          popular: false,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Action
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalCreditPackage({
    required String title,
    required int credits,
    required double price,
    required Color color,
    required bool popular,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement purchase logic
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title paketi satın alma özelliği yakında eklenecek'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: popular ? color : color.withOpacity(0.2),
            width: popular ? 2.5 : 1.5,
          ),
          boxShadow: popular ? [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Popular Badge
                  if (popular) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'En Popüler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Package Title
                  Text(
                    '$title Paket',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Credits Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$credits',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kredi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₺${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Value Calculation
                  Text(
                    '≈ ₺${(price / credits).toStringAsFixed(2)} / kredi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 