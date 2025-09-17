import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Helper class for chart data
class _ChartData {
  final String label;
  final double value;
  final Color color;
  const _ChartData(this.label, this.value, this.color);
}

class ProgressChartCard extends StatefulWidget {
  const ProgressChartCard({super.key});

  @override
  State<ProgressChartCard> createState() => _ProgressChartCardState();
}

class _ProgressChartCardState extends State<ProgressChartCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _animationStarted = false;

  // MODIFICATION: The chart data now reflects CSE subjects.
  final List<_ChartData> _chartData = const [
    _ChartData('Data Structures', 300, DashboardStyles.primary),
    _ChartData('Algorithms', 800, DashboardStyles.primary),
    _ChartData('OS', 500, DashboardStyles.accentGreen),
    _ChartData('DBMS', 1000, DashboardStyles.accentGreen),
    _ChartData('Networks', 1100, DashboardStyles.accentOrange),
    _ChartData('AI/ML', 400, DashboardStyles.primary),
    _ChartData('Web Dev', 200, DashboardStyles.accentRed),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animation.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('progress-chart-card'),
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
            _buildHeader(),
            const SizedBox(height: 24),
            AspectRatio(aspectRatio: 16 / 10, child: BarChart(_mainBarData())),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Student Progress', style: DashboardStyles.sectionTitle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Text(
                'This Week',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  BarChartData _mainBarData() {
    return BarChartData(
      maxY: 1200,
      alignment: BarChartAlignment.spaceBetween,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) =>
              group.barRods.first.gradient!.colors.last.withOpacity(0.9),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = _chartData[group.x.toInt()];
            return BarTooltipItem(
              '${data.label}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY).round().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _getBottomTitles,
            reservedSize: 42,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              if (value > 0 && value % 400 == 0) {
                return Text(
                  "${(value / 1000).toStringAsFixed(1)}k",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
          dashArray: [3, 4],
        ),
      ),
      barGroups: List.generate(_chartData.length, (index) {
        final data = _chartData[index];
        return _makeGroupData(index, data.value * _animation.value, data.color);
      }),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [barColor.withOpacity(0.8), barColor],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 15,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 1200,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: DashboardStyles.textLight,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    final label = _chartData[value.toInt()].label;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      angle: -math.pi / 4,
      child: Text(label, style: style, overflow: TextOverflow.ellipsis),
    );
  }
}
