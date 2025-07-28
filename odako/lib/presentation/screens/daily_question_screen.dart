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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isProcessingQueue = false;
  String? _sessionId;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
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

  Future<void> _processMessageQueue() async {
    if (_isProcessingQueue) return;

    setState(() => _isProcessingQueue = true);

    try {
      final pendingUserMessages = _messages
          .where((msg) => msg.isUser && !msg.hasAiResponse)
          .toList();

      for (final userMessage in pendingUserMessages) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Typing...',
            isUser: false,
            timestamp: DateTime.now(),
            isTyping: true,
          ));
        });

        _scrollToBottom();

        final aiReply = await AIService.getDailyTaskSuggestion(userMessage.text);

        setState(() {
          _messages.removeWhere((msg) => msg.isTyping);
          _messages.add(ChatMessage(
            text: aiReply,
            isUser: false,
            timestamp: DateTime.now(),
          ));

          final index = _messages.indexOf(userMessage);
          if (index != -1) {
            _messages[index] = userMessage.copyWith(hasAiResponse: true);
          }
        });

        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error processing message queue: $e');
      setState(() => _messages.removeWhere((msg) => msg.isTyping));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessingQueue = false;
        });
        _scrollToBottom();
      }
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
                        return ChatBubble(
                          text: message.text,
                          isUser: message.isUser,
                        );
                      },
                    ),
                  ),
                  if (_messages.length > 1 && !_isLoading)
                    _buildSuggestBreakdownButton(context),
                  _buildMessageInputRow(context),
                  const SizedBox(height: 16),
                  _buildContinueButton(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestBreakdownButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.suggestBreakdown),
        style: _buttonStyle(),
        child: _buttonContent(
          icon: Icons.check_circle_outline,
          label: 'Check Your Tasks',
        ),
      ),
    );
  }

  Widget _buildMessageInputRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your task...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onSubmitted: _isLoading ? null : (_) => _sendMessage(),
            enabled: !_isLoading,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _isLoading ? null : _sendMessage,
          child: Image.asset(
            'lib/presentation/assets/button_send.png',
            width: 48, // Adjust width as needed
            height: 48, // Adjust height as needed
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _messages.length > 1 && !_isLoading
            ? () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.mainMenu,
                  (route) => false,
                )
            : null,
        style: _buttonStyle(),
        child: _buttonContent(label: 'Continue'),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      fixedSize: const Size(300, 45),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buttonContent({required String label, IconData? icon}) {
    return Container(
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('lib/presentation/assets/Button.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.black),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          isUser == other.isUser &&
          timestamp == other.timestamp &&
          isTyping == other.isTyping &&
          hasAiResponse == other.hasAiResponse;

  @override
  int get hashCode => Object.hash(text, isUser, timestamp, isTyping, hasAiResponse);
}