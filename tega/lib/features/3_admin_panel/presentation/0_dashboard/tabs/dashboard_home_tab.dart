import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class DashboardHomeTab extends StatefulWidget {
  final AuthService authService;

  const DashboardHomeTab({super.key, required this.authService});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  // Dashboard data
  List<dynamic> _recentStudents = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;

  // Statistics
  int _totalPrincipals = 0;
  int _totalStudents = 0;
  int _totalAdmins = 0;
  int _recentRegistrations = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();
    
    // Try to load from cache first
    await _loadFromCache();
    
    // Then load fresh data
    await _loadDashboardData();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _cacheService.getDashboardData();
      final cachedPaymentStats = await _cacheService.getPaymentStats();

      if (cachedData != null) {
        setState(() {
          _isLoadingFromCache = true;
        });

        final stats = cachedData['stats'] as Map<String, dynamic>?;
        final recentStudents = cachedData['recentStudents'] as List<dynamic>?;

        double totalRevenue = 0.0;
        if (cachedPaymentStats != null && cachedPaymentStats['success'] == true) {
          final paymentStatsData = cachedPaymentStats['data'] as Map<String, dynamic>?;
          totalRevenue = (paymentStatsData?['totalRevenue'] ?? 0).toDouble();
        }

        if (stats != null && recentStudents != null) {
          setState(() {
            _recentStudents = recentStudents;
            _totalPrincipals = stats['totalPrincipals'] ?? 0;
            _totalStudents = stats['totalStudents'] ?? 0;
            _totalAdmins = stats['totalAdmins'] ?? 0;
            _recentRegistrations = stats['recentRegistrations'] ?? 0;
            _totalRevenue = totalRevenue;
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    } catch (e) {
      // Silently fail cache loading
      setState(() {
        _isLoadingFromCache = false;
      });
    }
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    try {
      // Skip cache if force refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getDashboardData();
        if (cachedData != null && !_isLoadingFromCache) {
          // Already loaded from cache, just update in background
          _loadDashboardDataInBackground();
          return;
        }
      }

      if (!_isLoadingFromCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      }

      // Load dashboard data
      final data = await _dashboardService.getDashboardData();

      if (data['success'] == true) {
        final stats = data['stats'] as Map<String, dynamic>;
        final recentStudents = data['recentStudents'] as List<dynamic>;

        // Cache the dashboard data
        await _cacheService.setDashboardData(data);

        // Try to load payment stats, but don't fail if it errors
        double totalRevenue = 0.0;
        try {
          final paymentData = await _dashboardService.getPaymentStats();
          if (paymentData['success'] == true) {
            final paymentStatsData = paymentData['data'] as Map<String, dynamic>;
            totalRevenue = (paymentStatsData['totalRevenue'] ?? 0).toDouble();
            
            // Cache payment stats
            await _cacheService.setPaymentStats(paymentData);
          }
        } catch (e) {
          // Silently fail for payment stats - dashboard should still load
        }

        setState(() {
          _recentStudents = recentStudents;
          _totalPrincipals = stats['totalPrincipals'] ?? 0;
          _totalStudents = stats['totalStudents'] ?? 0;
          _totalAdmins = stats['totalAdmins'] ?? 0;
          _recentRegistrations = stats['recentRegistrations'] ?? 0;
          _totalRevenue = totalRevenue;
          _isLoading = false;
          _isLoadingFromCache = false;
        });
        // Show "back online" toast if we were offline
        _cacheService.handleOnlineState(context);
      } else {
        throw Exception(data['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getDashboardData();
        final cachedPaymentStats = await _cacheService.getPaymentStats();
        
        if (cachedData != null) {
          final stats = cachedData['stats'] as Map<String, dynamic>?;
          final recentStudents = cachedData['recentStudents'] as List<dynamic>?;

          double totalRevenue = 0.0;
          if (cachedPaymentStats != null && cachedPaymentStats['success'] == true) {
            final paymentStatsData = cachedPaymentStats['data'] as Map<String, dynamic>?;
            totalRevenue = (paymentStatsData?['totalRevenue'] ?? 0).toDouble();
          }

          if (stats != null && recentStudents != null) {
            // Load from cache and show toast
            setState(() {
              _recentStudents = recentStudents;
              _totalPrincipals = stats['totalPrincipals'] ?? 0;
              _totalStudents = stats['totalStudents'] ?? 0;
              _totalAdmins = stats['totalAdmins'] ?? 0;
              _recentRegistrations = stats['recentRegistrations'] ?? 0;
              _totalRevenue = totalRevenue;
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = null; // Clear error since we have cached data
            });
            // Show "offline" toast even if we have cache
            _cacheService.handleOfflineState(context);
            return;
          }
        }
        
        // No cache available, show error
        setState(() {
          _errorMessage = 'No internet connection';
          _isLoading = false;
          _isLoadingFromCache = false;
        });
        // Show "offline" toast
        _cacheService.handleOfflineState(context);
      } else {
        // Other errors
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
          _isLoadingFromCache = false;
      });
      }
    }
  }

  Future<void> _loadDashboardDataInBackground() async {
    try {
      final data = await _dashboardService.getDashboardData();
      if (data['success'] == true) {
        await _cacheService.setDashboardData(data);
        
        final stats = data['stats'] as Map<String, dynamic>;
        final recentStudents = data['recentStudents'] as List<dynamic>;

        double totalRevenue = 0.0;
        try {
          final paymentData = await _dashboardService.getPaymentStats();
          if (paymentData['success'] == true) {
            final paymentStatsData = paymentData['data'] as Map<String, dynamic>;
            totalRevenue = (paymentStatsData['totalRevenue'] ?? 0).toDouble();
            await _cacheService.setPaymentStats(paymentData);
          }
        } catch (e) {
          // Silently fail
        }

        if (mounted) {
          setState(() {
            _recentStudents = recentStudents;
            _totalPrincipals = stats['totalPrincipals'] ?? 0;
            _totalStudents = stats['totalStudents'] ?? 0;
            _totalAdmins = stats['totalAdmins'] ?? 0;
            _recentRegistrations = stats['recentRegistrations'] ?? 0;
            _totalRevenue = totalRevenue;
          });
          // Show "back online" toast if we were offline
          _cacheService.handleOnlineState(context);
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AdminDashboardStyles.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null && !_isLoadingFromCache) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : isTablet ? 40 : 60,
          ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(
                Icons.cloud_off,
                size: isMobile ? 56 : isTablet ? 64 : 72,
                color: Colors.grey[400],
              ),
              SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
            Text(
              'Failed to Load Dashboard',
                style: TextStyle(
                  fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
              ),
            ),
              SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  color: Colors.grey[600],
            ),
              ),
              SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),
            ElevatedButton.icon(
                onPressed: () => _loadDashboardData(forceRefresh: true),
                icon: Icon(Icons.refresh, size: isMobile ? 16 : isTablet ? 17 : 18),
                label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(
                isMobile ? 16 : isTablet ? 20 : 24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCreativeHeader(isMobile, isTablet, isDesktop),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildCreativeStatsSection(isMobile, isTablet, isDesktop),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildCreativeRegistrationsSection(
                    isMobile,
                    isTablet,
                    isDesktop,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreativeHeader(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    String adminName = widget.authService.currentUser?.name ?? 'Admin';
    return Container(
      constraints: BoxConstraints(
        minHeight: isMobile ? 160 : isTablet ? 180 : 200,
        maxHeight: isMobile ? 220 : isTablet ? 240 : 260,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminDashboardStyles.primary,
            AdminDashboardStyles.primaryLight,
            AdminDashboardStyles.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminDashboardStyles.primary.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: isMobile ? 100 : 120,
              height: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: isMobile ? 60 : 80,
              height: isMobile ? 60 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome back, $adminName!',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : isTablet ? 22 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isMobile ? 4 : 6),
                          Text(
                            'Ready to manage your educational platform?',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 15,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: isMobile ? 12 : 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Platform Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            color: Colors.white,
                            size: isMobile ? 12 : 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$_totalStudents Students',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3);
  }

  Widget _buildCreativeStatsSection(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return _buildUnifiedAnalyticsCard(isMobile, isTablet, isDesktop);
  }

  Widget _buildUnifiedAnalyticsCard(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AdminDashboardStyles.primary,
                size: isMobile ? 18 : 20,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF48BB78),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: const Color(0xFF48BB78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),
          isDesktop
              ? _buildDesktopStatsGrid()
              : isTablet
                  ? _buildTabletStatsGrid()
                  : _buildMobileStatsGrid(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildMobileStatsGrid() {
    return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatItem(
                      icon: Icons.people_outline,
                      title: 'Principals',
                      value: _totalPrincipals.toString(),
                      color: const Color(0xFF4299E1),
                isMobile: true,
                    ),
                  ),
            const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactStatItem(
                      icon: Icons.school_outlined,
                      title: 'Students',
                      value: _totalStudents.toString(),
                      color: const Color(0xFF9F7AEA),
                isMobile: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admins',
                      value: _totalAdmins.toString(),
                      color: const Color(0xFFF56565),
                isMobile: true,
                    ),
                  ),
            const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactStatItem(
                      icon: Icons.access_time_outlined,
                      title: 'Recent',
                      value: _recentRegistrations.toString(),
                      color: const Color(0xFF48BB78),
                isMobile: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
        _buildCompactStatItem(
          icon: Icons.currency_rupee_rounded,
          title: 'Total Revenue',
          value: '₹${NumberFormat('#,##,###').format(_totalRevenue.toInt())}',
          color: const Color(0xFFF6AD55),
          isMobile: true,
        ),
      ],
    );
  }

  Widget _buildTabletStatsGrid() {
    return Column(
      children: [
              Row(
                children: [
            Expanded(
              child: _buildCompactStatItem(
                icon: Icons.people_outline,
                title: 'Principals',
                value: _totalPrincipals.toString(),
                color: const Color(0xFF4299E1),
                isMobile: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactStatItem(
                icon: Icons.school_outlined,
                title: 'Students',
                value: _totalStudents.toString(),
                color: const Color(0xFF9F7AEA),
                isMobile: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactStatItem(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admins',
                value: _totalAdmins.toString(),
                color: const Color(0xFFF56565),
                isMobile: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactStatItem(
                icon: Icons.access_time_outlined,
                title: 'Recent',
                value: _recentRegistrations.toString(),
                color: const Color(0xFF48BB78),
                isMobile: false,
              ),
            ),
            const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactStatItem(
                      icon: Icons.currency_rupee_rounded,
                      title: 'Total Revenue',
                      value: '₹${NumberFormat('#,##,###').format(_totalRevenue.toInt())}',
                      color: const Color(0xFFF6AD55),
                isMobile: false,
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildDesktopStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatItem(
            icon: Icons.people_outline,
            title: 'Principals',
            value: _totalPrincipals.toString(),
            color: const Color(0xFF4299E1),
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCompactStatItem(
            icon: Icons.school_outlined,
            title: 'Students',
            value: _totalStudents.toString(),
            color: const Color(0xFF9F7AEA),
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCompactStatItem(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admins',
            value: _totalAdmins.toString(),
            color: const Color(0xFFF56565),
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCompactStatItem(
            icon: Icons.access_time_outlined,
            title: 'Recent',
            value: _recentRegistrations.toString(),
            color: const Color(0xFF48BB78),
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCompactStatItem(
            icon: Icons.currency_rupee_rounded,
            title: 'Total Revenue',
            value: '₹${NumberFormat('#,##,###').format(_totalRevenue.toInt())}',
            color: const Color(0xFFF6AD55),
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          width: isMobile ? 36 : 40,
          height: isMobile ? 36 : 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isMobile ? 18 : 20),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: const Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeRegistrationsSection(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: AdminDashboardStyles.primary,
                size: isMobile ? 18 : 20,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Latest Registrations',
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF48BB78),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_recentStudents.length}',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: const Color(0xFF48BB78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),
          if (_recentStudents.isEmpty)
            Container(
              padding: EdgeInsets.all(isMobile ? 30 : 40),
              child: Column(
                children: [
                  Container(
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_add_disabled_outlined,
                      size: isMobile ? 28 : 32,
                      color: const Color(0xFFA0AEC0),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'No Recent Registrations',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New student registrations will appear here',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: const Color(0xFF718096),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: isMobile ? 400 : isTablet ? 500 : 550,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _recentStudents.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: isMobile ? 10 : 12),
                itemBuilder: (context, index) {
                  final student = _recentStudents[index];

                  // Extract data from API response
                  final username = student['username'] ?? 'N/A';
                  final firstName = student['firstName'] ?? '';
                  final lastName = student['lastName'] ?? '';
                  final fullName = firstName.isNotEmpty && lastName.isNotEmpty
                      ? '$firstName $lastName'
                      : username;
                  final email = student['email'] ?? 'N/A';
                  final institute = student['institute'] ?? 'No Institute';
                  final studentId = student['studentId'] ?? 'N/A';
                  final createdAt = student['createdAt'] ?? '';

                  // Format date
                  String registrationDate = 'Recently';
                  if (createdAt.isNotEmpty) {
                    try {
                      final date = DateTime.parse(createdAt);
                      final now = DateTime.now();
                      final difference = now.difference(date);

                      if (difference.inDays == 0) {
                        registrationDate = 'Today';
                      } else if (difference.inDays == 1) {
                        registrationDate = 'Yesterday';
                      } else if (difference.inDays < 7) {
                        registrationDate = '${difference.inDays} days ago';
                      } else {
                        registrationDate =
                            '${date.day}/${date.month}/${date.year}';
                      }
                    } catch (e) {
                      registrationDate = 'Recently';
                    }
                  }

                  return Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Name + Student ID
                        Row(
                          children: [
                            // Avatar Circle
                            Container(
                              width: isMobile ? 40 : 44,
                              height: isMobile ? 40 : 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AdminDashboardStyles.primary.withOpacity(
                                      0.8,
                                    ),
                                    AdminDashboardStyles.primaryLight,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AdminDashboardStyles.primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 10 : 12),
                            // Name and Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D3748),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isMobile ? 2 : 3),
                                  Text(
                                    '@$username',
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: const Color(0xFF718096),
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            // Student ID Badge
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 10,
                                  vertical: isMobile ? 5 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE6FFFA),
                                      Color(0xFFB2F5EA),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF38B2AC),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38B2AC)
                                          .withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  studentId,
                                  style: TextStyle(
                                    fontSize: isMobile ? 9 : 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C7A7B),
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 10 : 12),

                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE2E8F0).withOpacity(0.1),
                                const Color(0xFFE2E8F0),
                                const Color(0xFFE2E8F0).withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 10 : 12),

                        // Info Row: Email
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 5 : 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.email_outlined,
                                size: isMobile ? 12 : 14,
                                color: const Color(0xFF4299E1),
                              ),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: const Color(0xFF4A5568),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 6 : 8),

                        // Info Row: Institute
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 5 : 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: isMobile ? 12 : 14,
                                color: const Color(0xFF9F7AEA),
                              ),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                institute,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: const Color(0xFF4A5568),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 6 : 8),

                        // Info Row: Registration Date
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 5 : 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.calendar_today_outlined,
                                size: isMobile ? 12 : 14,
                                color: const Color(0xFF48BB78),
                              ),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Registered $registrationDate',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: const Color(0xFF48BB78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3);
  }
}
