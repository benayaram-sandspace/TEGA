import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          'Enrolled Students',
          '3,125',
          Icons.people_outline,
          DashboardStyles.primary,
        ),
        _buildStatCard(
          'Engagement',
          '72%',
          Icons.timeline,
          DashboardStyles.accentGreen,
        ),
        _buildStatCard(
          'AI',
          'course',
          Icons.school_outlined,
          DashboardStyles.accentOrange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: DashboardStyles.statValue),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: DashboardStyles.statTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
