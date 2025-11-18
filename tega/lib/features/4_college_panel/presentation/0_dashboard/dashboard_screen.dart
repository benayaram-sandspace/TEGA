import 'dart:ui'; // Required for ImageFilter.blur
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/principal_dashboard_cache_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/reports_insights_tab.dart';
import 'tabs/communication_tab.dart';

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
  final PrincipalDashboardCacheService _cacheService =
      PrincipalDashboardCacheService();
  late AnimationController _sidebarAnimationController;

  // Principal data from backend
  Map<String, dynamic>? _principalData;

  final List<Widget> _pages = [
    const DashboardTab(),
    const StudentsPage(), // Student Management
    const AnalyticsPage(), // Analytics
    const ReportsInsightsPage(), // Reports & Insights
    const CommunicationPage(), // Communication
  ];

  final List<String> _pageTitles = const [
    'Dashboard',
    'Student Management',
    'Analytics',
    'Reports & Insights',
    'Communication',
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeCacheAndLoadPrincipalData();
  }

  Future<void> _initializeCacheAndLoadPrincipalData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadPrincipalDataFromCache();

    // Then load fresh data
    await _loadPrincipalData();
  }

  Future<void> _loadPrincipalDataFromCache() async {
    try {
      final cachedData = await _cacheService.getPrincipalData();
      if (cachedData != null && mounted) {
        setState(() {
          _principalData = cachedData;
        });
      }
    } catch (e) {
      // Silently handle cache errors
    }
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
  }

  Future<void> _loadPrincipalData() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(ApiEndpoints.principalDashboard), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['principal'] != null) {
          final principalData = data['principal'] as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _principalData = principalData;
            });

            // Cache the principal data
            await _cacheService.setPrincipalData(principalData);
          }
        }
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getPrincipalData();
        if (cachedData != null && mounted) {
          setState(() {
            _principalData = cachedData;
          });
        }
      }
      // Silently handle errors, fallback to AuthService data
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Fixed sidebar width for all screen sizes
    final sidebarWidth = 260.0;

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
              size: isMobile ? 22 : 24,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _toggleSidebar();
          },
        ),
        title: Text(
          _pageTitles[_selectedIndex],
          style: DashboardStyles.insightTitle.copyWith(
            fontSize: isMobile
                ? 18
                : isTablet
                ? 19
                : 20,
          ),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        elevation: 2,
        iconTheme: const IconThemeData(color: DashboardStyles.textDark),
        titleTextStyle: DashboardStyles.insightTitle.copyWith(
          fontSize: isMobile
              ? 18
              : isTablet
              ? 19
              : 20,
        ),
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
            left: _isSidebarOpen ? 0 : -sidebarWidth,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
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
                    _buildSidebarHeader(isMobile, isTablet),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildNavSection(
                            title: '',
                            items: [
                              NavItem(
                                icon: Icons.dashboard_rounded,
                                title: 'Dashboard',
                                index: 0,
                              ),
                              NavItem(
                                icon: Icons.people_rounded,
                                title: 'Student Management',
                                index: 1,
                              ),
                              NavItem(
                                icon: Icons.analytics_rounded,
                                title: 'Analytics',
                                index: 2,
                              ),
                              NavItem(
                                icon: Icons.insights_rounded,
                                title: 'Reports & Insights',
                                index: 3,
                              ),
                              NavItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'Communication',
                                index: 4,
                                badge: '3',
                              ),
                            ],
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: DashboardStyles.textLight,
                      thickness: 1,
                    ),
                    _buildLogoutTile(isMobile, isTablet),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isMobile, bool isTablet) {
    // Use backend data if available, otherwise fallback to AuthService
    final principalName =
        _principalData?['principalName'] as String? ??
        _authService.currentUser?.name ??
        'Principal';
    final collegeName =
        _principalData?['university'] as String? ??
        _authService.currentUser?.university ??
        'College';

    // Get first letter from principal name
    final firstLetter = principalName.isNotEmpty
        ? principalName[0].toUpperCase()
        : 'P';

    // Responsive values
    final padding = isMobile
        ? 16.0
        : isTablet
        ? 18.0
        : 20.0;
    final topPadding = isMobile
        ? 32.0
        : isTablet
        ? 36.0
        : 40.0;
    final avatarRadius = isMobile
        ? 24.0
        : isTablet
        ? 26.0
        : 28.0;
    final avatarFontSize = isMobile
        ? 28.0
        : isTablet
        ? 30.0
        : 32.0;
    final nameFontSize = isMobile
        ? 15.0
        : isTablet
        ? 15.5
        : 16.0;
    final collegeFontSize = isMobile
        ? 11.0
        : isTablet
        ? 11.5
        : 12.0;
    final badgePadding = isMobile ? 8.0 : 10.0;
    final badgeFontSize = isMobile ? 11.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(padding, topPadding, padding, padding * 1.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.primary,
            DashboardStyles.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 2.5 : 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: isMobile ? 1.5 : 2,
              ),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: DashboardStyles.primary,
                  fontSize: avatarFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Text(
            principalName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: nameFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 3 : 4),
          Text(
            collegeName.length > (isMobile ? 25 : 30)
                ? '${collegeName.substring(0, isMobile ? 25 : 30)}...'
                : collegeName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: collegeFontSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: badgePadding,
              vertical: isMobile ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: DashboardStyles.accentGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMobile ? 5 : 6,
                  height: isMobile ? 5 : 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isMobile ? 5 : 6),
                Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection({
    required String title,
    required List<NavItem> items,
    required bool isMobile,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 16,
              isMobile ? 14 : 16,
              isMobile ? 14 : 16,
              isMobile ? 6 : 8,
            ),
            child: Text(
              title,
              style: TextStyle(
                color: DashboardStyles.textLight.withOpacity(0.6),
                fontSize: isMobile ? 11 : 12,
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
            badge: item.badge,
            isMobile: isMobile,
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    int? index,
    String? badge,
    required bool isMobile,
    required bool isTablet,
  }) {
    final isSelected = index != null && _selectedIndex == index;

    // Responsive values
    final margin = isMobile ? 6.0 : 8.0;
    final iconSize = isMobile
        ? 18.0
        : isTablet
        ? 19.0
        : 20.0;
    final iconPadding = isMobile ? 6.0 : 8.0;
    final fontSize = isMobile
        ? 13.0
        : isTablet
        ? 13.5
        : 14.0;
    final badgePadding = isMobile ? 6.0 : 8.0;
    final badgeFontSize = isMobile ? 11.0 : 12.0;
    final borderRadius = isMobile ? 10.0 : 12.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
        horizontal: margin,
        vertical: isMobile ? 0.5 : 1,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? DashboardStyles.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isSelected
              ? DashboardStyles.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 2 : 4,
        ),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: isSelected
                ? DashboardStyles.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: iconSize,
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
            fontSize: fontSize,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: EdgeInsets.symmetric(
                  horizontal: badgePadding,
                  vertical: isMobile ? 1.5 : 2,
                ),
                decoration: BoxDecoration(
                  color: DashboardStyles.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : isSelected
            ? Container(
                width: 3,
                height: isMobile ? 18 : 20,
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

  Widget _buildLogoutTile(bool isMobile, bool isTablet) {
    // Responsive values
    final margin = isMobile ? 6.0 : 8.0;
    final iconSize = isMobile
        ? 18.0
        : isTablet
        ? 19.0
        : 20.0;
    final iconPadding = isMobile ? 6.0 : 8.0;
    final fontSize = isMobile
        ? 13.0
        : isTablet
        ? 13.5
        : 14.0;
    final trailingIconSize = isMobile ? 14.0 : 16.0;
    final borderRadius = isMobile ? 10.0 : 12.0;

    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: DashboardStyles.accentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: DashboardStyles.accentRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 4 : 8,
        ),
        leading: Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: DashboardStyles.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.logout,
            color: DashboardStyles.accentRed,
            size: iconSize,
          ),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: DashboardStyles.accentRed,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: DashboardStyles.accentRed,
          size: trailingIconSize,
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
  final String? badge;

  NavItem({required this.icon, required this.title, this.index, this.badge});
}
