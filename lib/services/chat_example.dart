import 'package:flutter/foundation.dart';
import 'chat_service.dart';

/// Example usage of the session-based chat system
class ChatExample {
  static Future<void> demonstrateSessionBasedChat() async {
    try {
      // 1. Create a new chat session
      String sessionId = await ChatService.createChatSession();
      debugPrint('Created session: $sessionId');

      // 2. Save user messages to the session
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

      // 3. Save AI responses to the session
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

      // 4. Get messages from the session (in real app, this would be a Stream)
      // Stream<QuerySnapshot> messages = ChatService.getSessionMessages(sessionId);

    } catch (e) {
      debugPrint('Error in chat example: $e');
    }
  }

  static Future<void> demonstrateLegacyChat() async {
    try {
      // Legacy method still works for backward compatibility
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