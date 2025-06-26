import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/blog_post.dart';

class BlogService {
  static final Map<String, List<BlogPost>> _cache = {};
  static const List<String> supportedLanguages = ['tr', 'en'];

  static Future<List<BlogPost>> loadBlogPosts([String language = 'tr']) async {
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
      print('Loading blog_posts.json for language: $language');
      final String jsonString = await rootBundle.loadString('assets/data/blog_posts.json');
      print('JSON loaded successfully, length: ${jsonString.length}');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      print('JSON parsed successfully, keys: ${jsonData.keys}');
      
      // Get the language-specific data
      final Map<String, dynamic>? languageData = jsonData[language];
      
      if (languageData == null) {
        // If language not found, try fallback to Turkish
        if (language != 'tr') {
          return await loadBlogPosts('tr');
        }
        throw Exception('No data found for language: $language');
      }

      // Parse posts for the specific language
      final List<dynamic> postsJson = languageData['posts'] ?? [];
      final List<BlogPost> posts = postsJson
          .map((post) => BlogPost.fromJson(post))
          .toList();

      // Cache the result
      _cache[language] = posts;
      
      return posts;
    } catch (e) {
      print('Error loading blog posts for language $language: $e');
      
      // If there's an error and we're not already trying Turkish, try Turkish as fallback
      if (language != 'tr') {
        return await loadBlogPosts('tr');
      }
      
      // If Turkish also fails, return empty list
      return [];
    }
  }

  static Future<List<BlogPost>> getBlogPostsByCategory(String category, [String language = 'tr']) async {
    final posts = await loadBlogPosts(language);
    if (category == 'Tümü' || category == 'All') {
      return posts;
    }
    return posts.where((post) => post.category == category).toList();
  }

  static Future<List<BlogPost>> searchBlogPosts(String query, [String language = 'tr']) async {
    final posts = await loadBlogPosts(language);
    if (query.isEmpty) {
      return posts;
    }
    
    return posts.where((post) => 
      post.title.toLowerCase().contains(query.toLowerCase()) ||
      post.excerpt.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  static Future<BlogPost?> getBlogPostById(String id, [String language = 'tr']) async {
    final posts = await loadBlogPosts(language);
    try {
      return posts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<BlogPost>> getFeaturedPosts([String language = 'tr']) async {
    final posts = await loadBlogPosts(language);
    return posts.where((post) => post.isFeatured).toList();
  }

  static Future<List<String>> getCategories([String language = 'tr']) async {
    final posts = await loadBlogPosts(language);
    final categories = posts.map((post) => post.category).toSet().toList();
    
    // Add "All" category at the beginning based on language
    if (language == 'en') {
      categories.insert(0, 'All');
    } else {
      categories.insert(0, 'Tümü');
    }
    
    return categories;
  }

  static void clearCache() {
    _cache.clear();
  }

  // Get available languages
  static List<String> getAvailableLanguages() {
    return supportedLanguages;
  }
} 