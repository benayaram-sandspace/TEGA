import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/tabs/dashboard_home_tab.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/colleges/admins_management_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/colleges/colleges_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/colleges/add_college_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/students/students_page.dart';
import 'package:tega/features/3_admin_panel/presentation/2_content/content_page.dart';
import 'package:tega/features/3_admin_panel/presentation/3_reports_and_analytics/analytics_page.dart';
import 'package:tega/features/3_admin_panel/presentation/3_reports_and_analytics/report_export_page.dart';
import 'package:tega/features/3_admin_panel/presentation/4_settings_and_misc/notification_manager_page.dart';
import 'package:tega/features/3_admin_panel/presentation/4_settings_and_misc/settings_page.dart';
import 'package:tega/features/6_support_system/presentation/admin_view/support_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  final AuthService _authService = AuthService();
  late AnimationController _sidebarAnimationController;

  static final Map<String, Map<String, String>> _translations = {
    'EN': {
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
    },
  };

  String _tr(String key) => _translations['EN']![key] ?? key;

  late final List<Widget> _pages;
  late final List<String> _pageTitles;

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pages = [
      DashboardHomeTab(authService: _authService),
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

    _pageTitles = [
      _tr('dashboard'),
      _tr('colleges'),
      _tr('students'),
      _tr('analytics'),
      _tr('content'),
      _tr('support'),
      _tr('admin_management'),
      _tr('settings'),
      _tr('notification_manager'),
      _tr('reports'),
    ];
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    });
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pop();
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 8),
                Text(_tr('logout_confirm_title')),
              ],
            ),
            content: Text(_tr('logout_confirm_body')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _tr('logout'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardStyles.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: AdminDashboardStyles.mediumAnimation,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AdminDashboardStyles.defaultCurve,
                )),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
          ),
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar,
              child: AnimatedBuilder(
                animation: _sidebarAnimationController,
                builder: (context, child) => Container(
                  color: Colors.black.withValues(
                    alpha: 0.6 * _sidebarAnimationController.value,
                  ),
                ),
              ),
            ),
          _buildSidebar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          progress: _sidebarAnimationController,
          color: Colors.white,
        ),
        onPressed: _toggleSidebar,
      ),
      title: Text(
        _pageTitles[_selectedIndex],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 18,
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2),
      backgroundColor: AdminDashboardStyles.primary,
      elevation: 8,
      shadowColor: AdminDashboardStyles.primary.withValues(alpha: 0.3),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AdminDashboardStyles.primary,
              AdminDashboardStyles.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: _selectedIndex == 1 ? [
        // Show Add New College button only when on Colleges page
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const AddCollegePage(),
                    ),
                  )
                  .then((_) {
                    // Refresh colleges list if needed
                    if (mounted) {
                      setState(() {});
                    }
                  });
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add New College',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ] : null,
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      duration: AdminDashboardStyles.mediumAnimation,
      curve: AdminDashboardStyles.slideCurve,
      left: _isSidebarOpen ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Material(
        color: Colors.white,
        elevation: 20,
        shadowColor: AdminDashboardStyles.primary.withValues(alpha: 0.2),
        child: Column(
          children: [
            _buildSidebarHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    title: _tr('dashboard'),
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.school_rounded,
                    title: _tr('colleges'),
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.people_rounded,
                    title: _tr('students'),
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.analytics_rounded,
                    title: _tr('analytics'),
                    index: 3,
                  ),
                  _buildNavItem(
                    icon: Icons.content_copy_rounded,
                    title: _tr('content'),
                    index: 4,
                  ),
                  _buildNavItem(
                    icon: Icons.support_agent_rounded,
                    title: _tr('support'),
                    index: 5,
                  ),
                  const Divider(height: 24),
                  _buildNavItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: _tr('admin_management'),
                    index: 6,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    title: _tr('settings'),
                    index: 7,
                  ),
                  _buildNavItem(
                    icon: Icons.notifications_rounded,
                    title: _tr('notification_manager'),
                    index: 8,
                  ),
                  _buildNavItem(
                    icon: Icons.assessment_rounded,
                    title: _tr('reports'),
                    index: 9,
                  ),
                ],
              ),
            ),
            _buildLogoutTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdminDashboardStyles.primary,
            AdminDashboardStyles.primaryLight,
          ],
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
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.shield_rounded,
                size: 36,
                color: AdminDashboardStyles.primary,
              ),
            ),
          ).animate().scale(duration: 500.ms, curve: AdminDashboardStyles.bounceCurve),
          const SizedBox(height: 16),
          Text(
            _authService.currentUser?.name ?? 'Admin User',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(begin: 0.3),
          const SizedBox(height: 4),
          Text(
            _authService.currentUserRole != null
                ? _authService.getRoleDisplayName(_authService.currentUserRole!)
                : 'Administrator',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideX(begin: 0.3),
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
    return Material(
      color: isSelected
          ? AdminDashboardStyles.primary.withValues(alpha: 0.1)
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
        splashColor: AdminDashboardStyles.primary.withValues(alpha: 0.2),
        highlightColor: AdminDashboardStyles.primary.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: AdminDashboardStyles.shortAnimation,
          curve: AdminDashboardStyles.defaultCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected 
                ? AdminDashboardStyles.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isSelected 
                ? Border.all(
                    color: AdminDashboardStyles.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AdminDashboardStyles.shortAnimation,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AdminDashboardStyles.primary.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AdminDashboardStyles.primary : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AdminDashboardStyles.primary : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.arrow_forward_ios,
                  color: AdminDashboardStyles.primary,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50)).slideX(begin: 0.2);
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: _showLogoutConfirmation,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: Text(
          _tr('logout'),
          style: const TextStyle(
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
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 600.ms).slideX(begin: 0.2);
  }
}