import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog_post.dart';
import 'blog_service.dart';

class SavedPostsService {
  static const String _savedPostsKey = 'saved_blog_posts';
  static List<String> _inMemorySavedIds = []; // Temporary in-memory storage
  static List<String>? _cachedSavedPostIds;

  static Future<List<String>> getSavedPostIds() async {
    // Temporary: return in-memory list instead of SharedPreferences
    return _inMemorySavedIds;
  }

  static Future<bool> isPostSaved(String postId) async {
    final savedIds = await getSavedPostIds();
    return savedIds.contains(postId);
  }

  static Future<bool> savePost(String postId) async {
    try {
      // Temporary: use in-memory storage
      if (!_inMemorySavedIds.contains(postId)) {
        _inMemorySavedIds.add(postId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving post: $e');
      return false;
    }
  }

  static Future<bool> unsavePost(String postId) async {
    try {
      // Temporary: use in-memory storage
      if (_inMemorySavedIds.contains(postId)) {
        _inMemorySavedIds.remove(postId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error unsaving post: $e');
      return false;
    }
  }

  static Future<bool> toggleSavePost(String postId) async {
    final isCurrentlySaved = await isPostSaved(postId);
    if (isCurrentlySaved) {
      return await unsavePost(postId);
    } else {
      return await savePost(postId);
    }
  }

  static Future<List<BlogPost>> getSavedPosts() async {
    try {
      final savedIds = await getSavedPostIds();
      final allPosts = await BlogService.loadBlogPosts();
      
      return allPosts.where((post) => savedIds.contains(post.id)).toList();
    } catch (e) {
      print('Error getting saved posts: $e');
      return [];
    }
  }

  static void clearCache() {
    _cachedSavedPostIds = null;
    _inMemorySavedIds.clear(); // Clear in-memory storage
  }
} 