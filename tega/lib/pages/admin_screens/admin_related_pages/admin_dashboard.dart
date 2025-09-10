import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/pages/admin_screens/admin_student_pages/students_page.dart';
import 'package:tega/pages/admin_screens/analysis_report/analytics_page.dart';
import 'package:tega/pages/admin_screens/colleges/colleges_page.dart';
import 'package:tega/pages/admin_screens/content_page/content_page.dart';
import 'package:tega/pages/admin_screens/misc/settings_page.dart';
import 'package:tega/pages/admin_screens/notification_pages/notification_manager_page.dart';
import 'package:tega/pages/admin_screens/reports/report_export_page.dart';
import 'package:tega/pages/admin_screens/support/support_page.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/services/auth_service.dart';
import 'admin_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  final AuthService _authService = AuthService();

  final List<Widget> _pages = [
    const DashboardHome(),
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

        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          // Navigate to login page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) => const LoginPage(),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            key: ValueKey(_isSidebarOpen),
            icon: Icon(
              _isSidebarOpen ? Icons.close : Icons.menu,
              color: AppColors.pureWhite,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
          ),
        ),
        title: const Text(
          'TEGA Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.pureWhite,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: AppColors.pureWhite),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(_authService.currentUser?.name ?? 'User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: _authService.getRoleColor(
                        _authService.currentUserRole!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _authService.getRoleDisplayName(
                        _authService.currentUserRole!,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Watermark Layer
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.08, // Very subtle watermark
                  child: Image.asset(
                    'assets/logo.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(); // Return empty container if image fails
                    },
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          _pages[_selectedIndex],

          // Overlay Background
          if (_isSidebarOpen)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSidebarOpen ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSidebarOpen = false;
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

          // Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isSidebarOpen ? 0 : -250,
            top: 0,
            bottom: 0,
            width: 250,
            child: Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  // Navigation Menu
                  Expanded(
                    child: ListView(
                      children: [
                        _buildNavItem(
                          icon: Icons.dashboard,
                          title: 'Dashboard',
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.school,
                          title: 'Colleges',
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.people,
                          title: 'Students',
                          index: 2,
                        ),
                        _buildNavItem(
                          icon: Icons.analytics,
                          title: 'Analytics',
                          index: 3,
                        ),
                        _buildNavItem(
                          icon: Icons.content_copy,
                          title: 'Content',
                          index: 4,
                        ),
                        _buildNavItem(
                          icon: Icons.support_agent,
                          title: 'Support and feedback',
                          index: 5,
                        ),
                        _buildNavItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Admins Management',
                          index: 6,
                        ),
                        _buildNavItem(
                          icon: Icons.settings,
                          title: 'Settings',
                          index: 7,
                        ),
                        _buildNavItem(
                          icon: Icons.notifications,
                          title: 'Notification Manager',
                          index: 8,
                        ),
                        _buildNavItem(
                          icon: Icons.assessment,
                          title: 'Report And Export Center',
                          index: 9,
                        ),
                      ],
                    ),
                  ),
                  // Add Logout Button at bottom of sidebar
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                      _showLogoutConfirmation();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _isSidebarOpen = false; // Always close sidebar after selection
          });
        },
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Just close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _handleLogout(); // Then handle logout
              },
              child: const Text(
                'Logout',
                style: TextStyle(
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
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to TEGA Admin Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a menu item from the sidebar to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
