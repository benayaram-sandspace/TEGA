import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  final AuthService _auth = AuthService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  Map<String, dynamic>? _stats;

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
    await _loadStats();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);
      
      final cachedStats = await _cacheService.getPlacementPrepStatsData();
      if (cachedStats != null && cachedStats.isNotEmpty) {
        setState(() {
          _stats = Map<String, dynamic>.from(cachedStats);
          _isLoadingFromCache = false;
        });
      } else {
        setState(() => _isLoadingFromCache = false);
      }
    } catch (e) {
      setState(() => _isLoadingFromCache = false);
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

  Future<void> _loadStats({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _stats != null && _stats!.isNotEmpty) {
      // Make sure loading is false since we have cached data
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _loadStatsInBackground();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementStats),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _stats = data['stats'] ?? {};
              _isLoading = false;
            });
            
            // Cache the data
            await _cacheService.setPlacementPrepStatsData(_stats!);
            
            // Reset toast flag on successful load (internet is back)
            _cacheService.resetNoInternetToastFlag();
            // Show "back online" toast if we were offline
            _cacheService.handleOnlineState(context);
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch stats');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch stats: ${res.statusCode}');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedStats = await _cacheService.getPlacementPrepStatsData();
        if (cachedStats != null && cachedStats.isNotEmpty) {
          // Load from cache
          if (mounted) {
            setState(() {
              _stats = Map<String, dynamic>.from(cachedStats);
              _isLoading = false;
              _errorMessage = null; // Clear error since we have cached data
            });
            // Show "offline" toast even if we have cache
            _cacheService.handleOfflineState(context);
          }
          return;
        }
        
        // No cache available, show error
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection';
          });
          // Show "offline" toast
          _cacheService.handleOfflineState(context);
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  Future<void> _loadStatsInBackground() async {
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementStats),
        headers: headers,
      );

      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          setState(() {
            _stats = data['stats'] ?? {};
          });
          
          // Cache the data
          await _cacheService.setPlacementPrepStatsData(_stats!);
          
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
          // Show "back online" toast if we were offline
          _cacheService.handleOnlineState(context);
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  String _formatTime(int? minutes) {
    if (minutes == null || minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminDashboardStyles.primary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 16 : 20),
      child: _errorMessage != null && !_isLoadingFromCache
          ? _buildErrorState(isMobile, isTablet, isDesktop)
          : _stats == null
          ? _buildEmptyState(isMobile, isTablet, isDesktop)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(isMobile, isTablet, isDesktop),
                SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
                _buildPerformanceCard(isMobile, isTablet, isDesktop),
                SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
                _buildDetailedAnalytics(isMobile, isTablet, isDesktop),
              ],
            ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
      child: Center(
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
              'Failed to load analytics',
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
            SizedBox(height: isMobile ? 20 : isTablet ? 24 : 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadStats(forceRefresh: true);
              },
              icon: Icon(Icons.refresh, size: isMobile ? 18 : isTablet ? 20 : 22),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : isTablet ? 24 : 28,
                  vertical: isMobile ? 12 : isTablet ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            color: AdminDashboardStyles.primary,
            size: isMobile ? 32 : isTablet ? 36 : 40,
          ),
          SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
          Text(
            'No analytics data available',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminDashboardStyles.textDark,
              fontSize: isMobile ? 14 : isTablet ? 15 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: isMobile ? 10 : isTablet ? 11 : 12,
        mainAxisSpacing: isMobile ? 10 : isTablet ? 11 : 12,
        childAspectRatio: isMobile ? 2.3 : isTablet ? 2.4 : 2.5,
        children: [
          _buildStatItem(
            title: 'Total Questions',
            value: '${_stats!['totalQuestions'] ?? 0}',
            icon: Icons.description_rounded,
            color: const Color(0xFF3B82F6),
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          _buildStatItem(
            title: 'Total Modules',
            value: '${_stats!['totalModules'] ?? 0}',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF10B981),
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          _buildStatItem(
            title: 'Average Score',
            value: '${_stats!['averageScore'] ?? 0}%',
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF8B5CF6),
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          _buildStatItem(
            title: 'Active Students',
            value: '${_stats!['activeStudents'] ?? 0}',
            icon: Icons.people_rounded,
            color: const Color(0xFFF59E0B),
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Container(
          width: isMobile ? 36 : isTablet ? 38 : 40,
          height: isMobile ? 36 : isTablet ? 38 : 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
          ),
          child: Icon(icon, color: color, size: isMobile ? 16 : isTablet ? 17 : 18),
        ),
        SizedBox(width: isMobile ? 8 : isTablet ? 9 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 10 : isTablet ? 10.5 : 11,
                  color: AdminDashboardStyles.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isMobile ? 2 : isTablet ? 2.5 : 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: AdminDashboardStyles.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: const Color(0xFF10B981),
                  size: isMobile ? 18 : isTablet ? 19 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
              Text(
                'Performance Analytics',
                style: TextStyle(
                  fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildPerformanceMetric(
                      icon: Icons.flag_rounded,
                      value: '${_stats!['completionRate'] ?? 0}%',
                      label: 'Students completing modules',
                      color: const Color(0xFF3B82F6),
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    )),
                    SizedBox(width: isMobile ? 16 : isTablet ? 18 : 20),
                    Expanded(child: _buildPerformanceMetric(
                      icon: Icons.emoji_events_rounded,
                      value: '${_stats!['topScore'] ?? 0}%',
                      label: 'Highest score achieved',
                      color: const Color(0xFFF59E0B),
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    )),
                    SizedBox(width: isMobile ? 16 : isTablet ? 18 : 20),
                    Expanded(child: _buildPerformanceMetric(
                      icon: Icons.access_time_rounded,
                      value: _formatTime(_stats!['averageTime']),
                      label: 'Time per assessment',
                      color: const Color(0xFF8B5CF6),
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    )),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPerformanceMetric(
                      icon: Icons.flag_rounded,
                      value: '${_stats!['completionRate'] ?? 0}%',
                      label: 'Students completing modules',
                      color: const Color(0xFF3B82F6),
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                    _buildPerformanceMetric(
                      icon: Icons.emoji_events_rounded,
                      value: '${_stats!['topScore'] ?? 0}%',
                      label: 'Highest score achieved',
                      color: const Color(0xFFF59E0B),
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                    _buildPerformanceMetric(
                      icon: Icons.access_time_rounded,
                      value: _formatTime(_stats!['averageTime']),
                      label: 'Time per assessment',
                      color: const Color(0xFF8B5CF6),
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : isTablet ? 9 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
          ),
          child: Icon(icon, color: color, size: isMobile ? 20 : isTablet ? 22 : 24),
        ),
        SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isMobile ? 3 : isTablet ? 3.5 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : isTablet ? 11.5 : 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalytics(bool isMobile, bool isTablet, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCategoryCard(isMobile, isTablet, isDesktop)),
              SizedBox(width: isMobile ? 12 : isTablet ? 14 : 16),
              Expanded(child: _buildDifficultyCard(isMobile, isTablet, isDesktop)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildCategoryCard(isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              _buildDifficultyCard(isMobile, isTablet, isDesktop),
            ],
          );
        }
      },
    );
  }

  Widget _buildCategoryCard(bool isMobile, bool isTablet, bool isDesktop) {
    final categories = _stats!['questionsByCategory'] as Map<String, dynamic>? ?? {};
    final categoryList = categories.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: const Color(0xFF3B82F6),
                  size: isMobile ? 18 : isTablet ? 19 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
              Text(
                'Questions by Category',
                style: TextStyle(
                  fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
          if (categoryList.isEmpty)
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
              child: Text(
                'No categories available',
                style: TextStyle(
                  color: AdminDashboardStyles.textLight,
                  fontSize: isMobile ? 12 : isTablet ? 12.5 : 13,
                ),
              ),
            )
          else
            ...categoryList.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: isMobile ? 10 : isTablet ? 11 : 12),
                  child: Row(
                    children: [
                      Container(
                        width: isMobile ? 6 : isTablet ? 7 : 8,
                        height: isMobile ? 6 : isTablet ? 7 : 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                      Expanded(
                        child: Text(
                          _capitalizeFirst(entry.key),
                          style: TextStyle(
                            fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                          fontWeight: FontWeight.w700,
                          color: AdminDashboardStyles.textDark,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(bool isMobile, bool isTablet, bool isDesktop) {
    final difficulties = _stats!['questionsByDifficulty'] as Map<String, dynamic>? ?? {};
    final difficultyList = difficulties.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'hard':
          return const Color(0xFFEF4444);
        case 'medium':
          return AdminDashboardStyles.primary;
        case 'easy':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF6B7280);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: const Color(0xFF10B981),
                  size: isMobile ? 18 : isTablet ? 19 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
              Text(
                'Questions by Difficulty',
                style: TextStyle(
                  fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
          if (difficultyList.isEmpty)
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
              child: Text(
                'No difficulty data available',
                style: TextStyle(
                  color: AdminDashboardStyles.textLight,
                  fontSize: isMobile ? 12 : isTablet ? 12.5 : 13,
                ),
              ),
            )
          else
            ...difficultyList.map((entry) {
              final color = getDifficultyColor(entry.key);
              return Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 10 : isTablet ? 11 : 12),
                child: Row(
                  children: [
                    Container(
                      width: isMobile ? 6 : isTablet ? 7 : 8,
                      height: isMobile ? 6 : isTablet ? 7 : 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                    Expanded(
                      child: Text(
                        _capitalizeFirst(entry.key),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                        fontWeight: FontWeight.w700,
                        color: AdminDashboardStyles.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
