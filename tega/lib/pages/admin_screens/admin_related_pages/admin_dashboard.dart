import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/pages/admin_screens/admin_related_pages/admin_management_page.dart';
import 'package:tega/pages/admin_screens/analysis_report/analytics_page.dart';
import 'package:tega/pages/admin_screens/colleges/colleges_page.dart';
import 'package:tega/pages/admin_screens/content_page/content_page.dart';
import 'package:tega/pages/admin_screens/misc/settings_page.dart';
import 'package:tega/pages/admin_screens/notification_pages/notification_manager_page.dart';
import 'package:tega/pages/admin_screens/reports/report_export_page.dart';
import 'package:tega/pages/admin_screens/support/support_page.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/services/auth_service.dart';
import 'package:tega/pages/admin_screens/admin_student_pages/students_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  final AuthService _authService = AuthService();

  // ✨ --- Language Translations (English only) --- ✨
  static final Map<String, Map<String, String>> _translations = {
    'EN': {
      'dashboard_title': 'TEGA Admin Dashboard',
      'dashboard': 'Dashboard',
      'colleges': 'Colleges',
      'students': 'Students',
      'analytics': 'Analytics',
      'content': 'Content',
      'support': 'Support & Feedback',
      'admin_management': 'Admins Management',
      'settings': 'Settings',
      'notification_manager': 'Notification Manager',
      'reports': 'Reports & Export',
      'logout': 'Logout',
      'logout_confirm_title': 'Logout',
      'logout_confirm_body': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'profile': 'Profile',
      'role': 'Role',
      'welcome_back': 'Welcome Back,',
      'dashboard_subtitle': "Here's your performance summary for today.",
      'analytics_chart_title': 'Weekly Student Signups',
      'total_colleges': 'Total Colleges',
      'total_students': 'Total Students',
      'content_modules': 'Content Modules',
      'support_tickets': 'Support Tickets',
    },
  };

  String _tr(String key) {
    // Always use English as Telugu has been removed.
    return _translations['EN']![key] ?? key;
  }
  // ✨ --- End of Translations --- ✨

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHome(
        tr: _tr,
        authService: _authService,
      ), // Pass translator and service
      const CollegesPage(),
      const StudentsPage(),
      const AnalyticsPage(),
      const ContentPage(),
      const SupportPage(),
      const AdminManagementPage(),
      const SettingsPage(),
      const NotificationManagerPage(),
      const ReportsExportCenterPage(),
    ];
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(_tr('logout_confirm_title')),
          content: Text(_tr('logout_confirm_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _tr('cancel'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: Text(
                _tr('logout'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              // Simplified key as language no longer changes
              key: ValueKey<int>(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
          ),
          _buildSidebar(),
        ],
      ),
      // Removed the FloatingActionButton for language switching
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              RotationTransition(turns: animation, child: child),
          child: Icon(
            _isSidebarOpen ? Icons.close : Icons.menu,
            key: ValueKey<bool>(_isSidebarOpen),
            color: AppColors.pureWhite,
          ),
        ),
        onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
      ),
      title: Text(
        _tr('dashboard_title'),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
        ),
      ),
      backgroundColor: AppColors.primary,
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.3),
    );
  }

  Widget _buildSidebar() {
    return Stack(
      children: [
        if (_isSidebarOpen)
          GestureDetector(
            onTap: () => setState(() => _isSidebarOpen = false),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _isSidebarOpen ? 0 : -280,
          top: 0,
          bottom: 0,
          width: 280,
          child: Material(
            color: AppColors.surface,
            elevation: 16,
            child: Column(
              children: [
                _buildSidebarHeader(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        title: _tr('dashboard'),
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.school,
                        title: _tr('colleges'),
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.people,
                        title: _tr('students'),
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.analytics,
                        title: _tr('analytics'),
                        index: 3,
                      ),
                      _buildNavItem(
                        icon: Icons.content_copy,
                        title: _tr('content'),
                        index: 4,
                      ),
                      _buildNavItem(
                        icon: Icons.support_agent,
                        title: _tr('support'),
                        index: 5,
                      ),
                      _buildNavItem(
                        icon: Icons.admin_panel_settings,
                        title: _tr('admin_management'),
                        index: 6,
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        title: _tr('settings'),
                        index: 7,
                      ),
                      _buildNavItem(
                        icon: Icons.notifications,
                        title: _tr('notification_manager'),
                        index: 8,
                      ),
                      _buildNavItem(
                        icon: Icons.assessment,
                        title: _tr('reports'),
                        index: 9,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    _tr('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: _showLogoutConfirmation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.account_circle,
              size: 40,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _authService.currentUser?.name ?? 'Admin User',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          // ✨ --- FIX: Added a null check for currentUserRole --- ✨
          Text(
            _authService.currentUserRole != null
                ? _authService.getRoleDisplayName(_authService.currentUserRole!)
                : 'Admin', // Default fallback text
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _isSidebarOpen = false;
          });
        },
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  final String Function(String) tr;
  final AuthService authService;

  const DashboardHome({super.key, required this.tr, required this.authService});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCardsGridView(),
            const SizedBox(height: 24),
            _buildAnalyticsChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String adminName = widget.authService.currentUser?.name ?? 'Admin';
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.tr('welcome_back')} $adminName!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.tr('dashboard_subtitle'),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGridView() {
    final items = [
      {
        'icon': Icons.school,
        'title': widget.tr('total_colleges'),
        'value': '150',
        'color': Colors.blue,
      },
      {
        'icon': Icons.people,
        'title': widget.tr('total_students'),
        'value': '12,500',
        'color': Colors.green,
      },
      {
        'icon': Icons.content_copy,
        'title': widget.tr('content_modules'),
        'value': '85',
        'color': Colors.orange,
      },
      {
        'icon': Icons.support_agent,
        'title': widget.tr('support_tickets'),
        'value': '25',
        'color': Colors.red,
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.2 * index,
              0.6 + 0.1 * index,
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        return _buildAnimatedDashboardCard(item: item, animation: animation);
      },
    );
  }

  Widget _buildAnimatedDashboardCard({
    required Map<String, dynamic> item,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: _buildDashboardCard(
          icon: item['icon'],
          title: item['title'],
          value: item['value'],
          color: item['color'],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tr('analytics_chart_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildChartBar('Mon', 0.4, Colors.blue),
                      _buildChartBar('Tue', 0.6, Colors.blue),
                      _buildChartBar('Wed', 0.5, Colors.blue),
                      _buildChartBar('Thu', 0.8, Colors.orange),
                      _buildChartBar('Fri', 0.9, Colors.orange),
                      _buildChartBar('Sat', 0.7, Colors.green),
                      _buildChartBar('Sun', 0.3, Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar(String day, double heightFraction, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 120 * heightFraction,
          width: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
