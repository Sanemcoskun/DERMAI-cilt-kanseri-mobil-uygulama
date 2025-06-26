import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    
    // Hoş geldin mesajı
    if (ChatService.conversationHistory.isEmpty) {
      ChatService.addMessage(ChatMessage(
        text: 'Merhaba! Ben DermaNova, cilt sağlığı konusunda size yardımcı olmak için buradayım. Size nasıl yardımcı olabilirim?',
        isBot: true,
      ));
    }
    
    setState(() {
      _isConnected = true; // Gemini API direkt bağlantı
    });
  }

  void _addMessage(String text, {bool isBot = false}) {
    ChatService.addMessage(ChatMessage(
      text: text,
      isBot: isBot,
    ));
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();
    
    // 1. Önce kullanıcı mesajını ekle ve göster
    ChatService.addUserMessage(userMessage);
    setState(() {});
    _scrollToBottom();

    // 2. Loading göster
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Bot'a mesajı gönder ve yanıtı bekle
      final botResponse = await ChatService.sendMessageToBot(userMessage);
      setState(() {});
      _scrollToBottom();
    } catch (e) {
      // Hata durumunda kullanıcıya geri bildirim
      ChatService.addMessage(ChatMessage(
        text: 'Üzgünüm, şu anda yanıt veremiyorum. Lütfen daha sonra tekrar deneyin. Hata: ${e.toString()}',
        isBot: true,
      ));
      setState(() {});
      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DermaNova',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isConnected ? 'Çevrimiçi' : 'Bağlantı Yok',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.green[200] : Colors.red[200],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearConversation,
            icon: const Icon(Icons.refresh),
            tooltip: 'Sohbeti Temizle',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: ChatService.conversationHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == ChatService.conversationHistory.length) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(ChatService.conversationHistory[index]);
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FFFE),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF05a5a5).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Mesajınızı yazın...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : const Color(0xFF05a5a5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearConversation() {
    ChatService.clearConversation();
    // Hoş geldin mesajını tekrar ekle
    ChatService.addMessage(ChatMessage(
      text: 'Merhaba! Ben DermaNova, cilt sağlığı konusunda size yardımcı olmak için buradayım. Size nasıl yardımcı olabilirim?',
      isBot: true,
    ));
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sohbet temizlendi')),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF05a5a5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF05a5a5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Yazıyor...',
                  style: TextStyle(
                    color: Color(0xFF1A202C),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isBot 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF05a5a5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isBot 
                    ? Colors.white
                    : const Color(0xFF05a5a5),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isBot 
                      ? const Color(0xFF1A202C)
                      : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ChatMessage sınıfı artık chat_service.dart'ta tanımlı 