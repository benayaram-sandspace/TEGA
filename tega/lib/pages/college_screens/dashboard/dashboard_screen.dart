import 'dart:ui'; // Required for ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/services/auth_service.dart';
// Tab imports
import 'tabs/dashboard_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/reports_tab.dart';
// More options imports - now used as tabs
import 'more_options/learning_activity_page.dart';
import 'more_options/resume_interview_page.dart';
import 'more_options/settings_support_page.dart';

// Main Dashboard Screen Widget
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  final AuthService _authService = AuthService();
  late AnimationController _sidebarAnimationController;

  final List<Widget> _pages = [
    const DashboardTab(),
    const StudentsPage(),
    const ProgressPage(),
    const ReportsPage(),
    const LearningActivityPage(),
    const ResumeInterviewPage(),
    const SettingsSupportPage(),
  ];

  final List<String> _pageTitles = const [
    'Dashboard',
    'Students',
    'Progress',
    'Reports',
    'Learning Activity',
    'Resume & Interview',
    'Settings & Support',
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
      builder: (BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DashboardStyles.primary),
          ),
        ),
      ),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: DashboardStyles.cardBackground,
            title: const Row(
              children: [
                Icon(Icons.logout, color: DashboardStyles.accentRed),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: DashboardStyles.textLight),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: DashboardStyles.textLight),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).pop();
                  _handleLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardStyles.accentRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
      backgroundColor: DashboardStyles.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.5).animate(animation),
              child: child,
            ),
            child: Icon(
              _isSidebarOpen ? Icons.close : Icons.menu,
              key: ValueKey<bool>(_isSidebarOpen),
              color: DashboardStyles.textDark,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _toggleSidebar();
          },
        ),
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: DashboardStyles.cardBackground,
        elevation: 2,
        iconTheme: const IconThemeData(color: DashboardStyles.textDark),
        titleTextStyle: DashboardStyles.insightTitle.copyWith(fontSize: 20),
      ),
      body: Stack(
        children: [
          // Main content - ensure all pages are rendered
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey<int>(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
          ),
          // Overlay when sidebar is open
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar,
              child: AnimatedBuilder(
                animation: _sidebarAnimationController,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(
                      0.5 * _sidebarAnimationController.value,
                    ),
                  );
                },
              ),
            ),
          // Animated Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            left: _isSidebarOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            width: 280,
            child: Material(
              color: DashboardStyles.cardBackground,
              elevation: 16,
              shadowColor: Colors.black.withOpacity(0.3),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DashboardStyles.cardBackground,
                      DashboardStyles.background.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _buildSidebarHeader(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildNavSection(
                            title: '',
                            items: [
                              NavItem(
                                icon: Icons.dashboard,
                                title: 'Dashboard',
                                index: 0,
                              ),
                              NavItem(
                                icon: Icons.people,
                                title: 'Students',
                                index: 1,
                              ),
                              NavItem(
                                icon: Icons.trending_up,
                                title: 'Progress',
                                index: 2,
                              ),
                              NavItem(
                                icon: Icons.bar_chart,
                                title: 'Reports',
                                index: 3,
                              ),
                              NavItem(
                                icon: Icons.local_activity,
                                title: 'Learning Activity',
                                index: 4,
                              ),
                              NavItem(
                                icon: Icons.article,
                                title: 'Resume & Interview',
                                index: 5,
                              ),
                              NavItem(
                                icon: Icons.settings,
                                title: 'Settings & Support',
                                index: 6,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: DashboardStyles.textLight),
                    _buildLogoutTile(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.primary.withOpacity(0.9),
            DashboardStyles.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardStyles.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 35,
                color: DashboardStyles.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'College Admin',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Administrator',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection({
    required String title,
    required List<NavItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: DashboardStyles.textLight.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map(
          (item) => _buildNavItem(
            icon: item.icon,
            title: item.title,
            index: item.index,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    int? index,
  }) {
    final isSelected = index != null && _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? DashboardStyles.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? DashboardStyles.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? DashboardStyles.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? DashboardStyles.primary
                : DashboardStyles.textLight,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? DashboardStyles.primary
                : DashboardStyles.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: DashboardStyles.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            if (index != null) {
              _selectedIndex = index;
            }
            _isSidebarOpen = false;
          });
        },
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DashboardStyles.accentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DashboardStyles.accentRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DashboardStyles.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.logout,
            color: DashboardStyles.accentRed,
            size: 20,
          ),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: DashboardStyles.accentRed,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: DashboardStyles.accentRed,
          size: 16,
        ),
        onTap: _showLogoutConfirmation,
      ),
    );
  }
}

// Helper class for navigation items
class NavItem {
  final IconData icon;
  final String title;
  final int? index;

  NavItem({required this.icon, required this.title, this.index});
}
