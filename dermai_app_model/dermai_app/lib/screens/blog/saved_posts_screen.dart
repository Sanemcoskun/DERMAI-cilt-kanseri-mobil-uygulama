import 'package:flutter/material.dart';
import '../../models/blog_post.dart';
import '../../services/saved_posts_service.dart';
import 'blog_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<BlogPost> savedPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    try {
      final posts = await SavedPostsService.getSavedPosts();
      setState(() {
        savedPosts = posts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading saved posts: $e');
    }
  }

  Future<void> _toggleSavePost(BlogPost post) async {
    final success = await SavedPostsService.toggleSavePost(post.id);
    if (success) {
      // Reload the saved posts list
      await _loadSavedPosts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yazı kaydedilenlerden kaldırıldı!'),
            backgroundColor: Color(0xFF05a5a5),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToPost(BlogPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogDetailScreen(post: post),
      ),
    ).then((_) {
      // Refresh the list when coming back from detail screen
      _loadSavedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFe3f3f2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF05a5a5),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Kaydedilen Yazılar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF05a5a5),
                        ),
                      )
                    : savedPosts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: savedPosts.length,
                            itemBuilder: (context, index) {
                              final post = savedPosts[index];
                              return _buildSavedPostCard(post);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF05a5a5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline,
                size: 64,
                color: Color(0xFF05a5a5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz kaydettiğiniz yazı yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Beğendiğiniz blog yazılarını bookmark ikonuna tıklayarak kaydedebilirsiniz.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05a5a5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Blog Yazılarına Dön',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostCard(BlogPost post) {
    return GestureDetector(
      onTap: () => _navigateToPost(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05a5a5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    post.category,
                    style: const TextStyle(
                      color: Color(0xFF05a5a5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleSavePost(post),
                  child: const Icon(
                    Icons.bookmark,
                    color: Color(0xFF05a5a5),
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              post.excerpt,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Text(
                  post.author,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Text(
                  ' • ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  post.readTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  post.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 