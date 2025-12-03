import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_notification_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/learning_history_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/transaction_history_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/start_payment_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/student_dashboard_header.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/student_stats_grid.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/weekly_progress_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/upcoming_events_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/recent_activity_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/achievements_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/enrolled_courses_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/widgets/recommended_courses_widget.dart';
import 'package:tega/features/5_student_dashboard/presentation/2_learning_hub/courses_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/student_ai_job_search_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/student_internships_page.dart';
// import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/resume_builder_page.dart'; // Kept for future use - removed from navbar
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

import 'package:tega/features/5_student_dashboard/data/announcement_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/student_profile_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/student_setting_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/help_support_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/placement_prep_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/6_exams/exams_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/7_results/my_results_page.dart';
// import 'package:tega/features/5_student_dashboard/presentation/shared/widgets/coming_soon_overlay.dart'; // Removed - LockedNavItem no longer used
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/ai_assistant_page.dart'
    as ai;
import 'package:tega/core/services/dashboard_cache_service.dart';

// --- AnnouncementDialog widget for college announcements ---
class AnnouncementDialog extends StatefulWidget {
  final List
  announcements; // Accepts either NotificationModel or AnnouncementModel
  const AnnouncementDialog({super.key, required this.announcements});

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  int _currentIndex = 0;

