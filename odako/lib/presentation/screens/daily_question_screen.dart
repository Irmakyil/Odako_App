import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';
import '../../routes/app_routes.dart';
import '../../services/ai_service.dart';
import '../../services/chat_service.dart';

class DailyQuestionScreen extends StatefulWidget {
  const DailyQuestionScreen({super.key});

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isProcessingQueue = false;
  String? _sessionId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChatSession();
    _messages.add(
      ChatMessage(
        text:
            'Howdy! I\'m Reishi 🍄. Your personalized AI helper to get you through the hardships that come with ADHD. What do you want to accomplish today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initializeChatSession() async {
    try {
      _sessionId = await ChatService.createChatSession();
      debugPrint('Chat session initialized: $_sessionId');
    } catch (e) {
      debugPrint('Error creating chat session: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_isLoading) {
      setState(() {
        _messages.add(
          ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
        );
        _isLoading = true;
        _controller.clear();
      });
      _scrollToBottom();

      if (_sessionId != null) {
        try {
          await ChatService.saveMessageToSession(
            message: text,
            sender: 'user',
            sessionId: _sessionId!,
          );
        } catch (e) {
          debugPrint('Error saving user message to session: $e');
        }
      }

      _processMessageQueue();
    }
  }

  Future<void> _processMessageQueue() async {
    if (_isProcessingQueue) return;

    setState(() {
      _isProcessingQueue = true;
    });

    try {
      final pendingUserMessages = <ChatMessage>[];
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.isUser && !message.hasAiResponse) {
          pendingUserMessages.add(message);
        }
      }

      for (final userMessage in pendingUserMessages) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Typing...',
              isUser: false,
              timestamp: DateTime.now(),
              isTyping: true,
            ),
          );
        });
        _scrollToBottom();

        final aiReply = await AIService.getDailyTaskSuggestion(
          userMessage.text,
        );

        setState(() {
          _messages.removeWhere((msg) => msg.isTyping);
          _messages.add(
            ChatMessage(
              text: aiReply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );

          final userMessageIndex = _messages.indexWhere(
            (msg) => msg == userMessage,
          );
          if (userMessageIndex != -1) {
            _messages[userMessageIndex] = userMessage.copyWith(
              hasAiResponse: true,
            );
          }
        });
        _scrollToBottom();

        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error processing message queue: $e');
      setState(() {
        _messages.removeWhere((msg) => msg.isTyping);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isProcessingQueue = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_2.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Daily Task Helper',
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'What do you want to accomplish today?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF203F9A),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        if (message.isTyping) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
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
                        return ChatBubble(
                          text: message.text,
                          isUser: message.isUser,
                        );
                      },
                    ),
                  ),
                  if (_messages.length > 1 && !_isLoading)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.suggestBreakdown,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          fixedSize: const Size(double.infinity, 45.0),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                'lib/presentation/assets/Button.png',
                              ),
                              fit: BoxFit.fill,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Check Your Tasks',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          0,
                                          0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your task...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: _isLoading
                              ? null
                              : (_) => _sendMessage(),
                          enabled: !_isLoading,
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
                              color: Theme.of(
                                context,
                              ).shadowColor.withAlpha(20),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _messages.length > 1 && !_isLoading
                          ? () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.mainMenu,
                                (route) => false,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        fixedSize: const Size(double.infinity, 45.0),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(
                              'lib/presentation/assets/Button.png',
                            ),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  final bool hasAiResponse;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.hasAiResponse = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isTyping,
    bool? hasAiResponse,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      hasAiResponse: hasAiResponse ?? this.hasAiResponse,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.isTyping == isTyping &&
        other.hasAiResponse == hasAiResponse;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        isTyping.hashCode ^
        hasAiResponse.hashCode;
  }
}
