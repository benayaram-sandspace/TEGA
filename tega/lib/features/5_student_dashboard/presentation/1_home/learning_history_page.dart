import 'package:flutter/material.dart';
import '../../data/learning_history_service.dart';

class LearningHistoryPage extends StatefulWidget {
  const LearningHistoryPage({super.key});

  @override
  State<LearningHistoryPage> createState() => _LearningHistoryPageState();
}

class _LearningHistoryPageState extends State<LearningHistoryPage> {
  final LearningHistoryService _learningService = LearningHistoryService();

  // Data
  LearningStats? _learningStats;

  // Loading states
  bool _isLoadingStats = true;

  // Error states
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadLearningStats();
  }

  Future<void> _loadLearningStats() async {
    try {
      setState(() {
        _isLoadingStats = true;
        _statsError = null;
      });

      final stats = await _learningService.getLearningStats();
      setState(() {
        _learningStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _statsError = e.toString();
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(child: _buildOverviewTab()),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C88FF)),
        ),
      );
    }

    if (_statsError != null) {
      return _buildErrorState(
        'Failed to load learning stats',
        _statsError!,
        _loadLearningStats,
      );
    }

    if (_learningStats == null) {
      return _buildEmptyState('No learning data available');
    }

    return RefreshIndicator(
      onRefresh: _loadLearningStats,
      color: const Color(0xFF9C88FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Progress Ring
            _buildHeroSection(),
            const SizedBox(height: 24),
            // Search and Filter Section
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            // Learning Activities List
            _buildLearningActivitiesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final stats = _learningStats!;
    final completionRate = stats.completionRate / 100;
    
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop 
            ? 40 
            : isDesktop 
            ? 36 
            : isTablet 
            ? 32 
            : isSmallScreen 
            ? 24 
            : 28
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C88FF), Color(0xFF7A6BFF)],
        ),
        borderRadius: BorderRadius.circular(
          isLargeDesktop ? 28 : isDesktop ? 26 : isTablet ? 24 : isSmallScreen ? 20 : 22
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C88FF).withOpacity(0.3),
            blurRadius: isLargeDesktop ? 24 : isDesktop ? 20 : isTablet ? 18 : isSmallScreen ? 12 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Ring Section
          Row(
            children: [
              // Circular Progress Ring
              SizedBox(
                width: isLargeDesktop 
                    ? 160 
                    : isDesktop 
                    ? 140 
                    : isTablet 
                    ? 120 
                    : isSmallScreen 
                    ? 100 
                    : 110,
                height: isLargeDesktop 
                    ? 160 
                    : isDesktop 
                    ? 140 
                    : isTablet 
                    ? 120 
                    : isSmallScreen 
                    ? 100 
                    : 110,
                child: Stack(
                  children: [
                    // Background Circle
                    Container(
                      width: isLargeDesktop 
                          ? 160 
                          : isDesktop 
                          ? 140 
                          : isTablet 
                          ? 120 
                          : isSmallScreen 
                          ? 100 
                          : 110,
                      height: isLargeDesktop 
                          ? 160 
                          : isDesktop 
                          ? 140 
                          : isTablet 
                          ? 120 
                          : isSmallScreen 
                          ? 100 
                          : 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    // Progress Circle
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: completionRate,
                        strokeWidth: isLargeDesktop 
                            ? 12 
                            : isDesktop 
                            ? 10 
                            : isTablet 
                            ? 9 
                            : isSmallScreen 
                            ? 7 
                            : 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    // Center Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stats.completionRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: isLargeDesktop 
                                  ? 36 
                                  : isDesktop 
                                  ? 32 
                                  : isTablet 
                                  ? 28 
                                  : isSmallScreen 
                                  ? 22 
                                  : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: isLargeDesktop 
                                  ? 18 
                                  : isDesktop 
                                  ? 16 
                                  : isTablet 
                                  ? 14 
                                  : isSmallScreen 
                                  ? 12 
                                  : 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isLargeDesktop ? 32 : isDesktop ? 28 : isTablet ? 24 : isSmallScreen ? 16 : 20),
              // Stats Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: isLargeDesktop 
                            ? 32 
                            : isDesktop 
                            ? 28 
                            : isTablet 
                            ? 24 
                            : isSmallScreen 
                            ? 20 
                            : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : isSmallScreen ? 6 : 8),
                    _buildStatRow(
                      Icons.school_outlined,
                      '${stats.coursesEnrolled} Courses',
                      'Enrolled',
                    ),
                    SizedBox(height: isLargeDesktop ? 12 : isDesktop ? 10 : isTablet ? 8 : isSmallScreen ? 5 : 6),
                    _buildStatRow(
                      Icons.check_circle_outline,
                      '${stats.completedLectures} Completed',
                      'Lectures',
                    ),
                    SizedBox(height: isLargeDesktop ? 12 : isDesktop ? 10 : isTablet ? 8 : isSmallScreen ? 5 : 6),
                    _buildStatRow(
                      Icons.access_time,
                      stats.formattedTimeSpent,
                      'Study Time',
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeDesktop ? 32 : isDesktop ? 28 : isTablet ? 24 : 20),
          // Achievement Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeDesktop ? 28 : isDesktop ? 24 : isTablet ? 20 : isSmallScreen ? 16 : 18,
              vertical: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : isSmallScreen ? 8 : 9
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                isLargeDesktop ? 28 : isDesktop ? 24 : isTablet ? 22 : isSmallScreen ? 20 : 22
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events, 
                  color: Colors.white, 
                  size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : isSmallScreen ? 16 : 17
                ),
                            SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                Flexible(
                  child: Text(
                    'Keep up the great work!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeDesktop 
                          ? 20 
                          : isDesktop 
                          ? 18 
                          : isTablet 
                          ? 16 
                          : isSmallScreen 
                          ? 14 
                          : 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String value, String label) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    final isSmallScreen = screenWidth < 400;
    
    return Row(
      children: [
        Icon(
          icon, 
          color: Colors.white70, 
          size: isLargeDesktop 
              ? 22 
              : isDesktop 
              ? 20 
              : isTablet 
              ? 18 
              : isSmallScreen 
              ? 16 
              : 17
        ),
                            SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLargeDesktop 
                  ? 20 
                  : isDesktop 
                  ? 18 
                  : isTablet 
                  ? 16 
                  : isSmallScreen 
                  ? 14 
                  : 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 6 : isSmallScreen ? 4 : 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70, 
              fontSize: isLargeDesktop 
                  ? 18 
                  : isDesktop 
                  ? 16 
                  : isTablet 
                  ? 14 
                  : isSmallScreen 
                  ? 12 
                  : 13
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      height: isLargeDesktop ? 40 : isDesktop ? 36 : isTablet ? 34 : isSmallScreen ? 30 : 32,
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop ? 18 : isDesktop ? 16 : isTablet ? 14 : isSmallScreen ? 10 : 12
      ),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF9C88FF) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(
          isLargeDesktop ? 20 : isDesktop ? 18 : isTablet ? 16 : isSmallScreen ? 14 : 16
        ),
        border: Border.all(
          color: isSelected ? const Color(0xFF9C88FF) : const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6C757D),
            fontSize: isLargeDesktop 
                ? 14 
                : isDesktop 
                ? 12 
                : isTablet 
                ? 11 
                : isSmallScreen 
                ? 9 
                : 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildErrorState(String title, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF9C88FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 64,
                color: Color(0xFF9C88FF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop 
            ? 24 
            : isDesktop 
            ? 20 
            : isTablet 
            ? 18 
            : 16
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop ? 20 : isDesktop ? 16 : isTablet ? 14 : 15
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isLargeDesktop ? 16 : isDesktop ? 12 : isTablet ? 10 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 7 : 6
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C88FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 7 : 8
                  ),
                ),
                child: Icon(
                  Icons.tune,
                  color: const Color(0xFF9C88FF),
                  size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : 17,
                ),
              ),
              SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9),
              Expanded(
                child: Text(
                  'Filter & Search',
                  style: TextStyle(
                    fontSize: isLargeDesktop 
                        ? 20 
                        : isDesktop 
                        ? 18 
                        : isTablet 
                        ? 17 
                        : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeDesktop ? 32 : isDesktop ? 28 : isTablet ? 24 : 20),
          // Search Bar with enhanced styling
          Container(
            height: isLargeDesktop ? 52 : isDesktop ? 48 : isTablet ? 44 : 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(
                isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
              ),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search learning activities...',
                hintStyle: TextStyle(
                  color: const Color(0xFF6C757D),
                  fontSize: isLargeDesktop 
                      ? 16 
                      : isDesktop 
                      ? 14 
                      : isTablet 
                      ? 13 
                      : 12,
                ),
                prefixIcon: Container(
                  padding: EdgeInsets.all(
                    isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 10
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF9C88FF),
                    size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : 17,
                  ),
                ),
                suffixIcon: Container(
                  padding: EdgeInsets.all(
                    isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 10
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: const Color(0xFF6C757D),
                    size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : 17,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop ? 18 : isDesktop ? 16 : isTablet ? 14 : 13,
                  vertical: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 10,
                ),
              ),
            ),
          ),
          SizedBox(height: isLargeDesktop ? 20 : isDesktop ? 16 : isTablet ? 14 : 12),
          // Filter Chips Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Activities', true),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Lectures', false),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Quizzes', false),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Assignments', false),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Certificates', false),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9),
              // Sort Button
              Container(
                height: isLargeDesktop ? 40 : isDesktop ? 36 : isTablet ? 34 : 32,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop ? 20 : isDesktop ? 18 : isTablet ? 16 : 16
                  ),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      color: const Color(0xFF6C757D),
                      size: isLargeDesktop ? 18 : isDesktop ? 16 : isTablet ? 15 : 14,
                    ),
                    SizedBox(width: isLargeDesktop ? 8 : isDesktop ? 6 : isTablet ? 5 : 4),
                    Flexible(
                      child: Text(
                        'Newest',
                        style: TextStyle(
                          color: const Color(0xFF6C757D),
                          fontSize: isLargeDesktop 
                              ? 14 
                              : isDesktop 
                              ? 12 
                              : isTablet 
                              ? 11 
                              : 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 6 : 5),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF6C757D),
                      size: isLargeDesktop ? 18 : isDesktop ? 16 : isTablet ? 15 : 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeDesktop ? 20 : isDesktop ? 16 : isTablet ? 14 : 12),
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: isLargeDesktop ? 48 : isDesktop ? 44 : isTablet ? 42 : 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C88FF), Color(0xFF7A6BFF)],
                    ),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C88FF).withOpacity(0.3),
                        blurRadius: isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 7 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                      ),
                      onTap: () {},
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_rounded,
                              color: Colors.white,
                              size: isLargeDesktop ? 20 : isDesktop ? 18 : isTablet ? 17 : 16,
                            ),
                            SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                            Flexible(
                              child: Text(
                                'View Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isLargeDesktop 
                                      ? 16 
                                      : isDesktop 
                                      ? 14 
                                      : isTablet 
                                      ? 13 
                                      : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9),
              Container(
                height: isLargeDesktop ? 48 : isDesktop ? 44 : isTablet ? 42 : 40,
                width: isLargeDesktop ? 48 : isDesktop ? 44 : isTablet ? 42 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                  ),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                    ),
                    onTap: () {},
                    child: Center(
                      child: Icon(
                        Icons.refresh_rounded,
                        color: const Color(0xFF6C757D),
                        size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningActivitiesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Learning Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              Container(height: 1, width: 100, color: const Color(0xFFE0E0E0)),
            ],
          ),
          const SizedBox(height: 16),
          // Empty State (matching the reference)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No learning activities found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start learning to see your activities here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
