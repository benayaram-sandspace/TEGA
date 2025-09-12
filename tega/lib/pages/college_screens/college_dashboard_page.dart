import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// A centralized class for styles and colors to ensure UI uniformity.
class DashboardStyles {
  // Color Palette
  static const Color background = Color(0xFFF7F8FC);
  static const Color cardBackground = Colors.white;
  static const Color primary = Color(0xFF4A80F0);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF6E7E9A);
  static const Color iconLight = Color(0xFFB0B8C8);

  // Priority Colors
  static const Color priorityHighBg = Color(0xFFFBE9E7);
  static const Color priorityHighText = Color(0xFFD32F2F);
  static const Color priorityMediumBg = Color(0xFFFFF3E0);
  static const Color priorityMediumText = Color(0xFFF57C00);
  static const Color priorityLowBg = Color(0xFFE3F2FD);
  static const Color priorityLowText = Color(0xFF1E88E5);

  // Chart & Accent Colors
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color accentOrange = Color(0xFFFBC02D);
  static const Color accentRed = Color(0xFFF4511E);

  // TextStyles
  static const TextStyle welcomeHeader = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle statValue = TextStyle(
    fontSize: 18, // Reduced from 20 for better fit
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle statTitle = TextStyle(color: textLight, fontSize: 13);
  static const TextStyle insightTitle = TextStyle(
    fontWeight: FontWeight.w500,
    color: textDark,
    fontSize: 14,
  );
  static const TextStyle priorityTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
}

// Main dashboard screen widget
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildWelcomeHeader(),
              const SizedBox(height: 32),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildProgressChartCard(),
              const SizedBox(height: 32),
              _buildActionableInsights(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Welcome Header Widget
  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          CrossAxisAlignment.center, // Vertically center align items
      children: [
        const Flexible(
          // Wrap with Flexible to prevent overflow
          child: Text(
            'Welcome, Sarah!',
            style: DashboardStyles.welcomeHeader,
            overflow: TextOverflow.ellipsis, // Handle long text gracefully
          ),
        ),
        const SizedBox(width: 16), // Add spacing for smaller screens
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
            radius: 22,
          ),
        ),
      ],
    );
  }

  // Statistics Cards Grid - more responsive and uniform
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0, // Adjusted to 1.0 for better vertical spacing
      children: [
        _buildStatCard(
          'Enrolled Students',
          '3,125',
          Icons.people_outline,
          DashboardStyles.primary,
        ),
        _buildStatCard(
          'Engagement',
          '72%',
          Icons.timeline,
          DashboardStyles.accentGreen,
        ),
        _buildStatCard(
          'Top Course',
          'Data Science',
          Icons.school_outlined,
          DashboardStyles.accentOrange,
        ),
      ],
    );
  }

  // Reusable card for statistics with a more modern, icon-focused design.
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24), // Reduced from 28
          const SizedBox(height: 8), // Reduced from 12
          Text(value, style: DashboardStyles.statValue),
          const SizedBox(height: 4),
          Flexible(
            // Added Flexible to allow text to wrap without overflow
            child: Text(
              title,
              style: DashboardStyles.statTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Student Progress Chart Card
  Widget _buildProgressChartCard() {
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
          const Text(
            'Student Progress Overview',
            style: DashboardStyles.sectionTitle,
          ),
          const SizedBox(height: 20),
          SizedBox(height: 150, child: BarChart(_mainBarData())),
        ],
      ),
    );
  }

  // Actionable Insights Section
  Widget _buildActionableInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actionable Insights', style: DashboardStyles.sectionTitle),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: Icons.school_outlined,
          iconColor: DashboardStyles.accentRed,
          title: '5 students require academic advising',
          priority: 'High priority',
        ),
        _buildInsightCard(
          icon: Icons.book_outlined,
          iconColor: DashboardStyles.accentOrange,
          title: 'New curriculum update available',
          priority: 'Medium priority',
        ),
        _buildInsightCard(
          icon: Icons.trending_up_outlined,
          iconColor: DashboardStyles.primary,
          title: 'Enrollment trends for Q4 available',
          priority: 'Low priority',
        ),
      ],
    );
  }

  // Reusable card for insights, with priority colors handled internally.
  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String priority,
  }) {
    Color priorityBgColor;
    Color priorityTextColor;

    switch (priority.toLowerCase()) {
      case 'high priority':
        priorityBgColor = DashboardStyles.priorityHighBg;
        priorityTextColor = DashboardStyles.priorityHighText;
        break;
      case 'medium priority':
        priorityBgColor = DashboardStyles.priorityMediumBg;
        priorityTextColor = DashboardStyles.priorityMediumText;
        break;
      default: // Low priority
        priorityBgColor = DashboardStyles.priorityLowBg;
        priorityTextColor = DashboardStyles.priorityLowText;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashboardStyles.insightTitle),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: priorityBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: DashboardStyles.priorityTag.copyWith(
                      color: priorityTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: DashboardStyles.iconLight),
        ],
      ),
    );
  }

  // Bottom Navigation Bar Widget
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Students',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up_outlined),
          activeIcon: Icon(Icons.trending_up),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_activity_outlined),
          activeIcon: Icon(Icons.local_activity),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: DashboardStyles.primary,
      unselectedItemColor: DashboardStyles.textLight,
      onTap: _onItemTapped,
      backgroundColor: DashboardStyles.cardBackground,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 5,
    );
  }

  // Data and configuration for the bar chart
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

  // Groups of bars for the chart using the consistent color palette
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

  // Widget for the bottom titles (labels) of the chart
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
