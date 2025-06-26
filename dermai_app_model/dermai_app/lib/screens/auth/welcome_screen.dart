import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  AppLocalizations get localizations => AppLocalizations.instance;

  void _showLanguageModal() {
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
                      color: const Color(0xFF37a9a3),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations.getText('selectLanguage'),
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
                ...localizations.supportedLanguages.map((languageCode) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLanguageOption(
                      code: languageCode,
                      flag: localizations.getLanguageFlag(languageCode),
                      name: localizations.getLanguageName(languageCode),
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
    bool isSelected = localizations.currentLanguage == code;
    
    return GestureDetector(
      onTap: () {
        localizations.changeLanguage(code);
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
              ? const Color(0xFF37a9a3) 
              : const Color(0xFF37a9a3).withOpacity(0.3),
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
                color: const Color(0xFF37a9a3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localizations,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFe3f3f2), // Açık mint yeşili
                  Color(0xFFffffff), // Beyaz
                ],
                stops: [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Ana içerik
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),
                        
                        // Üst kısım - Sadece versiyon
                        Row(
                          children: [
                            Text(
                              localizations.getText('version'),
                              style: const TextStyle(
                                color: Colors.grey, 
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Logo - Şeffaf arkaplanlı
                        Center(
                          child: Transform.translate(
                            offset: const Offset(0, 10),
                            child: Image.asset(
                              'assets/images/dermai_logo.png',
                              height: 90,
                              width: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Başlık - DermAI'ye Hoşgeldiniz (küçültüldü)
                        Text(
                          localizations.getText('welcome'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Alt başlık - Cilt kanseri erken teşhis sistemi (küçültüldü)
                        Text(
                          localizations.getText('subtitle'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Butonlar - Gradient arka planlı, hafif gölgeli beyaz kart
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Giriş Yap butonu - Gradient
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Color(0xFF106c6a),
                                        Color(0xFF0d9f9f),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF106c6a).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      localizations.getText('login'),
                                      style: const TextStyle(
                                        fontSize: 17, 
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Kayıt Ol butonu - Gradient
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Color(0xFF106c6a),
                                        Color(0xFF0d9f9f),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF106c6a).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      localizations.getText('register'),
                                      style: const TextStyle(
                                        fontSize: 17, 
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Bilgi kutusu - Açık mint yeşili arkaplanlı
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFe9f5f5),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF37a9a3).withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.7),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Üstte ortalanmış i simgesi
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF37a9a3),
                                size: 22,
                              ),
                              const SizedBox(height: 12),
                              // Altında ortalanmış bilgi metni
                              Text(
                                localizations.getText('info'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Text(
                          localizations.getText('copyright'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                  
                  // Sağ üst köşe dil seçici
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _showLanguageModal,
                      child: Container(
                        margin: const EdgeInsets.only(top: 16, right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.lightBlueAccent, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localizations.getCurrentFlag(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 