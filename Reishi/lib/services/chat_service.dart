import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<String?> _fetchUsername() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('profile')
          .doc('data')
          .get();

      final data = doc.data();
      if (data != null && data['username'] != null && data['username'].toString().isNotEmpty) {
        return data['username'];
      }
    } catch (e) {
      debugPrint('Error fetching username for chat message: $e');
    }
    return null;
  }

  static Future<void> saveMessageToSession({
    required String message,
    required String sender,
    required String sessionId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    if (sender != 'user' && sender != 'ai') throw Exception('Invalid sender. Must be "user" or "ai"');

    try {
      final username = sender == 'user' ? await _fetchUsername() : null;
      final messageData = {
        'message': message,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
        if (sender == 'user') 'username': username ?? 'User',
        if (sender == 'ai') 'ai': true,
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(messageData);

      debugPrint('Message saved to session $sessionId: $sender - $message');
    } catch (e) {
      debugPrint('Error saving message to session: $e');
      rethrow;
    }
  }

  static Future<void> saveMessage({
    required String message,
    required String sender,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    if (sender != 'user' && sender != 'ai') throw Exception('Invalid sender. Must be "user" or "ai"');

    try {
      final messageData = {
        'message': message,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .add(messageData);

      debugPrint('Message saved successfully: $sender - $message');
    } catch (e) {
      debugPrint('Error saving message: $e');
      rethrow;
    }
  }

  static Future<String> createChatSession() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
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
    } catch (e) {
      debugPrint('Error creating chat session: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getSessionMessages(String sessionId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Stream<QuerySnapshot> getChatSessions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chat_sessions')
        .orderBy('lastActivity', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getChatHistory() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}