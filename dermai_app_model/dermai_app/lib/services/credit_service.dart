import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreditService {
  static const String baseUrl = 'http://192.168.1.100/flutter/dermai_api';
  
  static Future<Map<String, dynamic>?> getUserCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      
      if (sessionId == null) {
        throw Exception('Session ID bulunamadı');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/profile/get_user_credits.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dermai-api-2024',
          'X-Session-ID': sessionId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Kredi bilgileri alınamadı');
      }
    } catch (e) {
      print('Kredi bilgisi alma hatası: $e');
      return null;
    }
  }
  
  static Future<bool> useCredits({
    required int credits,
    required String serviceType,
    String? description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      
      if (sessionId == null) {
        throw Exception('Session ID bulunamadı');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/credits/use'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dermai-api-2024',
          'X-Session-ID': sessionId,
        },
        body: json.encode({
          'credits': credits,
          'service_type': serviceType,
          'description': description ?? 'Kredi kullanımı',
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 402) {
        // Yetersiz kredi
        final errorData = json.decode(response.body);
        throw Exception('Yetersiz kredi: ${errorData['message']}');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Kredi kullanılamadı');
      }
    } catch (e) {
      print('Kredi kullanma hatası: $e');
      throw e;
    }
  }
  
  static Future<int> getCurrentCredits() async {
    try {
      final result = await getUserCredits();
      if (result != null && result['status'] == true) {
        return result['data']['credits']['current_balance'] ?? 0;
      }
    } catch (e) {
      print('Mevcut kredi alma hatası: $e');
    }
    return 0;
  }
} 