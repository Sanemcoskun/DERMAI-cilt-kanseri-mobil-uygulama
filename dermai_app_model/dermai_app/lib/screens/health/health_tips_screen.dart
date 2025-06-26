import 'package:flutter/material.dart';
import '../../services/health_tips_service.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final HealthTipsService _healthTipsService = HealthTipsService();
  
  List<HealthCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthTips();
  }

  Future<void> _loadHealthTips() async {
    try {
      final categories = await _healthTipsService.getHealthCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      _tabController = TabController(length: _categories.length, vsync: this);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sağlık tavsiyeleri yüklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_categories.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF05a5a5),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Sağlık Tavsiyeleri',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF05a5a5),
              ),
              SizedBox(height: 16),
              Text(
                'Sağlık tavsiyeleri yükleniyor...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF05a5a5),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Sağlık Tavsiyeleri',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Sağlık tavsiyeleri yüklenemedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen internet bağlantınızı kontrol edin',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadHealthTips();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05a5a5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sağlık Tavsiyeleri',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: _categories.map((category) => 
            Tab(
              icon: Icon(category.icon, size: 20),
              text: category.title,
            )
          ).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) => 
          _buildCategoryContent(category)
        ).toList(),
      ),
    );
  }

  Widget _buildCategoryContent(HealthCategory category) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: category.tips.length,
      itemBuilder: (context, index) {
        final tip = category.tips[index];
        return _buildHealthTipCard(tip, category.color);
      },
    );
  }

  Widget _buildHealthTipCard(HealthTip tip, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getImportanceIcon(tip.importance),
            color: categoryColor,
            size: 20,
          ),
        ),
        title: Text(
          tip.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A202C),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              tip.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(tip.importance, _getImportanceColor(tip.importance)),
                const SizedBox(width: 8),
                _buildInfoChip(tip.frequency, categoryColor),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.details,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama Adımları:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 12),
                ...tip.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  IconData _getImportanceIcon(String importance) {
    switch (importance) {
      case 'Çok Yüksek':
        return Icons.priority_high;
      case 'Yüksek':
        return Icons.trending_up;
      case 'Orta':
        return Icons.trending_flat;
      default:
        return Icons.info_outline;
    }
  }

  Color _getImportanceColor(String importance) {
    switch (importance) {
      case 'Çok Yüksek':
        return const Color(0xFFDC2626);
      case 'Yüksek':
        return const Color(0xFFEA580C);
      case 'Orta':
        return const Color(0xFFCA8A04);
      default:
        return const Color(0xFF6B7280);
    }
  }
} 