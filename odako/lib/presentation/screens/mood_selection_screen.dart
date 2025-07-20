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
      'label': 'MEH',
      'face': 'lib/presentation/assets/face_meh.png',
      'sliderColor': Color(0xFFC88A9A),
      'faceColor': Color(0xFFC88A9A), // renk kodları ve widget ayarları yapılacak ben genel assetleri güncelledim 
    },
    {
      'label': 'NOT BAD',
      'face': 'lib/presentation/assets/face_mid.png',
      'sliderColor': Color(0xFFD4B887),
      'faceColor': Color(0xFFE2C799), //eğer yüz ifadelerini kod ile yazabilirseniz widgets kısmını kontrol edin 
                                        //oraya yazabilirsiniz yoksa png üzerinden yapılabilecek güncellemeleri burdan yapalım
    },
    {
      'label': 'GOOD',
      'face': 'lib/presentation/assets/face_good.png',
      'sliderColor': Color(0xFF9ABA5A),
      'faceColor': Color(0xFFA7D676), // 
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/presentation/assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Başlık
                Text(
                  "How's your mood\ntoday?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: sliderColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // PNG yüz ifadesi
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      color: mood['faceColor'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      mood['face'] as String,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Mood label
                Text(
                  mood['label'] as String,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 60),

                // Slider
                Slider(
                  value: _mood.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  onChanged: (value) {
                    setState(() {
                      _mood = value.round();
                    });
                  },
                  activeColor: sliderColor,
                  inactiveColor: sliderColor.withAlpha(77),
                ),

                const Spacer(),

                // Devam Butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sliderColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
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
      ),
    );
  }
}
