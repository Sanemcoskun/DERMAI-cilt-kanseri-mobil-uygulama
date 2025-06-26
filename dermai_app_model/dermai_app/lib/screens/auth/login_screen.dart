import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppLocalizations get localizations => AppLocalizations.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF05a5a5),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    return ListenableBuilder(
      listenable: localizations,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
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
              child: Column(
                children: [
                  // AppBar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF05a5a5),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          localizations.getText('login'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40), // Balance for back button
                      ],
                    ),
                  ),
                  
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          
                          // Logo
                          Center(
                            child: Image.asset(
                              'assets/images/dermai_logo.png',
                              height: 60,
                              width: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          const SizedBox(height: 100),
                          
                          // Login Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF106c6a).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                // Title
                                Center(
                                  child: Text(
                                    localizations.getText('welcome'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A202C),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Center(
                                  child: Text(
                                    localizations.getText('loginSubtitle'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Email Field
                                _buildInputField(
                                  controller: _emailController,
                                  label: localizations.getText('email'),
                                  hint: localizations.getText('emailHint'),
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Password Field
                                _buildInputField(
                                  controller: _passwordController,
                                  label: localizations.getText('password'),
                                  hint: localizations.getText('passwordHint'),
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isPasswordVisible: _isPasswordVisible,
                                  onTogglePassword: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                
                                const SizedBox(height: 28),
                                
                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Forgot password action
                                    },
                                    child: Text(
                                      localizations.getText('forgotPassword'),
                                      style: const TextStyle(
                                        color: Color(0xFF37a9a3),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 36),
                                
                                // Login Button
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
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : () => _handleLogin(),
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
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
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
                                
                                const SizedBox(height: 32),
                                
                                // Register Link - moved inside card
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      localizations.getText('noAccount'),
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        localizations.getText('register'),
                                        style: const TextStyle(
                                          color: Color(0xFF37a9a3),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ),
                          ),
                        ],
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

  // Login işlemi
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['success']) {
        // Başarılı giriş
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );

          // Ana ekrana yönlendir
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        // Hata durumu
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1A202C),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label alanı boş bırakılamaz';
          }
          if (keyboardType == TextInputType.emailAddress) {
            if (!value.contains('@') || !value.contains('.')) {
              return 'Geçerli bir e-posta adresi giriniz';
            }
          }
          if (isPassword && value.length < 6) {
            return 'Şifre en az 6 karakter olmalıdır';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF37a9a3),
            size: 20,
          ),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onTogglePassword,
                  child: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF05a5a5),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF05a5a5),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF037373),
              width: 2.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }
} 