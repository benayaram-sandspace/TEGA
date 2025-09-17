import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class Student {
  final String name;
  final int grade;
  final double gpa;
  final String avatarUrl;
  final String status;
  final Color statusColor;

  const Student({
    required this.name,
    required this.grade,
    required this.gpa,
    required this.avatarUrl,
    required this.status,
    required this.statusColor,
  });
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });
}

class StudentDetailsPage extends StatefulWidget {
  final Student student;

  const StudentDetailsPage({super.key, required this.student});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      final isCollapsed =
          _scrollController.hasClients &&
          _scrollController.offset > (200 - kToolbarHeight);
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedCard(index: 0, child: _buildStatsCard()),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  index: 1,
                  child: _buildPerformanceChartCard(),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(index: 2, child: _buildRecentActivityCard()),
                const SizedBox(height: 20),
                _buildAnimatedCard(index: 3, child: _buildContactCard()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      stretch: true,
      backgroundColor: DashboardStyles.cardBackground,
      foregroundColor: DashboardStyles.textDark,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCollapsed ? 1.0 : 0.0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.student.avatarUrl),
            ),
            const SizedBox(width: 12),
            Text(
              widget.student.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.student.statusColor.withOpacity(0.2),
                DashboardStyles.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isCollapsed ? 0.0 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: kToolbarHeight / 2),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundImage: NetworkImage(widget.student.avatarUrl),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.student.name,
                  style: const TextStyle(
                    color: DashboardStyles.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int index}) {
    final double start = (0.15 * index).clamp(0.0, 1.0);
    final double end = (start + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.star_border_rounded,
            'Grade',
            widget.student.grade.toString(),
          ),
          _buildStatItem(
            Icons.score_rounded,
            'GPA',
            widget.student.gpa.toStringAsFixed(1),
          ),
          _buildStatItem(Icons.checklist_rtl_rounded, 'Attendance', '92%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: DashboardStyles.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPerformanceChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Semester Performance (GPA)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [3, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => DashboardStyles.primary,
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            'GPA: ${spot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        switch (value.toInt()) {
                          case 1:
                            return const Text('S1', style: style);
                          case 3:
                            return const Text('S2', style: style);
                          case 5:
                            return const Text('S3', style: style);
                          case 7:
                            return const Text('S4', style: style);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3.1),
                      FlSpot(2, 3.5),
                      FlSpot(4, 3.0),
                      FlSpot(6, 3.8),
                      FlSpot(8, 3.7),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [
                        DashboardStyles.primary,
                        DashboardStyles.accentGreen,
                      ],
                    ),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          DashboardStyles.primary.withOpacity(0.2),
                          DashboardStyles.accentGreen.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final activities = [
      _ActivityItem(
        icon: Icons.assignment_turned_in_outlined,
        color: DashboardStyles.accentGreen,
        title: 'Submitted "Data Structures" assignment',
        time: 'Yesterday',
      ),
      _ActivityItem(
        icon: Icons.book_outlined,
        color: DashboardStyles.primary,
        title: 'Attended "Algorithms" lecture',
        time: 'Sep 15, 2025',
      ),
      _ActivityItem(
        icon: Icons.cancel_outlined,
        color: DashboardStyles.accentRed,
        title: 'Missed "Operating Systems" class',
        time: 'Sep 14, 2025',
      ),
      _ActivityItem(
        icon: Icons.quiz_outlined,
        color: DashboardStyles.accentOrange,
        title: 'Completed "DBMS" quiz',
        time: 'Sep 12, 2025',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(activities.length, (index) {
            return _buildActivityTimelineTile(
              activities[index],
              isLast: index == activities.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineTile(
    _ActivityItem activity, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.icon, color: activity.color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (!isLast) const Divider(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(
              '${widget.student.name.replaceAll(' ', '.').toLowerCase()}@tega.edu',
            ),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: const Text('+91 98765 43210'),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
