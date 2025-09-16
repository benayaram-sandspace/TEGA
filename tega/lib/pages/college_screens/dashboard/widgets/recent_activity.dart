import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: DashboardStyles.sectionTitle),
          const SizedBox(height: 16),
          _buildActivityItem(
            'John Smith submitted assignment',
            '2 minutes ago',
            Icons.assignment_turned_in_outlined,
            DashboardStyles.accentGreen,
          ),
          _buildActivityItem(
            'New message from Emma Wilson',
            '15 minutes ago',
            Icons.message_outlined,
            DashboardStyles.primary,
          ),
          _buildActivityItem(
            'Quiz results available for Math 101',
            '1 hour ago',
            Icons.quiz_outlined,
            DashboardStyles.accentOrange,
          ),
          _buildActivityItem(
            'Sarah Johnson joined the class',
            '3 hours ago',
            Icons.person_add_outlined,
            DashboardStyles.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
