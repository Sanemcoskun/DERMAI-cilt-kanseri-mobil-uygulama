import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isBot': isBot,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isBot: json['isBot'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatService {
  static const String apiKey = 'AIzaSyDUMBXdMSeUc1PFGcDFaMyCtv8KEf0Ixkc';
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  static List<ChatMessage> _conversationHistory = [];
  static List<ChatMessage> get conversationHistory => _conversationHistory;

  static ChatMessage addUserMessage(String message) {
    final userMessage = ChatMessage(text: message, isBot: false);
    _conversationHistory.add(userMessage);
    return userMessage;
  }

  static Future<ChatMessage?> sendMessageToBot(String message) async {
    if (message.trim().isEmpty) {
      throw Exception('Mesaj boş olamaz');
    }

    try {
      // Gemini API'ye istek gönder
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': _buildPromptWithHistory(message)
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null) {
          
          final botResponse = responseData['candidates'][0]['content']['parts'][0]['text'];
          
          // Bot yanıtını ekle
          final botMessage = ChatMessage(text: botResponse, isBot: true);
          _conversationHistory.add(botMessage);
          
          return botMessage;
        } else {
          throw Exception('Geçersiz API yanıtı');
        }
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('İnternet bağlantısı bulunamadı');
    } catch (e) {
      throw Exception('Hata: ${e.toString()}');
    }
  }

  static String _buildPromptWithHistory(String message) {
    final systemPrompt = """
You are DermaNova, an advanced dermatology and skin health AI assistant. You help users with skin health, dermatology, and skincare topics.

YOUR FEATURES:
- Expert knowledge in skin health
- Empathy and understanding  
- Clear and understandable explanations
- Multilingual communication (respond in the user's language)
- Reliable medical information

YOUR TOPICS:
1. Skincare advice
2. Acne and pimple management
3. Sun protection
4. General information about skin diseases
5. Moisturizing and cleansing routines
6. Anti-aging care
7. Sensitive skin care

IMPORTANT RULES:
- Never make definitive diagnoses
- Refer to doctors for serious conditions
- Provide safe and approved information
- Use general categories in product recommendations
- Provide personalized suggestions

RESPONSE FORMAT:
- Use a warm and friendly tone
- Explain point by point
- Highlight important points
- Recommend doctor consultation when necessary

LANGUAGE RULE:
- If the user writes in Turkish, respond in Turkish
- If the user writes in English, respond in English
- Always match the user's language preference

You only help with skin health topics. For other topics, say "I can't help with that, I'm a skin health specialist" in the user's language.

""";

    // Son 5 mesajı al (çok uzun olmasın diye)
    final recentHistory = _conversationHistory.length > 10 
        ? _conversationHistory.sublist(_conversationHistory.length - 10) 
        : _conversationHistory;

    String fullPrompt = systemPrompt;
    
    if (recentHistory.isNotEmpty) {
      fullPrompt += "\n\nÖnceki konuşma:\n";
      for (var msg in recentHistory) {
        fullPrompt += "${msg.isBot ? 'DermaNova' : 'Kullanıcı'}: ${msg.text}\n";
      }
    }
    
    fullPrompt += "\nKullanıcı: $message\nDermaNova:";
    
    return fullPrompt;
  }

  static void clearConversation() {
    _conversationHistory.clear();
  }

  static void addMessage(ChatMessage message) {
    _conversationHistory.add(message);
  }

  static bool get hasMessages => _conversationHistory.isNotEmpty;
  static int get messageCount => _conversationHistory.length;

  // Kategorilere göre hazır mesajlar
  static final Map<String, List<String>> suggestedMessages = {
    'Genel': [
      'Merhaba! Cilt bakımı hakkında bilgi almak istiyorum.',
      'Günlük cilt bakım rutini nasıl olmalı?',
      'Hangi cilt tipinde olduğumu nasıl anlarım?',
    ],
    'Sivilce': [
      'Sivilce sorunu yaşıyorum, ne önerirsiniz?',
      'Sivilce izleri nasıl geçer?',
      'Akne tedavisi için ne yapmalıyım?',
    ],
    'Güneş Koruması': [
      'Güneş kremi seçimi nasıl yapılır?',
      'SPF değeri ne demek?',
      'Yazın cilt nasıl korunur?',
    ],
    'Yaşlanma Karşıtı': [
      'Yaşlanma karşıtı bakım nasıl yapılır?',
      'Kırışıklıklar için ne önerirsiniz?',
      'Anti-aging ürünler nasıl kullanılır?',
    ],
  };

  static List<String> getSuggestedMessages(String category) {
    return suggestedMessages[category] ?? [];
  }

  static List<String> getAllCategories() {
    return suggestedMessages.keys.toList();
  }
} 