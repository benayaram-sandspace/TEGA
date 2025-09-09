import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/services/college_service.dart';


class CollegeAnalyticsPage extends StatefulWidget {
  final College college;

  const CollegeAnalyticsPage({super.key, required this.college});

  @override
  State<CollegeAnalyticsPage> createState() => _CollegeAnalyticsPageState();
}

class _CollegeAnalyticsPageState extends State<CollegeAnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module Usage Section
            _buildSectionTitle('Module Usage'),
            const SizedBox(height: 16),
            _buildModuleUsageCard(),
            const SizedBox(height: 24),

            // Skill Growth Section
            _buildSectionTitle('Skill Growth'),
            const SizedBox(height: 16),
            _buildSkillGrowthCard(),
            const SizedBox(height: 24),

            // Top Performing Students Section
            _buildSectionTitle('Top Performing Students'),
            const SizedBox(height: 16),
            _buildTopStudentsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModuleUsageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Module Usage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Main metric
          const Text(
            '100%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          
          // Timeframe
          Text(
            'Last 30 Days',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          // Bar chart
          _buildModuleUsageChart(),
        ],
      ),
    );
  }

  Widget _buildModuleUsageChart() {
    return Container(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  );
                  Widget text;
                  switch (value.toInt()) {
                    case 0:
                      text = const Text('Skill Drill', style: style);
                      break;
                    case 1:
                      text = const Text('Resume Optimizer', style: style);
                      break;
                    case 2:
                      text = const Text('Interviews', style: style);
                      break;
                    default:
                      text = const Text('', style: style);
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: text,
                  );
                },
                reservedSize: 42,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: 100,
                  color: AppColors.mutedPurple,
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: 100,
                  color: AppColors.mutedPurple,
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: 100,
                  color: AppColors.mutedPurple,
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGrowthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Skill Growth Report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Main metric
          const Text(
            '+15%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          
          // Timeframe
          Text(
            'Last 6 Months',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          // Line chart
          _buildSkillGrowthChart(),
        ],
      ),
    );
  }

  Widget _buildSkillGrowthChart() {
    return Container(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  );
                  Widget text;
                  switch (value.toInt()) {
                    case 0:
                      text = const Text('Jan', style: style);
                      break;
                    case 1:
                      text = const Text('Feb', style: style);
                      break;
                    case 2:
                      text = const Text('Mar', style: style);
                      break;
                    case 3:
                      text = const Text('Apr', style: style);
                      break;
                    case 4:
                      text = const Text('May', style: style);
                      break;
                    case 5:
                      text = const Text('Jun', style: style);
                      break;
                    default:
                      text = const Text('', style: style);
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: text,
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(1, 4),
                const FlSpot(2, 3.5),
                const FlSpot(3, 5),
                const FlSpot(4, 4.5),
                const FlSpot(5, 5.5),
              ],
              isCurved: true,
              color: AppColors.info,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStudentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStudentItem(
            'David',
            'Computer Science',
            AppColors.info,
            Icons.person,
          ),
          const SizedBox(height: 16),
          _buildStudentItem(
            'Ruth',
            'Artificial Intelligence',
            AppColors.primary,
            Icons.person,
          ),
          const SizedBox(height: 16),
          _buildStudentItem(
            'Noah Thompson',
            'Machine Learning',
            AppColors.primary,
            Icons.person,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(String name, String field, Color avatarColor, IconData icon) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.pureWhite,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        
        // Student info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              const SizedBox(height: 4),
              Text(
                field,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

}