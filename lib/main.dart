import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/mood_selection_screen.dart';
import 'presentation/screens/task_list_screen.dart';
import 'presentation/screens/daily_question_screen.dart';
import 'presentation/screens/suggest_breakdown_screen.dart';
//import 'presentation/screens/list_showcase_screen.dart';
import 'presentation/screens/main_menu.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OdakoApp());
}

class OdakoApp extends StatelessWidget {
  const OdakoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odako',
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(), 
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.moodSelection: (context) => const MoodSelectionScreen(),
        AppRoutes.moodSelector: (context) => const MoodSelectionScreen(),
        AppRoutes.taskList: (context) => const TaskListScreen(),
        AppRoutes.dailyQuestion: (context) => const DailyQuestionScreen(),
        AppRoutes.suggestBreakdown: (context) => const SuggestBreakdownScreen(),
        //AppRoutes.listShowcase: (context) => const ListShowcaseScreen(),
        AppRoutes.mainMenu: (context) => const MainMenuScreen(),
        AppRoutes.chat: (context) => const ChatScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
