import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves a chat message to Firestore within a session
  /// 
  /// [message] - The message content
  /// [sender] - Either 'user' or 'ai'
  /// [sessionId] - Unique identifier for the chat session
  /// 
  /// Throws FirebaseException if user is not authenticated or save fails
  static Future<void> saveMessageToSession({
    required String message,
    required String sender,
    required String sessionId,
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate sender
      if (sender != 'user' && sender != 'ai') {
        throw Exception('Invalid sender. Must be "user" or "ai"');
      }

      // Create message data
      final messageData = {
        'message': message,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore within session
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(messageData);

      debugPrint('Message saved to session $sessionId: $sender - $message');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error saving message to session: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error saving message to session: $e');
      rethrow;
    }
  }

  /// Saves a chat message to Firestore (legacy method for backward compatibility)
  /// 
  /// [message] - The message content
  /// [sender] - Either 'user' or 'ai'
  /// 
  /// Throws FirebaseException if user is not authenticated or save fails
  static Future<void> saveMessage({
    required String message,
    required String sender,
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate sender
      if (sender != 'user' && sender != 'ai') {
        throw Exception('Invalid sender. Must be "user" or "ai"');
      }

      // Create message document
      final messageData = {
        'message': message,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .add(messageData);

      debugPrint('Message saved successfully: $sender - $message');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error saving message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error saving message: $e');
      rethrow;
    }
  }

  /// Creates a new chat session
  /// 
  /// Returns the session ID
  static Future<String> createChatSession() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create session document
      final sessionData = {
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'messageCount': 0,
      };

      final sessionRef = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chat_sessions')
          .add(sessionData);

      debugPrint('Chat session created: ${sessionRef.id}');
      return sessionRef.id;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error creating chat session: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error creating chat session: $e');
      rethrow;
    }
  }

  /// Gets chat history for a specific session
  /// 
  /// Returns a stream of chat messages ordered by timestamp
  static Stream<QuerySnapshot> getSessionMessages(String sessionId) {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Gets all chat sessions for the current user
  /// 
  /// Returns a stream of chat sessions ordered by last activity
  static Stream<QuerySnapshot> getChatSessions() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chat_sessions')
        .orderBy('lastActivity', descending: true)
        .snapshots();
  }

  /// Gets chat history for the current user (legacy method for backward compatibility)
  /// 
  /// Returns a stream of chat messages ordered by timestamp
  static Stream<QuerySnapshot> getChatHistory() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
} 