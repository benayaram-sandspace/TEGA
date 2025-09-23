import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

// Model for student data
class StudentData {
  final String name;
  final String rollNumber;
  final int resumeScore;
  final int mockInterviews;
  final double avgInterviewScore;
  final String interviewRole;
  final String jobRole;

  StudentData({
    required this.name,
    required this.rollNumber,
    required this.resumeScore,
    required this.mockInterviews,
    required this.avgInterviewScore,
    required this.interviewRole,
    required this.jobRole,
  });
}

class ResumeInterviewPage extends StatefulWidget {
  const ResumeInterviewPage({super.key});

  @override
  State<ResumeInterviewPage> createState() => _ResumeInterviewPageState();
}

class _ResumeInterviewPageState extends State<ResumeInterviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for students
  final List<StudentData> _allStudents = [
    StudentData(name: 'John Doe', rollNumber: 'CST-101', resumeScore: 85, mockInterviews: 12, avgInterviewScore: 78.0, interviewRole: 'Software Engineer', jobRole: 'Frontend Developer'),
    StudentData(name: 'Jane Smith', rollNumber: 'ECE-205', resumeScore: 92, mockInterviews: 8, avgInterviewScore: 85.5, interviewRole: 'Data Analyst', jobRole: 'Data Analyst'),
    StudentData(name: 'Peter Jones', rollNumber: 'MECH-302', resumeScore: 78, mockInterviews: 5, avgInterviewScore: 72.3, interviewRole: 'Mechanical Engineer', jobRole: 'Product Designer'),
    StudentData(name: 'Mary Johnson', rollNumber: 'IT-410', resumeScore: 88, mockInterviews: 15, avgInterviewScore: 91.0, interviewRole: 'Product Manager', jobRole: 'Product Manager'),
    StudentData(name: 'David Williams', rollNumber: 'CSE-115', resumeScore: 95, mockInterviews: 10, avgInterviewScore: 88.8, interviewRole: 'DevOps Engineer', jobRole: 'DevOps Engineer'),
  ];

  List<StudentData> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredStudents = _allStudents;
    _searchController.addListener(_filterStudents);
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        return student.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Analytics'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DashboardStyles.primary,
          unselectedLabelColor: DashboardStyles.textLight,
          indicatorColor: DashboardStyles.primary,
          tabs: const [
            Tab(text: 'Resume Analysis'),
            Tab(text: 'Interview Analysis'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResumeTab(),
                _buildInterviewTab(),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: DashboardStyles.background,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildResumeTab() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildResumeCard(student),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInterviewTab() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildInterviewCard(student),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumeCard(StudentData student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll No: ${student.rollNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: DashboardStyles.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Job Role: ${student.jobRole}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: student.resumeScore.toDouble()),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return CircularPercentIndicator(
                  radius: 40.0,
                  lineWidth: 8.0,
                  percent: value / 100,
                  center: Text(
                    '${value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: _getScoreColor(value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewCard(StudentData student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll No: ${student.rollNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: DashboardStyles.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Interviewed for: ${student.interviewRole}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: student.avgInterviewScore),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return CircularPercentIndicator(
                  radius: 40.0,
                  lineWidth: 8.0,
                  percent: value / 100,
                  center: Text(
                    '${value.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: _getScoreColor(value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) {
      return DashboardStyles.accentGreen;
    } else if (score >= 75) {
      return DashboardStyles.accentOrange;
    } else {
      return Colors.red;
    }
  }
}