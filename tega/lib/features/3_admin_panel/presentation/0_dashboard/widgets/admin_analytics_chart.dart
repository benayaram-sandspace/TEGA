import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _AdminChartData {
  final String day;
  final double value;

  const _AdminChartData(this.day, this.value);
}

class AdminAnalyticsChart extends StatefulWidget {
  final AnimationController animationController;

  const AdminAnalyticsChart({super.key, required this.animationController});

  @override
  State<AdminAnalyticsChart> createState() => _AdminAnalyticsChartState();
}

class _AdminAnalyticsChartState extends State<AdminAnalyticsChart>
    with TickerProviderStateMixin {
  late AnimationController _chartAnimationController;
  late Animation<double> _barAnimation;
  bool _animationStarted = false;

  final List<_AdminChartData> _weekData = const [
    _AdminChartData('Mon', 45),
    _AdminChartData('Tue', 68),
    _AdminChartData('Wed', 52),
    _AdminChartData('Thu', 85),
    _AdminChartData('Fri', 93),
    _AdminChartData('Sat', 71),
    _AdminChartData('Sun', 34),
  ];

  static final Map<String, Map<String, String>> _translations = {
    'EN': {'analytics_chart_title': 'Weekly Student Signups'},
  };

  String _tr(String key) => _translations['EN']![key] ?? key;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _barAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _barAnimation.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: VisibilityDetector(
          key: const Key('admin-analytics-chart'),
          onVisibilityChanged: (visibilityInfo) {
            if (visibilityInfo.visibleFraction > 0.1 && !_animationStarted) {
              setState(() {
                _animationStarted = true;
                _chartAnimationController.forward();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                AspectRatio(aspectRatio: 1.7, child: BarChart(_mainBarData())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _tr('analytics_chart_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFA726),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFFFFA726),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _mainBarData() {
    return BarChartData(
      maxY: 120,
      alignment: BarChartAlignment.spaceBetween,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => const Color(0xFFFFA726),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = _weekData[group.x.toInt()];
            return BarTooltipItem(
              '${data.day}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY).round().toString(),
                  style: const TextStyle(color: Colors.yellow),
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
            getTitlesWidget: (value, meta) {
              final style = TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(_weekData[value.toInt()].day, style: style),
              );
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value % 40 != 0) {
                return const SizedBox.shrink();
              }
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              );
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
      barGroups: List.generate(_weekData.length, (index) {
        return _makeGroupData(
          index,
          _weekData[index].value * _barAnimation.value,
        );
      }),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFA726).withOpacity(0.7),
              const Color(0xFFFFA726),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 20,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 120,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}
