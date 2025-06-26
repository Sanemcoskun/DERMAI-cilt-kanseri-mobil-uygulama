import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HealthTip {
  final String title;
  final String description;
  final String details;
  final List<String> steps;
  final String importance;
  final String frequency;

  HealthTip({
    required this.title,
    required this.description,
    required this.details,
    required this.steps,
    required this.importance,
    required this.frequency,
  });

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      details: json['details'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      importance: json['importance'] ?? '',
      frequency: json['frequency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'details': details,
      'steps': steps,
      'importance': importance,
      'frequency': frequency,
    };
  }
}

class HealthCategory {
  final String id;
  final String title;
  final String iconName;
  final String colorHex;
  final List<HealthTip> tips;

  HealthCategory({
    required this.id,
    required this.title,
    required this.iconName,
    required this.colorHex,
    required this.tips,
  });

  factory HealthCategory.fromJson(Map<String, dynamic> json) {
    return HealthCategory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      iconName: json['icon'] ?? 'info_outline',
      colorHex: json['color'] ?? '#6B7280',
      tips: (json['tips'] as List<dynamic>?)
          ?.map((tip) => HealthTip.fromJson(tip))
          .toList() ?? [],
    );
  }

  // IconData dönüştürücü
  IconData get icon {
    switch (iconName) {
      case 'spa_outlined':
        return Icons.spa_outlined;
      case 'wb_sunny_outlined':
        return Icons.wb_sunny_outlined;
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'self_improvement_outlined':
        return Icons.self_improvement_outlined;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'local_hospital_outlined':
        return Icons.local_hospital_outlined;
      case 'psychology_outlined':
        return Icons.psychology_outlined;
      case 'favorite_outlined':
        return Icons.favorite_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // Color dönüştürücü
  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }
}

class HealthTipsService {
  static final HealthTipsService _instance = HealthTipsService._internal();
  factory HealthTipsService() => _instance;
  HealthTipsService._internal();

  final Map<String, List<HealthCategory>> _cache = {};
  static const List<String> supportedLanguages = ['tr', 'en'];

  Future<List<HealthCategory>> getHealthCategories([String language = 'tr']) async {
    // Validate language
    if (!supportedLanguages.contains(language)) {
      language = 'tr'; // Default to Turkish
    }

    // Check cache first
    if (_cache.containsKey(language)) {
      return _cache[language]!;
    }

    try {
      // Load the combined JSON file
      final String jsonString = await rootBundle.loadString('assets/data/health_tips.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Get the language-specific data
      final Map<String, dynamic>? languageData = jsonData[language];
      
      if (languageData == null) {
        // If language not found, try fallback to Turkish
        if (language != 'tr') {
          return await getHealthCategories('tr');
        }
        throw Exception('No data found for language: $language');
      }

      // Parse categories for the specific language
      final List<dynamic> categoriesJson = languageData['categories'] ?? [];
      final List<HealthCategory> categories = categoriesJson
          .map((categoryJson) => HealthCategory.fromJson(categoryJson))
          .toList();

      // Cache the result
      _cache[language] = categories;
      
      return categories;
    } catch (e) {
      print('Error loading health tips for language $language: $e');
      
      // If there's an error and we're not already trying Turkish, try Turkish as fallback
      if (language != 'tr') {
        return await getHealthCategories('tr');
      }
      
      // If Turkish also fails, return empty list
      return [];
    }
  }

  Future<HealthCategory?> getCategoryById(String categoryId, [String language = 'tr']) async {
    final categories = await getHealthCategories(language);
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      debugPrint('Kategori bulunamadı: $categoryId');
      return null;
    }
  }

  Future<List<HealthTip>> getTipsByCategory(String categoryId, [String language = 'tr']) async {
    final category = await getCategoryById(categoryId, language);
    return category?.tips ?? [];
  }

  // Clear cache if needed
  void clearCache() {
    _cache.clear();
  }

  // Get available languages
  List<String> getAvailableLanguages() {
    return supportedLanguages;
  }
} 