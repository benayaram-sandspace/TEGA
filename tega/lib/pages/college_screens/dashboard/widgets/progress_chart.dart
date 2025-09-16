import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Progress',
                style: DashboardStyles.sectionTitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('This Week', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 150, child: BarChart(_mainBarData())),
        ],
      ),
    );
  }

  BarChartData _mainBarData() {
    return BarChartData(
      maxY: 1200,
      barTouchData: BarTouchData(enabled: false),
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
            reservedSize: 38,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value % 400 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  textAlign: TextAlign.left,
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
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      barGroups: _showingGroups(),
    );
  }

  List<BarChartGroupData> _showingGroups() => [
    _makeGroupData(0, 300, DashboardStyles.primary),
    _makeGroupData(1, 800, DashboardStyles.primary),
    _makeGroupData(2, 500, DashboardStyles.accentGreen),
    _makeGroupData(3, 1000, DashboardStyles.accentGreen),
    _makeGroupData(4, 1100, DashboardStyles.accentOrange),
    _makeGroupData(5, 400, DashboardStyles.primary),
    _makeGroupData(6, 200, DashboardStyles.accentRed),
  ];

  BarChartGroupData _makeGroupData(int x, double y, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
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
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Calculus', style: style);
        break;
      case 1:
        text = const Text('Biology', style: style);
        break;
      case 2:
        text = const Text('Strategy', style: style);
        break;
      case 3:
        text = const Text('History', style: style);
        break;
      case 4:
        text = const Text('Physics', style: style);
        break;
      case 5:
        text = const Text('Arts', style: style);
        break;
      case 6:
        text = const Text('Music', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 16.0, child: text);
  }
}
