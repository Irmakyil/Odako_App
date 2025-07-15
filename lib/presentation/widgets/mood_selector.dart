import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class MoodSelector extends StatelessWidget {
  final String? selectedMoodId;
  final Function(String moodId)? onMoodSelected;

  const MoodSelector({
    super.key,
    this.selectedMoodId,
    this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
          child: Text(
            'How are you feeling?',
            style: AppTheme.headingSmall,
          ),
        ),
        const SizedBox(height: AppTheme.smallPadding),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
            itemCount: AppConstants.mockMoods.length,
            itemBuilder: (context, index) {
              final mood = AppConstants.mockMoods[index];
              final isSelected = selectedMoodId == mood['id'];
              
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.smallPadding),
                child: GestureDetector(
                  onTap: () => onMoodSelected?.call(mood['id']),
                  child: AnimatedContainer(
                    duration: AppConstants.shortAnimation,
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(mood['color']).withValues(alpha: 0.2)
                          : AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: isSelected
                          ? Border.all(
                              color: Color(mood['color']),
                              width: 2,
                            )
                          : null,
                      boxShadow: isSelected ? AppTheme.cardShadow : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mood['emoji'],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mood['name'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected 
                                ? Color(mood['color'])
                                : AppTheme.darkGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
