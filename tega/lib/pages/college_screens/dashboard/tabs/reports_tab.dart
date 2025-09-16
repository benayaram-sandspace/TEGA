import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildReportCard(
            'Monthly Report',
            'December 2024',
            Icons.calendar_month,
            DashboardStyles.primary,
          ),
          _buildReportCard(
            'Attendance Report',
            '92% Average',
            Icons.check_circle_outline,
            DashboardStyles.accentGreen,
          ),
          _buildReportCard(
            'Performance Report',
            'Q4 2024',
            Icons.trending_up,
            DashboardStyles.accentOrange,
          ),
          _buildReportCard(
            'Financial Report',
            'Budget Analysis',
            Icons.attach_money,
            DashboardStyles.accentPurple,
          ),
          _buildReportCard(
            'Student Report',
            '3,125 Total',
            Icons.people_outline,
            DashboardStyles.accentTeal,
          ),
          _buildReportCard(
            'Custom Report',
            'Generate New',
            Icons.add_chart,
            DashboardStyles.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
