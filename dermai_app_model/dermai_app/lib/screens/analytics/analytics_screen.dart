import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/analysis_history_service.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import '../../services/analysis_history_service.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import '../../config/api_config.dart';
import 'analysis_detail_screen.dart';



class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalysisHistoryService _historyService = AnalysisHistoryService();
  
  List<AnalysisHistoryItem> _analysisHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kullanıcı ID'sini al
      final user = await AuthService.getCurrentUser();
      if (user == null || user['id'] == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
        });
        return;
      }

      final userId = int.parse(user['id'].toString());
      
      // Analiz geçmişini çek
      final response = await _historyService.getAnalysisHistory(userId);
      
      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _analysisHistory = data.map((item) => AnalysisHistoryItem.fromJson(item)).toList();
          _isLoading = false;
          
          // Debug: Analiz verisini yazdır
          if (_analysisHistory.isNotEmpty) {
            print('🔍 Analytics Debug - İlk analiz:');
            print('🔍 ID: ${_analysisHistory[0].id}');
            print('🔍 Image Path: ${_analysisHistory[0].imagePath}');
            print('🔍 Image Name: ${_analysisHistory[0].imageName}');
            print('🔍 Class Name: ${_analysisHistory[0].className}');
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Analiz geçmişi yüklenirken hata oluştu';
        });
      }
    } catch (e) {
      print('Load Analysis History Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bağlantı hatası: ${e.toString()}';
      });
    }
  }

  // İstatistikleri hesapla
  Map<String, int> _calculateStats() {
    int totalAnalyses = _analysisHistory.length;
    int highRiskCount = _analysisHistory.where((item) => item.riskLevel == 'Yüksek Risk').length;
    int mediumRiskCount = _analysisHistory.where((item) => item.riskLevel == 'Orta Risk').length;
    int lowRiskCount = _analysisHistory.where((item) => item.riskLevel == 'Düşük Risk').length;

    return {
      'total': totalAnalyses,
      'high_risk': highRiskCount,
      'medium_risk': mediumRiskCount,
      'low_risk': lowRiskCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        elevation: 0,
        title: const Text(
          'Analiz Geçmişi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalysisHistory,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _analysisHistory.isEmpty
                  ? _buildEmptyStateWidget()
                  : _buildAnalysisHistoryWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05a5a5)),
          ),
          SizedBox(height: 16),
          Text(
            'Analiz geçmişi yükleniyor...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAnalysisHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF05a5a5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 60,
                color: Color(0xFF05a5a5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz analiz geçmişiniz yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'İlk cilt analizinizi yapmak için analiz sayfasına gidin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/skin-analysis');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'İlk Analizimi Yap',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisHistoryWidget() {
    final stats = _calculateStats();
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İstatistik kartları
            _buildStatsSection(stats),
            
            const SizedBox(height: 24),
            
            // Analiz geçmişi başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Son Analizler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
                Text(
                  '${_analysisHistory.length} analiz',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Analiz kartları
            ..._analysisHistory.map((analysis) => _buildAnalysisCard(analysis)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam Analiz',
            stats['total']!,
            const Color(0xFF05a5a5),
            Icons.analytics,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Yüksek Risk',
            stats['high_risk']!,
            const Color(0xFFEF4444),
            Icons.dangerous,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Düşük Risk',
            stats['low_risk']!,
            const Color(0xFF10B981),
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(AnalysisHistoryItem analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisDetailScreen(analysis: analysis),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sol taraf - Görsel
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: analysis.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: analysis.imagePath!.startsWith('assets/')
                            ? Image.asset(
                                analysis.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('🖼️ Asset Image Error: $error');
                                  print('🖼️ Asset Path: ${analysis.imagePath}');
                                  return _buildImagePlaceholder();
                                },
                              )
                            : Image.network(
                                ApiConfig.getImageUrl(analysis.imagePath!),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05a5a5)),
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('🖼️ Network Image Error: $error');
                                  print('🖼️ Network URL: ${ApiConfig.getImageUrl(analysis.imagePath!)}');
                                  return _buildImagePlaceholder();
                                },
                              ),
                      )
                    : _buildImagePlaceholder(),
              ),
              
              const SizedBox(width: 16),
              
              // Sağ taraf - Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve tarih
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cilt Analizi - ${analysis.regionDisplay}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Tarih
                    Text(
                      analysis.formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Analiz sonucu
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: analysis.riskColorValue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            analysis.riskIcon,
                            size: 16,
                            color: analysis.riskColorValue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            analysis.className,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A202C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Risk seviyesi ve güven oranı
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: analysis.riskColorValue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            analysis.riskLevel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: analysis.riskColorValue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Güven: %${(analysis.confidence * 100).toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              size: 20,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 2),
            Text(
              'Görsel',
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 