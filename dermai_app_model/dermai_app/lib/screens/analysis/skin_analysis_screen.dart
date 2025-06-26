import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/skin_analysis_service.dart';
import '../../services/analysis_history_service.dart';
import '../../services/auth_service.dart';

enum SkinRegion {
  face('Yüz', 'Alın, yanak, burun', Icons.face),
  neck('Boyun', 'Boyun bölgesi', Icons.accessibility_new),
  chest('Göğüs', 'Göğüs bölgesi', Icons.person),
  back('Sırt', 'Sırt bölgesi', Icons.accessibility),
  arms('Kollar', 'Kol ve omuz', Icons.pan_tool),
  legs('Bacaklar', 'Bacak bölgesi', Icons.directions_walk),
  hands('Eller', 'El ve parmak', Icons.back_hand),
  other('Diğer', 'Diğer bölgeler', Icons.more_horiz);

  const SkinRegion(this.title, this.description, this.icon);
  final String title;
  final String description;
  final IconData icon;
}

class SkinAnalysisScreen extends StatefulWidget {
  const SkinAnalysisScreen({super.key});

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen> {
  bool _hasSelectedImage = false;
  bool _isAnalyzing = false;
  SkinRegion? _selectedRegion;
  bool _isDropdownOpen = false;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  final SkinAnalysisService _analysisService = SkinAnalysisService();
  final AnalysisHistoryService _historyService = AnalysisHistoryService();
  Map<String, dynamic>? _analysisResult;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fotoğraf Seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _selectFromCamera();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05a5a5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF05a5a5).withOpacity(0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: Color(0xFF05a5a5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF05a5a5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _selectFromGallery();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05a5a5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF05a5a5).withOpacity(0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 32,
                              color: Color(0xFF05a5a5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Galeri',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF05a5a5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _hasSelectedImage = true;
        });
        _showSuccessSnackBar('Fotoğraf kameradan çekildi');
      }
    } catch (e) {
      _showErrorSnackBar('Kamera erişiminde hata oluştu: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _hasSelectedImage = true;
        });
        _showSuccessSnackBar('Fotoğraf galeriden seçildi');
      }
    } catch (e) {
      _showErrorSnackBar('Galeri erişiminde hata oluştu: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _hasSelectedImage = false;
      _selectedImageFile = null;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF05a5a5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Analiz sonucunu geçmişe kaydet
  Future<void> _saveAnalysisToHistory() async {
    if (_analysisResult == null || !_analysisResult!['success']) {
      _showErrorSnackBar('Kaydedilecek analiz sonucu bulunamadı');
      return;
    }

    try {
      // Kullanıcı ID'sini al
      final user = await AuthService.getCurrentUser();
      if (user == null || user['id'] == null) {
        _showErrorSnackBar('Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
        return;
      }

      final userId = int.parse(user['id'].toString());
      final result = _analysisResult!;

      // Görsel dosyasını kaydet (eğer varsa)
      String? imagePath;
      String? imageName;
      if (_selectedImageFile != null) {
        print('🖼️ Original image path: ${_selectedImageFile!.path}');
        imagePath = await _historyService.saveAnalysisWithImage(_selectedImageFile!, userId);
        print('🖼️ Saved image path: $imagePath');
        if (imagePath != null) {
          imageName = imagePath.split('/').last;
          print('🖼️ Image name: $imageName');
        }
      }

      // Analiz sonucunu veritabanına kaydet
      final saveResponse = await _historyService.saveAnalysisResult(
        userId: userId,
        region: _selectedRegion?.title.toLowerCase() ?? 'other',
        predictedClass: result['predicted_class'] ?? '',
        className: result['class_name'] ?? '',
        confidence: result['confidence']?.toDouble() ?? 0.0,
        riskLevel: result['risk_level'] ?? '',
        riskColor: result['risk_color'] ?? '#6B7280',
        recommendations: List<String>.from(result['recommendations'] ?? []),
        allPredictions: result['all_predictions'],
        imagePath: imagePath,
        imageName: imageName,
      );

      if (saveResponse['success']) {
        _showSuccessSnackBar('Analiz sonucu başarıyla kaydedildi!');
        
        // Analytics sayfasına yönlendir
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
          arguments: {'initialIndex': 2}, // Analytics tab
        );
      } else {
        _showErrorSnackBar(saveResponse['message'] ?? 'Kaydetme sırasında hata oluştu');
      }
    } catch (e) {
      print('Save Analysis History Error: $e');
      _showErrorSnackBar('Kaydetme sırasında hata oluştu: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _startAnalysis() async {
    if (!_hasSelectedImage || _selectedRegion == null || _selectedImageFile == null) {
      _showErrorSnackBar('Lütfen bir resim seçin ve bölge belirtin');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      // Gerçek analiz işlemi
      final result = await _analysisService.analyzeImage(
        _selectedImageFile!,
        _selectedRegion!.title,
      );

      setState(() {
        _isAnalyzing = false;
        _analysisResult = result;
      });

      if (result['success']) {
        _showAnalysisCompleteDialog();
      } else {
        _showErrorSnackBar(result['error'] ?? 'Analiz sırasında bir hata oluştu');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorSnackBar('Analiz sırasında bir hata oluştu: $e');
    }
  }

  void _showImagePreviewModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // Ana görsel
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/skin_sample.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 300,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA)],
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Color(0xFFD97706),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Örnek Görsel',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Kapatma butonu
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Alt bilgi paneli
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '✅ İdeal Cilt Analizi Fotoğrafı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Net, yakın ve gün ışığında çekilmiş. Bu şekilde fotoğraf çekmeniz önerilir.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAnalysisCompleteDialog() {
    if (_analysisResult == null || !_analysisResult!['success']) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final result = _analysisResult!;
        final confidence = (result['confidence'] * 100).toStringAsFixed(1);
        final riskColor = Color(int.parse(result['risk_color'].replaceFirst('#', '0xFF')));
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.analytics,
                color: const Color(0xFF05a5a5),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Analiz Sonucu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ana Sonuç
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05a5a5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        result['class_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              result['risk_level'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: riskColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Güven: %$confidence',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bölge Bilgisi
                if (_selectedRegion != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedRegion!.icon,
                          size: 20,
                          color: const Color(0xFF05a5a5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bölge: ${_selectedRegion!.title}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Öneriler
                const Text(
                  'Öneriler:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                ...((result['recommendations'] as List<String>).take(3).map((recommendation) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFF05a5a5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                
                const SizedBox(height: 12),
                
                // Uyarı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bu analiz yalnızca bilgilendirme amaçlıdır. Kesin teşhis için mutlaka bir hekime başvurun.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Kapat',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _saveAnalysisToHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Kaydet ve Geçmişe Ekle',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cilt Analizi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yönergeler Bölümü
              _buildGuidelinesSection(),
              
              const SizedBox(height: 30),
              
              // Bölge Seçimi Kartı
              _buildRegionSelectionCard(),
              
              const SizedBox(height: 30),
              
              // Fotoğraf Yükleme Kartı
              _buildPhotoUploadCard(),
              
              const SizedBox(height: 30),
              
              // Analizi Başlat Butonu
              _buildAnalysisButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelinesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05a5a5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF05a5a5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Fotoğraf Çekim Yönergeleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildGuidelineItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGuidelineItems() {
    final guidelines = [
      {
        'icon': Icons.camera_enhance,
        'text': 'Fotoğraf net ve odaklı olmalı',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.visibility,
        'text': 'Cilt lezyonu tam olarak görünür olmalı',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.wb_sunny,
        'text': 'Gölgesiz ve gün ışığında çekilmiş olması tercih edilir',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.zoom_in,
        'text': 'Yakın çekim yapılmalı, bulanıklık olmamalı',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.no_photography,
        'text': 'Krem, makyaj veya filtre kullanılmamalı',
        'color': const Color(0xFFEF4444),
      },
    ];

    return guidelines.map((guideline) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (guideline['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                guideline['icon'] as IconData,
                color: guideline['color'] as Color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                guideline['text'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRegionSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analiz Edilecek Bölgeyi Seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dropdown Container
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDropdownOpen = !_isDropdownOpen;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedRegion != null 
                        ? const Color(0xFF05a5a5).withOpacity(0.05)
                        : const Color(0xFFF8FAFC),
                      borderRadius: _isDropdownOpen 
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          )
                        : BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDropdownOpen
                          ? const Color(0xFF05a5a5)
                          : _selectedRegion != null 
                            ? const Color(0xFF05a5a5)
                            : const Color(0xFFE2E8F0),
                        width: _isDropdownOpen || _selectedRegion != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedRegion != null 
                              ? const Color(0xFF05a5a5).withOpacity(0.1)
                              : const Color(0xFFE2E8F0).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedRegion?.icon ?? Icons.touch_app_outlined,
                            color: _selectedRegion != null 
                              ? const Color(0xFF05a5a5)
                              : const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRegion != null 
                                  ? 'Cilt Kanseri Tarama - ${_selectedRegion!.title}'
                                  : 'Lütfen bölge seçiniz',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedRegion != null 
                                    ? const Color(0xFF1A202C)
                                    : const Color(0xFF9CA3AF),
                                ),
                              ),
                              if (_selectedRegion != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedRegion!.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Analiz edilecek vücut bölgesini seçin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Dropdown Arrow
                        AnimatedRotation(
                          turns: _isDropdownOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: _isDropdownOpen
                              ? const Color(0xFF05a5a5)
                              : _selectedRegion != null 
                                ? const Color(0xFF05a5a5)
                                : const Color(0xFF9CA3AF),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Dropdown List
                if (_isDropdownOpen)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 200, // Maksimum yükseklik sınırı
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF05a5a5), width: 2),
                        right: BorderSide(color: Color(0xFF05a5a5), width: 2),
                        bottom: BorderSide(color: Color(0xFF05a5a5), width: 2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(2),
                      child: SingleChildScrollView(
                        child: Column(
                          children: SkinRegion.values.map((region) {
                            final isSelected = _selectedRegion == region;
                            final isLast = region == SkinRegion.values.last;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRegion = region;
                                  _isDropdownOpen = false;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? const Color(0xFF05a5a5).withOpacity(0.1)
                                    : Colors.transparent,
                                  border: !isLast ? const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ) : null,
                                ),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                          ? const Color(0xFF05a5a5).withOpacity(0.1)
                                          : const Color(0xFFE2E8F0).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        region.icon,
                                        color: isSelected 
                                          ? const Color(0xFF05a5a5)
                                          : const Color(0xFF6B7280),
                                        size: 18,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 12),
                                    
                                    // Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cilt Kanseri Tarama - ${region.title}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected 
                                                ? const Color(0xFF1A202C)
                                                : const Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            region.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected 
                                                ? const Color(0xFF6B7280)
                                                : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Selection indicator
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Color(0xFF05a5a5),
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Selected Region Badge
            if (_selectedRegion != null && !_isDropdownOpen) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Seçilen bölge: ${_selectedRegion!.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05a5a5).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _hasSelectedImage
          ? _buildImagePreview()
          : _buildUploadPrompt(),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      children: [
        // Örnek Fotoğraf Bölümü
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Örnek Cilt Analizi Fotoğrafı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF05a5a5).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => _showImagePreviewModal(),
                  borderRadius: BorderRadius.circular(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // Güzel placeholder görsel - telif hakkı problemi yok
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE0F2F1),
                                Color(0xFFB2DFDB),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF05a5a5).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Icon(
                                    Icons.camera_enhance,
                                    size: 24,
                                    color: Color(0xFF05a5a5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Net ve Yakın Çekim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'İyi Işıklandırma',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Alt kısımda bilgi etiketi
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: const Text(
                              '✅ İdeal Cilt Analizi Fotoğrafı',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu şekilde net, yakın ve gün ışığında çekilmiş fotoğraflar en iyi sonucu verir.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Fotoğraf Yükleme Alanı
        InkWell(
          onTap: _showImagePickerDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF05a5a5),
                width: 2,
              ),
              color: const Color(0xFF05a5a5).withOpacity(0.05),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05a5a5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    size: 36,
                    color: Color(0xFF05a5a5),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '📷 Fotoğraf Yükleyin veya Kamera ile Çekin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'JPEG, PNG | Maks. 10 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF05a5a5).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _selectedImageFile != null
                  ? Stack(
                      children: [
                        Image.file(
                          _selectedImageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Hazır',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fotoğraf yüklenemedi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _showImagePickerDialog,
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF05a5a5),
                    size: 16,
                  ),
                  label: const Text(
                    'Yeniden Seç',
                    style: TextStyle(
                      color: Color(0xFF05a5a5),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  label: const Text(
                    'Sil',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton() {
    final bool isButtonActive = _hasSelectedImage && _selectedRegion != null && !_isAnalyzing;
    
    return Column(
      children: [
        if (_selectedRegion == null || !_hasSelectedImage) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedRegion == null && !_hasSelectedImage
                        ? 'Önce bir bölge seçin ve fotoğraf yükleyin'
                        : _selectedRegion == null
                            ? 'Lütfen analiz edilecek bölgeyi seçin'
                            : 'Lütfen bir fotoğraf yükleyin',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isButtonActive ? _startAnalysis : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isButtonActive 
                  ? const Color(0xFF05a5a5) 
                  : const Color(0xFFE5E7EB),
              foregroundColor: isButtonActive 
                  ? Colors.white 
                  : const Color(0xFF9CA3AF),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isButtonActive ? 2 : 0,
            ),
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Analiz Ediliyor...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Analizi Başlat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
} 