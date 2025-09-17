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

class StudentProgress {
  final Student student;
  final double courseCompletion;
  final int mockTestsTaken;
  final int totalMockTests;
  final double engagementLevel;

  const StudentProgress({
    required this.student,
    required this.courseCompletion,
    required this.mockTestsTaken,
    required this.totalMockTests,
    required this.engagementLevel,
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

class StudentProgressDetailsPage extends StatefulWidget {
  final StudentProgress progressData;

  const StudentProgressDetailsPage({super.key, required this.progressData});

  @override
  State<StudentProgressDetailsPage> createState() =>
      _StudentProgressDetailsPageState();
}

class _StudentProgressDetailsPageState extends State<StudentProgressDetailsPage>
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildTimeline()),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline() {
    final courses = [
      {
        'name': 'Data Structures',
        'value': 0.95,
        'color': DashboardStyles.accentGreen,
      },
      {
        'name': 'Algorithms',
        'value': 0.80,
        'color': DashboardStyles.accentGreen,
      },
      {
        'name': 'Operating Systems',
        'value': 0.60,
        'color': DashboardStyles.accentOrange,
      },
      {'name': 'Databases', 'value': 0.25, 'color': DashboardStyles.accentRed},
    ];

    List<Widget> timelineEvents = [
      _buildTimelineHeader("Academics", Icons.school_outlined, 0),
      ...List.generate(courses.length, (index) {
        return _buildAnimatedTimelineEvent(
          index: index + 1,
          child: _buildCourseProgressEvent(
            courses[index]['name'] as String,
            courses[index]['value'] as double,
            courses[index]['color'] as Color,
          ),
        );
      }),
      _buildAnimatedTimelineEvent(
        index: courses.length + 1,
        child: _buildMockTestCard(),
      ),
      _buildTimelineHeader(
        "Engagement",
        Icons.insights_rounded,
        courses.length + 2,
      ),
      _buildAnimatedTimelineEvent(
        index: courses.length + 3,
        child: _buildEngagementEvent(
          Icons.video_library_outlined,
          DashboardStyles.accentPurple,
          'Lectures Viewed',
          '95%',
        ),
      ),
      _buildAnimatedTimelineEvent(
        index: courses.length + 4,
        isLast: true,
        child: _buildEngagementEvent(
          Icons.forum_outlined,
          DashboardStyles.accentOrange,
          'Forum Posts',
          '32',
        ),
      ),
    ];

    return timelineEvents;
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
              backgroundImage: NetworkImage(
                widget.progressData.student.avatarUrl,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.progressData.student.name,
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
                widget.progressData.student.statusColor.withOpacity(0.2),
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
                    backgroundImage: NetworkImage(
                      widget.progressData.student.avatarUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.progressData.student.name,
                  style: const TextStyle(
                    color: DashboardStyles.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overall Completion: ${(widget.progressData.courseCompletion * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTimelineEvent({
    required Widget child,
    required int index,
    bool isLast = false,
  }) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (0.1 * index).clamp(0.0, 1.0),
        (0.5 + 0.1 * index).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(animation),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimelineConnector(isLast: isLast),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineConnector({bool isLast = false}) {
    final Color color = widget.progressData.student.statusColor;

    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardStyles.cardBackground,
              border: Border.all(width: 2, color: Colors.grey.shade200),
            ),
            child: Icon(Icons.circle, size: 8, color: color),
          ),
          if (isLast)
            const Expanded(child: SizedBox())
          else
            Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader(String title, IconData icon, int index) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (0.1 * index).clamp(0.0, 1.0),
        (0.5 + 0.1 * index).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseProgressEvent(String course, double value, Color color) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                course,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Text(
                  '${(value * animation.value * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value * animation.value,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTestCard() {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    final mockScores = [75.0, 88.0, 82.0, 91.0, 85.0, 93.0];
    final averageScore = mockScores.reduce((a, b) => a + b) / mockScores.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mock Test Scores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Avg: ${averageScore.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DashboardStyles.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => BarChart(
                BarChartData(
                  maxY: 100,
                  alignment: BarChartAlignment.spaceBetween,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          DashboardStyles.primary.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Score: ${(rod.toY).round()}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 25,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
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
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'T${value.toInt() + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
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
                  barGroups: List.generate(
                    mockScores.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: mockScores[index] * animation.value,
                          gradient: LinearGradient(
                            colors: [
                              DashboardStyles.primary.withOpacity(0.7),
                              DashboardStyles.primary,
                            ],
                          ),
                          width: 14,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementEvent(
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: double.tryParse(value.replaceAll('%', '')) ?? 0.0,
            ),
            duration: const Duration(milliseconds: 800),
            builder: (context, animatedValue, child) {
              final displayValue = value.contains('%')
                  ? '${(animatedValue * animation.value).toInt()}%'
                  : (animatedValue * animation.value).toInt().toString();
              return Text(
                displayValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
