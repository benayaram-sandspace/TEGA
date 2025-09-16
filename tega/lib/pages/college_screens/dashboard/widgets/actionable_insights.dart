import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';


class ActionableInsights extends StatelessWidget {
  const ActionableInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actionable Insights', style: DashboardStyles.sectionTitle),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: Icons.school_outlined,
          iconColor: DashboardStyles.accentOrange,
          title: '5 students require academic advising',
          priority: 'High priority',
          priorityColor: DashboardStyles.priorityHighBg,
          priorityTextColor: DashboardStyles.priorityHighText,
        ),
        _buildInsightCard(
          icon: Icons.book_outlined,
          iconColor: DashboardStyles.primary,
          title: 'New curriculum update available',
          priority: 'Medium priority',
          priorityColor: DashboardStyles.priorityMediumBg,
          priorityTextColor: DashboardStyles.priorityMediumText,
        ),
        _buildInsightCard(
          icon: Icons.trending_up_outlined,
          iconColor: DashboardStyles.accentGreen,
          title: 'Enrollment trends for Q4 are available',
          priority: 'Low',
          priorityColor: DashboardStyles.priorityLowBg,
          priorityTextColor: DashboardStyles.priorityLowText,
        ),
      ],
    );
  }

   Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String priority,
    required Color priorityColor,
    required Color priorityTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashboardStyles.insightTitle),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: DashboardStyles.priorityTag.copyWith(
                      color: priorityTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: DashboardStyles.iconLight),
        ],
      ),
    );
  }
}
