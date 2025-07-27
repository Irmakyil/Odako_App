import 'package:flutter/foundation.dart';
import 'chat_service.dart';

/// Example usage of the session-based chat system
class ChatExample {
  static Future<void> demonstrateSessionBasedChat() async {
    try {
      final sessionId = await ChatService.createChatSession();
      debugPrint('Created session: $sessionId');

      // User messages
      await ChatService.saveMessageToSession(
        message: "I want to clean my room today",
        sender: "user",
        sessionId: sessionId,
      );
      await ChatService.saveMessageToSession(
        message: "I also need to do my homework",
        sender: "user",
        sessionId: sessionId,
      );

      // AI responses
      await ChatService.saveMessageToSession(
        message: "Great! Let's start with making your bed",
        sender: "ai",
        sessionId: sessionId,
      );
      await ChatService.saveMessageToSession(
        message: "For homework, let's break it into smaller tasks",
        sender: "ai",
        sessionId: sessionId,
      );

      debugPrint('All messages saved to session successfully');

      // For real app, use stream to get messages:
      // Stream<QuerySnapshot> messages = ChatService.getSessionMessages(sessionId);
    } catch (e) {
      debugPrint('Error in chat example: $e');
    }
  }

  static Future<void> demonstrateLegacyChat() async {
    try {
      await ChatService.saveMessage(
        message: "This is a legacy message",
        sender: "user",
      );
      await ChatService.saveMessage(
        message: "This is a legacy AI response",
        sender: "ai",
      );

      debugPrint('Legacy messages saved successfully');
    } catch (e) {
      debugPrint('Error in legacy chat example: $e');
    }
  }
}