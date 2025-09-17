import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class _ReportInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const _ReportInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  final List<_ReportInfo> _reports = const [
    _ReportInfo(
      title: 'Monthly Report',
      subtitle: 'September 2025',
      icon: Icons.calendar_month_rounded,
      color: DashboardStyles.primary,
    ),
    _ReportInfo(
      title: 'Attendance Report',
      subtitle: '92% Average',
      icon: Icons.check_circle_outline_rounded,
      color: DashboardStyles.accentGreen,
    ),
    _ReportInfo(
      title: 'Performance Report',
      subtitle: 'Q3 2025',
      icon: Icons.trending_up_rounded,
      color: DashboardStyles.accentOrange,
    ),
    _ReportInfo(
      title: 'Financial Report',
      subtitle: 'Budget Analysis',
      icon: Icons.attach_money_rounded,
      color: DashboardStyles.accentPurple,
    ),
    _ReportInfo(
      title: 'Student Demographics',
      subtitle: '3,125 Total',
      icon: Icons.people_outline_rounded,
      color: DashboardStyles.accentTeal,
    ),
    _ReportInfo(
      title: 'Custom Report',
      subtitle: 'Generate New',
      icon: Icons.add_chart_rounded,
      color: DashboardStyles.textLight,
      isCustom: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      _reports.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 450),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _animationControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) {
            _animationControllers[i].forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          return ScaleTransition(
            scale: _scaleAnimations[index],
            child: _buildReportCard(_reports[index]),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(_ReportInfo report) {
    if (report.isCustom) {
      return _buildCustomReportCard(report);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [report.color, report.color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: report.color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(report.icon, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  report.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomReportCard(_ReportInfo report) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: DottedBorder(
        color: Colors.grey.shade400,
        strokeWidth: 2,
        dashPattern: const [8, 6],
        borderType: BorderType.RRect,
        radius: const Radius.circular(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(report.icon, color: Colors.grey.shade600, size: 40),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for the dashed border.
// You might need to add the `dotted_border` package or use this custom painter.
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;
  final BorderType borderType;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashPattern = const <double>[3, 1],
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.Rect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
        radius: radius,
        borderType: borderType,
      ),
      child: child,
    );
  }
}

enum BorderType { Rect, RRect, Oval, Circle }

class _DottedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;
  final BorderType borderType;

  _DottedPainter({
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashPattern = const <double>[3, 1],
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.Rect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path;
    switch (borderType) {
      case BorderType.RRect:
        path = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.width, size.height),
              radius,
            ),
          );
        break;
      case BorderType.Rect:
        path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
        break;
      case BorderType.Oval:
        path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
        break;
      case BorderType.Circle:
        path = Path()
          ..addOval(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2,
            ),
          );
        break;
    }

    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashPattern[0]),
          Offset.zero,
        );
        distance += dashPattern[0];
        distance += dashPattern[1];
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
