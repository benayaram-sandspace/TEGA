import 'package:flutter/material.dart';

/// Smooth animation utilities for better UX

/// Pre-configured smooth animations
class SmoothAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curves
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve snapCurve = Curves.easeOutExpo;

  /// Fade transition
  static Widget fade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// Scale transition
  static Widget scale({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(scale: animation, child: child);
  }

  /// Slide transition
  static Widget slide({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: smoothCurve)),
      child: child,
    );
  }

  /// Combined fade and slide
  static Widget fadeSlide({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(0.0, 0.3),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: smoothCurve)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Smooth page route transitions
class SmoothPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;
  final Curve curve;

  SmoothPageRoute({
    required this.child,
    this.duration = SmoothAnimations.normal,
    this.curve = SmoothAnimations.smoothCurve,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [0.0, _controller.value, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Staggered animation helper
class StaggeredAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration itemDuration;
  final Axis direction;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 50),
    this.itemDuration = SmoothAnimations.normal,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        children.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: itemDuration,
          curve: SmoothAnimations.smoothCurve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: direction == Axis.vertical
                  ? Offset(0, 20 * (1 - value))
                  : Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: children[index],
        ),
      ),
    );
  }
}

/// Animated counter
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = SmoothAnimations.normal,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: SmoothAnimations.smoothCurve,
      builder: (context, value, child) {
        return Text(value.toString(), style: style);
      },
    );
  }
}

/// Smooth animated list
class SmoothAnimatedList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const SmoothAnimatedList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        children.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: SmoothAnimations.normal + (staggerDelay * index),
          curve: SmoothAnimations.smoothCurve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: children[index],
        ),
      ),
    );
  }
}
