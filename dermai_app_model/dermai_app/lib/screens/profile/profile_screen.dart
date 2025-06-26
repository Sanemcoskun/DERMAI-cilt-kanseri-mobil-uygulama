import 'package:flutter/material.dart';
import '../auth/welcome_screen.dart';
import 'help_screen.dart';
import 'feedback_screen.dart';
import 'about_screen.dart';
import '../../localization/app_localizations.dart';
import 'personal_info_screen.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String _userName = 'Yükleniyor...';
  String _userEmail = 'Yükleniyor...';
  String _userId = 'Yükleniyor...';
  String _errorMessage = '';


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('ProfileScreen: _loadUserData başlatıldı');
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Cache'den kontrol et
      if (UserService.getCachedUserData() != null) {
        print('ProfileScreen: Cache\'den veri alındı');
        final fullName = UserService.getFullName();
        final email = UserService.getEmail();
        final userId = UserService.getUserId();
        
        print('ProfileScreen: Cache - Name: $fullName, Email: $email, ID: $userId');
        
        setState(() {
          _userName = fullName.isEmpty ? 'Kullanıcı' : fullName;
          _userEmail = email.isEmpty ? 'Email yok' : email;
          _userId = userId.isEmpty ? '#AD2024' : userId;
          _isLoading = false;
        });
        return;
      }

      // Auth'dan user ID al
      final userIdString = await AuthService.getUserId();
      print('ProfileScreen: AuthService User ID: $userIdString');
      
      // Eğer auth'dan ID alınamazsa test için 1 kullan
      int userId = 1;
      if (userIdString != null && userIdString.isNotEmpty) {
        userId = int.tryParse(userIdString) ?? 1;
      }
      
      print('ProfileScreen: Kullanılacak User ID: $userId');
      print('ProfileScreen: Parsed User ID: $userId');
      
      if (userId == null) {
        print('ProfileScreen: User ID parse edilemedi');
        setState(() {
          _userName = 'Hata';
          _userEmail = 'User ID geçersiz';
          _userId = '#ERROR';
          _isLoading = false;
          _errorMessage = 'Kullanıcı ID\'si geçersiz';
        });
        return;
      }
      
      print('ProfileScreen: UserService.getUserData çağrılıyor...');
      final result = await UserService.getUserData(userId);
      print('ProfileScreen: UserService sonucu: $result');
      
      if (result['success']) {
        print('ProfileScreen: Başarılı - UI güncelleniyor');
        final fullName = UserService.getFullName();
        final email = UserService.getEmail();
        final userIdFormatted = UserService.getUserId();
        
        print('ProfileScreen: Success - Name: $fullName, Email: $email, ID: $userIdFormatted');
        
        setState(() {
          _userName = fullName.isEmpty ? 'Ad Soyad Yok' : fullName;
          _userEmail = email.isEmpty ? 'Email Yok' : email;
          _userId = userIdFormatted.isEmpty ? '#AD2024' : userIdFormatted;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        print('ProfileScreen: Başarısız - ${result['message']}');
        setState(() {
          _userName = 'Veri Hatası';
          _userEmail = result['message'] ?? 'Bilinmeyen hata';
          _userId = '#ERROR';
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Veri yüklenemedi';
        });
      }
    } catch (e) {
      print('ProfileScreen: Exception - $e');
      setState(() {
        _userName = 'Bağlantı Hatası';
        _userEmail = 'Sunucuya bağlanılamadı';
        _userId = '#ERROR';
        _isLoading = false;
        _errorMessage = 'Bağlantı hatası: $e';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC), // Very light gray-blue
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with profile info
                _buildProfileHeader(),
                const SizedBox(height: 20),
                
                // Profile options
                _buildProfileOptions(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF05a5a5).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Profile picture with professional design
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF05a5a5),
                        const Color(0xFF059999),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF05a5a5).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05a5a5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF05a5a5).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // User info
            _isLoading
                ? Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  )
                : Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                      letterSpacing: 0.5,
                    ),
                  ),
            const SizedBox(height: 8),
            
            _isLoading
                ? Container(
                    width: 100,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(13),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05a5a5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF05a5a5).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _userId,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF05a5a5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            
            _isLoading
                ? Container(
                    width: 150,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  )
                : Text(
                    _userEmail,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Düzenle',
                  onTap: () => _showEditProfileDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF05a5a5).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF05a5a5).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF05a5a5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF05a5a5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Account section
          _buildSection(
            title: 'Hesap',
            icon: Icons.account_circle_outlined,
            children: [
              _buildOptionTile(
                icon: Icons.person_outline,
                title: 'Kişisel Bilgiler',
                subtitle: 'Ad, yaş, cinsiyet',
                onTap: () => _showPersonalInfoDialog(),
              ),
              _buildOptionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Kredi Sistemi',
                subtitle: 'Kredi yükle ve paketler',
                onTap: () => Navigator.pushNamed(context, '/credit'),
              ),
              _buildOptionTile(
                icon: Icons.security,
                title: 'Güvenlik',
                subtitle: 'Şifre ve güvenlik ayarları',
                onTap: () => Navigator.pushNamed(context, '/security'),
              ),
              _buildOptionTile(
                icon: Icons.history,
                title: 'Analiz Geçmişi',
                subtitle: 'Geçmiş cilt analizleri',
                onTap: () => _showAnalysisHistory(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Settings section
          _buildSection(
            title: 'Ayarlar',
            icon: Icons.settings_outlined,
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                subtitle: 'Analizler ve hatırlatmalar',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              _buildOptionTile(
                icon: Icons.language,
                title: 'Dil',
                                      subtitle: AppLocalizations.instance.getLanguageName(AppLocalizations.instance.currentLanguage),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Support section
          _buildSection(
            title: 'Destek',
            icon: Icons.help_outline,
            children: [
              _buildOptionTile(
                icon: Icons.help_outline,
                title: 'Yardım',
                subtitle: 'SSS ve kullanım kılavuzu',
                onTap: () => _showHelp(),
              ),
              _buildOptionTile(
                icon: Icons.feedback_outlined,
                title: 'Geri Bildirim',
                subtitle: 'Öneriler ve şikayetler',
                onTap: () => _showFeedback(),
              ),
              _buildOptionTile(
                icon: Icons.info_outline,
                title: 'Hakkında',
                subtitle: 'Uygulama bilgileri',
                onTap: () => _showAbout(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Logout section
          _buildSection(
            title: 'Oturum',
            icon: Icons.logout,
            children: [
              _buildOptionTile(
                icon: Icons.logout,
                title: 'Çıkış Yap',
                subtitle: 'Hesaptan çık',
                onTap: () => _showLogoutDialog(),
                titleColor: Colors.red,
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF05a5a5).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05a5a5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF05a5a5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
          ),
          // Section content
          ...children,
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF05a5a5)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF05a5a5),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor ?? const Color(0xFF1A202C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.2,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF05a5a5),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A202C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.2,
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: value 
                ? const Color(0xFF05a5a5).withOpacity(0.1) 
                : Colors.grey.shade100,
          ),
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF05a5a5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInfoScreen(),
      ),
    );
  }

  void _showPersonalInfoDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInfoScreen(),
      ),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik'),
        content: const Text('Şifre değiştirme ve iki faktörlü doğrulama ayarları.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisHistory() {
    Navigator.pushReplacementNamed(context, '/main-analytics');
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Sadece X ile kapanabilir
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: const Color(0xFF05a5a5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.instance.getText('selectLanguage'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Dil Seçenekleri
                ...AppLocalizations.instance.supportedLanguages.map((languageCode) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLanguageOption(
                      code: languageCode,
                      flag: AppLocalizations.instance.getLanguageFlag(languageCode),
                      name: AppLocalizations.instance.getLanguageName(languageCode),
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

  Widget _buildLanguageOption({
    required String code,
    required String flag,
    required String name,
  }) {
    bool isSelected = AppLocalizations.instance.currentLanguage == code;
    
    return GestureDetector(
      onTap: () {
        AppLocalizations.instance.changeLanguage(code);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFFe9f5f5) 
            : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF05a5a5) 
              : const Color(0xFF05a5a5).withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                    ? const Color(0xFF1A202C) 
                    : const Color(0xFF64748B),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF05a5a5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpScreen(),
      ),
    );
  }

  void _showFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedbackScreen(),
      ),
    );
  }

  void _showAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesaptan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // AuthService logout işlemi (UserService cache'ini de temizler)
              await AuthService.logout();
              
              // WelcomeScreen'e yönlendir ve tüm önceki ekranları temizle
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Çıkış yapıldı')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showMyReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cilt Analiz Raporlarım'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReportItem('15 Ocak 2024', 'Normal', Colors.green),
              _buildReportItem('08 Ocak 2024', 'Kontrol Önerisi', Colors.orange),
              _buildReportItem('28 Aralık 2023', 'Normal', Colors.green),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to analytics screen
            },
            child: const Text('Tümünü Gör'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(String date, String result, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  result,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cilt Sağlığı İpuçları'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHealthTip('🧴', 'Günlük güneş kremi kullanın'),
              _buildHealthTip('💧', 'Cildinizi nemli tutun'),
              _buildHealthTip('🥗', 'Sağlıklı beslenin'),
              _buildHealthTip('🚿', 'Cildinizi nazikçe temizleyin'),
              _buildHealthTip('👩‍⚕️', 'Düzenli cilt kontrolü yaptırın'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to health tips
            },
            child: const Text('Daha Fazla'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTip(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A202C),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 