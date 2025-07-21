import 'package:flutter/material.dart';

class MoodFace extends StatelessWidget {
  final int moodIndex; // 0: Meh, 1: Not Bad, 2: Good
  const MoodFace({super.key, required this.moodIndex});

  @override
  Widget build(BuildContext context) {
    switch (moodIndex) {
      case 0:
        // DEPRESSED
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ovalEye(color: const Color.fromARGB(255, 255, 100, 100)),
                const SizedBox(width: 24),
                _ovalEye(color: const Color.fromARGB(255, 255, 100, 100)),
              ],
            ),
            const SizedBox(height: 8),
            Transform.rotate(
              angle: 3.14,
              child: Icon(Icons.sentiment_dissatisfied, color: Color.fromARGB(255, 255, 100, 100), size: 48),
            ),
          ],
        );
      case 1:
        // NOT BAD
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rectEye(color: const Color.fromARGB(255, 255, 212, 82)),
                const SizedBox(width: 24),
                _rectEye(color: const Color.fromARGB(255, 255, 212, 82)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 6,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 212, 82),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      case 2:
        // AMAZING
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleEye(color: const Color.fromARGB(255, 173, 255, 91)),
                const SizedBox(width: 24),
                _circleEye(color: const Color.fromARGB(255, 173, 255, 91)),
              ],
            ),
            const SizedBox(height: 8),
            Icon(Icons.sentiment_satisfied, color: Color.fromARGB(255, 173, 255, 91), size: 32),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _ovalEye({required Color color}) => Container(
        width: 32,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      );
  Widget _rectEye({required Color color}) => Container(
        width: 36,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      );
  Widget _circleEye({required Color color}) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
} 