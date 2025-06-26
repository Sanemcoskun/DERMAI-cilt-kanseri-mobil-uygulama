import 'package:flutter/material.dart';
import '../../models/blog_post.dart';
import '../../services/saved_posts_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final BlogPost post;

  const BlogDetailScreen({super.key, required this.post});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  bool isPostSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfPostSaved();
  }

  Future<void> _checkIfPostSaved() async {
    final saved = await SavedPostsService.isPostSaved(widget.post.id);
    setState(() {
      isPostSaved = saved;
    });
  }

  Future<void> _toggleSavePost() async {
    final success = await SavedPostsService.toggleSavePost(widget.post.id);
    if (success) {
      final nowSaved = await SavedPostsService.isPostSaved(widget.post.id);
      setState(() {
        isPostSaved = nowSaved;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPostSaved ? 'Yazı kaydedildi!' : 'Yazı kaydedilenlerden kaldırıldı!',
            ),
            backgroundColor: const Color(0xFF05a5a5),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
                    const Spacer(),
                    const Text(
                      'Blog Yazısı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleSavePost,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isPostSaved ? Icons.bookmark : Icons.bookmark_outline,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05a5a5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.post.category,
                          style: const TextStyle(
                            color: Color(0xFF05a5a5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.post.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Meta Info
                      Row(
                        children: [
                          Text(
                            widget.post.author,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          Text(
                            widget.post.readTime,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.post.date,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Excerpt
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05a5a5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF05a5a5).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.post.excerpt,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF374151),
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Content from JSON
                      ...widget.post.content.sections.map((section) => _buildSection(section)).toList(),

                      const SizedBox(height: 32),

                      // Share Section
                      Container(
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
                          children: [
                            const Text(
                              'Bu yazıyı faydalı buldunuz mu?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                        colors: [
                                          Color(0xFF106c6a),
                                          Color(0xFF0d9f9f),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.share,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Paylaş',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _toggleSavePost,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF05a5a5).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPostSaved ? Icons.bookmark : Icons.bookmark_outline,
                                      color: const Color(0xFF05a5a5),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BlogSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        
        // Section Content based on type
        if (section.type == 'paragraph' && section.text != null)
          _buildParagraph(section.text!),
        
        if (section.type == 'bullet_list' && section.items != null)
          ...section.items!.map((item) => _buildBulletPoint(item)).toList(),
        
        if (section.type == 'numbered_list' && section.items != null)
          ...section.items!.asMap().entries.map((entry) => 
            _buildNumberedPoint((entry.key + 1).toString(), entry.value)
          ).toList(),
        
        if (section.type == 'subtitle_paragraph' && section.subtitleItems != null)
          ...section.subtitleItems!.map((item) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubTitle(item.subtitle),
              _buildParagraph(item.text),
            ],
          )).toList(),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF374151),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF05a5a5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF05a5a5),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF05a5a5),
        ),
      ),
    );
  }
} 