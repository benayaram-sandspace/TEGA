import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'actionable_insights.dart'; // Import the InsightInfo class

// Dummy model for a student
class Student {
  final String name;
  final String id;
  final String course;
  final String reason;
  const Student(this.name, this.id, this.course, this.reason);
}

class InsightDetailsPage extends StatefulWidget {
  final InsightInfo insight;
  const InsightDetailsPage({super.key, required this.insight});
  @override
  State<InsightDetailsPage> createState() => _InsightDetailsPageState();
}

class _InsightDetailsPageState extends State<InsightDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Student> _studentsForAdvising = const [
    Student('Riya Sharma', '721A05', 'B.Tech CSE', 'Low attendance in C++'),
    Student('Amit Kumar', '721B12', 'B.Tech ECE', 'Failed last semester exam'),
    Student(
      'Priya Singh',
      '721A21',
      'B.Tech CSE',
      'Multiple missed assignments',
    ),
    Student(
      'Vikram Rathod',
      '721C03',
      'B.Tech Mech',
      'Consistently low scores',
    ),
    Student(
      'Sneha Patil',
      '721B08',
      'B.Tech ECE',
      'Requested transfer guidance',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: AppBar(
        title: const Text(
          'Academic Advising',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAnimatedHeader(),
          const SizedBox(height: 24),
          _buildAnimatedStudentListHeader(),
          const SizedBox(height: 12),
          ...List.generate(_studentsForAdvising.length, (index) {
            return _buildAnimatedStudentTile(
              _studentsForAdvising[index],
              index,
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text(
          'Schedule Meetings',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.event_available, color: Colors.white),
        backgroundColor: widget.insight.iconColor,
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: _buildHeaderCard(),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.insight.iconColor.withOpacity(0.8),
            widget.insight.iconColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.insight.iconColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.insight.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.insight.priorityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.insight.priority,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.insight.priorityTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.insight.title,
            style: DashboardStyles.sectionTitle.copyWith(
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The following students have been flagged by the system for immediate academic review. Please schedule an advising session.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStudentListHeader() {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: Text(
        'STUDENTS REQUIRING ATTENTION',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAnimatedStudentTile(Student student, int index) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.5 + (index * 0.1), 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation),
        // MODIFICATION: Pass the insight's theme color to the tile builder
        child: _buildStudentTile(student, widget.insight.iconColor),
      ),
    );
  }

  // MODIFICATION: The tile builder now accepts a themeColor
  Widget _buildStudentTile(Student student, Color themeColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                // MODIFICATION: Using themeColor instead of hardcoded primary color
                backgroundColor: themeColor.withOpacity(0.1),
                child: Text(
                  student.name.substring(0, 1),
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {},
                child: const Text('Contact'),
                style: TextButton.styleFrom(
                  // MODIFICATION: Using themeColor for the button text
                  foregroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
