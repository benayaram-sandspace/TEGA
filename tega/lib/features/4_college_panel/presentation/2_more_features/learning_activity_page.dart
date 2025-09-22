import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/data/models/learning_activity_student_model.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/tabs/student_details_tab.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/activity_breakdown_card.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/activity_feed_section.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/engagement_chart_card.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/students_to_watch_card.dart';

class LearningActivityPage extends StatefulWidget {
  const LearningActivityPage({super.key});

  @override
  State<LearningActivityPage> createState() => _LearningActivityPageState();
}

class _LearningActivityPageState extends State<LearningActivityPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Videos',
    'Quizzes',
    'Assignments',
    'Reading',
  ];

  late final List<Student> _studentsToWatch;
  late final List<Activity> _allActivities;
  List<Activity> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _studentsToWatch = _generateDummyStudents().take(4).toList();
    _allActivities = _generateDummyActivities();
    _filteredActivities = _allActivities;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _filterActivities() {
    if (_selectedCategory == 'All') {
      _filteredActivities = _allActivities;
    } else {
      _filteredActivities = _allActivities
          .where((activity) => activity.type == _selectedCategory)
          .toList();
    }
    setState(() {});
  }

  List<Student> _generateDummyStudents() {
    final names = [
      'Riya Sharma',
      'Amit Kumar',
      'Priya Singh',
      'Vikram Rathod',
      'Sneha Patil',
      'Arjun Verma',
      'Neha Gupta',
      'Rahul Desai',
    ];
    return List.generate(names.length, (index) {
      return Student(
        name: names[index],
        avatarUrl: 'https://i.pravatar.cc/150?img=${index + 1}',
        grade: 12 - (index % 5),
        gpa: (4.0 - (index % 8) * 0.15).clamp(2.5, 4.0),
        status: 'Good',
        statusColor: DashboardStyles.accentOrange,
      );
    });
  }

  List<Activity> _generateDummyActivities() {
    return [
      Activity(
        title: 'Watched "Intro to Calculus"',
        type: 'Videos',
        studentName: 'Riya Sharma',
        studentAvatarUrl: 'https://i.pravatar.cc/150?img=1',
        timestamp: '5m ago',
        icon: Icons.play_circle_fill_rounded,
        color: DashboardStyles.primary,
      ),
      Activity(
        title: 'Submitted "Essay on Climate Change"',
        type: 'Assignments',
        studentName: 'Amit Kumar',
        studentAvatarUrl: 'https://i.pravatar.cc/150?img=2',
        timestamp: '1h ago',
        icon: Icons.assignment_turned_in_rounded,
        color: DashboardStyles.accentGreen,
      ),
      Activity(
        title: 'Scored 85% in "Physics Quiz 5"',
        type: 'Quizzes',
        studentName: 'Priya Singh',
        studentAvatarUrl: 'https://i.pravatar.cc/150?img=3',
        timestamp: '3h ago',
        icon: Icons.quiz_rounded,
        color: DashboardStyles.accentOrange,
      ),
      Activity(
        title: 'Finished "Adv. Calculus Ch. 3"',
        type: 'Reading',
        studentName: 'Riya Sharma',
        studentAvatarUrl: 'https://i.pravatar.cc/150?img=1',
        timestamp: 'Yesterday',
        icon: Icons.menu_book_rounded,
        color: DashboardStyles.accentPurple,
      ),
      Activity(
        title: 'Watched "Linear Algebra Basics"',
        type: 'Videos',
        studentName: 'Vikram Rathod',
        studentAvatarUrl: 'https://i.pravatar.cc/150?img=4',
        timestamp: 'Yesterday',
        icon: Icons.play_circle_fill_rounded,
        color: DashboardStyles.primary,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: AppBar(
        title: const Text(
          'Learning Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryFilters(),
            const SizedBox(height: 16),
            ActivityFeedSection(
              animationController: _animationController,
              filteredActivities: _filteredActivities,
              selectedCategory: _selectedCategory,
            ),
            EngagementChartCard(animationController: _animationController),
            const SizedBox(height: 16),
            ActivityBreakdownCard(animationController: _animationController),
            const SizedBox(height: 16),
            StudentsToWatchCard(
              animationController: _animationController,
              students: _studentsToWatch,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                _selectedCategory = category;
                _filterActivities();
              },
              backgroundColor: DashboardStyles.cardBackground,
              selectedColor: DashboardStyles.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : DashboardStyles.textDark,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
