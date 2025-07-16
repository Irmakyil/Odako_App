import 'package:flutter/material.dart';

class MoodFace extends StatelessWidget {
  final int moodIndex; // 0: Meh, 1: Not Bad, 2: Good
  const MoodFace({super.key, required this.moodIndex});

  @override
  Widget build(BuildContext context) {
    switch (moodIndex) {
      case 0:
        // MEH
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ovalEye(color: const Color(0xFF7B4B4B)),
                const SizedBox(width: 24),
                _ovalEye(color: const Color(0xFF7B4B4B)),
              ],
            ),
            const SizedBox(height: 8),
            Transform.rotate(
              angle: 3.14,
              child: Icon(Icons.sentiment_dissatisfied, color: Color(0xFF7B4B4B), size: 48),
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
                _rectEye(color: const Color(0xFF8B7B4B)),
                const SizedBox(width: 24),
                _rectEye(color: const Color(0xFF8B7B4B)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF8B7B4B),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      case 2:
        // GOOD
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleEye(color: const Color(0xFF6B8B4B)),
                const SizedBox(width: 24),
                _circleEye(color: const Color(0xFF6B8B4B)),
              ],
            ),
            const SizedBox(height: 8),
            Icon(Icons.sentiment_satisfied, color: Color(0xFF6B8B4B), size: 32),
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