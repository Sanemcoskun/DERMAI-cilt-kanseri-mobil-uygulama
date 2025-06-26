import 'package:http/http.dart' as http;

class ApiConfig {
  // Ana sunucu adresi - sadece burayı değiştirin
  static const String baseUrl = 'http://192.168.1.100/flutter/dermai_api';
  
  // API anahtarı
  static const String apiKey = 'dermai-api-2024';
  
  // API endpoint'leri
  static const String authEndpoint = '$baseUrl/auth/auth_handler.php';
  static const String analysisHistoryEndpoint = '$baseUrl/analysis/get_analysis_history.php';
  static const String saveAnalysisEndpoint = '$baseUrl/analysis/save_analysis.php';
  static const String uploadImageEndpoint = '$baseUrl/analysis/upload_image.php';
  static const String profileEndpoint = '$baseUrl/profile/profile_handler.php';
  static const String feedbackEndpoint = '$baseUrl/profile/feedback_handler.php';
  static const String passwordEndpoint = '$baseUrl/profile/change_password.php';
  static const String creditEndpoint = '$baseUrl/credits/credits_handler.php';
  static const String blogEndpoint = '$baseUrl/blog/blog_handler.php';
  static const String chatEndpoint = '$baseUrl/api/chat.php';
  
  // AI Model sunucusu (farklı sunucu)
  static const String aiModelUrl = 'http://193.164.7.249:8000';
  static const String analyzeEndpoint = '$aiModelUrl/analyze';
  
  // Görsel URL'leri oluşturma
  static String getImageUrl(String relativePath) {
    return '$baseUrl/$relativePath';
  }
  
  // Sunucu sağlık kontrolü
  static Future<bool> isServerReachable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/index.php'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 