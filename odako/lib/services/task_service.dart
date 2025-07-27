import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/models/ai_task.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> saveAITasks(List<AITask> tasks) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final task in tasks) {
        final taskRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc();

        batch.set(taskRef, {
          'text': task.text,
          'priority': task.priority,
          'createdAt': timestamp,
          'source': 'AI',
        });
      }

      await batch.commit();

      debugPrint('Successfully saved ${tasks.length} AI tasks to Firestore');
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error saving AI tasks: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error saving AI tasks: $e');
      return false;
    }
  }

  static Future<bool> saveAITasksWithSession(List<AITask> tasks, String sessionId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final task in tasks) {
        final taskRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc();

        batch.set(taskRef, {
          'text': task.text,
          'priority': task.priority,
          'createdAt': timestamp,
          'source': 'AI',
          'sessionId': sessionId,
        });
      }

      await batch.commit();

      debugPrint('Successfully saved ${tasks.length} AI tasks to Firestore with session $sessionId');
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error saving AI tasks: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error saving AI tasks: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot> getUserTasks() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static List<AITask> parseAITasksFromJson(String jsonString) {
    try {
      String cleaned = jsonString.trim();

      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7).trim();
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3).trim();
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3).trim();

      cleaned = cleaned.replaceAll('```', '').trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      return jsonList.map((json) => AITask.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error parsing AI tasks JSON: $e');
      return [];
    }
  }
}