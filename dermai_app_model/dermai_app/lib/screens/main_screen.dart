import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/app_localizations.dart';
import 'home/home_screen.dart';
import 'blog/blog_screen.dart';
import 'analytics/analytics_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      const HomeScreen(),
      const BlogScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF05a5a5),
      statusBarIconBrightness: Brightness.light,
    ));

    return ListenableBuilder(
      listenable: AppLocalizations.instance,
      builder: (context, child) {
        final localizations = AppLocalizations.instance;
        
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFF05a5a5),
                  unselectedItemColor: const Color(0xFF9CA3AF),
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: _currentIndex == 0
                            ? BoxDecoration(
                                color: const Color(0xFF05a5a5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Icon(
                          _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                          size: 24,
                        ),
                      ),
                      label: 'Ana Sayfa',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: _currentIndex == 1
                            ? BoxDecoration(
                                color: const Color(0xFF05a5a5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Icon(
                          _currentIndex == 1 ? Icons.article : Icons.article_outlined,
                          size: 24,
                        ),
                      ),
                      label: 'Blog',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: _currentIndex == 2
                            ? BoxDecoration(
                                color: const Color(0xFF05a5a5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Icon(
                          _currentIndex == 2 ? Icons.analytics : Icons.analytics_outlined,
                          size: 24,
                        ),
                      ),
                      label: 'Analizler',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: _currentIndex == 3
                            ? BoxDecoration(
                                color: const Color(0xFF05a5a5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Icon(
                          _currentIndex == 3 ? Icons.person : Icons.person_outline,
                          size: 24,
                        ),
                      ),
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 