import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/api_config.dart';

class AnalysisHistoryService {

  // Analiz sonucunu kaydet
  Future<Map<String, dynamic>> saveAnalysisResult({
    required int userId,
    required String region,
    required String predictedClass,
    required String className,
    required double confidence,
    required String riskLevel,
    required String riskColor,
    required List<String> recommendations,
    List<dynamic>? allPredictions,
    String? imagePath,
    String? imageName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.saveAnalysisEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: json.encode({
          'user_id': userId,
          'region': region,
          'predicted_class': predictedClass,
          'class_name': className,
          'confidence': confidence,
          'risk_level': riskLevel,
          'risk_color': riskColor,
          'recommendations': recommendations,
          'all_predictions': allPredictions,
          'image_path': imagePath,
          'image_name': imageName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse;
      } else {
        return {
          'success': false,
          'message': 'HTTP Hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Save Analysis Error: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  // Kullanıcının analiz geçmişini çek
  Future<Map<String, dynamic>> getAnalysisHistory(int userId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.analysisHistoryEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: json.encode({
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse;
      } else {
        return {
          'success': false,
          'message': 'HTTP Hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Get Analysis History Error: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  // Analiz sonucunu dosya yolu ile birlikte kaydet (HTTP Upload)
  Future<String?> saveAnalysisWithImage(File imageFile, int userId) async {
    try {
      print('📁 saveAnalysisWithImage started (HTTP Upload)');
      print('📁 Original file: ${imageFile.path}');
      print('📁 File exists: ${await imageFile.exists()}');
      
      // MultipartRequest oluştur
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadImageEndpoint),
      );
      
      // Headers ekle
      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConfig.apiKey}',
      });
      
      // User ID ekle
      request.fields['user_id'] = userId.toString();
      
      // Dosyayı ekle
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      print('📁 Uploading to: ${ApiConfig.uploadImageEndpoint}');
      print('📁 File size: ${await imageFile.length()} bytes');
      
      // Request gönder
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📁 Upload response status: ${response.statusCode}');
      print('📁 Upload response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final imagePath = responseData['image_path'];
          print('📁 Upload successful, path: $imagePath');
          return imagePath;
        } else {
          print('📁 Upload failed: ${responseData['message']}');
          return null;
        }
      } else {
        print('📁 HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('📁 Save Image Error: $e');
      print('📁 Error type: ${e.runtimeType}');
      return null;
    }
  }
}

// Analiz geçmişi modeli
class AnalysisHistoryItem {
  final int id;
  final DateTime analysisDate;
  final String region;
  final String predictedClass;
  final String className;
  final double confidence;
  final String riskLevel;
  final String riskColor;
  final List<String> recommendations;
  final List<dynamic>? allPredictions;
  final String? imagePath;
  final String? imageName;
  final String formattedDate;

  AnalysisHistoryItem({
    required this.id,
    required this.analysisDate,
    required this.region,
    required this.predictedClass,
    required this.className,
    required this.confidence,
    required this.riskLevel,
    required this.riskColor,
    required this.recommendations,
    this.allPredictions,
    this.imagePath,
    this.imageName,
    required this.formattedDate,
  });

  factory AnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryItem(
      id: int.parse(json['id'].toString()),
      analysisDate: DateTime.parse(json['analysis_date']),
      region: json['region'] ?? '',
      predictedClass: json['predicted_class'] ?? '',
      className: json['class_name'] ?? '',
      confidence: double.parse(json['confidence'].toString()),
      riskLevel: json['risk_level'] ?? '',
      riskColor: json['risk_color'] ?? '#6B7280',
      recommendations: json['recommendations'] is List 
          ? List<String>.from(json['recommendations'])
          : [json['recommendations']?.toString() ?? ''],
      allPredictions: json['all_predictions'],
      imagePath: json['image_path'],
      imageName: json['image_name'],
      formattedDate: json['formatted_date'] ?? '',
    );
  }

  // Bölge adlarını Türkçe'ye çevir
  String get regionDisplay {
    switch (region.toLowerCase()) {
      case 'face': return 'Yüz';
      case 'neck': return 'Boyun';
      case 'chest': return 'Göğüs';
      case 'back': return 'Sırt';
      case 'arms': return 'Kollar';
      case 'legs': return 'Bacaklar';
      case 'hands': return 'Eller';
      case 'other': return 'Diğer';
      default: return region;
    }
  }

  // Risk seviyesi rengi
  Color get riskColorValue {
    switch (riskColor) {
      case '#EF4444': return const Color(0xFFEF4444); // Kırmızı - Yüksek Risk
      case '#F59E0B': return const Color(0xFFF59E0B); // Sarı - Orta Risk  
      case '#10B981': return const Color(0xFF10B981); // Yeşil - Düşük Risk
      default: 
        // Risk seviyesine göre fallback renk
        switch (riskLevel) {
          case 'Yüksek Risk': return const Color(0xFFEF4444);
          case 'Orta Risk': return const Color(0xFFF59E0B);
          case 'Düşük Risk': return const Color(0xFF10B981);
          default: return const Color(0xFF6B7280); // Gri
        }
    }
  }

  // Risk ikonu
  IconData get riskIcon {
    switch (riskLevel) {
      case 'Yüksek Risk': return Icons.dangerous;
      case 'Orta Risk': return Icons.warning;
      case 'Düşük Risk': return Icons.check_circle;
      default: return Icons.help;
    }
  }
} 