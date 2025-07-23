import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../data/datasources/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    if (user == null) {
      // Not signed in: show onboarding if first launch or after sign out
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }
    // User is signed in, check last mood check date
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastMoodCheckDate = await LocalStorage.getString('lastMoodCheckDate');
    if (!mounted) return;
    if (lastMoodCheckDate == today) {
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
                // Maskot görseli
                Image.asset(
                  'lib/presentation/assets/maskot.png',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),

                // Welcome başlığı
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
