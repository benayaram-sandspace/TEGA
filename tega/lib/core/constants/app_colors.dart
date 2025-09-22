import 'package:flutter/material.dart';

class AppColors {
  // Primary Color Palette from the provided image
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkBrown = Color(0xFF2D1810);
  static const Color lightGray = Color(0xFFE5E5E5);
  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color warmOrange = Color(0xFFFDB827);
  static const Color mutedPurple = Color(0xFF6B7280);

  // Additional shades and variations
  static const Color whiteShade1 = Color(0xFFFAFAFA);
  static const Color whiteShade2 = Color(0xFFF5F5F5);
  static const Color whiteShade3 = Color(0xFFEEEEEE);

  static const Color brownShade1 = Color(0xFF4A2C1A);
  static const Color brownShade2 = Color(0xFF3D1F12);
  static const Color brownShade3 = Color(0xFF1A0F08);

  static const Color grayShade1 = Color(0xFFF0F0F0);
  static const Color grayShade2 = Color(0xFFD0D0D0);
  static const Color grayShade3 = Color(0xFFB0B0B0);
  static const Color grayShade4 = Color(0xFF909090);
  static const Color grayShade5 = Color(0xFF707070);

  static const Color blueShade1 = Color(0xFF3B82F6);
  static const Color blueShade2 = Color(0xFF2563EB);
  static const Color blueShade3 = Color(0xFF1D4ED8);
  static const Color blueShade4 = Color(0xFF1E40AF);

  static const Color orangeShade1 = Color(0xFFFDCB47); // Lighter yellow
  static const Color orangeShade2 = Color(0xFFFDB827); // Same as warmOrange
  static const Color orangeShade3 = Color(0xFFE6A023); // Darker yellow
  static const Color orangeShade4 = Color(0xFFCC8A1F); // Darkest yellow

  static const Color purpleShade1 = Color(0xFF9CA3AF);
  static const Color purpleShade2 = Color(0xFF6B7280);
  static const Color purpleShade3 = Color(0xFF4B5563);
  static const Color purpleShade4 = Color(0xFF374151);

  // Semantic colors for UI components
  static const Color primary = warmOrange;
  static const Color primaryDark = orangeShade4;
  static const Color primaryLight = orangeShade1;

  static const Color secondary = deepBlue;
  static const Color secondaryDark = blueShade4;
  static const Color secondaryLight = blueShade1;

  static const Color accent = mutedPurple;
  static const Color accentDark = purpleShade4;
  static const Color accentLight = purpleShade1;

  static const Color background = pureWhite;
  static const Color surface = whiteShade1;
  static const Color surfaceVariant = whiteShade2;

  static const Color textPrimary = darkBrown;
  static const Color textSecondary = grayShade5;
  static const Color textDisabled = grayShade3;

  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color info = blueShade1;

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [warmOrange, orangeShade1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [deepBlue, blueShade1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [mutedPurple, purpleShade1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Border colors
  static const Color borderLight = lightGray;
  static const Color borderMedium = grayShade2;
  static const Color borderDark = grayShade4;
}
