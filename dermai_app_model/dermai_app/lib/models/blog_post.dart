class BlogPost {
  final String id;
  final String title;
  final String excerpt;
  final String category;
  final String author;
  final String readTime;
  final String date;
  final String imageUrl;
  final bool isFeatured;
  final BlogContent content;

  BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.author,
    required this.readTime,
    required this.date,
    required this.imageUrl,
    required this.isFeatured,
    required this.content,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      excerpt: json['excerpt'],
      category: json['category'],
      author: json['author'],
      readTime: json['readTime'],
      date: json['date'],
      imageUrl: json['imageUrl'],
      isFeatured: json['isFeatured'],
      content: BlogContent.fromJson(json['content']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'category': category,
      'author': author,
      'readTime': readTime,
      'date': date,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
      'content': content.toJson(),
    };
  }
}

class BlogContent {
  final List<BlogSection> sections;

  BlogContent({required this.sections});

  factory BlogContent.fromJson(Map<String, dynamic> json) {
    return BlogContent(
      sections: (json['sections'] as List)
          .map((section) => BlogSection.fromJson(section))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

class BlogSection {
  final String title;
  final String type;
  final String? text;
  final List<String>? items;
  final List<SubtitleParagraph>? subtitleItems;

  BlogSection({
    required this.title,
    required this.type,
    this.text,
    this.items,
    this.subtitleItems,
  });

  factory BlogSection.fromJson(Map<String, dynamic> json) {
    List<SubtitleParagraph>? subtitleItems;
    if (json['items'] != null && json['type'] == 'subtitle_paragraph') {
      subtitleItems = (json['items'] as List)
          .map((item) => SubtitleParagraph.fromJson(item))
          .toList();
    }

    return BlogSection(
      title: json['title'],
      type: json['type'],
      text: json['text'],
      items: json['items'] != null && json['type'] != 'subtitle_paragraph' 
          ? List<String>.from(json['items']) 
          : null,
      subtitleItems: subtitleItems,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'title': title,
      'type': type,
    };

    if (text != null) result['text'] = text;
    if (items != null) result['items'] = items;
    if (subtitleItems != null) {
      result['items'] = subtitleItems!.map((item) => item.toJson()).toList();
    }

    return result;
  }
}

class SubtitleParagraph {
  final String subtitle;
  final String text;

  SubtitleParagraph({
    required this.subtitle,
    required this.text,
  });

  factory SubtitleParagraph.fromJson(Map<String, dynamic> json) {
    return SubtitleParagraph(
      subtitle: json['subtitle'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtitle': subtitle,
      'text': text,
    };
  }
} 