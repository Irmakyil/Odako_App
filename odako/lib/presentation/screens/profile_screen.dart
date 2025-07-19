import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../routes/app_routes.dart';
import '../../services/gamification_service.dart';

// List of badge conditions for unlock information
final List<Map<String, dynamic>> badgeConditions = [
  {
    'id': 'first_step',
    'unlockInfo': 'Complete your first task',
  },
  {
    'id': 'consistent_mind',
    'unlockInfo': 'Complete all tasks for 3 days in a row',
  },
  {
    'id': 'focused_day',
    'unlockInfo': 'Complete all 3 tasks today',
  },
  {
    'id': 'morning_start',
    'unlockInfo': 'Complete a task between 08:00–12:00',
  },
  {
    'id': 'productive_streak',
    'unlockInfo': 'Complete 10 total tasks',
  },
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _badgesFuture;
  List<String> _earnedBadgeIds = [];

  @override
  void initState() {
    super.initState();
    _profileFuture = GamificationService().fetchProfile();
    _badgesFuture = GamificationService().fetchBadges();
    _listenForNewBadges();
  }

  // Listen for new badges in Firestore and show a snackbar when a new badge is earned
  void _listenForNewBadges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('badges')
        .snapshots()
        .listen((snapshot) {
      final newIds = snapshot.docs.map((d) => d.id).toList();
      if (_earnedBadgeIds.isNotEmpty && newIds.length > _earnedBadgeIds.length) {
        // New badge earned
        final newBadgeId = newIds.firstWhere((id) => !_earnedBadgeIds.contains(id), orElse: () => '');
        if (newBadgeId.isNotEmpty) {
          final badge = GamificationService().badgeDefinitions.firstWhere((b) => b['id'] == newBadgeId, orElse: () => {});
          if (badge.isNotEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("🎉 New Achievement! You unlocked the ' ${badge['name']}' badge! Great job!"),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
      _earnedBadgeIds = newIds;
    });
  }

  // Log out the user and reset onboarding status
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', false);
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.onboarding,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while logging out: $e')),
        );
      }
    }
  }

  // Show a dialog with badge details and unlock information
  void _showBadgeDialog(Map<String, dynamic> badge) {
    final unlocked = badge['unlocked'] == true;
    final name = badge['name'] ?? '';
    final icon = badge['icon'] ?? '';
    final desc = badge['desc'] ?? '';
    final unlockInfo = badgeConditions.firstWhere((b) => b['id'] == badge['id'], orElse: () => {'unlockInfo': ''})['unlockInfo'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(unlocked ? 'Badge Unlocked!' : 'Locked Badge', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(icon, style: const TextStyle(fontSize: 28)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (unlocked)
                Text(desc, style: Theme.of(context).textTheme.bodyMedium),
              // Show unlock info only for locked badges
              if (!unlocked && unlockInfo != null && unlockInfo != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('How to unlock: $unlockInfo', style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'user@email.com';
    final username = email.split('@').first;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User information card
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primary.withAlpha(25),
                        backgroundImage: const AssetImage('lib/presentation/assets/mantar_maskot.png'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        username,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Statistics card
              FutureBuilder<Map<String, dynamic>>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {};
                  final xp = data['xp'] ?? 0;
                  final completedTaskCount = data['completedTaskCount'] ?? 0;
                  final streak = data['streak'] ?? 0;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overview', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Text('XP: $xp', style: theme.textTheme.bodyMedium)),
                              Expanded(child: Text('Tasks: $completedTaskCount', style: theme.textTheme.bodyMedium)),
                              Expanded(child: Text('Day Streak 🔥: $streak', style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Achievements card
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _badgesFuture,
                builder: (context, snapshot) {
                  final badges = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Achievements', style: theme.textTheme.titleMedium),
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 12),
                          badges.isEmpty
                              ? Text('No badges yet!', style: theme.textTheme.bodyMedium)
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: badges.map((badge) {
                                      final unlocked = badge['unlocked'] == true;
                                      final icon = badge['icon'] ?? '';
                                      final name = badge['name'] ?? '';
                                      return GestureDetector(
                                        onTap: () => _showBadgeDialog(badge),
                                        child: Opacity(
                                          opacity: unlocked ? 1.0 : 0.5,
                                          child: Container(
                                            width: 80,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: unlocked ? theme.colorScheme.primary.withAlpha(30) : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: unlocked ? theme.colorScheme.primary : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  icon,
                                                  style: const TextStyle(fontSize: 32),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  name,
                                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Feedback button (not implemented yet)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null, // Feedback route not implemented yet
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Feedback'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Sign out button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App information
              Center(
                child: Column(
                  children: [
                    Text(
                      'Odako',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'xxx',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 