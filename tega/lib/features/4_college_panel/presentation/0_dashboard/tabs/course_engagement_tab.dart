import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class CourseEngagementPage extends StatelessWidget {
  const CourseEngagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_rounded,
              size: 64,
              color: DashboardStyles.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Course Engagement',
              style: DashboardStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Course engagement dashboard coming soon',
              style: DashboardStyles.statTitle,
            ),
          ],
        ),
      ),
    );
  }
}

