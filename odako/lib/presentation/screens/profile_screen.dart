import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../routes/app_routes.dart';
import '../../services/gamification_service.dart';

final List<Map<String, dynamic>> badgeConditions = [
  {'id': 'first_step', 'unlockInfo': 'Complete your first task'},
  {
    'id': 'consistent_mind',
    'unlockInfo': 'Complete all tasks for 3 days in a row',
  },
  {'id': 'focused_day', 'unlockInfo': 'Complete all 3 tasks today'},
  {'id': 'morning_start', 'unlockInfo': 'Complete a task between 06:00–12:00'},
  {'id': 'productive_streak', 'unlockInfo': 'Complete 10 total tasks'},
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
          if (_earnedBadgeIds.isNotEmpty &&
              newIds.length > _earnedBadgeIds.length) {
            // New badge earned
            final newBadgeId = newIds.firstWhere(
              (id) => !_earnedBadgeIds.contains(id),
              orElse: () => '',
            );
            if (newBadgeId.isNotEmpty) {
              final badge = GamificationService().badgeDefinitions.firstWhere(
                (b) => b['id'] == newBadgeId,
                orElse: () => {},
              );
              if (badge.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "🎉 New Achievement! You unlocked the ' ${badge['name']}' badge! Great job!",
                    ),
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

  void _showBadgeDialog(Map<String, dynamic> badge) {
    final unlocked = badge['unlocked'] == true;
    final name = badge['name'] ?? '';
    final icon = badge['icon'] ?? '';
    final desc = badge['desc'] ?? '';
    final unlockInfo = badgeConditions.firstWhere(
      (b) => b['id'] == badge['id'],
      orElse: () => {'unlockInfo': ''},
    )['unlockInfo'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(
              unlocked ? 'Badge Unlocked!' : 'Locked Badge',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(icon, style: const TextStyle(fontSize: 28)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (unlocked)
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              if (!unlocked && unlockInfo != null && unlockInfo != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'How to unlock: $unlockInfo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_1.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          color: theme.colorScheme.surface,
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        );
                      }
                      final data = snapshot.data ?? {};
                      final username =
                          (data['username'] != null &&
                              data['username'].toString().isNotEmpty)
                          ? data['username']
                          : 'User';
                      final email =
                          FirebaseAuth.instance.currentUser?.email ?? '';
                      final age = data['age']?.toString() ?? '';
                      final gender = data['gender']?.toString() ?? '';
                      final adhdType = data['adhdType']?.toString() ?? '';
                      return Card(
                        color: theme.colorScheme.surface,
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 50 / 255),
                                backgroundImage: const AssetImage(
                                  'lib/presentation/assets/maskot.png',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                username,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                email,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (age.isNotEmpty ||
                                  gender.isNotEmpty ||
                                  adhdType.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                if (age.isNotEmpty)
                                  Text(
                                    'Age: $age',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                if (gender.isNotEmpty)
                                  Text(
                                    'Gender: $gender',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                if (adhdType.isNotEmpty)
                                  Text(
                                    'ADHD Type: $adhdType',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Statistics card
                  FutureBuilder<Map<String, dynamic>>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? {};
                      final completedTaskCount =
                          data['completedTaskCount'] ?? 0;
                      final streak = data['streak'] ?? 0;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          color: theme.colorScheme.surface,
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return Card(
                        color: theme.colorScheme.surface,
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress Overview',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Completed Tasks: $completedTaskCount',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Login Streak 🔥: $streak',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _badgesFuture,
                    builder: (context, snapshot) {
                      final badges = snapshot.data ?? [];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          color: theme.colorScheme.surface,
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return Card(
                        color: theme.colorScheme.surface,
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Achievements',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.stars,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              badges.isEmpty
                                  ? Text(
                                      'No badges yet! Complete tasks to earn them.',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: badges.map((badge) {
                                          final unlocked =
                                              badge['unlocked'] == true;
                                          final icon = badge['icon'] ?? '';
                                          final name = badge['name'] ?? '';
                                          return GestureDetector(
                                            onTap: () =>
                                                _showBadgeDialog(badge),
                                            child: Opacity(
                                              opacity: unlocked ? 1.0 : 0.5,
                                              child: Container(
                                                width: 100,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: unlocked
                                                      ? theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 50 / 255,
                                                            )
                                                      : theme
                                                            .colorScheme
                                                            .surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: unlocked
                                                        ? theme
                                                              .colorScheme
                                                              .primary
                                                        : theme
                                                              .colorScheme
                                                              .outline,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    if (unlocked)
                                                      BoxShadow(
                                                        color: theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 20 / 255,
                                                            ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      icon,
                                                      style: const TextStyle(
                                                        fontSize: 40,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      name,
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: unlocked
                                                                ? theme
                                                                      .colorScheme
                                                                      .onSurface
                                                                : theme
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      ),
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Sign Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Odako',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v1.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
