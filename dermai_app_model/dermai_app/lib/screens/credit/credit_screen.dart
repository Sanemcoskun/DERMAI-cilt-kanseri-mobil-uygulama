import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../services/credit_service.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  int _userCredits = 0;
  bool _isLoading = true;
  String? _selectedPackage; // Seçilen paket

  @override
  void initState() {
    super.initState();
    _loadUserCredits();
  }

  Future<void> _loadUserCredits() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await CreditService.getUserCredits();
      if (result != null && result['status'] == true) {
        setState(() {
          _userCredits = result['data']['credits']['current_balance'] ?? 0;
          _isLoading = false;
        });
      } else {
        // API'den veri alınamazsa yerel servisi kullan
        setState(() {
          _userCredits = UserService.getCredits();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Kredi yükleme hatası: $e');
      // Hata durumunda yerel servisi kullan
      setState(() {
        _userCredits = UserService.getCredits();
        _isLoading = false;
      });
    }
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
          'Premium Kredi Sistemi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama
            const Center(
              child: Text(
                'AI destekli sağlık analizleri için kredi kullanın',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Mevcut Kredi Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mevcut Kredi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const SizedBox(
                          height: 32,
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF05a5a5),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          '$_userCredits Kredi',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Hizmet Fiyatlandırması
            const Text(
              'Hizmet Fiyatlandırması',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildServiceItem('Cilt Analizi', '5 Kredi'),
            const Divider(color: Color(0xFFE2E8F0)),
            _buildServiceItem('PDF Raporu', '2 Kredi'),
            
            const SizedBox(height: 40),
            
            // Kredi Paketleri
            const Text(
              'Kredi Paketleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildCreditPackage(
              title: 'Başlangıç',
              price: '₺49',
              credits: '5 Kredi',
              isPopular: false,
              packageId: 'starter',
            ),
            
            const SizedBox(height: 16),
            
            _buildCreditPackage(
              title: 'Standart',
              price: '₺129',
              credits: '15 Kredi',
              isPopular: true,
              packageId: 'standard',
            ),
            
            const SizedBox(height: 16),
            
            _buildCreditPackage(
              title: 'Premium',
              price: '₺249',
              credits: '35 Kredi',
              isPopular: false,
              packageId: 'premium',
            ),
            
            const SizedBox(height: 30),
            
            // Kredi Yükle Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showPurchaseDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05a5a5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kredi Yükle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // İptal Et Butonu
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/main', 
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'İptal Et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String service, String cost) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            cost,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPackage({
    required String title,
    required String price,
    required String credits,
    required bool isPopular,
    required String packageId,
  }) {
    final isSelected = _selectedPackage == packageId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = packageId;
        });
        _showPackageSelectedSnackBar(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF05a5a5).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF05a5a5)
                : isPopular 
                    ? const Color(0xFF05a5a5).withOpacity(0.5) 
                    : const Color(0xFFE2E8F0),
            width: isSelected ? 3 : (isPopular ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05a5a5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Popüler',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tek Seferlik',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.check,
                  color: isSelected ? const Color(0xFF05a5a5) : const Color(0xFF10B981),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  credits,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF05a5a5) : const Color(0xFF64748B),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05a5a5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Seçildi',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageSelectedSnackBar(String packageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$packageName paketi seçildi',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF05a5a5),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showPurchaseDialog() {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir paket seçin'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String selectedPackageName = '';
    String selectedPrice = '';
    switch (_selectedPackage) {
      case 'starter':
        selectedPackageName = 'Başlangıç';
        selectedPrice = '₺49';
        break;
      case 'standard':
        selectedPackageName = 'Standart';
        selectedPrice = '₺129';
        break;
      case 'premium':
        selectedPackageName = 'Premium';
        selectedPrice = '₺249';
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Kredi Satın Al',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seçilen Paket: $selectedPackageName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fiyat: $selectedPrice',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kredi satın alma özelliği yakında eklenecektir.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tamam',
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


} 