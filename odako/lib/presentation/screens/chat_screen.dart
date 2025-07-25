import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart';

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
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }


  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final chatCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('feelingsChat');
    final messenger = ScaffoldMessenger.of(context);

    final userMessageText = text;

    try {
      setState(() {
        _isLoading = true;
      });

      await chatCol.add({
        'text': userMessageText,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      setState(() {});

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Get AI reply
      final aiReply = await AIService.sendMessageToGemini(userMessageText);

      // Add AI reply to Firestore
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
          _isLoading = false;
        });
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_5.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Let\'s Talk',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
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
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              final docs = snapshot.data!.docs;
                              final messages = docs
                                  .map(
                                    (doc) => ChatMessage.fromFirestore(
                                        doc.data() as Map<String, dynamic>),
                                  )
                                  .toList();

                              final showGreeting = messages.isEmpty && !_isLoading;
                              int itemCount = messages.length;
                              if (showGreeting) {
                                itemCount++;
                              }
                              if (_isLoading) {
                                itemCount++;
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  if (showGreeting && index == 0) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          'How are you feeling today?',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    );
                                  }

                                  final msgIndex = showGreeting ? index - 1 : index;

                                  if (_isLoading && msgIndex == messages.length) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFE84797),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (msgIndex < 0 || msgIndex >= messages.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final msg = messages[msgIndex];
                                  return Align(
                                    alignment: msg.isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: msg.isUser
                                            ? const Color(0xFFE7A0CC)
                                            : Theme.of(context).colorScheme.surface,
                                        borderRadius: msg.isUser
                                            ? const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                                bottomLeft: Radius.circular(16),
                                              )
                                            : const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                                bottomRight: Radius.circular(16),
                                              ),
                                      ),
                                      child: Text(
                                        msg.text,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  );
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
                          style: Theme.of(context).textTheme.bodyMedium, 
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE84797), 
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          color: Theme.of(context).colorScheme.onPrimary,
                          onPressed: _isLoading ? null : _sendMessage,
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