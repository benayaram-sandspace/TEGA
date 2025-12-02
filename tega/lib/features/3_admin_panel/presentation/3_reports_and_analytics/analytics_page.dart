import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboardStyles.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Using SliverPadding for consistent spacing of the content.
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildModuleUsageCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Skill Growth',
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 16),
                    _buildSkillGrowthCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Top Performing Students',
                      icon: Icons.star_border,
                    ),
                    const SizedBox(height: 16),
                    _buildTopStudentsCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String metric,
    required String timeframe,
    required Widget chart,
    IconData? headerIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(20), // Softer corners
        boxShadow: [
          BoxShadow(
            color: AdminDashboardStyles.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (headerIcon != null) ...[
                Icon(
                  headerIcon,
                  color: AdminDashboardStyles.textLight,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metric,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeframe,
            style: TextStyle(
              fontSize: 14,
              color: AdminDashboardStyles.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }

  /// A more distinct section header with an optional icon.
  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AdminDashboardStyles.textDark, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AdminDashboardStyles.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleUsageCard() {
    return _buildAnalyticsCard(
      title: 'Module Engagement',
      metric: '100%',
      timeframe: 'Last 30 Days',
      headerIcon: Icons.widgets_outlined,
      chart: _buildModuleUsageChart(),
    );
  }

  /// An enhanced BarChart with gradients and touch interactivity.
  Widget _buildModuleUsageChart() {
    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          maxY: 100,
          // Adding touch data for interactivity
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.deepBlue,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
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
                  final style = TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Skill Drill';
                      break;
                    case 1:
                      text = 'Resume'; // Shortened for better fit
                      break;
                    case 2:
                      text = 'Interviews';
                      break;
                    default:
                      text = '';
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: style),
                  );
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: [
            _buildBarGroupData(0, 100, AppColors.primary),
            _buildBarGroupData(1, 100, AppColors.info),
            _buildBarGroupData(2, 100, AppColors.mutedPurple),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 25,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          // Using gradients for a more modern look
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillGrowthCard() {
    return _buildAnalyticsCard(
      title: 'Skill Growth Report',
      metric: '+15%',
      timeframe: 'Last 6 Months',
      headerIcon: Icons.show_chart,
      chart: _buildSkillGrowthChart(),
    );
  }

  /// An enhanced LineChart with a gradient area, visible dots, and interactivity.
  Widget _buildSkillGrowthChart() {
    final List<Color> gradientColors = [AppColors.primary, AppColors.info];
    return SizedBox(
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
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Jan';
                      break;
                    case 1:
                      text = 'Feb';
                      break;
                    case 2:
                      text = 'Mar';
                      break;
                    case 3:
                      text = 'Apr';
                      break;
                    case 4:
                      text = 'May';
                      break;
                    case 5:
                      text = 'Jun';
                      break;
                    default:
                      text = '';
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: style),
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
          // Adding touch data for interactivity
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.deepBlue,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toStringAsFixed(1)} score',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4.5),
                FlSpot(5, 5.5),
              ],
              isCurved: true,
              gradient: LinearGradient(colors: gradientColors),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true), // Show dots on the line
              // Filling the area below the line with a gradient
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStudentsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStudentTile('David', 'Computer Science', 1),
          _buildStudentTile('Ruth', 'Artificial Intelligence', 2),
          _buildStudentTile('Noah Thompson', 'Machine Learning', 3),
        ],
      ),
    );
  }

  /// Using ListTile for a more structured and conventional list item.
  Widget _buildStudentTile(String name, String field, int rank) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        field,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        // TODO: Navigate to student's profile page
      },
    );
  }
}
