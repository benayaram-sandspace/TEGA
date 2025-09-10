import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/services/college_service.dart';
import 'college_main_dashboard.dart';
import 'college_student_management.dart';
import 'career_progress_tracker.dart';
import 'learning_activity_engagement.dart';
import 'resume_interview_monitor.dart';
import 'college_student_analytics.dart';
import 'college_reports_page.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/services/auth_service.dart';

class CollegeDashboardMain extends StatefulWidget {
  final College college;

  const CollegeDashboardMain({super.key, required this.college});

  @override
  State<CollegeDashboardMain> createState() => _CollegeDashboardMainState();
}

class _CollegeDashboardMainState extends State<CollegeDashboardMain> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _pages = [
    // Will be initialized in initState
  ];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      CollegeMainDashboard(college: widget.college),
      CollegeStudentManagement(college: widget.college),
      CareerProgressTracker(college: widget.college),
      LearningActivityEngagement(college: widget.college),
      ResumeInterviewMonitor(college: widget.college),
      CollegeStudentAnalytics(college: widget.college),
      CollegeReportsPage(college: widget.college),
    ]);
  }

  // Handle logout with proper context management
  Future<void> _handleLogout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Perform logout
      await _authService.logout();

      // Close loading indicator and navigate
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Handle logout error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar - Always visible
          Container(
            width: 250,
            child: _buildSidebar(),
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),
                
                // Page Content
                Expanded(
                  child: _pages.isNotEmpty ? _pages[_selectedIndex] : const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // College Name and Title
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEGA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.college.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // User Info and Logout
          Row(
            children: [
              // College Principal Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _authService.getRoleDisplayName(_authService.currentUserRole!),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _authService.currentUser?.name ?? 'Principal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Logout Button
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: AppColors.error),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A), // Dark blue header
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEGA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.college.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.people,
                  title: 'Student Management',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.track_changes,
                  title: 'Career Progress Tracker',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.play_circle_outline,
                  title: 'Learning Activity & Engagement',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.work_outline,
                  title: 'Resume & Interview Monitor',
                  index: 4,
                ),
                _buildNavItem(
                  icon: Icons.analytics,
                  title: 'Reports & Analytics',
                  index: 5,
                ),
                _buildNavItem(
                  icon: Icons.assessment,
                  title: 'Settings & Support',
                  index: 6,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 8),
                Text(
                  'College Dashboard v1.0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            print('Navigating to page: $index'); // Debug print
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
