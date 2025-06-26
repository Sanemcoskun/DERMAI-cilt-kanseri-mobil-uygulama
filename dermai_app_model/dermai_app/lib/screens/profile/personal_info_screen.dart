import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/user_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '5551234567');
  final _emailController = TextEditingController();
  final _ageController = TextEditingController(text: '28');
  final _heightController = TextEditingController(text: '165');
  final _weightController = TextEditingController(text: '58');
  final _allergiesController = TextEditingController(text: 'Polen, toz');
  final _medicationsController = TextEditingController(text: 'Günlük vitamin D');

  String? _selectedGender;
  String _selectedBloodType = 'A Rh+';
  String _selectedSkinType = 'Karma';
  String _selectedSkinSensitivity = 'Orta';
  String _selectedCountryCode = '+90';
  DateTime _selectedBirthDate = DateTime(1995, 5, 15);
  bool _isLoading = true;

  final List<String> _genderOptions = ['Kadın', 'Erkek', 'Belirtmek İstemiyorum'];
  final List<String> _bloodTypeOptions = ['A Rh+', 'A Rh-', 'B Rh+', 'B Rh-', 'AB Rh+', 'AB Rh-', 'O Rh+', 'O Rh-'];
  final List<String> _skinTypeOptions = ['Kuru', 'Yağlı', 'Karma', 'Normal', 'Hassas'];
  final List<String> _skinSensitivityOptions = ['Düşük', 'Orta', 'Yüksek', 'Çok Yüksek'];
  
  final Map<String, String> _countryCodeOptions = {
    '+90': '🇹🇷 Türkiye (+90)',
    '+1': '🇺🇸 ABD (+1)',
    '+44': '🇬🇧 İngiltere (+44)',
    '+49': '🇩🇪 Almanya (+49)',
    '+33': '🇫🇷 Fransa (+33)',
    '+34': '🇪🇸 İspanya (+34)',
    '+39': '🇮🇹 İtalya (+39)',
    '+31': '🇳🇱 Hollanda (+31)',
    '+32': '🇧🇪 Belçika (+32)',
    '+41': '🇨🇭 İsviçre (+41)',
    '+43': '🇦🇹 Avusturya (+43)',
    '+46': '🇸🇪 İsveç (+46)',
    '+47': '🇳🇴 Norveç (+47)',
    '+45': '🇩🇰 Danimarka (+45)',
    '+358': '🇫🇮 Finlandiya (+358)',
    '+7': '🇷🇺 Rusya (+7)',
    '+86': '🇨🇳 Çin (+86)',
    '+81': '🇯🇵 Japonya (+81)',
    '+82': '🇰🇷 Güney Kore (+82)',
    '+91': '🇮🇳 Hindistan (+91)',
    '+966': '🇸🇦 Suudi Arabistan (+966)',
    '+971': '🇦🇪 BAE (+971)',
    '+964': '🇮🇶 Irak (+964)',
    '+98': '🇮🇷 İran (+98)',
    '+962': '🇯🇴 Ürdün (+962)',
    '+961': '🇱🇧 Lübnan (+961)',
    '+963': '🇸🇾 Suriye (+963)',
    '+20': '🇪🇬 Mısır (+20)',
    '+212': '🇲🇦 Fas (+212)',
    '+213': '🇩🇿 Cezayir (+213)',
    '+216': '🇹🇳 Tunus (+216)',
    '+218': '🇱🇾 Libya (+218)',
    '+27': '🇿🇦 Güney Afrika (+27)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Cache'den veya API'den kullanıcı bilgilerini al
      final cachedData = UserService.getCachedUserData();
      
      if (cachedData != null) {
        _updateFormFields(cachedData);
      } else {
        // Cache yoksa API'den çek (user_id 1 varsayılan olarak)
        final result = await UserService.getUserData(1);
        if (result['success']) {
          _updateFormFields(result['data']);
        } else {
          _showErrorMessage(result['message']);
        }
      }
    } catch (e) {
      _showErrorMessage('Kullanıcı bilgileri yüklenirken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateFormFields(Map<String, dynamic> userData) {
    setState(() {
      // Ad soyad birleştir
      final name = userData['name'] ?? '';
      final surname = userData['surname'] ?? '';
      _nameController.text = '$name $surname'.trim();
      
      // Email
      _emailController.text = userData['email'] ?? '';
      
      // Diğer bilgiler de gelirse güncellenebilir
      if (userData['phone'] != null) {
        _phoneController.text = userData['phone'];
      }
      if (userData['age'] != null) {
        _ageController.text = userData['age'].toString();
      }
      if (userData['height'] != null) {
        _heightController.text = userData['height'].toString();
      }
      if (userData['weight'] != null) {
        _weightController.text = userData['weight'].toString();
      }
      if (userData['gender'] != null) {
        _selectedGender = userData['gender'];
      }
    });
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

        @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
          'Kişisel Bilgiler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF05a5a5),
              ),
            )
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralInfoTab(),
                      _buildPhysicalInfoTab(),
                      _buildHealthInfoTab(),
                    ],
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
    );
  }



  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFF05a5a5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF05a5a5).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(
            height: 44,
            text: 'Hesap Bilgileri',
          ),
          Tab(
            height: 44,
            text: 'Fiziksel',
          ),
          Tab(
            height: 44,
            text: 'Sağlık',
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            // Ad Soyad Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ad Soyad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF6B7280), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Ülke Kodu Section
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: _buildCountryCodeField(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhoneField(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // E-posta Adresi Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-posta Adresi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Color(0xFF6B7280), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _emailController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Cinsiyet Section
            _buildGenderDropdown(),
            
            const SizedBox(height: 24),
            
            // Doğum Tarihi Section
            _buildBirthDateField(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalInfoTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ageController,
                  label: 'Yaş',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _selectedBloodType,
                  items: _bloodTypeOptions,
                  label: 'Kan Grubu',
                  icon: Icons.local_hospital_outlined,
                  onChanged: (value) => setState(() => _selectedBloodType = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'Boy (cm)',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Kilo (kg)',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          _buildBMICard(),
        ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
        children: [
          _buildDropdownField(
            value: _selectedSkinType,
            items: _skinTypeOptions,
            label: 'Cilt Tipi',
            icon: Icons.face_retouching_natural,
            onChanged: (value) => setState(() => _selectedSkinType = value!),
          ),
          const SizedBox(height: 20),
          
          _buildDropdownField(
            value: _selectedSkinSensitivity,
            items: _skinSensitivityOptions,
            label: 'Cilt Hassasiyeti',
            icon: Icons.sensors,
            onChanged: (value) => setState(() => _selectedSkinSensitivity = value!),
          ),
          const SizedBox(height: 20),
          
          _buildAllergyCard(),
          const SizedBox(height: 20),
          
          _buildMedicationCard(),
          const SizedBox(height: 20),
          
          _buildSkinCareCard(),
          const SizedBox(height: 20),
          
          _buildHealthInfoCard(),
        ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon, 
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cinsiyet',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            isExpanded: true,
            hint: const Text(
              'Cinsiyet Seçiniz',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
                letterSpacing: -0.2,
              ),
            ),
            items: _genderOptions.map((item) => DropdownMenuItem(
              value: item, 
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (value) => setState(() => _selectedGender = value),
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.wc, 
                color: Color(0xFF6B7280),
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doğum Tarihi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF6B7280), size: 18),
                const SizedBox(width: 12),
                Text(
                  '${_selectedBirthDate.day}/${_selectedBirthDate.month}/${_selectedBirthDate.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(
              value: item, 
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: onChanged,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon, 
                color: const Color(0xFF6B7280),
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryCodeField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ülke Kodu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCountryCode,
            isExpanded: true,
            items: _countryCodeOptions.entries.map((entry) => DropdownMenuItem(
              value: entry.key, 
              child: Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (value) => setState(() => _selectedCountryCode = value!),
            dropdownColor: Colors.white,
            selectedItemBuilder: (context) {
              return _countryCodeOptions.entries.map((entry) => Text(
                entry.key, // Sadece kodu göster (+90)
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              )).toList();
            },
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.public_outlined, 
                color: Color(0xFF6B7280),
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telefon Numarası',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined, 
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCountryCode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Telefon numaranızı girin',
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doğum Tarihi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFF05a5a5), size: 20),
                const SizedBox(width: 16),
                Text(
                  '${_selectedBirthDate.day}/${_selectedBirthDate.month}/${_selectedBirthDate.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerjiler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Bilinen alerjilerinizi belirtin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _allergiesController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: 'Örn: Polen, toz, hayvan tüyü, belirli yiyecekler...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(16),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD97706),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alerji bilgileriniz doktor konsültasyonlarında önemlidir',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFDF7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullandığı İlaçlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Düzenli kullandığınız ilaçları belirtin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicationsController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: 'Örn: Günlük vitamin D, B12 vitamini, omega-3...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF05a5a5), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(16),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFDF7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF059669),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'İlaç bilgileriniz cilt analizinde göz önünde bulundurulur',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard() {
    double height = double.tryParse(_heightController.text) ?? 165;
    double weight = double.tryParse(_weightController.text) ?? 58;
    double bmi = weight / ((height / 100) * (height / 100));
    
    String bmiCategory;
    Color bmiColor;
    
    if (bmi < 18.5) {
      bmiCategory = 'Zayıf';
      bmiColor = Colors.blue;
    } else if (bmi < 25) {
      bmiCategory = 'Normal';
      bmiColor = Colors.green;
    } else if (bmi < 30) {
      bmiCategory = 'Fazla Kilolu';
      bmiColor = Colors.orange;
    } else {
      bmiCategory = 'Obez';
      bmiColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: bmiColor),
              const SizedBox(width: 12),
              const Text(
                'Vücut Kitle İndeksi (BMI)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: bmiColor,
                    ),
                  ),
                  const Text(
                    'BMI',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: bmiColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCareCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[600]),
              const SizedBox(width: 12),
              const Text(
                'Cilt Bakım Önerileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSkinTip('🧴', 'Cildinize uygun nemlendirici kullanın'),
          _buildSkinTip('☀️', 'Günlük SPF 30+ güneş kremi sürün'),
          _buildSkinTip('💧', 'Günde en az 8 bardak su için'),
          _buildSkinTip('🥗', 'Antioksidan açısından zengin beslenin'),
        ],
      ),
    );
  }

  Widget _buildHealthInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.green[600]),
              const SizedBox(width: 12),
              const Text(
                'Sağlık Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu bilgiler cilt analizi sırasında daha doğru sonuçlar elde etmek için kullanılır. Tüm verileriniz güvenli bir şekilde saklanır.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinTip(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A202C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _savePersonalInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF05a5a5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Değişiklikleri Kaydet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF05a5a5),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1A202C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        final age = DateTime.now().year - picked.year;
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _savePersonalInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Ad soyadı ayır
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      final name = nameParts.isNotEmpty ? nameParts.first : '';
      final surname = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

      // Güncelleme verisini hazırla
      final updateData = {
        'name': name,
        'surname': surname,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'height': int.tryParse(_heightController.text) ?? 0,
        'weight': int.tryParse(_weightController.text) ?? 0,
        'gender': _selectedGender,
        'blood_type': _selectedBloodType,
        'skin_type': _selectedSkinType,
        'skin_sensitivity': _selectedSkinSensitivity,
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'birth_date': '${_selectedBirthDate.year}-${_selectedBirthDate.month.toString().padLeft(2, '0')}-${_selectedBirthDate.day.toString().padLeft(2, '0')}',
        'country_code': _selectedCountryCode,
      };

      // Veritabanına kaydet
      final result = await UserService.updateUserData(1, updateData);
      
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kişisel bilgiler başarıyla güncellendi'),
              backgroundColor: Color(0xFF05a5a5),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showErrorMessage(result['message'] ?? 'Güncelleme sırasında hata oluştu');
      }
    } catch (e) {
      _showErrorMessage('Kaydetme sırasında hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 