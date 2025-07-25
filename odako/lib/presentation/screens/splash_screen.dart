import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../data/datasources/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartupRouting();
  }

  Future<void> _handleStartupRouting() async {
    await Future.delayed(const Duration(seconds: 3));
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    final localContext = context;
    if (user == null) {
      Navigator.pushReplacementNamed(localContext, AppRoutes.onboarding);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      final profile = doc.data()?['profile'] ?? {};
      if (profile['username'] == null || (profile['username'] as String).isEmpty) {
        Navigator.of(localContext).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileOnboardingScreen()),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking user profile: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(localContext, AppRoutes.onboarding);
      return;
    }
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastMoodCheckDate = await LocalStorage.getString('lastMoodCheckDate');
    if (!mounted) return;
    if (lastMoodCheckDate == today) {
      Navigator.pushReplacementNamed(localContext, AppRoutes.mainMenu);
    } else {
      Navigator.pushReplacementNamed(localContext, AppRoutes.moodSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/presentation/assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/presentation/assets/maskot.png',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),

                Text(
                  'Welcome to Odako',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
