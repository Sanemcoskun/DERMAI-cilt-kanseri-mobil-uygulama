import 'package:flutter/material.dart';
import '../../services/analysis_history_service.dart';
import '../../config/api_config.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final AnalysisHistoryItem analysis;

  const AnalysisDetailScreen({Key? key, required this.analysis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        elevation: 0,
        title: const Text(
          'Analiz Detayı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görsel ve temel bilgiler
              _buildImageAndBasicInfo(),
              
              const SizedBox(height: 24),
              
              // Analiz sonucu detayları
              _buildAnalysisResult(),
              
              const SizedBox(height: 24),
              
              // Öneriler
              _buildRecommendations(),
              
              const SizedBox(height: 24),
              
              // Hastalık hakkında bilgi
              _buildDiseaseInformation(),
              
              const SizedBox(height: 24),
              
              // Uyarı notu
              _buildDisclaimerNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageAndBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Görsel
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: analysis.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiConfig.getImageUrl(analysis.imagePath!),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05a5a5)),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
              ),
              
              const SizedBox(width: 16),
              
              // Temel bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cilt Analizi - ${analysis.regionDisplay}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis.formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: analysis.riskColorValue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: analysis.riskColorValue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            analysis.riskIcon,
                            size: 16,
                            color: analysis.riskColorValue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            analysis.riskLevel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: analysis.riskColorValue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analiz Sonucu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          
          // Tespit edilen hastalık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: analysis.riskColorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: analysis.riskColorValue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tespit Edilen:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Güven Oranı: %${(analysis.confidence * 100).toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Öneriler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          ...analysis.recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF05a5a5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDiseaseInformation() {
    final diseaseInfo = _getDiseaseInformation(analysis.predictedClass);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF05a5a5),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Bu Durum Hakkında',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            diseaseInfo['title']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            diseaseInfo['description']!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
          if (diseaseInfo['symptoms'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Belirtiler:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              diseaseInfo['symptoms']!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ],
          if (diseaseInfo['treatment'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Tedavi Yaklaşımı:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              diseaseInfo['treatment']!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimerNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Önemli Uyarı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bu analiz sadece bilgilendirme amaçlıdır ve kesin tanı değildir. Herhangi bir sağlık sorunu için mutlaka bir dermatoloğa başvurunuz. Erken teşhis ve tedavi her zaman en iyi seçenektir.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 4),
            Text(
              'Görsel',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getDiseaseInformation(String predictedClass) {
    switch (predictedClass) {
      case 'bcc':
        return {
          'title': 'Bazal Hücreli Karsinom (BCC)',
          'description': 'Bazal hücreli karsinom, en yaygın görülen cilt kanseri türüdür. Genellikle güneşe maruz kalan alanlarda ortaya çıkar ve yavaş büyür. İyi huylu davranış gösterse de, tedavi edilmezse çevredeki dokulara zarar verebilir.',
          'symptoms': 'Parlak, pembe veya kırmızı düğümcük; açık renkli, düz leke; sınırları belirsiz yaralar; kanamaya eğilimli lezyonlar; iyileşmeyen yaralar.',
          'treatment': 'Cerrahi eksizyon, mohs cerrahisi, kriyoterapi, elektrokoter, topikal tedaviler veya radyoterapi uygulanabilir. Erken teşhis edildiğinde tedavi başarısı %95\'in üzerindedir.',
        };
      case 'mel':
        return {
          'title': 'Melanom',
          'description': 'Melanom, melanosit hücrelerinden gelişen ve en tehlikeli cilt kanseri türüdür. Vücudun diğer bölgelerine yayılma (metastaz) potansiyeli yüksektir. Erken teşhis hayati önem taşır.',
          'symptoms': 'ABCDE kuralı: Asimetri, Bordür düzensizliği, Renk değişikliği, Çap (6mm\'den büyük), Evrim (değişen ben). Kaşıntı, kanama, kabuklanma.',
          'treatment': 'Cerrahi eksizyon ana tedavidir. İleri evrelerde immunoterapi, hedefli tedavi, kemoterapi veya radyoterapi uygulanabilir. Erken evrede 5 yıllık yaşam oranı %99\'dur.',
        };
      case 'akiec':
        return {
          'title': 'Aktinik Keratoz (Güneş Lekesi)',
          'description': 'Aktinik keratoz, uzun süreli güneş maruziyeti sonucu oluşan pre-kanseröz (kanser öncesi) lezyonlardır. Tedavi edilmezse skuamöz hücreli karsinoma dönüşebilir.',
          'symptoms': 'Kaba, pul pul, kahverengi veya kırmızı lekeler; dokunulduğunda kum kağıdı hissi; güneşe maruz kalan alanlarda görülme.',
          'treatment': 'Kriyoterapi (sıvı azot), topikal kemoterapi, fotodinamik terapi, lazer tedavisi veya cerrahi eksizyon uygulanabilir.',
        };
      case 'bkl':
        return {
          'title': 'Benign Keratoz (Seboreik Keratoz)',
          'description': 'Seboreik keratoz, yaşlanmayla birlikte ortaya çıkan iyi huylu cilt lezyonlarıdır. Kanser değildir ve tehlikeli değildir, ancak bazen melanomla karıştırılabilir.',
          'symptoms': 'Kahverengi, siyah veya açık renkli; kabartı şeklinde; mum damlası görünümü; çok sayıda olabilir.',
          'treatment': 'Tedavi gerekli değildir, ancak estetik kaygılar varsa kriyoterapi, elektrokoter veya lazer ile çıkarılabilir.',
        };
      case 'df':
        return {
          'title': 'Dermatofibrom',
          'description': 'Dermatofibrom, derinin alt tabakalarında oluşan iyi huylu fibröz nodüllerdir. Genellikle bacaklarda görülür ve yaralanma sonrası gelişebilir.',
          'symptoms': 'Sert, kahverengi veya kırmızımsı nodül; dokunulduğunda hafif acı verebilir; yavaş büyür.',
          'treatment': 'Genellikle tedavi gerektirmez. Estetik nedenlerle cerrahi eksizyon yapılabilir.',
        };
      case 'nv':
        return {
          'title': 'Melanositik Nevüs (Ben)',
          'description': 'Melanositik nevüs, melanosit hücrelerinin birikimi sonucu oluşan iyi huylu lezyonlardır. Yaygın olarak "ben" diye bilinir ve çoğu insan için normaldir.',
          'symptoms': 'Kahverengi, siyah veya pembemsi; düz veya kabartı; sınırları düzenli; genellikle 6mm\'den küçük.',
          'treatment': 'Normal benler tedavi gerektirmez. Şüpheli değişiklikler olursa dermatoloğa başvurulmalıdır.',
        };
      case 'vasc':
        return {
          'title': 'Vasküler Lezyon',
          'description': 'Vasküler lezyonlar, kan damarlarının anormal büyümesi veya genişlemesi sonucu oluşur. Çoğu iyi huyludur ve doğumsal veya sonradan gelişebilir.',
          'symptoms': 'Kırmızı, mor veya mavimsi renkler; çeşitli boyutlarda; basınçla solabilir.',
          'treatment': 'Çoğu tedavi gerektirmez. Gerekirse lazer tedavisi, skleroterapi veya cerrahi seçenekler mevcuttur.',
        };
      default:
        return {
          'title': 'Cilt Lezyonu',
          'description': 'Bu tip cilt lezyonu hakkında daha fazla bilgi için bir dermatoloğa danışmanız önerilir.',
          'symptoms': 'Belirtiler lezyonun tipine göre değişiklik gösterebilir.',
          'treatment': 'Tedavi seçenekleri için dermatoloji uzmanına başvurunuz.',
        };
    }
  }
} 