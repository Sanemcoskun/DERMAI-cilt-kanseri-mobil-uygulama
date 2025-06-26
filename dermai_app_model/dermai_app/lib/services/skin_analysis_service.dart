import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SkinAnalysisService {
  
  // Cilt lezyonu sınıfları
  static const Map<String, String> lesionClasses = {
    'akiec': 'Actinic Keratoses (Güneş Lekesi)',
    'bcc': 'Basal Cell Carcinoma (Bazal Hücreli Karsinom)',
    'bkl': 'Benign Keratosis (İyi Huylu Keratoz)',
    'df': 'Dermatofibroma (Dermatofibrom)',
    'mel': 'Melanoma (Melanom)',
    'nv': 'Melanocytic Nevus (Melanositik Nevüs)',
    'vasc': 'Vascular Lesion (Vasküler Lezyon)'
  };

  // Risk seviyesi belirleme
  static String getRiskLevel(String lesionType, double confidence) {
    if (lesionType == 'mel' && confidence > 0.7) {
      return 'Yüksek Risk';
    } else if ((lesionType == 'bcc' || lesionType == 'akiec') && confidence > 0.6) {
      return 'Orta Risk';
    } else {
      return 'Düşük Risk';
    }
  }

  // Risk rengi belirleme
  static String getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Yüksek Risk':
        return '#EF4444'; // Kırmızı
      case 'Orta Risk':
        return '#F59E0B'; // Sarı
      case 'Düşük Risk':
        return '#10B981'; // Yeşil
      default:
        return '#6B7280'; // Gri
    }
  }

  Future<Map<String, dynamic>> analyzeImage(File imageFile, String region) async {
    // Emülatör için geçici mock analiz sonucu
    print('🔬 Mock analiz başlatılıyor - emülatör modu');
    
    // 2-3 saniye bekleyerek gerçek analiz simülasyonu
    await Future.delayed(Duration(seconds: 2));
    
    // Mock analiz sonucu (çeşitli sonuçlar için rastgele)
    List<String> mockClasses = ['nv', 'bkl', 'bcc', 'akiec'];
    String randomClass = mockClasses[(DateTime.now().millisecond % mockClasses.length)];
    double mockConfidence = 0.75 + (DateTime.now().millisecond % 25) / 100; // 0.75-0.99 arası
    
    String riskLevel = getRiskLevel(randomClass, mockConfidence);
    
    print('🔬 Mock analiz tamamlandı: $randomClass (${(mockConfidence * 100).toStringAsFixed(1)}%)');
    
    return {
      'success': true,
      'predicted_class': randomClass,
      'class_name': lesionClasses[randomClass] ?? 'Bilinmeyen',
      'confidence': mockConfidence,
      'risk_level': riskLevel,
      'risk_color': getRiskColor(riskLevel),
      'all_predictions': [
        {'class': randomClass, 'confidence': mockConfidence},
        {'class': 'nv', 'confidence': 0.15},
        {'class': 'bkl', 'confidence': 0.08},
      ],
      'region': region,
      'recommendations': _getRecommendations(randomClass, mockConfidence),
    };
    
    /* Gerçek AI sunucu kodu - emülatör için devre dışı
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.analyzeEndpoint),
      );

      // Resim dosyasını multipart forma ekle
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'skin_image.jpg',
      );
      
      request.files.add(multipartFile);
      
      // Bölge bilgisini form field olarak ekle
      request.fields['region'] = region;

      // İsteği gönder (10 saniye timeout)
      var streamedResponse = await request.send().timeout(Duration(seconds: 10));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        
        // Tahmin sonucunu güvenli şekilde işle
        String predictedClass = jsonResponse['predicted_class'] ?? 'nv';
        double confidence = (jsonResponse['confidence'] ?? 0.5).toDouble();
        List<dynamic> allPredictions = jsonResponse['all_predictions'] ?? [];
        
        // Risk seviyesini belirle
        String riskLevel = getRiskLevel(predictedClass, confidence);
        
        return {
          'success': true,
          'predicted_class': predictedClass,
          'class_name': lesionClasses[predictedClass] ?? 'Bilinmeyen',
          'confidence': confidence,
          'risk_level': riskLevel,
          'risk_color': getRiskColor(riskLevel),
          'all_predictions': allPredictions,
          'region': region,
          'recommendations': _getRecommendations(predictedClass, confidence),
        };
      } else {
        return {
          'success': false,
          'error': 'Analiz sırasında hata oluştu: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Skin Analysis Error: $e');
      
      return {
        'success': false,
        'error': 'Bağlantı hatası: ${e.toString()}',
      };
    }
    */
  }

  List<String> _getRecommendations(String lesionType, double confidence) {
    List<String> recommendations = [];
    
    switch (lesionType) {
      case 'mel':
        recommendations.addAll([
          'Derhal bir dermatologa başvurun',
          'Bu durum acil tıbbi müdahale gerektirebilir',
          'Güneş koruyucu kullanmayı ihmal etmeyin',
          'Cilt değişikliklerini düzenli takip edin'
        ]);
        break;
      case 'bcc':
        recommendations.addAll([
          'Bir dermatologa danışmanız önerilir',
          'Erken müdahale ile tedavi başarısı yüksektir',
          'Güneşten korunma önlemlerini artırın',
          '6 ay içinde kontrol yaptırın'
        ]);
        break;
      case 'akiec':
        recommendations.addAll([
          'Dermatoloji kontrolü yaptırın',
          'Güneş koruyucu düzenli kullanın',
          'Şapka ve koruyucu kıyafet giyin',
          'Değişiklikleri takip edin'
        ]);
        break;
      case 'nv':
        recommendations.addAll([
          'Yıllık dermatoloji kontrolü yeterlidir',
          'Boyut, renk değişikliklerini izleyin',
          'Güneş koruyucu kullanmayı sürdürün',
          'ABCDE kuralını uygulayın'
        ]);
        break;
      default:
        recommendations.addAll([
          'Dermatoloji kontrolü önerilir',
          'Güneş koruyucu kullanın',
          'Değişiklikleri takip edin',
          'Şüpheli durumda hekime başvurun'
        ]);
    }
    
    return recommendations;
  }
}

class AnalysisResult {
  final String predictedClass;
  final String className;
  final double confidence;
  final String riskLevel;
  final String riskColor;
  final List<dynamic> allPredictions;
  final String region;
  final List<String> recommendations;

  AnalysisResult({
    required this.predictedClass,
    required this.className,
    required this.confidence,
    required this.riskLevel,
    required this.riskColor,
    required this.allPredictions,
    required this.region,
    required this.recommendations,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      predictedClass: json['predicted_class'],
      className: json['class_name'],
      confidence: json['confidence'],
      riskLevel: json['risk_level'],
      riskColor: json['risk_color'],
      allPredictions: json['all_predictions'],
      region: json['region'],
      recommendations: List<String>.from(json['recommendations']),
    );
  }
} 