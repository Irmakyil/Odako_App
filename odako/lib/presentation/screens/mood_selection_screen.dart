import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../data/datasources/local_storage.dart';
import 'package:intl/intl.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  int _mood = 1;

  static const _moodData = [
    {
      'label': 'DEPRESSED',
      'face': 'lib/presentation/assets/face_meh.png',
      'sliderColor': Color.fromARGB(255, 255, 100, 100), 
      'faceColor': Color.fromARGB(255, 255, 100, 100),
      'backgroundColor': Color.fromARGB(255, 255, 200, 200),
    },
    {
      'label': 'MEH',
      'face': 'lib/presentation/assets/face_mid.png',
      'sliderColor': Color.fromARGB(255, 255, 212, 82),
      'faceColor': Color.fromARGB(255, 255, 212, 82),
      'backgroundColor': Color.fromARGB(255, 255, 233, 168),
    },
    {
      'label': 'AMAZING',
      'face': 'lib/presentation/assets/face_good.png',
      'sliderColor': Color.fromARGB(255, 173, 255, 91),
      'faceColor': Color.fromARGB(255, 173, 255, 91),
      'backgroundColor': Color.fromARGB(255, 229, 255, 202),
    },
  ];

  Future<void> _handleContinue() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await LocalStorage.setString('lastMoodCheckDate', today);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.dailyQuestion);
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodData[_mood];
    final sliderColor = mood['sliderColor'] as Color;
    final faceColor = mood['faceColor'] as Color;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_3.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Mood Tracker',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Text(
                    "Share Your Feelings",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  Container(
                    height: 150,
                    width: 150, 
                    decoration: BoxDecoration(
                      color: faceColor, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withAlpha(50),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        mood['face'] as String,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    mood['label'] as String,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 2,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 8.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                      activeTrackColor: sliderColor,
                      inactiveTrackColor: sliderColor.withAlpha(77),
                      thumbColor: sliderColor,
                      overlayColor: sliderColor.withAlpha(50),
                    ),
                    child: Slider(
                      value: _mood.toDouble(),
                      min: 0,
                      max: 2,
                      divisions: 2,
                      onChanged: (value) {
                        setState(() {
                          _mood = value.round();
                        });
                      },
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        fixedSize: const Size(double.infinity, 56.0),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('lib/presentation/assets/na_background_4.png'),
                            fit: BoxFit.fill,
                            colorFilter: ColorFilter.mode(
                              sliderColor,
                              BlendMode.srcATop,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
