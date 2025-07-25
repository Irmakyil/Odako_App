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
    'unlockInfo': 'Complete a task between 06:00–12:00',
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
    final unlockInfo =
        badgeConditions.firstWhere((b) => b['id'] == badge['id'], orElse: () => {'unlockInfo': ''})['unlockInfo'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface, // Consistent dialog background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners
        title: Row(
          children: [
            Text(unlocked ? 'Badge Unlocked!' : 'Locked Badge',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(width: 8),
            Text(icon, style: const TextStyle(fontSize: 28)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 8),
              if (unlocked)
                Text(desc,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        )),
              // Show unlock info only for locked badges
              if (!unlocked && unlockInfo != null && unlockInfo != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('How to unlock: $unlockInfo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          )),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary, // Primary color for action buttons
                      fontWeight: FontWeight.bold,
                    )),
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
    return Stack(
      children: [
        // --- Full-screen background image ---
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_1.png'), // Use your background image
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent, // Make Scaffold background transparent
          appBar: AppBar(
            title: Text(
              'Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface, // Consistent title color
                  ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Transparent AppBar
            elevation: 0, // No shadow for AppBar
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface, // Consistent icon color
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User information card
                  Card(
                    color: theme.colorScheme.surface, // Use theme surface color
                    elevation: 4, // Consistent elevation
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // More rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45, // Slightly larger avatar
                            backgroundColor: theme.colorScheme.primary.withAlpha(50), // More visible background
                            backgroundImage: const AssetImage('lib/presentation/assets/maskot.png'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            username,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ), // More prominent username
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7), // Softer email color
                                ),
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
                      final completedTaskCount = data['completedTaskCount'] ?? 0;
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
                            )),
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
                              Text('Progress Overview',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      )),
                              const SizedBox(height: 16), // Increased spacing
                              Row(
                                children: [
                                  Expanded(
                                      child: Text('Completed Tasks: $completedTaskCount',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                              ))),
                                  Expanded(
                                      child: Text('Login Streak 🔥: $streak',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                              ))),
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
                            )),
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
                                  Text('Achievements',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          )),
                                  const SizedBox(width: 8),
                                  Icon(Icons.stars, color: theme.colorScheme.secondary), // Added an icon for achievements
                                ],
                              ),
                              const SizedBox(height: 16), // Increased spacing
                              badges.isEmpty
                                  ? Text('No badges yet! Complete tasks to earn them.',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                                          ))
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
                                                width: 100, // Slightly wider badge container
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // More padding
                                                decoration: BoxDecoration(
                                                  color: unlocked
                                                      ? theme.colorScheme.primary.withAlpha(50) // More prominent unlocked color
                                                      : theme.colorScheme.surfaceVariant, // Different color for locked
                                                  borderRadius: BorderRadius.circular(16), // More rounded
                                                  border: Border.all(
                                                    color: unlocked
                                                        ? theme.colorScheme.primary // Primary for unlocked border
                                                        : theme.colorScheme.outline, // Outline for locked border
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    if (unlocked) // Add shadow only for unlocked badges
                                                      BoxShadow(
                                                        color: theme.colorScheme.primary.withAlpha(20),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      icon,
                                                      style: const TextStyle(fontSize: 40), // Larger icon
                                                    ),
                                                    const SizedBox(height: 8), // More spacing
                                                    Text(
                                                      name,
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                            fontWeight: FontWeight.w700,
                                                            color: unlocked
                                                                ? theme.colorScheme.onSurface // OnSurface for unlocked
                                                                : theme.colorScheme.onSurface.withOpacity(0.7), // Softer for locked
                                                          ),
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
                  // Feedback button
                  //SizedBox(
                    //width: double.infinity,
                    //height: 50, // Consistent button height
                    //child: OutlinedButton.icon(
                      //onPressed: null, // Feedback route not implemented yet
                      //icon: Icon(Icons.feedback_outlined, color: theme.colorScheme.primary),
                      //label: Text('Feedback',
                          //style: theme.textTheme.titleMedium?.copyWith(
                                //color: theme.colorScheme.primary,
                                //fontWeight: FontWeight.w600,
                              //)),
                      //style: OutlinedButton.styleFrom(
                        //padding: const EdgeInsets.symmetric(vertical: 16),
                        //shape: RoundedRectangleBorder(
                          //borderRadius: BorderRadius.circular(12),
                        //),
                        //side: BorderSide(color: theme.colorScheme.primary, width: 2), // Primary color border
                      //),
                    //),
                  //),
                  const SizedBox(height: 16), // Increased spacing
                  // Sign out button
                  SizedBox(
                    width: double.infinity,
                    height: 50, // Consistent button height
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text('Sign Out',
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
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
                                color: theme.colorScheme.onSurface, // Softer color
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