import 'package:flutter/material.dart';
import 'translations.dart';

class AppLocalizations extends ChangeNotifier {
  static AppLocalizations? _instance;
  static AppLocalizations get instance {
    _instance ??= AppLocalizations._internal();
    return _instance!;
  }
  
  AppLocalizations._internal();

  String _currentLanguage = 'tr';
  
  String get currentLanguage => _currentLanguage;
  
  String getText(String key) {
    return Translations.translations[_currentLanguage]?[key] ?? key;
  }
  
  void changeLanguage(String languageCode) {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }
  
  String getCurrentFlag() {
    return _currentLanguage == 'tr' ? '🇹🇷' : '🇬🇧';
  }
  
  List<String> get supportedLanguages => ['tr', 'en'];
  
  String getLanguageName(String code) {
    switch (code) {
      case 'tr':
        return getText('turkish');
      case 'en':
        return getText('english');
      default:
        return code;
    }
  }
  
  String getLanguageFlag(String code) {
    switch (code) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇬🇧';
      default:
        return '🌐';
    }
  }
} 