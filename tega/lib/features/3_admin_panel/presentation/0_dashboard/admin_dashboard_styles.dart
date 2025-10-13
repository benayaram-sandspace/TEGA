import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';

class AdminDashboardStyles {
  // Admin-specific color palette with orange theme
  static const Color background = Color(0xFFFEF7F0); // Warm orange-tinted background
  static const Color cardBackground = Colors.white;
  static const Color primary = AppColors.warmOrange;
  static const Color primaryLight = AppColors.orangeShade1;
  static const Color primaryDark = AppColors.orangeShade4;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;
  static const Color iconLight = Color(0xFFB0B8C8);
  static const Color surface = Colors.white;
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color pureWhite = Colors.white;
  static const Color shadowLight = Color(0xFFE0E0E0);

  // Admin-specific accent colors
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentRed = Color(0xFFF4511E);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF00BCD4);
  static const Color accentOrange = Color(0xFFFF9800);

  // Status colors for admin panel
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusError = Color(0xFFF44336);

  // Priority colors for admin tasks
  static const Color priorityHighBg = Color(0xFFFBE9E7);
  static const Color priorityHighText = Color(0xFFD32F2F);
  static const Color priorityMediumBg = Color(0xFFFFF3E0);
  static const Color priorityMediumText = Color(0xFFF57C00);
  static const Color priorityLowBg = Color(0xFFE8F5E8);
  static const Color priorityLowText = Color(0xFF4CAF50);

  // TextStyles for admin dashboard
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
  
  static const TextStyle statTitle = TextStyle(
    color: textLight, 
    fontSize: 13,
  );
  
  static const TextStyle insightTitle = TextStyle(
    fontWeight: FontWeight.w500,
    color: textDark,
    fontSize: 14,
  );
  
  static const TextStyle priorityTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );

  // Card decoration styles
  static BoxDecoration getCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          cardBackground,
          Color.lerp(cardBackground, Colors.black, 0.02)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor?.withValues(alpha: 0.2) ?? primary.withValues(alpha: 0.2), 
        width: 1
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Button styles
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: primary),
      foregroundColor: primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Animation curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve slideCurve = Curves.easeInOutCubic;
}
