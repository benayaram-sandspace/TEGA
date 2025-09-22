import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/tabs/student_details_tab.dart';

class StudentsToWatchCard extends StatelessWidget {
  final AnimationController animationController;
  final List<Student> students;

  const StudentsToWatchCard({
    super.key,
    required this.animationController,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
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
                'Students to Watch',
                style: DashboardStyles.sectionTitle,
              ),
              const SizedBox(height: 4),
              ...students.map(
                (student) =>
                    _buildStudentWatchTile(context, student, 'Low quiz scores'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentWatchTile(
    BuildContext context,
    Student student,
    String reason,
  ) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailsPage(student: student),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      leading: CircleAvatar(backgroundImage: NetworkImage(student.avatarUrl)),
      title: Text(
        student.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        reason,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
    );
  }
}