  void _nextAnnouncement() {
    if (_currentIndex < widget.announcements.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousAnnouncement() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    final currentAnnouncement = widget.announcements[_currentIndex];
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == widget.announcements.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop
              ? 600
              : isTablet
              ? 500
              : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: Theme.of(context).cardColor,
                      size: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College Announcements',
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          widget.announcements.length > 1
                              ? '${_currentIndex + 1} of ${widget.announcements.length}'
                              : 'Announcement',
                          style: TextStyle(
                            color: Theme.of(context).cardColor.withOpacity(0.9),
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Use the dialog's context to ensure we pop the correct route
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).cardColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: isSmallScreen ? 20 : 24,
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color:
                                  (currentAnnouncement.color ??
                                          Theme.of(context).primaryColor)
                                      .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              currentAnnouncement.icon ??
                                  Icons.campaign_rounded,
                              color:
                                  currentAnnouncement.color ??
                                  Theme.of(context).primaryColor,
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentAnnouncement.title?.toString() ??
                                      'Announcement',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: isSmallScreen ? 12 : 14,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      (currentAnnouncement.timeAgo
                                              ?.toString()) ??
                                          'Just now',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Message
                      if (currentAnnouncement.message != null &&
                          currentAnnouncement.message
                              .toString()
                              .isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentAnnouncement.message.toString(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Footer with navigation buttons
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous button
                  if (widget.announcements.length > 1)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: isFirst ? null : _previousAnnouncement,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: isSmallScreen ? 16 : 18,
                          color: isFirst
                              ? Colors.grey[400]
                              : Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: isFirst
                                ? Colors.grey[400]
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  // Spacing between buttons
                  if (widget.announcements.length > 1)
                    SizedBox(height: isSmallScreen ? 12 : 16),
                  // Next/Got it button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLast
                          ? () {
                              // Use the dialog's context to ensure we pop the correct route
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            }
                          : _nextAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).cardColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 24,
                          vertical: isSmallScreen ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLast ? 'Got it' : 'Next',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isLast) ...[
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: isSmallScreen ? 16 : 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with SingleTickerProviderStateMixin {
  // Static flag to prevent multiple dialogs across all instances
  static bool _isAnyAnnouncementShowing = false;
  // Static flag to track if announcements have been shown in this app session
  static bool _hasShownAnnouncementsThisSession = false;

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isSidebarOpen = false;
  bool _isAnnouncementDialogShowing = false;
  bool _isShowingAnnouncement =
      false; // Synchronous flag to prevent race conditions
  DateTime? _lastAnnouncementShown;
  User? _currentUser;
  late List<Widget> _pages;
  Map<String, dynamic> _sidebarCounts = {};
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _dashboardData = {};
  late AnimationController _sidebarAnimationController;
  final AuthService _authService = AuthService();
  final DashboardCacheService _cacheService = DashboardCacheService();

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Responsive getters
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // Responsive sidebar width
  double get sidebarWidth {
    if (isLargeDesktop) return 320;
    if (isDesktop) return 300;
    if (isTablet) return 280;
    return 300; // Mobile drawer width
  }

  // Should sidebar be always visible
  bool get shouldShowSidebarPermanently => isDesktop || isLargeDesktop;

  final List<String> _pageTitles = [
    'Dashboard', // 0
    'Explore Courses', // 1
    'Placement Prep', // 2
    'Exams', // 3
    'My Results', // 4
    'Jobs', // 5
    'Internships', // 6
    'AI Assistant', // 7 (Resume Builder removed)
    'Notifications', // 8
    'Learning History', // 9
    'Transaction History', // 10
    'Start Payment', // 11
    'Settings', // 12
    'Help & Support', // 13
    'Profile', // 14
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeCache();
    _loadUserData();
    _loadDashboardData();
    _initializePages();

    // Fetch and show announcements only once after initial login/app launch
    // Add a small delay to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showAnnouncementIfAny();
        }
      });
    });
  }

  Future<void> _showAnnouncementIfAny() async {
    // Prevent showing multiple dialogs - use static flag for global prevention
    // Also check if announcements have already been shown in this session
    if (_isAnyAnnouncementShowing ||
        _isShowingAnnouncement ||
        _isAnnouncementDialogShowing ||
        _hasShownAnnouncementsThisSession ||
        !mounted) {
      return;
    }

    // Set all flags immediately to prevent concurrent calls
    _isAnyAnnouncementShowing = true;
    _isShowingAnnouncement = true;

    // Set state flag as well
    setState(() {
      _isAnnouncementDialogShowing = true;
    });

    // Prevent showing too frequently (within 5 seconds)
    if (_lastAnnouncementShown != null) {
      final timeSinceLastShown = DateTime.now().difference(
        _lastAnnouncementShown!,
      );
      if (timeSinceLastShown.inSeconds < 5) {
        // Reset flags if we're not showing
        _isAnyAnnouncementShowing = false;
        _isShowingAnnouncement = false;
        if (mounted) {
          setState(() {
            _isAnnouncementDialogShowing = false;
          });
        }
        return;
      }
    }

    try {
      final announcements = await AnnouncementService()
          .getStudentAnnouncements();
      if (announcements.isNotEmpty && mounted) {
        setState(() {
          _lastAnnouncementShown = DateTime.now();
        });

        // Mark that announcements have been shown in this session
        _hasShownAnnouncementsThisSession = true;

        // Show dialog with consistent barrier color
        await showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Theme.of(context).shadowColor.withOpacity(0.5),
          builder: (ctx) => AnnouncementDialog(announcements: announcements),
        );
      } else {
        // No announcements, reset flags
        _isAnyAnnouncementShowing = false;
        _isShowingAnnouncement = false;
        if (mounted) {
          setState(() {
            _isAnnouncementDialogShowing = false;
          });
        }
      }
    } catch (_) {
      // Reset flags on error
      _isAnyAnnouncementShowing = false;
      _isShowingAnnouncement = false;
    } finally {
      // Always reset flags when done
      _isAnyAnnouncementShowing = false;
      _isShowingAnnouncement = false;
      if (mounted) {
        setState(() {
          _isAnnouncementDialogShowing = false;
        });
      }
    }
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
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

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    // If force refresh, clear cache first
    if (forceRefresh) {
      await _cacheService.clearCache();
    }

    // First, try to load from cache
    final cachedData = await _cacheService.getAllCachedData();

    if (cachedData != null && !forceRefresh) {
      // Cache is valid, use cached data immediately
      if (!mounted) return;
      setState(() {
        _sidebarCounts = cachedData['sidebarCounts'] ?? {};
        _dashboardData = cachedData['dashboard'] ?? {};
        _profile = cachedData['profile'] ?? {};
        _isLoading = false;
      });
      _initializePages();
    } else if (forceRefresh) {
      // Force refresh: show loading state
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
    }

    // Fetch fresh data from API (in background if cache exists)
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();

      // Fetch all data in parallel
      final results = await Future.wait([
        api.getSidebarCounts(headers),
        api.getDashboard(headers),
        api.getProfile(headers),
      ]);

      final sidebar = results[0];
      final dash = results[1];
      final prof = results[2];

      // Update cache with fresh data
      await _cacheService.setAllData(
        dashboard: dash,
        sidebarCounts: sidebar,
        profile: prof,
      );

      if (!mounted) return;
      setState(() {
        _sidebarCounts = sidebar;
        _dashboardData = dash;
        _profile = prof;
        _isLoading = false;
      });

      // Reinitialize pages with new data
      _initializePages();
    } catch (_) {
      // If API call fails and we have no cache, show error state
      if (!mounted) return;
      if (cachedData == null || forceRefresh) {
        setState(() {
          _isLoading = false;
        });
      }
      // If we have cached data, keep showing it even if API fails
    }
  }

  /// Refresh dashboard data (force fetch from API)
  Future<void> refreshDashboardData() async {
    await _loadDashboardData(forceRefresh: true);
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
      MyResultsPage(
        key: const PageStorageKey('results_page'),
        onNavigateToExams: () {
          setState(() {
            _selectedIndex = 3; // Switch to Exams tab (index 3)
          });
        },
      ), // My Results
      const JobRecommendationScreen(), // Jobs
      const InternshipsPage(), // Internships
      const _AIAssistantPage(), // AI Assistant (unlocked)
      const NotificationPage(), // Notifications
      const LearningHistoryPage(), // Learning History
      const TransactionHistoryPage(), // Transaction History
      const StartPaymentPage(), // Start Payment (unlocked)
      // const HelpPage(), // Help & Support (locked) - REMOVED
      const SettingsPage(), // Settings (unlocked)
      const HelpSupportPage(), // Help & Support (unlocked)
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
      barrierColor: Theme.of(context).shadowColor.withOpacity(0.3),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Row(
              children: [
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Clear cache before logout
                  await _cacheService.clearCache();

                  await _authService.logout();

                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
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

    // On desktop/large desktop, show sidebar permanently
    if (shouldShowSidebarPermanently) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              // Permanent sidebar
              _buildSidebar(),
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    // Header
                    StudentDashboardHeader(
                      onMenuTap: _toggleSidebar,
                      notificationCount: _sidebarCounts['notifications'] ?? 0,
                      title: _pageTitles[_selectedIndex],
                      profileData: _profile,
                    ),
                    // Page content
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
              ),
            ],
          ),
        ),
      );
    }

    // Mobile/Tablet: Drawer sidebar
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  profileData: _profile,
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
    // For desktop, always show sidebar
    if (shouldShowSidebarPermanently) {
      return Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: _buildSidebarContent(),
      );
    }

    // For mobile/tablet, use animated drawer
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isSidebarOpen ? 0 : -sidebarWidth,
      top: 0,
      bottom: 0,
      width: sidebarWidth,
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: shouldShowSidebarPermanently ? 0 : 20,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
        child: _buildSidebarContent(),
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        _buildSidebarHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
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
                // Resume Builder - Removed from navbar but code kept
                _buildNavItem(
                  icon: Icons.psychology_rounded,
                  title: 'AI Assistant',
                  index: 7,
                ),
                _buildNavItem(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  index: 8,
                  badge: (_sidebarCounts['notifications'] ?? 0) > 0
                      ? _sidebarCounts['notifications'].toString()
                      : null,
                ),
                _buildNavItem(
                  icon: Icons.history_rounded,
                  title: 'Learning History',
                  index: 9,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Transaction History',
                  index: 10,
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                const Divider(height: 1),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildSectionHeader('QUICK ACTIONS'),
                _buildNavItem(
                  icon: Icons.payment_rounded,
                  title: 'Start Payment',
                  index: 11,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  index: 12,
                ),
                _buildNavItem(
                  icon: Icons.help_rounded,
                  title: 'Help & Support',
                  index: 13,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  index: 14,
                ),
              ],
            ),
          ),
        ),
        _buildLogoutTile(),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    // Get course details - try multiple possible field names from backend
    final inst =
        (_profile['institute'] ??
                _profile['instituteName'] ??
                _profile['college'] ??
                _currentUser?.college ??
                '')
            .toString();
    final yr =
        (_profile['yearOfStudy'] ??
                _profile['year'] ??
                _currentUser?.year ??
                '')
            .toString();
    final cour =
        (_profile['course'] ??
                _profile['courseName'] ??
                _currentUser?.course ??
                '')
            .toString();
    final display = [
      cour.isNotEmpty ? cour : 'Course: To be updated',
      yr.isNotEmpty ? 'Year $yr' : 'Year: To be updated',
      inst.isNotEmpty ? inst : 'Institute: To be updated',
    ].join(' | ');

    // Responsive padding and sizes
    final headerPadding = isLargeDesktop
        ? const EdgeInsets.fromLTRB(24, 48, 24, 28)
        : isDesktop
        ? const EdgeInsets.fromLTRB(20, 40, 20, 24)
        : isTablet
        ? const EdgeInsets.fromLTRB(18, 36, 18, 20)
        : const EdgeInsets.fromLTRB(16, 32, 16, 20);

    final avatarRadius = isLargeDesktop
        ? 32.0
        : isDesktop
        ? 28.0
        : isTablet
        ? 26.0
        : 24.0;

    final iconSize = isLargeDesktop
        ? 36.0
        : isDesktop
        ? 32.0
        : isTablet
        ? 30.0
        : 28.0;

    final nameFontSize = isLargeDesktop
        ? 18.0
        : isDesktop
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;

    final detailFontSize = isLargeDesktop
        ? 13.0
        : isDesktop
        ? 12.0
        : isTablet
        ? 11.5
        : 11.0;

    return Container(
      width: double.infinity,
      padding: headerPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 2 : 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).cardColor.withOpacity(0.3),
                width: isSmallScreen ? 1.5 : 2,
              ),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(
                Icons.school_rounded,
                size: iconSize,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            _currentUser?.name ?? 'Student',
            style: TextStyle(
              color: Theme.of(context).cardColor,
              fontWeight: FontWeight.bold,
              fontSize: nameFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 3 : 4),
          Text(
            display,
            style: TextStyle(
              color: Theme.of(context).cardColor.withOpacity(0.8),
              fontSize: detailFontSize,
            ),
            maxLines: isSmallScreen ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final fontSize = isLargeDesktop
        ? 13.0
        : isDesktop
        ? 12.0
        : isTablet
        ? 11.5
        : 11.0;

    final padding = isLargeDesktop
        ? const EdgeInsets.fromLTRB(16, 20, 16, 10)
        : isDesktop
        ? const EdgeInsets.fromLTRB(12, 16, 12, 8)
        : isTablet
        ? const EdgeInsets.fromLTRB(10, 14, 10, 7)
        : const EdgeInsets.fromLTRB(8, 12, 8, 6);

    return Padding(
      padding: padding,
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).hintColor.withOpacity(0.6),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: isSmallScreen ? 0.8 : 1.2,
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

    // Responsive sizing
    final iconSize = isLargeDesktop
        ? 22.0
        : isDesktop
        ? 20.0
        : isTablet
        ? 19.0
        : 18.0;

    final fontSize = isLargeDesktop
        ? 15.0
        : isDesktop
        ? 14.0
        : isTablet
        ? 13.5
        : 13.0;

    final padding = isLargeDesktop
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
        : isDesktop
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : isTablet
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 8);

    final iconPadding = isLargeDesktop
        ? 7.0
        : isDesktop
        ? 6.0
        : isTablet
        ? 5.5
        : 5.0;

    final borderRadius = isLargeDesktop
        ? 14.0
        : isDesktop
        ? 12.0
        : isTablet
        ? 11.0
        : 10.0;

    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: () {
          if (_selectedIndex != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          }
          if (!shouldShowSidebarPermanently) {
            _toggleSidebar();
          }
        },
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Theme.of(context).disabledColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).unselectedWidgetColor,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color ??
                              Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: fontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: isSmallScreen ? 9 : 11,
                      fontWeight: FontWeight.w700,
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
    final margin = isSmallScreen
        ? const EdgeInsets.all(6)
        : isTablet
        ? const EdgeInsets.all(10)
        : const EdgeInsets.all(8);

    final fontSize = isLargeDesktop
        ? 15.0
        : isDesktop
        ? 14.0
        : isTablet
        ? 13.5
        : 13.0;

    final iconSize = isLargeDesktop
        ? 22.0
        : isDesktop
        ? 20.0
        : isTablet
        ? 19.0
        : 18.0;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        dense: isSmallScreen,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 4 : 8,
        ),
        leading: Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
            size: iconSize,
          ),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.error,
          size: isSmallScreen ? 14 : 16,
        ),
        onTap: _showLogoutConfirmation,
      ),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  final Map<String, dynamic> sidebarCounts;
  final Map<String, dynamic> dashboardData;

  _HomePageContent({required this.sidebarCounts, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final userProgress = dashboardData['userProgress'] ?? {};
    final recentActivity = dashboardData['recentActivity'] ?? [];
    final upcomingEvents = dashboardData['upcomingEvents'] ?? [];
    final achievements = dashboardData['achievements'] ?? [];
    final recommendedCourses = dashboardData['recommendedCourses'] ?? [];

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    final isSmallScreen = screenWidth < 400;
    final isLandscape = screenWidth > screenHeight;

    // Responsive padding
    final horizontalPadding = isLargeDesktop
        ? 32.0
        : isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : isSmallScreen
        ? 12.0
        : 16.0;

    final verticalPadding = isLargeDesktop
        ? 28.0
        : isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : isSmallScreen
        ? 14.0
        : 16.0;

    final spacing = isLargeDesktop
        ? 28.0
        : isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : isSmallScreen
        ? 14.0
        : 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = isLargeDesktop
            ? 1600.0
            : isDesktop
            ? 1400.0
            : double.infinity;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards Grid (2x2) with animations
                  // Use a key that changes when dashboardData is populated to force rebuild
                  StudentStatsGrid(
                    key: ValueKey(
                      'stats_${dashboardData.isNotEmpty ? dashboardData.hashCode : 'loading'}',
                    ),
                  ),
                  SizedBox(height: spacing),
                  // Weekly Progress
                  WeeklyProgressWidget(
                    weeklyProgress: userProgress['weeklyProgress'] ?? 0,
                    weeklyGoal: userProgress['weeklyGoal'] ?? 10,
                    currentStreak: userProgress['currentStreak'] ?? 0,
                  ),
                  SizedBox(height: spacing),
                  // Enrolled Courses
                  // Use a key that changes when dashboardData is populated to force rebuild
                  EnrolledCoursesWidget(
                    key: ValueKey(
                      'enrolled_${dashboardData.isNotEmpty ? dashboardData.hashCode : 'loading'}',
                    ),
                  ),
                  SizedBox(height: spacing),
                  // Recent Activity and Upcoming Events - Responsive layout
                  _buildResponsiveTwoColumn(
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                    isLargeDesktop: isLargeDesktop,
                    isLandscape: isLandscape,
                    spacing: spacing,
                    firstChild: RecentActivityWidget(
                      activities: recentActivity,
                    ),
                    secondChild: UpcomingEventsWidget(events: upcomingEvents),
                  ),
                  SizedBox(height: spacing),
                  // Achievements
                  AchievementsWidget(achievements: achievements),
                  SizedBox(height: spacing),
                  // Recommended Courses
                  RecommendedCoursesWidget(courses: recommendedCourses),
                  SizedBox(height: spacing),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveTwoColumn({
    required bool isTablet,
    required bool isDesktop,
    required bool isLargeDesktop,
    required bool isLandscape,
    required double spacing,
    required Widget firstChild,
    required Widget secondChild,
  }) {
    // Show side by side on desktop/large desktop, or tablet in landscape
    if (isLargeDesktop || (isDesktop && isLandscape)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: firstChild),
          SizedBox(width: spacing),
          Expanded(flex: 1, child: secondChild),
        ],
      );
    } else if (isDesktop || (isTablet && isLandscape)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: firstChild),
          SizedBox(width: spacing),
          Expanded(child: secondChild),
        ],
      );
    } else {
      // Stack vertically on mobile and tablet portrait
      return Column(
        children: [
          firstChild,
          SizedBox(height: spacing),
          secondChild,
        ],
      );
    }
  }
}

// Placeholder pages for navigation items
class _AIAssistantPage extends StatelessWidget {
  const _AIAssistantPage();

  @override
  Widget build(BuildContext context) {
    return const ai.AIAssistantPage();
  }
}
