import 'package:flutter/material.dart';
import 'package:tega/core/utils/responsive_size.dart';

/// Responsive text styles that scale with screen size
class ResponsiveTextStyles {
  final BuildContext context;
  late final ResponsiveSize _rs;

  ResponsiveTextStyles(this.context) {
    _rs = ResponsiveSize(context);
  }

  /// Display styles (largest)
  TextStyle get displayLarge => TextStyle(
        fontSize: _rs.sp(32),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  TextStyle get displayMedium => TextStyle(
        fontSize: _rs.sp(28),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  TextStyle get displaySmall => TextStyle(
        fontSize: _rs.sp(24),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  /// Headline styles
  TextStyle get headlineLarge => TextStyle(
        fontSize: _rs.sp(22),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  TextStyle get headlineMedium => TextStyle(
        fontSize: _rs.sp(20),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  TextStyle get headlineSmall => TextStyle(
        fontSize: _rs.sp(18),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// Title styles
  TextStyle get titleLarge => TextStyle(
        fontSize: _rs.sp(16),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  TextStyle get titleMedium => TextStyle(
        fontSize: _rs.sp(14),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  TextStyle get titleSmall => TextStyle(
        fontSize: _rs.sp(12),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Body styles
  TextStyle get bodyLarge => TextStyle(
        fontSize: _rs.sp(16),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get bodyMedium => TextStyle(
        fontSize: _rs.sp(14),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get bodySmall => TextStyle(
        fontSize: _rs.sp(12),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  /// Label styles
  TextStyle get labelLarge => TextStyle(
        fontSize: _rs.sp(14),
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  TextStyle get labelMedium => TextStyle(
        fontSize: _rs.sp(12),
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  TextStyle get labelSmall => TextStyle(
        fontSize: _rs.sp(10),
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// Button text style
  TextStyle get button => TextStyle(
        fontSize: _rs.sp(14),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  /// Caption style
  TextStyle get caption => TextStyle(
        fontSize: _rs.sp(10),
        fontWeight: FontWeight.normal,
        height: 1.3,
      );

  /// Overline style
  TextStyle get overline => TextStyle(
        fontSize: _rs.sp(10),
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.3,
      );
}

/// Extension on BuildContext for easy access
extension ResponsiveTextStylesExtension on BuildContext {
  ResponsiveTextStyles get textStyles => ResponsiveTextStyles(this);
}

