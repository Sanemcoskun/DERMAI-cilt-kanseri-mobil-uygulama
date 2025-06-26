import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class FeedbackService {

  static Future<Map<String, dynamic>> sendFeedback({
    required String name,
    required String subject,
    required String message,
    required int rating,
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
        Uri.parse(ApiConfig.feedbackEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
          'X-Session-ID': actualSessionId,
        },
        body: json.encode({
          'name': name,
          'subject': subject,
          'message': message,
          'rating': rating,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Geri bildirim gönderilirken bir hata oluştu',
        };
      }
    } catch (e) {
      print('Feedback Error: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }
} 