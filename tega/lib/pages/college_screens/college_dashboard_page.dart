import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: DashboardStyles.background,
        fontFamily: 'Inter',
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// A centralized class for styles and colors to ensure UI uniformity.
class DashboardStyles {
  // Color Palette
  static const Color background = Color(0xFFF7F8FC);
  static const Color cardBackground = Colors.white;
  static const Color primary = Color(0xFF4A80F0);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF6E7E9A);
  static const Color iconLight = Color(0xFFB0B8C8);

  // Priority Colors
  static const Color priorityHighBg = Color(0xFFFBE9E7);
  static const Color priorityHighText = Color(0xFFD32F2F);
  static const Color priorityMediumBg = Color(0xFFFFF3E0);
  static const Color priorityMediumText = Color(0xFFF57C00);
  static const Color priorityLowBg = Color(0xFFE3F2FD);
  static const Color priorityLowText = Color(0xFF1E88E5);

  // Chart & Accent Colors
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color accentOrange = Color(0xFFFBC02D);
  static const Color accentRed = Color(0xFFF4511E);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF00BCD4);

  // TextStyles
  static const TextStyle welcomeHeader = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle statValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle statTitle = TextStyle(color: textLight, fontSize: 13);
  static const TextStyle insightTitle = TextStyle(
    fontWeight: FontWeight.w500,
    color: textDark,
    fontSize: 14,
  );
  static const TextStyle priorityTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  late final List<Widget> _pages;

  // New: Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // New: Notification count
  int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    // Define the pages for the BottomNavigationBar
    _pages = [
      _buildDashboardPage(), // Index 0: Dashboard
      const StudentsPage(), // Enhanced Students Page
      const ProgressPage(), // Enhanced Progress Page
      const ReportsPage(), // Enhanced Reports Page
    ];
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      // The 'More' tab shows a bottom sheet without changing the page index.
      _showMoreOptions(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Builds the main dashboard page content.
  Widget _buildDashboardPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildWelcomeHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(), // New feature
            const SizedBox(height: 24),
            _buildQuickActions(), // New feature
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildProgressChartCard(),
            const SizedBox(height: 32),
            _buildPerformanceMetrics(), // New feature
            const SizedBox(height: 32),
            _buildUpcomingEvents(), // New feature
            const SizedBox(height: 32),
            _buildActionableInsights(),
            const SizedBox(height: 32),
            _buildRecentActivity(), // New feature
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'Welcome, Sarah!',
            style: DashboardStyles.welcomeHeader,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            // New: Notification Bell
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: DashboardStyles.textDark,
                  onPressed: () {
                    _showNotifications(context);
                  },
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: DashboardStyles.accentRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=1',
                ),
                radius: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New: Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students, courses, or activities...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
      ),
    );
  }

  // New: Quick Actions Widget
  Widget _buildQuickActions() {
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

  Widget _buildStatsGrid() {
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

  Widget _buildProgressChartCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Progress Overview',
                style: DashboardStyles.sectionTitle,
              ),
              // New: Filter dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('This Week', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 150, child: BarChart(_mainBarData())),
        ],
      ),
    );
  }

  // New: Performance Metrics Widget
  Widget _buildPerformanceMetrics() {
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

  // New: Upcoming Events Widget
  Widget _buildUpcomingEvents() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: DashboardStyles.sectionTitle,
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: DashboardStyles.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEventItem(
            'Parent-Teacher Meeting',
            'Tomorrow, 10:00 AM',
            Icons.groups_outlined,
            DashboardStyles.primary,
          ),
          _buildEventItem(
            'Science Fair',
            'Dec 15, 2:00 PM',
            Icons.science_outlined,
            DashboardStyles.accentGreen,
          ),
          _buildEventItem(
            'Final Exams Begin',
            'Dec 20, 9:00 AM',
            Icons.edit_note_outlined,
            DashboardStyles.accentOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableInsights() {
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

  // New: Recent Activity Widget
  Widget _buildRecentActivity() {
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

  // New: Notifications Dialog
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notifications'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNotificationItem(
                  'New assignment posted',
                  'Math 101 homework due tomorrow',
                  Icons.assignment_outlined,
                  DashboardStyles.primary,
                ),
                _buildNotificationItem(
                  'Attendance alert',
                  '3 students absent today',
                  Icons.warning_outlined,
                  DashboardStyles.accentOrange,
                ),
                _buildNotificationItem(
                  'System update',
                  'New features available',
                  Icons.system_update_outlined,
                  DashboardStyles.accentGreen,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _notificationCount = 0;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Mark all as read'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DashboardStyles.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.local_activity_outlined,
                  color: DashboardStyles.textDark,
                ),
                title: const Text(
                  'Learning Activity',
                  style: DashboardStyles.insightTitle,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LearningActivityPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.article_outlined,
                  color: DashboardStyles.textDark,
                ),
                title: const Text(
                  'Resume & Interview',
                  style: DashboardStyles.insightTitle,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResumeInterviewPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: DashboardStyles.textDark,
                ),
                title: const Text(
                  'Settings & Support',
                  style: DashboardStyles.insightTitle,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsSupportPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: DashboardStyles.accentRed,
                ),
                title: Text(
                  'Logout',
                  style: DashboardStyles.insightTitle.copyWith(
                    color: DashboardStyles.accentRed,
                  ),
                ),
                onTap: _handleLogout,
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Students',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up_outlined),
          activeIcon: Icon(Icons.trending_up),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_outlined),
          activeIcon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: DashboardStyles.primary,
      unselectedItemColor: DashboardStyles.textLight,
      onTap: _onItemTapped,
      backgroundColor: DashboardStyles.cardBackground,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 5,
    );
  }

  BarChartData _mainBarData() {
    return BarChartData(
      maxY: 1200,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _getBottomTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value % 400 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  textAlign: TextAlign.left,
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      barGroups: _showingGroups(),
    );
  }

  List<BarChartGroupData> _showingGroups() => [
    _makeGroupData(0, 300, DashboardStyles.primary),
    _makeGroupData(1, 800, DashboardStyles.primary),
    _makeGroupData(2, 500, DashboardStyles.accentGreen),
    _makeGroupData(3, 1000, DashboardStyles.accentGreen),
    _makeGroupData(4, 1100, DashboardStyles.accentOrange),
    _makeGroupData(5, 400, DashboardStyles.primary),
    _makeGroupData(6, 200, DashboardStyles.accentRed),
  ];

  BarChartGroupData _makeGroupData(int x, double y, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: DashboardStyles.textLight,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Calculus', style: style);
        break;
      case 1:
        text = const Text('Biology', style: style);
        break;
      case 2:
        text = const Text('Strategy', style: style);
        break;
      case 3:
        text = const Text('History', style: style);
        break;
      case 4:
        text = const Text('Physics', style: style);
        break;
      case 5:
        text = const Text('Arts', style: style);
        break;
      case 6:
        text = const Text('Music', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 16.0, child: text);
  }
}

