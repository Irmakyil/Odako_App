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

  @override
  void initState() {
    super.initState();
    _initializeChatSession();
    // Add initial AI message
    _messages.add(ChatMessage(
      text: 'What do you want to accomplish today?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initializeChatSession() async {
    try {
      _sessionId = await ChatService.createChatSession();
      debugPrint('Chat session initialized: $_sessionId');
    } catch (e) {
      debugPrint('Error creating chat session: $e');
      // Continue without session if creation fails
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_isLoading) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = true;
        _controller.clear();
      });

      // Save user message to session
      if (_sessionId != null) {
        try {
          await ChatService.saveMessageToSession(
            message: text,
            sender: 'user',
            sessionId: _sessionId!,
          );
        } catch (e) {
          debugPrint('Error saving user message to session: $e');
          // Continue with UI even if save fails
        }
      }

      // Process the message queue
      _processMessageQueue();
    }
  }

  Future<void> _processMessageQueue() async {
    if (_isProcessingQueue) return;

    setState(() {
      _isProcessingQueue = true;
    });

    try {
      // Find all user messages that don't have AI responses yet
      final pendingUserMessages = <ChatMessage>[];
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.isUser && !message.hasAiResponse) {
          pendingUserMessages.add(message);
        }
      }

      // Process each pending message
      for (final userMessage in pendingUserMessages) {
        // Add typing indicator
        setState(() {
          _messages.add(ChatMessage(
            text: 'Typing...',
            isUser: false,
            timestamp: DateTime.now(),
            isTyping: true,
          ));
        });

        // Get AI response
        final aiReply = await AIService.getDailyTaskSuggestion(userMessage.text);
        
        // Remove typing indicator and add AI response
        setState(() {
          _messages.removeWhere((msg) => msg.isTyping);
          _messages.add(ChatMessage(
            text: aiReply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          
          // Mark the user message as having an AI response
          final userMessageIndex = _messages.indexWhere((msg) => msg == userMessage);
          if (userMessageIndex != -1) {
            _messages[userMessageIndex] = userMessage.copyWith(hasAiResponse: true);
          }
        });

        // Save AI response to session
        if (_sessionId != null) {
          try {
            await ChatService.saveMessageToSession(
              message: aiReply,
              sender: 'ai',
              sessionId: _sessionId!,
            );
          } catch (e) {
            debugPrint('Error saving AI message to session: $e');
            // Continue with UI even if save fails
          }
        }

        // Small delay between responses for better UX
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error processing message queue: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isProcessingQueue = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'What do you want to accomplish today?',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ChatBubble(
                      text: message.text,
                      isUser: message.isUser,
                    );
                  },
                ),
              ),
              // Check Your Tasks button
              if (_messages.length > 1)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.suggestBreakdown);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Check Your Tasks'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      decoration: const InputDecoration(
                        hintText: 'Type your goal...'
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _messages.length > 1 && !_isLoading
                      ? () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainMenu, (route) => false);
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Represents a chat message with additional metadata
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
