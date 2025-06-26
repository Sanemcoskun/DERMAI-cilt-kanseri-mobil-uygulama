import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://192.168.1.100/flutter/dermai_api';
  static Map<String, dynamic>? _cachedUserData;

  static Future<Map<String, dynamic>> getUserData(int userId) async {
    try {
      print('UserService: getUserData çağrıldı - User ID: $userId');
      
      // Cache kontrolü
      if (_cachedUserData != null) {
        print('UserService: Cache\'den veri döndürülüyor');
        return {
          'success': true,
          'data': _cachedUserData,
        };
      }

      final url = '$baseUrl/profile/get_user.php?user_id=$userId';
      print('UserService: API çağrısı - URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dermai-api-2024',
        },
      );

      print('UserService: Response Status: ${response.statusCode}');
      print('UserService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status']) {
          _cachedUserData = responseData['data'];
          print('UserService: Veri başarıyla cache\'lendi');
          return {
            'success': true,
            'data': responseData['data']
          };
        } else {
          print('UserService: API hatası - ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Kullanıcı bilgisi alınamadı',
          };
        }
      } else {
        print('UserService: HTTP hatası - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('UserService: Exception - $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserData(int userId, Map<String, dynamic> userData) async {
    try {
      print('UserService: updateUserData çağrıldı - User ID: $userId');
      print('UserService: Update Data: $userData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer dermai-api-2024',
        },
        body: json.encode({
          'user_id': userId,
          ...userData,
        }),
      );

      print('UserService: Update Response Status: ${response.statusCode}');
      print('UserService: Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status']) {
          // Cache'i güncelle
          _cachedUserData = responseData['data'];
          return {
            'success': true,
            'data': responseData['data']
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Kullanıcı bilgisi güncellenemedi',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  static void clearCache() {
    _cachedUserData = null;
  }

  static Map<String, dynamic>? getCachedUserData() {
    return _cachedUserData;
  }

  static String getFullName() {
    if (_cachedUserData != null) {
      final name = _cachedUserData!['name'] ?? '';
      final surname = _cachedUserData!['surname'] ?? '';
      return '$name $surname'.trim();
    }
    return 'Kullanıcı';
  }

  static String getEmail() {
    if (_cachedUserData != null) {
      return _cachedUserData!['email'] ?? 'email@example.com';
    }
    return 'email@example.com';
  }

  static String getUserId() {
    if (_cachedUserData != null) {
      final id = _cachedUserData!['id'] ?? 1;
      return '#AD${DateTime.now().year}$id';
    }
    return '#AD2024';
  }

  static bool isPremiumUser() {
    if (_cachedUserData != null) {
      return _cachedUserData!['is_premium'] == 1 || _cachedUserData!['is_premium'] == true;
    }
    return false;
  }

  static int getCredits() {
    if (_cachedUserData != null && _cachedUserData!['credits'] != null) {
      return int.parse(_cachedUserData!['credits'].toString());
    }
    return 0;
  }
} 