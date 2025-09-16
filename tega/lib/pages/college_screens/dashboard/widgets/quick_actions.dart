import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';


class QuickActions extends StatelessWidget {
  const QuickActions({super.key});
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  // ... Paste _buildQuickActionCard here

  @override
  Widget build(BuildContext context) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: DashboardStyles.sectionTitle),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'Add Student',
                color: DashboardStyles.primary,
                onTap: () {},
              ),
              _buildQuickActionCard(
                icon: Icons.assignment_outlined,
                label: 'Create Test',
                color: DashboardStyles.accentGreen,
                onTap: () {},
              ),
              _buildQuickActionCard(
                icon: Icons.calendar_today_outlined,
                label: 'Schedule',
                color: DashboardStyles.accentOrange,
                onTap: () {},
              ),
              _buildQuickActionCard(
                icon: Icons.email_outlined,
                label: 'Messages',
                color: DashboardStyles.accentPurple,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
