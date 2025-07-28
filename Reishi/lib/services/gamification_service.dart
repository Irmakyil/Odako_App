import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef Badge = Map<String, dynamic>;

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;



  final List<Badge> badgeDefinitions = [
    {
      'id': 'headstart',
      'name': 'Headstart',
      'desc': 'You completed your first task!',
      'icon': 'lib/presentation/assets/achievement_headstart.png',
      'condition': (int completedTaskCount, bool isFirstTimeUser) =>
          completedTaskCount == 1 && isFirstTimeUser,
    },
    {
      'id': 'mushroom_madness',
      'name': 'Mushroom Madness',
      'desc': 'Complete all tasks for 3 days in a row',
      'icon': 'lib/presentation/assets/achievement_mushroom.png',
      'condition': (int streak, int streakCompletionRate) =>
          streak == 3 && streakCompletionRate == 100,
    },
    {
      'id': 'charm',
      'name': 'Third Time\'s the Charm',
      'desc': 'Complete all 3 tasks today',
      'icon': 'lib/presentation/assets/achievement_charm.png',
      'condition': (int todayCount) => todayCount == 3,
    },
    {
      'id': 'early_bird',
      'name': 'Early Bird',
      'desc': 'Complete a task between 06:00–12:00',
      'icon': 'lib/presentation/assets/achievement_bird.png',
      'condition': (bool isMorning) => isMorning,
    },
    {
      'id': 'tenacious_ten',
      'name': 'Tenacious Ten',
      'desc': 'Complete 10 tasks in Total',
      'icon': 'lib/presentation/assets/achievement_tenacious.png',
      'condition': (int completedTaskCount) => completedTaskCount >= 10,
    },
  ];

  Future<void> onTaskCompleted({
    required DateTime completedAt,
    required int totalTasksToday,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final profileRef = _firestore.collection('users').doc(uid).collection('profile').doc('data');
    try {
      await profileRef.set({
        'completedTaskCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating completedTaskCount: $e');
    }
    await _updateStreak(uid);
    await _checkAndUnlockBadges(uid, completedAt, totalTasksToday);
  }

  Future<void> _updateStreak(String uid) async {
    final profileRef = _firestore.collection('users').doc(uid).collection('profile').doc('data');
    try {
      final doc = await profileRef.get();
      final data = doc.data() ?? {};
      final lastDate = data['lastTaskDate'] != null ? DateTime.tryParse(data['lastTaskDate']) : null;
      final today = DateTime.now();
      int streak = (data['streak'] ?? 0) as int;
      if (lastDate != null) {
        final diff = today.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
        if (diff == 1) {
          streak += 1;
        } else if (diff > 1) {
          streak = 1;
        }
      } else {
        streak = 1;
      }
      await profileRef.set({
        'streak': streak,
        'lastTaskDate': today.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  Future<void> _checkAndUnlockBadges(String uid, DateTime completedAt, int totalTasksToday) async {
    final profileRef = _firestore.collection('users').doc(uid).collection('profile').doc('data');
    final badgesRef = _firestore.collection('users').doc(uid).collection('badges');
    try {
      final profileSnap = await profileRef.get();
      final profile = profileSnap.data() ?? {};
      final completedTaskCount = (profile['completedTaskCount'] ?? 0) as int;
      final streak = (profile['streak'] ?? 0) as int;
      final isMorning = completedAt.hour >= 6 && completedAt.hour < 12;
      final isFirstTimeUser = (profile['createdAt'] != null && completedTaskCount == 1);
      final streakCompletionRate = 100;
      for (final badge in badgeDefinitions) {
        final badgeId = badge['id'] as String;
        try {
          final badgeDoc = await badgesRef.doc(badgeId).get();
          if (badgeDoc.exists) {
            debugPrint('Badge $badgeId already unlocked, skipping.');
            continue;
          }
          bool unlocked = false;
          try {
            if (badge['condition'] == null) {
              debugPrint('Badge $badgeId has null condition, skipping.');
              continue;
            }
            switch (badgeId) {
              case 'headstart':
                unlocked = badge['condition'](completedTaskCount, isFirstTimeUser);
                break;
              case 'mushroom_madness':
                unlocked = badge['condition'](streak, streakCompletionRate);
                break;
              case 'charm':
                unlocked = badge['condition'](totalTasksToday);
                break;
              case 'early_bird':
                unlocked = badge['condition'](isMorning);
                break;
              case 'tenacious_ten':
                unlocked = badge['condition'](completedTaskCount);
                break;
              default:
                unlocked = false;
            }
          } catch (e) {
            debugPrint('Error evaluating badge $badgeId: $e');
            continue;
          }
          if (unlocked) {
            try {
              await badgesRef.doc(badgeId).set({
                'name': badge['name'],
                'desc': badge['desc'],
                'icon': badge['icon'],
                'unlockedAt': FieldValue.serverTimestamp(),
              });
              debugPrint('Badge $badgeId unlocked!');
            } catch (e) {
              debugPrint('Error writing badge $badgeId: $e');
            }
          } else {
            debugPrint('Badge $badgeId not unlocked (condition false).');
          }
        } catch (e) {
          debugPrint('Error in badge loop for $badgeId: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking/unlocking badges: $e');
    }
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final profileRef = _firestore.collection('users').doc(user.uid).collection('profile').doc('data');
    try {
      final doc = await profileRef.get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return {};
    }
  }

  Future<List<Badge>> fetchBadges() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final badgesRef = _firestore.collection('users').doc(user.uid).collection('badges');
    try {
      final unlocked = await badgesRef.get();
      final unlockedIds = unlocked.docs.map((d) => d.id).toSet();
      return badgeDefinitions.map((badge) {
        final isUnlocked = unlockedIds.contains(badge['id']);
        final unlockedDocList = unlocked.docs.where((d) => d.id == badge['id']).toList();
        final unlockedData = unlockedDocList.isNotEmpty ? unlockedDocList.first.data() : null;
        return {
          ...badge,
          'unlocked': isUnlocked,
          'unlockedAt': unlockedData != null ? unlockedData['unlockedAt'] : null,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return badgeDefinitions.map((b) => {...b, 'unlocked': false}).toList();
    }
  }
}