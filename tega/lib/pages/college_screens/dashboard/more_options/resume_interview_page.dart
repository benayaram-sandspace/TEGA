import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class ResumeInterviewPage extends StatefulWidget {
  const ResumeInterviewPage({super.key});

  @override
  State<ResumeInterviewPage> createState() => _ResumeInterviewPageState();
}

class _ResumeInterviewPageState extends State<ResumeInterviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume & Interview'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DashboardStyles.primary,
          unselectedLabelColor: DashboardStyles.textLight,
          indicatorColor: DashboardStyles.primary,
          tabs: const [
            Tab(text: 'Resume Builder'),
            Tab(text: 'Interview Prep'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildResumeTab(), _buildInterviewTab()],
      ),
      backgroundColor: DashboardStyles.background,
    );
  }

  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resume Score Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DashboardStyles.primary,
                  DashboardStyles.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '85',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resume Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your resume is looking good! Add more skills to improve.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resume Sections
          const Text('Resume Sections', style: DashboardStyles.sectionTitle),
          const SizedBox(height: 16),
          _buildResumeSection('Personal Information', Icons.person, true),
          _buildResumeSection('Education', Icons.school, true),
          _buildResumeSection('Experience', Icons.work, true),
          _buildResumeSection('Skills', Icons.psychology, false),
          _buildResumeSection('Projects', Icons.folder, false),
          _buildResumeSection('Certifications', Icons.verified, false),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardStyles.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardStyles.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: DashboardStyles.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumeSection(String title, IconData icon, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted
                ? DashboardStyles.accentGreen.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? DashboardStyles.accentGreen : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          isCompleted ? 'Completed' : 'Not completed',
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? DashboardStyles.accentGreen : Colors.grey,
          ),
        ),
        trailing: Icon(
          isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
          color: isCompleted ? DashboardStyles.accentGreen : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildInterviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interview Stats
          Row(
            children: [
              Expanded(
                child: _buildInterviewStatCard(
                  'Mock Interviews',
                  '12',
                  Icons.video_call,
                  DashboardStyles.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInterviewStatCard(
                  'Avg Score',
                  '78%',
                  Icons.star,
                  DashboardStyles.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Practice Categories
          const Text(
            'Practice Categories',
            style: DashboardStyles.sectionTitle,
          ),
          const SizedBox(height: 16),
          _buildPracticeCategory(
            'Behavioral Questions',
            45,
            DashboardStyles.primary,
          ),
          _buildPracticeCategory(
            'Technical Questions',
            32,
            DashboardStyles.accentGreen,
          ),
          _buildPracticeCategory(
            'Case Studies',
            18,
            DashboardStyles.accentOrange,
          ),
          _buildPracticeCategory(
            'Situational Questions',
            28,
            DashboardStyles.accentPurple,
          ),

          const SizedBox(height: 24),

          // Upcoming Interviews
          const Text(
            'Upcoming Practice Sessions',
            style: DashboardStyles.sectionTitle,
          ),
          const SizedBox(height: 16),
          _buildUpcomingInterview(
            'Mock Interview with AI',
            'Tomorrow, 3:00 PM',
          ),
          _buildUpcomingInterview(
            'Technical Round Practice',
            'Dec 15, 10:00 AM',
          ),
          _buildUpcomingInterview('HR Round Preparation', 'Dec 18, 2:00 PM'),

          const SizedBox(height: 24),

          // Start Practice Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Practice Interview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: DashboardStyles.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCategory(String title, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.arrow_forward, color: color),
        ],
      ),
    );
  }

  Widget _buildUpcomingInterview(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardStyles.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: DashboardStyles.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashboardStyles.textLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Join',
              style: TextStyle(color: DashboardStyles.primary),
            ),
          ),
        ],
      ),
    );
  }
}
