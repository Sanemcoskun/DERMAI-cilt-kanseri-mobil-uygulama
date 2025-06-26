import 'package:flutter/material.dart';
import '../../services/password_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _twoFactorAuth = false;
  bool _biometricAuth = true;
  bool _loginNotifications = true;
  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isChangingPassword = false;
  bool _passwordsMatch = true;
  bool _isPasswordStrong = true;

  @override
  void initState() {
    super.initState();
    // Şifre eşleşme kontrolü için listener ekle
    _currentPasswordController.addListener(_checkPasswordMatch);
    _newPasswordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordMatch() {
    setState(() {
      // Şifre eşleşme kontrolü - boş alan varsa true döndür
      if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
        _passwordsMatch = true;
      } else {
        _passwordsMatch = _newPasswordController.text == _confirmPasswordController.text;
      }
      
      // Şifre güçlülük kontrolü
      _isPasswordStrong = _newPasswordController.text.isEmpty || _newPasswordController.text.length >= 6;
    });
  }

  Color _getValidationColor() {
    if (!_isPasswordStrong) return Colors.red;
    if (!_passwordsMatch) return Colors.red;
    return Colors.green;
  }

  IconData _getValidationIcon() {
    if (!_isPasswordStrong) return Icons.error;
    if (!_passwordsMatch) return Icons.error;
    return Icons.check_circle;
  }

  String _getValidationMessage() {
    if (!_isPasswordStrong) return 'Şifre en az 6 karakter olmalı';
    if (!_passwordsMatch) return 'Şifreler eşleşmiyor';
    return 'Tüm kontroller tamam, şifreyi değiştirebilirsiniz';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Güvenlik',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: isDark ? null : const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFe3f3f2),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildPasswordSection(),
              const SizedBox(height: 20),
              _buildSecurityOptionsSection(),
              const SizedBox(height: 20),
              _buildDataManagementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF05a5a5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF05a5a5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Şifre Değiştir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _isObscureOld,
            decoration: InputDecoration(
              labelText: 'Mevcut Şifre',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF05a5a5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureOld ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isObscureOld = !_isObscureOld;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _newPasswordController,
            obscureText: _isObscureNew,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre',
              prefixIcon: const Icon(
                Icons.lock,
                color: Color(0xFF05a5a5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureNew ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isObscureNew = !_isObscureNew;
                  });
                },
              ),
              helperText: _newPasswordController.text.isNotEmpty && !_isPasswordStrong
                  ? 'Şifre en az 6 karakter olmalı'
                  : null,
              helperStyle: const TextStyle(color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _newPasswordController.text.isNotEmpty && !_isPasswordStrong
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _newPasswordController.text.isNotEmpty && !_isPasswordStrong
                      ? Colors.red
                      : const Color(0xFF05a5a5),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isObscureConfirm,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre Tekrar',
              prefixIcon: Icon(
                Icons.lock,
                color: _confirmPasswordController.text.isNotEmpty && !_passwordsMatch
                    ? Colors.red
                    : const Color(0xFF05a5a5),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_confirmPasswordController.text.isNotEmpty)
                    Icon(
                      _passwordsMatch ? Icons.check_circle : Icons.error,
                      color: _passwordsMatch ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  IconButton(
                    icon: Icon(
                      _isObscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureConfirm = !_isObscureConfirm;
                      });
                    },
                  ),
                ],
              ),
              helperText: _confirmPasswordController.text.isNotEmpty && !_passwordsMatch
                  ? 'Şifreler eşleşmiyor'
                  : _confirmPasswordController.text.isNotEmpty && _passwordsMatch
                      ? 'Şifreler eşleşiyor'
                      : null,
              helperStyle: TextStyle(
                color: _passwordsMatch ? Colors.green : Colors.red,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _confirmPasswordController.text.isNotEmpty && !_passwordsMatch
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _confirmPasswordController.text.isNotEmpty && !_passwordsMatch
                      ? Colors.red
                      : const Color(0xFF05a5a5),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isChangingPassword
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Şifreyi Değiştir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Durum mesajı
          if (_currentPasswordController.text.isNotEmpty && 
              _newPasswordController.text.isNotEmpty && 
              _confirmPasswordController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getValidationColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getValidationColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getValidationIcon(),
                    color: _getValidationColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getValidationMessage(),
                      style: TextStyle(
                        color: _getValidationColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityOptionsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF05a5a5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: Color(0xFF05a5a5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Güvenlik Seçenekleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildSwitchTile(
            title: 'İki Faktörlü Doğrulama',
            subtitle: 'SMS ile ek güvenlik',
            value: _twoFactorAuth,
            onChanged: (value) {
              setState(() {
                _twoFactorAuth = value;
              });
            },
            icon: Icons.security,
          ),
          
          const Divider(height: 32),
          
          _buildSwitchTile(
            title: 'Biyometrik Doğrulama',
            subtitle: 'Parmak izi / Yüz tanıma',
            value: _biometricAuth,
            onChanged: (value) {
              setState(() {
                _biometricAuth = value;
              });
            },
            icon: Icons.fingerprint,
          ),
          
          const Divider(height: 32),
          
          _buildSwitchTile(
            title: 'Giriş Bildirimleri',
            subtitle: 'Yeni giriş bildirimlerini al',
            value: _loginNotifications,
            onChanged: (value) {
              setState(() {
                _loginNotifications = value;
              });
            },
            icon: Icons.notifications_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storage,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Veri Yönetimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildActionTile(
            title: 'Verilerimi Dışa Aktar',
            subtitle: 'Tüm verilerinizi indirin',
            icon: Icons.download,
            onTap: _exportData,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Hesabı Sil',
            subtitle: 'Hesabınızı kalıcı olarak silin',
            icon: Icons.delete_forever,
            onTap: _deleteAccount,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF05a5a5),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF05a5a5),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    // Temel validasyonlar
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun', Colors.red);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('Yeni şifreler eşleşmiyor', Colors.red);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showMessage('Şifre en az 6 karakter olmalı', Colors.red);
      return;
    }
    
    if (_currentPasswordController.text == _newPasswordController.text) {
      _showMessage('Yeni şifre mevcut şifre ile aynı olamaz', Colors.red);
      return;
    }

    // Loading durumunu başlat
    setState(() {
      _isChangingPassword = true;
    });

    try {
      // API çağrısı
      final result = await PasswordService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (result['success']) {
        // Başarılı
        _showMessage(result['message'], Colors.green);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        // Başarılı dialog göster
        _showSuccessDialog();
      } else {
        // Hata
        _showMessage(result['message'], Colors.red);
      }
    } catch (e) {
      _showMessage('Beklenmedik bir hata oluştu: $e', Colors.red);
    } finally {
      // Loading durumunu bitir
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veri Dışa Aktarma'),
        content: const Text(
          'Tüm verileriniz PDF formatında e-posta adresinize gönderilecek. İşlem birkaç dakika sürebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Verileriniz e-posta adresinize gönderilecek', Colors.blue);
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Bu işlem geri alınamaz! Tüm verileriniz kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Son Onay'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hesabınızı silmek için "SİL" yazın:'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'SİL yazın',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Başarılı!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Şifreniz başarıyla değiştirildi. Güvenliğiniz için yeni şifrenizi kimseyle paylaşmayın.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05a5a5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
