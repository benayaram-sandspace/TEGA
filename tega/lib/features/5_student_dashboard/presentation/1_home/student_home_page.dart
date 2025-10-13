import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_notification_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/student_dashboard_header.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/student_stats_grid.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/weekly_progress_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/upcoming_events_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/recent_activity_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/achievements_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/quick_actions_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/recommended_courses_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/2_learning_hub/courses_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/student_ai_job_search_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/student_resume_optimizer.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/student_profile_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/student_setting_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/student_help_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/placement_prep_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/6_exams/exams_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isSidebarOpen = false;
  User? _currentUser;
  late List<Widget> _pages;
  Map<String, dynamic> _sidebarCounts = {};
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _dashboardData = {};
  late AnimationController _sidebarAnimationController;
  final AuthService _authService = AuthService();

  final List<String> _pageTitles = [
    'Dashboard',
    'Explore Courses',
    'Placement Prep',
    'Exams',
    'My Results',
    'Jobs',
    'Internships',
    'Resume Builder',
    'AI Assistant',
    'Notifications',
    'Learning History',
    'Transaction History',
    'Start Payment',
    'Help & Support',
    'Settings',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserData();
    _loadDashboardData();
    _initializePages();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = AuthService();
    setState(() {
      _currentUser = authService.currentUser;
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();
      final sidebar = await api.getSidebarCounts(headers);
      final dash = await api.getDashboard(headers);
      final prof = await api.getProfile(headers);
      setState(() {
        _sidebarCounts = sidebar;
        _dashboardData = dash;
        _profile = prof;
        _isLoading = false;
      });
      // Reinitialize pages with new data
      _initializePages();
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializePages() {
    _pages = [
      _HomePageContent(
        sidebarCounts: _sidebarCounts,
        dashboardData: _dashboardData,
      ),
      CoursesPage(key: const PageStorageKey('courses_page')), // Explore Courses
      const PlacementPrepPage(), // Placement Prep
      ExamsPage(key: const PageStorageKey('exams_page')), // Exams
      const _ResultsPage(), // My Results
      const JobRecommendationScreen(), // Jobs
      const _InternshipsPage(), // Internships
      const ResumeOptimizerPage(), // Resume Builder
      const _AIAssistantPage(), // AI Assistant
      const NotificationPage(), // Notifications
      const _LearningHistoryPage(), // Learning History
      const _TransactionHistoryPage(), // Transaction History
      const _StartPaymentPage(), // Start Payment
      const HelpPage(), // Help & Support
      const SettingsPage(), // Settings
      StudentProfilePage(), // Profile
    ];
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    if (_isSidebarOpen) {
      _sidebarAnimationController.forward();
    } else {
      _sidebarAnimationController.reverse();
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Could not load user data. Please try logging in again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header that stays visible for all pages
                StudentDashboardHeader(
                  onMenuTap: _toggleSidebar,
                  notificationCount: _sidebarCounts['notifications'] ?? 0,
                  title: _pageTitles[_selectedIndex],
                ),
                // Page content area
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
            if (_isSidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: AnimatedBuilder(
                  animation: _sidebarAnimationController,
                  builder: (context, child) => Container(
                    color: Colors.black.withOpacity(
                      0.6 * _sidebarAnimationController.value,
                    ),
                  ),
                ),
              ),
            _buildSidebar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isSidebarOpen ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Material(
        color: Colors.white,
        elevation: 20,
        shadowColor: const Color(0xFF6B5FFF).withOpacity(0.2),
        child: Column(
          children: [
            _buildSidebarHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('MAIN MENU'),
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.school_rounded,
                      title: 'Explore Courses',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.business_center_rounded,
                      title: 'Placement Prep',
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.assignment_rounded,
                      title: 'Exams',
                      index: 3,
                    ),
                    _buildNavItem(
                      icon: Icons.assessment_rounded,
                      title: 'My Results',
                      index: 4,
                    ),
                    _buildNavItem(
                      icon: Icons.work_rounded,
                      title: 'Jobs',
                      index: 5,
                    ),
                    _buildNavItem(
                      icon: Icons.work_outline_rounded,
                      title: 'Internships',
                      index: 6,
                    ),
                    _buildNavItem(
                      icon: Icons.description_rounded,
                      title: 'Resume Builder',
                      index: 7,
                    ),
                    _buildNavItem(
                      icon: Icons.psychology_rounded,
                      title: 'AI Assistant',
                      index: 8,
                    ),
                    _buildNavItem(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      index: 9,
                      badge: (_sidebarCounts['notifications'] ?? 0) > 0
                          ? _sidebarCounts['notifications'].toString()
                          : null,
                    ),
                    _buildNavItem(
                      icon: Icons.history_rounded,
                      title: 'Learning History',
                      index: 10,
                    ),
                    _buildNavItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Transaction History',
                      index: 11,
                    ),
                    const Divider(height: 24),
                    _buildSectionHeader('QUICK ACTIONS'),
                    _buildNavItem(
                      icon: Icons.payment_rounded,
                      title: 'Start Payment',
                      index: 12,
                    ),
                    _buildNavItem(
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      index: 13,
                    ),
                    _buildNavItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      index: 14,
                    ),
                    _buildNavItem(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      index: 15,
                    ),
                  ],
                ),
              ),
            ),
            _buildLogoutTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    // Get course details
    final inst = (_profile['institute'] ?? _currentUser?.college ?? '')
        .toString();
    final yr = (_profile['yearOfStudy'] ?? _currentUser?.year ?? '').toString();
    final cour = (_profile['course'] ?? _currentUser?.course ?? '').toString();
    final display = [
      cour.isNotEmpty ? cour : 'Course: To be updated',
      yr.isNotEmpty ? 'Year $yr' : 'Year: To be updated',
      inst.isNotEmpty ? inst : 'Institute: To be updated',
    ].join(' | ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B5FFF), Color(0xFF5E4FDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.school_rounded,
                size: 32,
                color: Color(0xFF6B5FFF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentUser?.name ?? 'Student',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: isSelected
          ? const Color(0xFF6B5FFF).withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          if (_selectedIndex != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          }
          _toggleSidebar();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF6B5FFF).withOpacity(0.2),
        highlightColor: const Color(0xFF6B5FFF).withOpacity(0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color(0xFF6B5FFF).withOpacity(0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF6B5FFF).withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6B5FFF).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF6B5FFF) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF6B5FFF)
                        : Colors.grey[800],
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.red,
          size: 16,
        ),
        onTap: _showLogoutConfirmation,
      ),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  final Map<String, dynamic> sidebarCounts;
  final Map<String, dynamic> dashboardData;

  const _HomePageContent({
    required this.sidebarCounts,
    required this.dashboardData,
  });

  @override
  Widget build(BuildContext context) {
    final userProgress = dashboardData['userProgress'] ?? {};
    final recentActivity = dashboardData['recentActivity'] ?? [];
    final upcomingEvents = dashboardData['upcomingEvents'] ?? [];
    final achievements = dashboardData['achievements'] ?? [];
    final recommendedCourses = dashboardData['recommendedCourses'] ?? [];

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isDesktop
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards Grid (2x2) with animations
          const StudentStatsGrid(),
          SizedBox(height: isDesktop ? 24 : 20),
          // Weekly Progress
          WeeklyProgressWidget(
            weeklyProgress: userProgress['weeklyProgress'] ?? 0,
            weeklyGoal: userProgress['weeklyGoal'] ?? 10,
            currentStreak: userProgress['currentStreak'] ?? 0,
          ),
          SizedBox(height: isDesktop ? 24 : 20),
          // Quick Actions
          const QuickActionsWidget(),
          SizedBox(height: isDesktop ? 24 : 20),
          // Recent Activity and Upcoming Events - Side by side on large screens
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecentActivityWidget(activities: recentActivity),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: UpcomingEventsWidget(events: upcomingEvents),
                    ),
                  ],
                )
              : Column(
                  children: [
                    RecentActivityWidget(activities: recentActivity),
                    const SizedBox(height: 20),
                    UpcomingEventsWidget(events: upcomingEvents),
                  ],
                ),
          SizedBox(height: isDesktop ? 24 : 20),
          // Achievements
          AchievementsWidget(achievements: achievements),
          SizedBox(height: isDesktop ? 24 : 20),
          // Recommended Courses
          RecommendedCoursesWidget(courses: recommendedCourses),
          SizedBox(height: isDesktop ? 24 : 20),
        ],
      ),
    );
  }
}

// Placeholder pages for navigation items
class _ResultsPage extends StatelessWidget {
  const _ResultsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.assessment_rounded,
                size: 80,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Results',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternshipsPage extends StatelessWidget {
  const _InternshipsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 80,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Internships',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAssistantPage extends StatelessWidget {
  const _AIAssistantPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 80,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Assistant',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningHistoryPage extends StatelessWidget {
  const _LearningHistoryPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 80,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Learning History',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionHistoryPage extends StatelessWidget {
  const _TransactionHistoryPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 80,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction History',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartPaymentPage extends StatelessWidget {
  const _StartPaymentPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.payment_rounded,
                size: 80,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start Payment',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
