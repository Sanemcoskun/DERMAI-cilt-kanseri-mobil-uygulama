import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/credit/credit_screen.dart';
import 'screens/main_screen.dart';
import 'screens/analysis/skin_analysis_screen.dart';
import 'screens/profile/security_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Sistem UI ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  runApp(const DermAIApp());
}

class DermAIApp extends StatelessWidget {
  const DermAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DermAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05a5a5), // DermAI tema rengi
        ),
        fontFamily: 'System', // Sistem fontunu kullan
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/credit': (context) => const CreditScreen(),
        '/main': (context) => const MainScreen(),
        '/main-analytics': (context) => const MainScreen(initialIndex: 2),
        '/skin-analysis': (context) => const SkinAnalysisScreen(),
        '/security': (context) => const SecurityScreen(),
      },
      debugShowCheckedModeBanner: false, // Debug banner'ını kaldır
      locale: const Locale('tr', 'TR'), // Türkçe dil desteği
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
