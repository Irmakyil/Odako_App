import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyProgressCircle extends StatelessWidget {
  final double size;
  final TextStyle? percentTextStyle;
  final Color? backgroundColor;
  final Color? progressColor;
  final Alignment alignment;
  final EdgeInsetsGeometry? margin;
  final bool showLabel;

  const DailyProgressCircle({
    super.key,
    this.size = 100,
    this.percentTextStyle,
    this.backgroundColor,
    this.progressColor,
    this.alignment = Alignment.center,
    this.margin,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildCircle(context, 0, 0, 0);
    }
    final now = DateTime.now();
    final twentyFourHoursAgo = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('selectedTasks')
        .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
        .snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int total = 0;
        int completed = 0;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          completed = docs.where((doc) => (doc['isCompleted'] ?? false) == true).length;
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildCircle(context, total, completed, total == 0 ? 0 : completed / total),
        );
      },
    );
  }

  Widget _buildCircle(BuildContext context, int total, int completed, double percent) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color bg;
    try {
      bg = (colorScheme as dynamic).surfaceContainerHighest ?? colorScheme.surface;
    } catch (_) {
      bg = colorScheme.surface;
    }
    const Color fixedProgressColor = Color(0xFFE7A0CC);

    final percentText = total == 0 ? '--%' : '${(percent * 100).round()}%';
    return Container(
      key: ValueKey(percentText),
      alignment: alignment,
      margin: margin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : percent,
              backgroundColor: backgroundColor ?? bg,
              color: fixedProgressColor,
              strokeWidth: size * 0.10,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percentText,
                style: percentTextStyle ?? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: size * 0.22),
              ),
              if (showLabel)
                Text(
                  'Today',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: size * 0.13),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
