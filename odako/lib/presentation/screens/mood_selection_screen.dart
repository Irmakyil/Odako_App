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
      'face': 'lib/presentation/assets/face_bad.png',
      'sliderColor': Color(0xFFCE6B70),
      'faceColor': Color(0xFF693537),
      'background': 'lib/presentation/assets/background_bad.png',
    },
    {
      'label': 'MEH',
      'face': 'lib/presentation/assets/face_mid.png',
      'sliderColor': Color(0xFFF1CC59),
      'faceColor': Color(0xFF786A3D),
      'background': 'lib/presentation/assets/background_mid.png',
    },
    {
      'label': 'AMAZING',
      'face': 'lib/presentation/assets/face_good.png',
      'sliderColor': Color(0xFFA6BA49),
      'faceColor': Color(0xFF666F36),
      'background': 'lib/presentation/assets/background_good.png',
    },
  ];

  Future<void> _handleContinue() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await LocalStorage.setString('lastMoodCheckDate', today);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.dailyQuestion);
  }

  Widget _buildFaceCircle(BuildContext context, Color faceColor, String faceAsset) {
    final width = MediaQuery.of(context).size.width * 0.7;
    final height = MediaQuery.of(context).size.height * 0.4;

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: faceColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          faceAsset,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildSlider(Color sliderColor) {
    return SliderTheme(
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
        onChanged: (value) => setState(() => _mood = value.round()),
      ),
    );
  }

  Widget _buildContinueButton(Color sliderColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: sliderColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 5,
          shadowColor: Theme.of(context).shadowColor.withAlpha(50),
          visualDensity: VisualDensity.compact,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodData[_mood];
    final sliderColor = mood['sliderColor'] as Color;
    final faceColor = mood['faceColor'] as Color;
    final backgroundImage = mood['background'] as String;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
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
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  _buildFaceCircle(context, faceColor, mood['face'] as String),
                  const SizedBox(height: 50),
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
                  _buildSlider(sliderColor),
                  const Spacer(),
                  _buildContinueButton(sliderColor),
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