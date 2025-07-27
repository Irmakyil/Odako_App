import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../data/datasources/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    await Future.delayed(const Duration(seconds: 1));
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    final uid = user.uid;

    final profileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('data')
        .get();

    final profileData = profileDoc.data();

    final isProfileComplete = profileData != null &&
        profileData.containsKey('username') &&
        profileData.containsKey('age') &&
        profileData.containsKey('gender') &&
        profileData.containsKey('adhdType');

    if (!mounted) return;

    if (!isProfileComplete) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileOnboarding);
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastMoodDate = await LocalStorage.getString('lastMoodCheckDate');

    if (!mounted) return;

    if (lastMoodDate == today) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainMenu);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
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
                  'Welcome!',
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
