import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Main widget for the Skills Hub screen
class SkillsHubScreen extends StatelessWidget {
  const SkillsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Refactored for theme consistency
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Skills Hub',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        // The header icon has been removed from the actions property.
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Skills Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The icon next to the title has been removed.
                  Text(
                    'My Skills',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _MySkillsSection(),
                ],
              ),
            ),

            // Recommended Courses Section
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Courses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _RecommendedCoursesSection(),
                ],
              ),
            ),

            // Activity Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Weekly Progress',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ActivitySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 1. "My Skills" Section ---
class _MySkillsSection extends StatelessWidget {
  const _MySkillsSection();

  @override
  Widget build(BuildContext context) {
    // Data using local asset paths for skill icons
    final List<Map<String, dynamic>> skills = [
      {
        'iconPath': 'assets/images/python_icon.png',
        'name': 'Python',
        'progress': 0.85,
        'percentage': '85%',
        'bgColor': Colors.blue[50],
        'progressColor': Colors.blue[600],
      },
      {
        'iconPath': 'assets/images/mobile_icon.png',
        'name': 'Mobile Development',
        'progress': 0.60,
        'percentage': '60%',
        'bgColor': Colors.green[50],
        'progressColor': Colors.green[600],
      },
      {
        'iconPath': 'assets/images/design_icon.png',
        'name': 'UI/UX Design',
        'progress': 0.70,
        'percentage': '70%',
        'bgColor': Colors.purple[50],
        'progressColor': Colors.purple[400],
      },
      {
        'iconPath': 'assets/images/dev_icon.png',
        'name': 'Development',
        'progress': 0.75,
        'percentage': '75%',
        'bgColor': Colors.red[50],
        'progressColor': Colors.red[400],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return _SkillCard(
          iconPath: skill['iconPath'],
          name: skill['name'],
          progress: skill['progress'],
          percentage: skill['percentage'],
          bgColor: skill['bgColor'],
          progressColor: skill['progressColor'],
        );
      },
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String iconPath;
  final String name;
  final double progress;
  final String percentage;
  final Color bgColor;
  final Color progressColor;

  const _SkillCard({
    required this.iconPath,
    required this.name,
    required this.progress,
    required this.percentage,
    required this.bgColor,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.code,
                      size: 24,
                      color: Theme.of(context).disabledColor,
                    );
                  },
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 2. "Recommended Courses" Section (FIXED) ---
class _RecommendedCoursesSection extends StatelessWidget {
  const _RecommendedCoursesSection();

  @override
  Widget build(BuildContext context) {
    // Data now uses local asset paths for the course images
    final List<Map<String, String>> courses = [
      {
        'imagePath': 'assets/images/flutter_course.png',
        'title': 'Advanced Flutter',
        'duration': '4 Weeks',
      },
      {
        'imagePath': 'assets/images/figma_course.png',
        'title': 'Intro to Figma',
        'duration': '10 Hours',
      },
      {
        'imagePath': 'assets/images/ml_course.png',
        'title': 'Machine Learning',
        'duration': '8 Weeks',
      },
      {
        'imagePath': 'assets/images/state_course.png',
        'title': 'State Management',
        'duration': '6 Hours',
      },
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _CourseCard(
            imagePath: course['imagePath']!,
            title: course['title']!,
            duration: course['duration']!,
          );
        },
      ),
    );
  }
}

// This widget is now completely updated to use images
class _CourseCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String duration;

  const _CourseCard({
    required this.imagePath,
    required this.title,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. "Activity" Section ---
class _ActivitySection extends StatelessWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bar Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 80,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _getBottomTitles(context, value, meta),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 == 0) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: _getBarGroups(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Achievement Cards
        Row(
          children: [
            Expanded(
              child: _AchievementCard(
                icon: Icons.emoji_events,
                iconColor: Colors.blue[600]!,
                title: 'Completed',
                subtitle: '"Flutter Animations" module',
                bgColor: Colors.blue[50]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AchievementCard(
                icon: Icons.workspace_premium,
                iconColor: Colors.amber[700]!,
                title: 'Earned',
                subtitle: '"Data Science" badge',
                bgColor: Colors.amber[50]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<BarChartGroupData> _getBarGroups() {
    final colors = [
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.amber[300]!,
      Colors.red[300]!,
      Colors.purple[300]!,
      Colors.orange[300]!,
      Colors.teal[300]!,
    ];
    final heights = [55.0, 40.0, 70.0, 60.0, 75.0, 50.0, 65.0];

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: heights[index],
            color: colors[index],
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  static Widget _getBottomTitles(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) {
    final style = TextStyle(color: Theme.of(context).hintColor, fontSize: 12);
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'M';
        break;
      case 1:
        text = 'T';
        break;
      case 2:
        text = 'W';
        break;
      case 3:
        text = 'T';
        break;
      case 4:
        text = 'F';
        break;
      case 5:
        text = 'S';
        break;
      case 6:
        text = 'S';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color bgColor;

  const _AchievementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
