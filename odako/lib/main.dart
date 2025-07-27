import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/mood_selection_screen.dart';
import 'presentation/screens/task_list_screen.dart';
import 'presentation/screens/daily_question_screen.dart';
import 'presentation/screens/suggest_breakdown_screen.dart';
import 'presentation/screens/main_menu.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/profile_onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await firebaseMessagingBackgroundHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  runApp(const OdakoApp());
}

class OdakoApp extends StatelessWidget {
  const OdakoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odako',
      theme: ThemeData(
        textTheme: GoogleFonts.marheyTextTheme(), 
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(), 
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.moodSelection: (context) => const MoodSelectionScreen(),
        AppRoutes.moodSelector: (context) => const MoodSelectionScreen(),
        AppRoutes.taskList: (context) => const TaskListScreen(),
        AppRoutes.dailyQuestion: (context) => const DailyQuestionScreen(),
        AppRoutes.suggestBreakdown: (context) => const SuggestBreakdownScreen(),
        AppRoutes.mainMenu: (context) => const MainMenuScreen(),
        AppRoutes.chat: (context) => const ChatScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.profileOnboarding: (context) => const ProfileOnboardingScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
