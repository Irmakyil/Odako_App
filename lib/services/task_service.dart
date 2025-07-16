import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/models/ai_task.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves multiple AI-generated tasks to Firestore using batch operations
  /// 
  /// [tasks] - List of AITask objects to save
  /// Returns true if successful, false otherwise
  static Future<bool> saveAITasks(List<AITask> tasks) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create batch for atomic operation
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      // Add each task to the batch
      for (final task in tasks) {
        final taskData = {
          'text': task.text,
          'priority': task.priority,
          'createdAt': timestamp,
          'source': 'AI',
        };

        final taskRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc();

        batch.set(taskRef, taskData);
      }

      // Commit the batch
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

  /// Saves multiple AI-generated tasks to Firestore with session ID
  /// 
  /// [tasks] - List of AITask objects to save
  /// [sessionId] - ID of the chat session used for context
  /// Returns true if successful, false otherwise
  static Future<bool> saveAITasksWithSession(List<AITask> tasks, String sessionId) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create batch for atomic operation
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      // Add each task to the batch
      for (final task in tasks) {
        final taskData = {
          'text': task.text,
          'priority': task.priority,
          'createdAt': timestamp,
          'source': 'AI',
          'sessionId': sessionId,
        };

        final taskRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc();

        batch.set(taskRef, taskData);
      }

      // Commit the batch
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

  /// Gets all tasks for the current user
  /// 
  /// Returns a stream of tasks ordered by creation time
  static Stream<QuerySnapshot> getUserTasks() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Parses JSON string into List&lt;AITask&gt;
  /// 
  /// [jsonString] - JSON string from AI response
  /// Returns list of AITask objects
  static List<AITask> parseAITasksFromJson(String jsonString) {
    try {
      // Kod bloğu etiketlerini temizle (hem başta hem sonda olabilir)
      String cleaned = jsonString.trim();
      // Hem ```json hem de ``` ile başlıyorsa
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7).trim();
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3).trim();
      }
      // Sonda ``` varsa
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
      // Arada hala satır başı veya fazladan boşluk varsa temizle
      cleaned = cleaned.replaceAll('```', '').trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);
      return jsonList
          .map((json) => AITask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error parsing AI tasks JSON: $e');
      return [];
    }
  }
} 