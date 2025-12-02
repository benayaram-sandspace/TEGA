import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: DashboardStyles.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text('Communication', style: DashboardStyles.sectionTitle),
            const SizedBox(height: 8),
            Text(
              'Communication dashboard coming soon',
              style: DashboardStyles.statTitle,
            ),
          ],
        ),
      ),
    );
  }
}
