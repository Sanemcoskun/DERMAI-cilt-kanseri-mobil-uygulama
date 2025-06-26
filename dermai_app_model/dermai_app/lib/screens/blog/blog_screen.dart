import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';
import '../../services/saved_posts_service.dart';
import 'blog_detail_screen.dart';
import 'saved_posts_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String selectedCategory = 'Tümü';
  final TextEditingController _searchController = TextEditingController();
  
  List<String> categories = ['Tümü'];
  List<BlogPost> blogPosts = [];
  List<BlogPost> filteredPosts = [];
  List<String> savedPostIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlogData();
  }

  Future<void> _loadBlogData() async {
    try {
      print('Starting to load blog data...');
      final posts = await BlogService.loadBlogPosts();
      print('Loaded ${posts.length} posts');
      final cats = await BlogService.getCategories();
      print('Loaded ${cats.length} categories: $cats');
      final saved = await SavedPostsService.getSavedPostIds();
      print('Loaded ${saved.length} saved posts');
      
      setState(() {
        blogPosts = posts;
        categories = cats;
        filteredPosts = posts;
        savedPostIds = saved;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading blog data: $e');
      // Show a snackbar with error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blog verileri yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterPosts() {
    List<BlogPost> filtered = blogPosts;
    
    if (selectedCategory != 'Tümü') {
      filtered = filtered.where((post) => post.category == selectedCategory).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((post) => 
        post.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        post.excerpt.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    setState(() {
      filteredPosts = filtered;
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
          child: isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF05a5a5),
                ),
              )
            : Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Blog',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sağlık ve cilt bakımı rehberi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SavedPostsScreen(),
                                ),
                              ).then((_) {
                                // Refresh data when coming back from saved posts
                                _loadBlogData();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF05a5a5).withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bookmark_outline,
                                color: Color(0xFF05a5a5),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => _filterPosts(),
                          decoration: const InputDecoration(
                            hintText: 'Blog yazılarında ara...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF05a5a5),
                              size: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Categories
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = selectedCategory == category;
                            
                            return Padding(
                              padding: EdgeInsets.only(right: index == categories.length - 1 ? 0 : 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = category;
                                  });
                                  _filterPosts();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF05a5a5) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: const Color(0xFF05a5a5).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Blog Posts List
                Expanded(
                  child: filteredPosts.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          
                          if (index == 0 && post.isFeatured) {
                            return _buildFeaturedCard(post);
                          }
                          
                          return _buildBlogCard(post);
                        },
                      ),
                ),
              ],
            ),
        ),
      ),
    );
  }
  
  Widget _buildFeaturedCard(BlogPost post) {
    return GestureDetector(
      onTap: () => _navigateToPost(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 240,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF05a5a5),
              Color(0xFF37a9a3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF05a5a5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ÖZEL YAZI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _toggleSavePost(post),
                    child: Icon(
                      savedPostIds.contains(post.id) ? Icons.bookmark : Icons.bookmark_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.excerpt,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        post.author,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        post.readTime,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.date,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBlogCard(BlogPost post) {
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
                  child: Icon(
                    savedPostIds.contains(post.id) ? Icons.bookmark : Icons.bookmark_outline,
                    color: savedPostIds.contains(post.id) ? const Color(0xFF05a5a5) : const Color(0xFF9CA3AF),
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

  void _navigateToPost(BlogPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogDetailScreen(post: post),
      ),
    );
  }

  Future<void> _toggleSavePost(BlogPost post) async {
    final success = await SavedPostsService.toggleSavePost(post.id);
    if (success) {
      final updatedSavedIds = await SavedPostsService.getSavedPostIds();
      setState(() {
        savedPostIds = updatedSavedIds;
      });
      
      // Show snackbar
      final isNowSaved = savedPostIds.contains(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowSaved ? 'Yazı kaydedildi!' : 'Yazı kaydedilenlerden kaldırıldı!',
            ),
            backgroundColor: const Color(0xFF05a5a5),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showLanguageModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Dil Seçimi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
            
            const SizedBox(height: 20),
            
                                      // Turkish Option
             GestureDetector(
               onTap: () {
                 AppLocalizations.instance.changeLanguage('tr');
                 setModalState(() {});
                 setState(() {});
                 Navigator.pop(context);
               },
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppLocalizations.instance.currentLanguage == 'tr' 
                     ? const Color(0xFF05a5a5).withOpacity(0.1)
                     : const Color(0xFFF8FAFC),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(
                     color: AppLocalizations.instance.currentLanguage == 'tr'
                       ? const Color(0xFF05a5a5)
                       : const Color(0xFFE2E8F0),
                     width: AppLocalizations.instance.currentLanguage == 'tr' ? 2 : 1,
                   ),
                 ),
                 child: Row(
                   children: [
                     const Text(
                       '🇹🇷',
                       style: TextStyle(fontSize: 24),
                     ),
                     const SizedBox(width: 12),
                     Text(
                       'Türkçe',
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: AppLocalizations.instance.currentLanguage == 'tr'
                           ? const Color(0xFF1A202C)
                           : const Color(0xFF64748B),
                       ),
                     ),
                     const Spacer(),
                     Icon(
                       AppLocalizations.instance.currentLanguage == 'tr'
                         ? Icons.check_circle
                         : Icons.radio_button_unchecked,
                       color: AppLocalizations.instance.currentLanguage == 'tr'
                         ? const Color(0xFF05a5a5)
                         : const Color(0xFF9CA3AF),
                       size: 24,
                     ),
                   ],
                 ),
               ),
             ),
            
            const SizedBox(height: 12),
            
                                      // English Option
             GestureDetector(
               onTap: () {
                 AppLocalizations.instance.changeLanguage('en');
                 setModalState(() {});
                 setState(() {});
                 Navigator.pop(context);
               },
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppLocalizations.instance.currentLanguage == 'en' 
                     ? const Color(0xFF05a5a5).withOpacity(0.1)
                     : const Color(0xFFF8FAFC),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(
                     color: AppLocalizations.instance.currentLanguage == 'en'
                       ? const Color(0xFF05a5a5)
                       : const Color(0xFFE2E8F0),
                     width: AppLocalizations.instance.currentLanguage == 'en' ? 2 : 1,
                   ),
                 ),
                 child: Row(
                   children: [
                     const Text(
                       '🇬🇧',
                       style: TextStyle(fontSize: 24),
                     ),
                     const SizedBox(width: 12),
                     Text(
                       'English',
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: AppLocalizations.instance.currentLanguage == 'en'
                           ? const Color(0xFF1A202C)
                           : const Color(0xFF64748B),
                       ),
                     ),
                     const Spacer(),
                     Icon(
                       AppLocalizations.instance.currentLanguage == 'en'
                         ? Icons.check_circle
                         : Icons.radio_button_unchecked,
                       color: AppLocalizations.instance.currentLanguage == 'en'
                         ? const Color(0xFF05a5a5)
                         : const Color(0xFF9CA3AF),
                       size: 24,
                     ),
                   ],
                 ),
               ),
             ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Blog yazısı bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz ${selectedCategory == 'Tümü' ? 'hiç' : selectedCategory + ' kategorisinde'} blog yazısı yok.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedCategory = 'Tümü';
                _searchController.clear();
              });
              _filterPosts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05a5a5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tüm Yazıları Göster',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 