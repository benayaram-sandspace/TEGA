import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/services/auth_service.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/reports_tab.dart';
import 'more_options/learning_activity_page.dart';
import 'more_options/resume_interview_page.dart';
import 'more_options/settings_support_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _pages = [
    const DashboardTab(),
    const StudentsPage(),
    const ProgressPage(),
    const ReportsPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
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
                  Navigator.pop(context);
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
                onTap: () {
                  Navigator.pop(context); // Close the sheet before logging out
                  _handleLogout();
                },
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
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
}
