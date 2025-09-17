import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Helper class for metric data
class _MetricInfo {
  final String title;
  final double value; // Value from 0.0 to 1.0
  final Color color;

  const _MetricInfo(this.title, this.value, this.color);
}

class PerformanceMetrics extends StatefulWidget {
  const PerformanceMetrics({super.key});

  @override
  State<PerformanceMetrics> createState() => _PerformanceMetricsState();
}

class _PerformanceMetricsState extends State<PerformanceMetrics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _animationStarted = false;

  final List<_MetricInfo> _metrics = const [
    _MetricInfo('Average Score', 0.85, DashboardStyles.accentGreen),
    _MetricInfo('Attendance', 0.92, DashboardStyles.primary),
    _MetricInfo('Completion', 0.78, DashboardStyles.accentOrange),
    _MetricInfo('Satisfaction', 0.88, DashboardStyles.accentPurple),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('performance-metrics-card'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_animationStarted) {
          setState(() {
            _animationStarted = true;
            _animationController.forward();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DashboardStyles.cardBackground,
              Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.04)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: DashboardStyles.sectionTitle,
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final metric = _metrics[index];
                return _buildMetricCard(metric);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(_MetricInfo metric) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            // MODIFICATION: This AspectRatio widget forces the child (the circle)
            // to be a perfect square, preventing any stretching.
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            metric.color.withOpacity(0.1),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CircularProgressIndicator(
                          value: metric.value * _animation.value,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            metric.color,
                          ),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: metric.value * _animation.value,
                        ),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Text(
                            '${(value * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: DashboardStyles.textDark,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // MODIFICATION: Increased spacing for better balance.
          const SizedBox(height: 16),
          Text(
            metric.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DashboardStyles.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
