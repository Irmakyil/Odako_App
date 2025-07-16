import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  int _mood = 1;

  static const _moodData = [
    {
      'faceColor': Color(0xFF8B4A6B),
      'label': 'MEH',
      'backgroundColor': Color(0xFFE8C5D1),
      'sliderColor': Color(0xFFC88A9A),
    },
    {
      'faceColor': Color(0xFF8B7355),
      'label': 'NOT BAD',
      'backgroundColor': Color(0xFFF0E8D4),
      'sliderColor': Color(0xFFD4B887),
    },
    {
      'faceColor': Color(0xFF6B8B47),
      'label': 'GOOD',
      'backgroundColor': Color(0xFFE8F0D4),
      'sliderColor': Color(0xFF9ABA5A),
    },
  ];

  Widget _buildFace(int moodIndex) {
    final faceColor = _moodData[moodIndex]['faceColor'] as Color;
    
    switch (moodIndex) {
      case 0: // MEH - sad face
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 35,
                  height: 25,
                  decoration: BoxDecoration(
                    color: faceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Container(
                  width: 35,
                  height: 25,
                  decoration: BoxDecoration(
                    color: faceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 40,
              height: 8,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        );
      case 1: // NOT BAD - neutral face
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: faceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: faceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 25,
              height: 8,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        );
      case 2: // GOOD - happy face
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: faceColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: faceColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodData[_mood];
    
    return Scaffold(
      backgroundColor: mood['backgroundColor'] as Color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Title
              Text(
                "How's your mood\ntoday?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _moodData[_mood]['faceColor'] as Color,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Face
              SizedBox(
                height: 100,
                width: 120,
                child: _buildFace(_mood),
              ),
              
              const SizedBox(height: 40),
              
              // Label
              Text(
                mood['label'] as String,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Slider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                    activeTrackColor: mood['sliderColor'] as Color,
                    inactiveTrackColor: (mood['sliderColor'] as Color).withValues(alpha: 0.3),
                    thumbColor: mood['sliderColor'] as Color,
                    overlayColor: (mood['sliderColor'] as Color).withValues(alpha: 0.2),
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
              ),
              
              const Spacer(),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.dailyQuestion);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mood['sliderColor'] as Color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}