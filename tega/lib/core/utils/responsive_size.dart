import 'package:flutter/material.dart';

/// Responsive sizing utilities for consistent layouts across devices
class ResponsiveSize {
  final BuildContext context;
  late final double _width;
  late final double _height;
  late final double _diagonal;

  ResponsiveSize(this.context) {
    final size = MediaQuery.of(context).size;
    _width = size.width;
    _height = size.height;
    _diagonal = size.shortestSide;
  }

  /// Screen width
  double get width => _width;

  /// Screen height
  double get height => _height;

  /// Responsive width percentage (0.0 - 1.0)
  double wp(double percentage) => _width * percentage / 100;

  /// Responsive height percentage (0.0 - 1.0)
  double hp(double percentage) => _height * percentage / 100;

  /// Responsive font size based on width
  double sp(double size) => size * _width / 375; // 375 is base width (iPhone SE)

  /// Responsive spacing
  double space(double size) => size * _diagonal / 375;

  /// Breakpoints
  bool get isMobile => _width < 600;
  bool get isTablet => _width >= 600 && _width < 1024;
  bool get isDesktop => _width >= 1024;
  bool get isSmallMobile => _width < 360;
  bool get isLargeMobile => _width >= 360 && _width < 600;

  /// Responsive value based on device type
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get padding scaled to screen size
  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: space(left ?? horizontal ?? all ?? 0),
      right: space(right ?? horizontal ?? all ?? 0),
      top: space(top ?? vertical ?? all ?? 0),
      bottom: space(bottom ?? vertical ?? all ?? 0),
    );
  }

  /// Get margin scaled to screen size
  EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return padding(
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }

  /// Get responsive border radius
  BorderRadius borderRadius(double radius) {
    return BorderRadius.circular(space(radius));
  }

  /// Get icon size
  double iconSize(double size) => space(size);

  /// Get button height
  double buttonHeight() => hp(6);

  /// Get app bar height
  double appBarHeight() => hp(7);

  /// Get card elevation
  double cardElevation() => space(2);
}

/// Extension on BuildContext for easy access
extension ResponsiveSizeExtension on BuildContext {
  ResponsiveSize get rs => ResponsiveSize(this);
}

/// Responsive breakpoint helper
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
}

/// Responsive spacing constants
class ResponsiveSpacing {
  static double xs(BuildContext context) => ResponsiveSize(context).space(4);
  static double sm(BuildContext context) => ResponsiveSize(context).space(8);
  static double md(BuildContext context) => ResponsiveSize(context).space(16);
  static double lg(BuildContext context) => ResponsiveSize(context).space(24);
  static double xl(BuildContext context) => ResponsiveSize(context).space(32);
  static double xxl(BuildContext context) => ResponsiveSize(context).space(48);
}

