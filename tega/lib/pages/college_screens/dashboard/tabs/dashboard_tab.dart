import 'package:flutter/material.dart';
import 'package:tega/services/auth_service.dart'; // NEW: Import AuthService
import 'package:tega/pages/college_screens/dashboard/widgets/actionable_insights.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/performance_metrics.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/progress_chart.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/quick_actions.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/recent_activity.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/search_bar.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/stats_grid.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/upcoming_events.dart';
import 'package:tega/pages/college_screens/dashboard/widgets/welcome_header.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final TextEditingController _searchController = TextEditingController();

  // NEW: State variables to hold user data and loading state
  User? _currentUser;
  bool _isLoading = true;
  int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // NEW: Method to get the logged-in user from the AuthService
  void _loadUserData() {
    final authService = AuthService();
    setState(() {
      _currentUser = authService.currentUser;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNotifications(BuildContext context) {
    // Implement your notification dialog logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Show a loading indicator while data is being fetched
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // NEW: Handle the case where the user might not be found
    if (_currentUser == null) {
      return const Center(child: Text("User not found."));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // MODIFIED: Pass the dynamic user name to the header
            WelcomeHeader(
              userName: _currentUser!.name, // Using the fetched user's name
              notificationCount: _notificationCount,
              onNotificationTap: () => _showNotifications(context),
            ),
            const SizedBox(height: 16),
            SearchBarWidget(controller: _searchController),
            const SizedBox(height: 24),
            const QuickActions(),
            const SizedBox(height: 32),
            const StatsGrid(),
            const SizedBox(height: 32),
            const ProgressChartCard(),
            const SizedBox(height: 32),
            const PerformanceMetrics(),
            const SizedBox(height: 32),
            const UpcomingEvents(),
            const SizedBox(height: 32),
            const ActionableInsights(),
            const SizedBox(height: 32),
            const RecentActivity(),
          ],
        ),
      ),
    );
  }
}
