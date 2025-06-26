import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class PasswordService {

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    String? sessionId,
  }) async {
    try {
      // SessionId parametre olarak gelmemişse SharedPreferences'tan al
      String? actualSessionId = sessionId;
      if (actualSessionId == null) {
        final prefs = await SharedPreferences.getInstance();
        actualSessionId = prefs.getString('session_id');
      }

      if (actualSessionId == null || actualSessionId.isEmpty) {
        return {
          'success': false,
          'message': 'Oturum bilgisi bulunamadı',
        };
      }

      final response = await http.post(
        Uri.parse(ApiConfig.passwordEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': actualSessionId,
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Şifre değiştirme sırasında bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }
} 