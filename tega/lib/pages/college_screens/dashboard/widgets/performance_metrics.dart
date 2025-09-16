import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class PerformanceMetrics extends StatelessWidget {
  const PerformanceMetrics({super.key});

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
          const Text(
            'Performance Metrics',
            style: DashboardStyles.sectionTitle,
          ),
          const SizedBox(height: 20),
          _buildMetricRow(
            'Average Test Score',
            '85%',
            0.85,
            DashboardStyles.accentGreen,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Attendance Rate',
            '92%',
            0.92,
            DashboardStyles.primary,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Assignment Completion',
            '78%',
            0.78,
            DashboardStyles.accentOrange,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Student Satisfaction',
            '88%',
            0.88,
            DashboardStyles.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String title,
    String percentage,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            Text(
              percentage,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }
}
