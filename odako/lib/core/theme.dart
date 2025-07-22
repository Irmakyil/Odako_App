import 'package:flutter/material.dart';

class AppTheme {
  // ADHD-friendly color palette
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color secondaryBlue = Color(0xFF7BB3F0);
  static const Color calmGreen = Color(0xFF7ED321);
  static const Color softYellow = Color(0xFFFFD93D);
  static const Color gentleOrange = Color(0xFFFF9F43);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color mediumGray = Color(0xFFE9ECEF);
  static const Color darkGray = Color(0xFF6C757D);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color errorRed = Color(0xFFE74C3C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [calmGreen, Color(0xFF95E1A5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: darkGray,
  );

  // Border radius
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // Padding
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}
