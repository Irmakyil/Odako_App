import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart';
import '../widgets/chat_bubble.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false; // This controls the send button and overall loading state

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return; // Only check for empty text here, _isLoading is handled by GestureDetector

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('feelingsChat');

    final messenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true; // Set loading state when sending message
      });

      await chatCol.add({
        'text': text,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _controller.clear();

      _scrollToBottom();

      // Get AI reply
      final aiReply = await AIService.sendMessageToGemini(text);

      // Save AI reply to Firestore
      await chatCol.add({
        'text': aiReply,
        'isUser': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Chat error: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Reset loading state
        });
        _scrollToBottom(); // Scroll to bottom after AI response
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // Add some buffer
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_3.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Let\'s Talk',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 160,
                    width: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'lib/presentation/assets/chatbox2_variant.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: Image.asset(
                            'lib/presentation/assets/maskot.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: user == null
                        ? const Center(child: Text('Please sign in to chat.'))
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('feelingsChat')
                                .orderBy('createdAt', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              final docs = snapshot.data!.docs;
                              final messages = docs
                                  .map((doc) => ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>))
                                  .toList();

                              final showGreeting = messages.isEmpty; // No need for _isLoading here
                              int itemCount = messages.length + (showGreeting ? 1 : 0); // Removed _isLoading check

                              return ListView.builder(
                                controller: _scrollController,
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  if (showGreeting && index == 0) {
                                    return const Align(
                                      alignment: Alignment.centerLeft,
                                      child: ChatBubble(
                                        text: 'How are you feeling today?',
                                        isUser: false,
                                      ),
                                    );
                                  }

                                  final msgIndex = showGreeting ? index - 1 : index;

                                  // Removed the _isLoading typing indicator block as it's not applicable here.
                                  // The ChatMessage class in this file does not have an isTyping property.

                                  if (msgIndex < 0 || msgIndex >= messages.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final msg = messages[msgIndex];
                                  return ChatBubble(text: msg.text, isUser: msg.isUser);
                                },
                              );
                            },
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                          enabled: !_isLoading, // Disable input when loading
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Replaced the Container with IconButton with a GestureDetector wrapping Image.asset
                      GestureDetector(
                        onTap: _isLoading ? null : _sendMessage, // Disable tap when loading
                        child: Image.asset(
                          'lib/presentation/assets/button_send.png', // Your send button image
                          width: 48, // Adjust width as needed
                          height: 48, // Adjust height as needed
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}