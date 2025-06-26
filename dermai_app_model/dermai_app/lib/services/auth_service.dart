import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import '../config/api_config.dart';

class AuthService {
  // Platform-spesifik URL belirleme
  static String get baseUrl {
    // GERÇEK TELEFON için bilgisayarın IP adresini kullan
    return 'http://192.168.1.100/flutter/dermai_api/auth';
    //return 'http://192.168.36.220/flutter/dermai_api/auth';

    // Emülatör test ederken aşağıdaki kodları aktif edin:
    /*
    if (Platform.isAndroid) {
      // Android Emülatör için 10.0.2.2 kullanılır
      return 'http://10.0.2.2/flutter/dermai_api/auth/auth_handler.php';
    } else if (Platform.isIOS) {
      // iOS Simülatör için localhost çalışır
      return 'http://localhost/flutter/dermai_api/auth/auth_handler.php';
    } else {
      // Web/Desktop için localhost
      return 'http://localhost/flutter/dermai_api/auth/auth_handler.php';
    }
    */
  }
  
  static const String apiKey = 'dermai-api-2024';
  
  // SharedPreferences keys
  static const String sessionKey = 'session_id';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';

  // Register API çağrısı
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'action': 'register',
          'ad': firstName,
          'soyad': lastName,
          'email': email,
          'sifre': password,
          'sifre_tekrar': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 200) {
        // Başarılı kayıt - session kaydetme, kullanıcı tekrar giriş yapmalı
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Kayıt sırasında bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  // Login API çağrısı
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Login attempt for: $email');
      print('🌐 Connecting to: ${ApiConfig.authEndpoint}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'action': 'login',
          'email': email,
          'sifre': password,
        }),
      ).timeout(Duration(seconds: 10));

      print('📱 Response status: ${response.statusCode}');
      print('📱 Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 200) {
        // Başarılı giriş - session bilgilerini kaydet
        await _saveSessionData(data['data']);
        
        // UserService cache'ini yükle
        final userId = int.tryParse(data['data']['user_id'].toString());
        if (userId != null) {
          await UserService.getUserData(userId);
        }
        
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Giriş sırasında bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  // Session doğrulama
  static Future<Map<String, dynamic>> validateSession() async {
    try {
      final sessionId = await getSessionId();
      if (sessionId == null) {
        return {'success': false, 'message': 'Session bulunamadı'};
      }

      final response = await http.post(
        Uri.parse(ApiConfig.authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
          'X-Session-ID': sessionId,
        },
        body: jsonEncode({
          'action': 'validate',
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        // Session geçersiz - temizle
        await clearSession();
        return {
          'success': false,
          'message': data['message'] ?? 'Session geçersiz',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final sessionId = await getSessionId();
      if (sessionId != null) {
        await http.post(
          Uri.parse(ApiConfig.authEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.apiKey}',
            'X-Session-ID': sessionId,
          },
          body: jsonEncode({
            'action': 'logout',
          }),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    }
    
    // Local session'ı temizle
    await clearSession();
    
    // UserService cache'ini temizle
    UserService.clearCache();
  }

  // Session bilgilerini SharedPreferences'a kaydet
  static Future<void> _saveSessionData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('session_id', data['session_id'] ?? '');
    await prefs.setString('user_id', data['user_id']?.toString() ?? '');
    await prefs.setString('user_email', data['email'] ?? '');
    await prefs.setString('user_name', '${data['ad'] ?? ''} ${data['soyad'] ?? ''}');
  }

  // Session ID'yi al
  static Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id');
  }

  // Session'ı temizle
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
  }

  // Giriş yapılmış mı kontrol et
  static Future<bool> isLoggedIn() async {
    final sessionId = await getSessionId();
    return sessionId != null && sessionId.isNotEmpty;
  }

  // Mevcut kullanıcı bilgilerini al
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('session_id');
    
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    
    return {
      'id': prefs.getString('user_id'),
      'email': prefs.getString('user_email'),
      'name': prefs.getString('user_name'),
      'session_id': sessionId,
    };
  }

  // Kullanıcı ID'sini al
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
} 