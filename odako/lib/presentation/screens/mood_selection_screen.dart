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
      'faceColor': Color.fromARGB(255, 255, 100, 100), // renk kodları ve widget ayarları yapılacak ben genel assetleri güncelledim 
    },
    {
      'label': 'MEH',
      'face': 'lib/presentation/assets/face_mid.png',
      'sliderColor': Color.fromARGB(255, 255, 212, 82),
      'faceColor': Color.fromARGB(255, 255, 212, 82), //eğer yüz ifadelerini kod ile yazabilirseniz widgets kısmını kontrol edin 
                                        //oraya yazabilirsiniz yoksa png üzerinden yapılabilecek güncellemeleri burdan yapalım
    },
    {
      'label': 'AMAZING',
      'face': 'lib/presentation/assets/face_good.png',
      'sliderColor': Color.fromARGB(255, 173, 255, 91),
      'faceColor': Color.fromARGB(255, 173, 255, 91), // 
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
                  "Share Your Feelings",
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
