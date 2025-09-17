import 'package:flutter/material.dart';

class DashboardStyles {
  // Color Palette
  static const Color background = Color(0xFFF7F8FC);
  static const Color cardBackground = Colors.white;
  static const Color primary = Color(0xFF4A80F0);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF6E7E9A);
  static const Color iconLight = Color(0xFFB0B8C8);

  // Priority Colors
  static const Color priorityHighBg = Color(0xFFFBE9E7);
  static const Color priorityHighText = Color(0xFFD32F2F);
  static const Color priorityMediumBg = Color(0xFFFFF3E0);
  static const Color priorityMediumText = Color(0xFFF57C00);
  static const Color priorityLowBg = Color(0xFFE3F2FD);
  static const Color priorityLowText = Color(0xFF1E88E5);

  // Chart & Accent Colors
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color accentOrange = Color(0xFFFBC02D);
  static const Color accentRed = Color(0xFFF4511E);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF00BCD4);

  // TextStyles
  static const TextStyle welcomeHeader = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle statValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle statTitle = TextStyle(color: textLight, fontSize: 13);
  static const TextStyle insightTitle = TextStyle(
    fontWeight: FontWeight.w500,
    color: textDark,
    fontSize: 14,
  );
  static const TextStyle priorityTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
}
