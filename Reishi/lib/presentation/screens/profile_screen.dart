import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../services/gamification_service.dart';

final List<Map<String, dynamic>> badgeConditions = [
  {'id': 'headstart', 'unlockInfo': 'Complete your first task'},
  {
    'id': 'mushroom_madness',
    'unlockInfo': 'Complete all tasks for 3 days in a row',
  },
  {'id': 'charm', 'unlockInfo': 'Complete all 3 tasks today'},
  {'id': 'early_bird', 'unlockInfo': 'Complete a task between 06:00–12:00'},
  {'id': 'tenacious_ten', 'unlockInfo': 'Complete 10 total tasks'},
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
                      "🎉 New Achievement! You unlocked the '${badge['name']}' badge! Great job!",
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
          setState(() {
            _earnedBadgeIds = newIds;
          });
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
            if (icon.isNotEmpty) Image.asset(icon, width: 28, height: 28),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              if (!unlocked && unlockInfo != null && unlockInfo != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'How to unlock: $unlockInfo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                        color: Colors.transparent,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                'lib/presentation/assets/box_profile1c.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Color(0xFFECA0CC),
                                  backgroundImage: const AssetImage(
                                    'lib/presentation/assets/maskot.png',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  username,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  email,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
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
                        ),
                      );
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final data = snapshot.data ?? {};
                      final completedTaskCount =
                          data['completedTaskCount'] ?? 0;
                      final streak = data['streak'] ?? 0;
                      return Card(
                        color: Colors.transparent,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                'lib/presentation/assets/box_profile2c.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress Overview',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
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
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Login Streak 🔥: $streak',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _badgesFuture,
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
                      final badges = snapshot.data ?? [];
                      return Card(
                        color: Colors.transparent,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                'lib/presentation/assets/box_profile3c.png',
                              ),
                              fit: BoxFit.cover,
                            ),
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
                                    Icon(Icons.stars, color: Color(0xFF203F9A)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                badges.isEmpty
                                    ? Text(
                                        'No badges yet! Complete tasks to earn them.',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      )
                                    : SizedBox(
                                        height: 120,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: badges.length,
                                          itemBuilder: (context, index) {
                                            final badge = badges[index];
                                            final unlocked =
                                                badge['unlocked'] == true;
                                            final icon = badge['icon'] ?? '';
                                            final name = badge['name'] ?? '';
                                            return GestureDetector(
                                              onTap: () =>
                                                  _showBadgeDialog(badge),
                                              child: Opacity(
                                                opacity: unlocked ? 1.0 : 0.4,
                                                child: Container(
                                                  width: 100,
                                                  margin: const EdgeInsets.only(
                                                    right: 16,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: unlocked
                                                        ? Colors.white
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: unlocked
                                                          ? Color(0xFF94C2DA)
                                                          : theme
                                                                .colorScheme
                                                                .outline,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (icon.isNotEmpty)
                                                        Image.asset(
                                                          icon,
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                      else
                                                        const SizedBox(
                                                          width: 40,
                                                          height: 40,
                                                        ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        name,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: InkWell(
                      onTap: () => _logout(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: const DecorationImage(
                            image: AssetImage(
                              'lib/presentation/assets/signin&out_button_red.png',
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Reishi',
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
