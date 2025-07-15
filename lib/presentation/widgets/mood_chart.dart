import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class MoodChart extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;
  final double? height;

  const MoodChart({
    super.key,
    this.moodData = AppConstants.mockWeeklyMood,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final maxMood = moodData.fold<int>(
      1,
      (max, day) => day['mood'] > max ? day['mood'] : max,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppTheme.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Mood',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: AppTheme.smallPadding),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: moodData.map((day) {
                final moodValue = day['mood'] as int;
                final height = (moodValue / maxMood) * 100;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: height,
                          decoration: BoxDecoration(
                            color: Color(day['color']),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day['day'],
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