// --- Enhanced Students Page ---
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=$index',
                ),
              ),
              title: Text('Student ${index + 1}'),
              subtitle: Text(
                'Grade: ${10 - index} | GPA: ${(4.0 - index * 0.2).toStringAsFixed(1)}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: index % 3 == 0
                      ? DashboardStyles.accentGreen.withOpacity(0.1)
                      : index % 3 == 1
                      ? DashboardStyles.accentOrange.withOpacity(0.1)
                      : DashboardStyles.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  index % 3 == 0
                      ? 'Excellent'
                      : index % 3 == 1
                      ? 'Good'
                      : 'Average',
                  style: TextStyle(
                    color: index % 3 == 0
                        ? DashboardStyles.accentGreen
                        : index % 3 == 1
                        ? DashboardStyles.accentOrange
                        : DashboardStyles.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: DashboardStyles.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Enhanced Progress Page ---
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overall Progress Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Class Progress',
                      style: DashboardStyles.sectionTitle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCircularProgress(
                          'Completed',
                          0.75,
                          DashboardStyles.accentGreen,
                        ),
                        _buildCircularProgress(
                          'In Progress',
                          0.45,
                          DashboardStyles.accentOrange,
                        ),
                        _buildCircularProgress(
                          'Not Started',
                          0.25,
                          DashboardStyles.accentRed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Subject-wise Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subject-wise Progress',
                      style: DashboardStyles.sectionTitle,
                    ),
                    const SizedBox(height: 20),
                    _buildSubjectProgress('Mathematics', 0.85),
                    _buildSubjectProgress('Science', 0.72),
                    _buildSubjectProgress('English', 0.90),
                    _buildSubjectProgress('History', 0.65),
                    _buildSubjectProgress('Computer Science', 0.95),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSubjectProgress(String subject, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              value > 0.8
                  ? DashboardStyles.accentGreen
                  : value > 0.6
                  ? DashboardStyles.accentOrange
                  : DashboardStyles.accentRed,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Enhanced Reports Page ---
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

// --- Fully Implemented Pages for 'More' Options ---

class LearningActivityPage extends StatefulWidget {
  const LearningActivityPage({super.key});

  @override
  State<LearningActivityPage> createState() => _LearningActivityPageState();
}

class _LearningActivityPageState extends State<LearningActivityPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Videos',
    'Quizzes',
    'Assignments',
    'Reading',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Activity'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: DashboardStyles.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? DashboardStyles.primary
                            : DashboardStyles.textLight,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? DashboardStyles.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Activity Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActivityStatCard(
                      'Completed',
                      '24',
                      Icons.check_circle,
                      DashboardStyles.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActivityStatCard(
                      'In Progress',
                      '8',
                      Icons.access_time,
                      DashboardStyles.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActivityStatCard(
                      'Upcoming',
                      '12',
                      Icons.upcoming,
                      DashboardStyles.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Current Activities
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Current Activities',
                style: DashboardStyles.sectionTitle,
              ),
            ),
            const SizedBox(height: 16),

            // Activity Cards
            ..._buildActivityCards(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: DashboardStyles.background,
    );
  }

  Widget _buildActivityStatCard(
    String label,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: DashboardStyles.textLight),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityCards() {
    final activities = [
      {
        'title': 'Introduction to Machine Learning',
        'type': 'Video',
        'duration': '45 min',
        'progress': 0.7,
        'icon': Icons.play_circle_filled,
        'color': DashboardStyles.primary,
      },
      {
        'title': 'Physics Quiz - Chapter 5',
        'type': 'Quiz',
        'duration': '20 min',
        'progress': 0.0,
        'icon': Icons.quiz,
        'color': DashboardStyles.accentOrange,
      },
      {
        'title': 'Essay on Climate Change',
        'type': 'Assignment',
        'duration': 'Due in 2 days',
        'progress': 0.3,
        'icon': Icons.assignment,
        'color': DashboardStyles.accentGreen,
      },
      {
        'title': 'Advanced Calculus Textbook',
        'type': 'Reading',
        'duration': '120 pages',
        'progress': 0.5,
        'icon': Icons.menu_book,
        'color': DashboardStyles.accentPurple,
      },
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (activity['color'] as Color).withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            activity['icon'] as IconData,
                            color: activity['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      activity['type'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    activity['duration'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                    if ((activity['progress'] as double) > 0) ...[
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${((activity['progress'] as double) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activity['color'] as Color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: activity['progress'] as double,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activity['color'] as Color,
                            ),
                            minHeight: 4,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

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
                  child: Center(
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
                      Text(
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
          Text('Resume Sections', style: DashboardStyles.sectionTitle),
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
                    side: BorderSide(color: DashboardStyles.primary),
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
          Text('Practice Categories', style: DashboardStyles.sectionTitle),
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
          Text(
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: DashboardStyles.textLight),
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
          Icon(Icons.calendar_today, color: DashboardStyles.primary, size: 20),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: DashboardStyles.textLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Join',
              style: TextStyle(color: DashboardStyles.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSupportPage extends StatefulWidget {
  const SettingsSupportPage({super.key});

  @override
  State<SettingsSupportPage> createState() => _SettingsSupportPageState();
}

class _SettingsSupportPageState extends State<SettingsSupportPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoSaveEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Support'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=1',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarah Johnson',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'sarah.johnson@example.com',
                          style: TextStyle(
                            color: DashboardStyles.textLight,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: DashboardStyles.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Settings Section
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DashboardStyles.textDark,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive notifications about updates'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    activeColor: DashboardStyles.primary,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                    activeColor: DashboardStyles.primary,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto-save'),
                    subtitle: const Text('Automatically save your progress'),
                    value: _autoSaveEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoSaveEnabled = value;
                      });
                    },
                    activeColor: DashboardStyles.primary,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLanguageDialog();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Support Section
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DashboardStyles.textDark,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.bug_report_outlined,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Report a Bug'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.star_outline,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Rate Us'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // About Section
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DashboardStyles.textDark,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('About TEGA'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.update_outlined,
                      color: DashboardStyles.primary,
                    ),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutConfirmation(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardStyles.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      backgroundColor: DashboardStyles.background,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile(
                title: const Text('Spanish'),
                value: 'Spanish',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile(
                title: const Text('French'),
                value: 'French',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile(
                title: const Text('German'),
                value: 'German',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardStyles.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
