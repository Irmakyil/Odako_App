import 'package:flutter/material.dart';

class MoodSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const MoodSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value.toDouble(),
      min: 0,
      max: 2,
      divisions: 2,
      label: _labelForValue(value),
      onChanged: (double newValue) {
        onChanged(newValue.round());
      },
    );
  }

  String _labelForValue(int value) {
    switch (value) {
      case 0:
        return 'MEH';
      case 1:
        return 'NOT BAD';
      case 2:
        return 'GOOD';
      default:
        return '';
    }
  }
} 