import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class LearningActivityPage extends StatefulWidget {
  const LearningActivityPage({super.key});

  @override
  State<LearningActivityPage> createState() => _LearningActivityPageState();
}

class _LearningActivityPageState extends State<LearningActivityPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Videos',
    'Quizzes',
    'Assignments',
    'Reading',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Activity'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: DashboardStyles.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? DashboardStyles.primary
                            : DashboardStyles.textLight,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? DashboardStyles.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Activity Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActivityStatCard(
                      'Completed',
                      '24',
                      Icons.check_circle,
                      DashboardStyles.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActivityStatCard(
                      'In Progress',
                      '8',
                      Icons.access_time,
                      DashboardStyles.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActivityStatCard(
                      'Upcoming',
                      '12',
                      Icons.upcoming,
                      DashboardStyles.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Current Activities
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Current Activities',
                style: DashboardStyles.sectionTitle,
              ),
            ),
            const SizedBox(height: 16),

            // Activity Cards
            ..._buildActivityCards(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: DashboardStyles.background,
    );
  }

  Widget _buildActivityStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DashboardStyles.textLight,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityCards() {
    final activities = [
      {
        'title': 'Introduction to Machine Learning',
        'type': 'Video',
        'duration': '45 min',
        'progress': 0.7,
        'icon': Icons.play_circle_filled,
        'color': DashboardStyles.primary,
      },
      {
        'title': 'Physics Quiz - Chapter 5',
        'type': 'Quiz',
        'duration': '20 min',
        'progress': 0.0,
        'icon': Icons.quiz,
        'color': DashboardStyles.accentOrange,
      },
      {
        'title': 'Essay on Climate Change',
        'type': 'Assignment',
        'duration': 'Due in 2 days',
        'progress': 0.3,
        'icon': Icons.assignment,
        'color': DashboardStyles.accentGreen,
      },
      {
        'title': 'Advanced Calculus Textbook',
        'type': 'Reading',
        'duration': '120 pages',
        'progress': 0.5,
        'icon': Icons.menu_book,
        'color': DashboardStyles.accentPurple,
      },
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (activity['color'] as Color).withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            activity['icon'] as IconData,
                            color: activity['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      activity['type'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    activity['duration'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                    if ((activity['progress'] as double) > 0) ...[
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${((activity['progress'] as double) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activity['color'] as Color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: activity['progress'] as double,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activity['color'] as Color,
                            ),
                            minHeight: 4,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
