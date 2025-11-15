import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/core/services/results_cache_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/6_exams/exams_page.dart';

class MyResultsPage extends StatefulWidget {
  final VoidCallback? onNavigateToExams;
  
  const MyResultsPage({
    super.key,
    this.onNavigateToExams,
  });

  @override
  State<MyResultsPage> createState() => _MyResultsPageState();
}

class _MyResultsPageState extends State<MyResultsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ResultsCacheService _cacheService = ResultsCacheService();

  // Filter states
  String _selectedResultFilter = 'All Results';
  String _selectedSortOption = 'Date';

  // Filter options
  final List<String> _resultFilters = [
    'All Results',
    'Passed',
    'Qualified',
    'Failed',
    'Under Review',
  ];

  // Stats
  int _totalExams = 0;
  int _passedExams = 0;
  int _qualifiedExams = 0;
  int _underReviewExams = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadResults();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedResults = await _cacheService.getResultsData();
      if (cachedResults != null && cachedResults.isNotEmpty && mounted) {
        setState(() {
          _allResults = cachedResults;
          _calculateStats();
          _filteredResults = List.from(_allResults);
          _applyFilters();
          _isLoading = false;
          _errorMessage = null;
        });
        // Still fetch in background to update cache
        _fetchResultsInBackground();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch from API
    await _fetchResultsInBackground();
  }

  Future<void> _fetchResultsInBackground() async {
    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final dashboardService = StudentDashboardService();

      // Fetch exam results from backend
      final results = await dashboardService.getExamResults(headers);

      if (mounted) {
        final transformedResults = results.map<Map<String, dynamic>>((result) {
          final score = (result['score'] ?? 0).toDouble();
          final totalMarks = (result['totalMarks'] ?? 100).toDouble();
          final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0;

          return {
            'id': result['_id'] ?? result['id'] ?? '',
            'examTitle': result['examTitle'] ?? 'Untitled Exam',
            'examId': result['examId'] ?? '',
            'subject': result['subject'] ?? result['category'] ?? 'General',
            'score': score,
            'totalMarks': totalMarks,
            'percentage': percentage,
            'status': result['status'] ?? _getStatus(percentage),
            'date':
                result['completedAt'] ??
                result['createdAt'] ??
                DateTime.now().toIso8601String(),
            'timeTaken': result['timeTaken'] ?? '0 min',
            'correctAnswers': result['correctAnswers'] ?? 0,
            'totalQuestions': result['totalQuestions'] ?? 0,
            'rank': result['rank'],
            'isReviewed': result['isReviewed'] ?? false,
          };
        }).toList();

        // Cache results data
        await _cacheService.setResultsData(transformedResults);

        _calculateStats();
        setState(() {
          _allResults = transformedResults;
          _filteredResults = List.from(_allResults);
          _applyFilters();
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedResults = await _cacheService.getResultsData();
          if (cachedResults != null && cachedResults.isNotEmpty) {
            setState(() {
              _allResults = cachedResults;
              _calculateStats();
              _filteredResults = List.from(_allResults);
              _applyFilters();
              _errorMessage = null; // Clear error since we have cached data
              _isLoading = false;
            });
            return;
          }
          // No cache available, show error
          setState(() {
            _errorMessage = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Unable to load results. Please try again.';
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getStatus(double percentage) {
    if (percentage >= 80) return 'Qualified';
    if (percentage >= 40) return 'Passed';
    return 'Failed';
  }

  void _calculateStats() {
    _totalExams = _allResults.length;
    _passedExams = _allResults.where((r) => r['percentage'] >= 40).length;
    _qualifiedExams = _allResults.where((r) => r['percentage'] >= 80).length;
    _underReviewExams = _allResults
        .where((r) => r['status'] == 'Under Review')
        .length;
  }

  void _applyFilters() {
    setState(() {
      // Apply result filter and search
      _filteredResults = _allResults.where((result) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            result['examTitle'].toString().toLowerCase().contains(
              searchQuery,
            ) ||
            result['subject'].toString().toLowerCase().contains(searchQuery);

        // Result status filter
        bool matchesResultFilter = false;
        switch (_selectedResultFilter) {
          case 'All Results':
            matchesResultFilter = true;
            break;
          case 'Passed':
            matchesResultFilter =
                result['percentage'] >= 40 && result['percentage'] < 80;
            break;
          case 'Qualified':
            matchesResultFilter = result['percentage'] >= 80;
            break;
          case 'Failed':
            matchesResultFilter = result['percentage'] < 40;
            break;
          case 'Under Review':
            matchesResultFilter = result['status'] == 'Under Review';
            break;
        }

        return matchesSearch && matchesResultFilter;
      }).toList();

      // Apply sorting
      switch (_selectedSortOption) {
        case 'Date':
          _filteredResults.sort((a, b) {
            final dateA = DateTime.tryParse(a['date']) ?? DateTime.now();
            final dateB = DateTime.tryParse(b['date']) ?? DateTime.now();
            return dateB.compareTo(dateA); // Most recent first
          });
          break;
        case 'Subject':
          _filteredResults.sort(
            (a, b) =>
                a['subject'].toString().compareTo(b['subject'].toString()),
          );
          break;
        case 'Score':
          _filteredResults.sort(
            (a, b) =>
                (b['percentage'] as num).compareTo(a['percentage'] as num),
          );
          break;
      }
    });
  }

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : _filteredResults.isEmpty
              ? _buildEmptyState()
          : _buildModernResultsPage(),
    );
  }

  Widget _buildModernResultsPage() {
    return CustomScrollView(
      slivers: [
        // Modern Header
        _buildModernHeader(),

        // Stats Overview
        _buildStatsOverview(),

        // Search and Filters
        _buildModernSearchAndFilters(),

        // Results List
        _buildModernResultsList(),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(
            height: isLargeDesktop
                ? 48
                : isDesktop
                ? 40
                : isTablet
                ? 32
                : isSmallScreen
                ? 20
                : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 40
              : isDesktop
              ? 32
              : isTablet
              ? 28
              : isSmallScreen
              ? 16
              : 24,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5FFF), Color(0xFF9C88FF), Color(0xFFB19CD9)],
          ),
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 20
                : isSmallScreen
                ? 12
                : 16,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5FFF).withOpacity(0.3),
              blurRadius: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 10
                  : 16,
              offset: Offset(
                0,
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 8
                    : isTablet
                    ? 7
                    : isSmallScreen
                    ? 4
                    : 6,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
          children: [
                Container(
                  padding: EdgeInsets.all(
                    isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 20
                          : isDesktop
                          ? 16
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 10
                          : 12,
                    ),
                  ),
                  child: Icon(
                    Icons.assessment_rounded,
                    color: Colors.white,
                    size: isLargeDesktop
                        ? 40
                        : isDesktop
                        ? 32
                        : isTablet
                        ? 30
                        : isSmallScreen
                        ? 22
                        : 28,
              ),
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Results',
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 32
                              : isDesktop
                              ? 28
                              : isTablet
                              ? 26
                              : isSmallScreen
                              ? 20
                              : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: isLargeDesktop || isDesktop
                            ? 6
                            : isTablet
                            ? 5
                            : isSmallScreen
                            ? 2
                            : 4,
                      ),
                      Text(
                        'Track your exam performance and progress',
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 18
                              : isDesktop
                              ? 16
                              : isTablet
                              ? 15
                              : isSmallScreen
                              ? 11
                              : 14,
                          color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 12
                  : 20,
            ),
            Container(
      padding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 12
                    : 16,
                vertical: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
      ),
      decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                  ),
                  SizedBox(
                    width: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 6
                        : 8,
                  ),
                  Expanded(
                    child: Text(
                      'View detailed analytics and performance insights',
          style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 16
                            : isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 11
                            : 13,
                        color: Colors.white,
            fontWeight: FontWeight.w500,
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

  Widget _buildStatsOverview() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 26
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            _buildModernStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatsRow() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 8
                        : 12,
                    offset: Offset(
                      0,
                      isLargeDesktop
                          ? 8
                          : isDesktop
                          ? 6
                          : isTablet
                          ? 5
                          : isSmallScreen
                          ? 3
                          : 4,
                    ),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModernStatItem(
          icon: Icons.assignment_rounded,
                      value: _totalExams.toString(),
                      label: 'Total Exams',
          color: const Color(0xFF6B5FFF),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isLargeDesktop
                        ? 70
                        : isDesktop
                        ? 60
                        : isTablet
                        ? 55
                        : isSmallScreen
                        ? 45
                        : 50,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildModernStatItem(
          icon: Icons.check_circle_rounded,
                      value: _passedExams.toString(),
                      label: 'Passed',
          color: const Color(0xFF4CAF50),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isLargeDesktop
                        ? 70
                        : isDesktop
                        ? 60
                        : isTablet
                        ? 55
                        : isSmallScreen
                        ? 45
                        : 50,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildModernStatItem(
          icon: Icons.workspace_premium_rounded,
                      value: _qualifiedExams.toString(),
                      label: 'Qualified',
          color: const Color(0xFFFFD700),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isLargeDesktop
                        ? 70
                        : isDesktop
                        ? 60
                        : isTablet
                        ? 55
                        : isSmallScreen
                        ? 45
                        : 50,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildModernStatItem(
          icon: Icons.pending_actions_rounded,
                      value: _underReviewExams.toString(),
                      label: 'Under Review',
          color: const Color(0xFFFF9800),
                    ),
        ),
      ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(
            isLargeDesktop
                ? 16
                : isDesktop
                ? 12
                : isTablet
                ? 11
                : isSmallScreen
                ? 8
                : 10,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 22
                : isSmallScreen
                ? 18
                : 20,
          ),
        ),
        SizedBox(
          height: isLargeDesktop
              ? 14
              : isDesktop
              ? 12
              : isTablet
              ? 11
              : isSmallScreen
              ? 6
              : 8,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 22
                : isSmallScreen
                ? 18
                : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(
          height: isLargeDesktop || isDesktop
              ? 4
              : isTablet
              ? 3
              : isSmallScreen
              ? 1
              : 2,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeDesktop
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 11
                : isSmallScreen
                ? 9
                : 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModernSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exam Results',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 26
                        : isDesktop
                        ? 22
                        : isTablet
                        ? 20
                        : isSmallScreen
                        ? 18
                        : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 7
                        : 8,
                    vertical: isLargeDesktop
                        ? 8
                        : isDesktop
                        ? 6
                        : isTablet
                        ? 5.5
                        : isSmallScreen
                        ? 3
                        : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5FFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 10
                          : isDesktop
                          ? 8
                          : isTablet
                          ? 7
                          : isSmallScreen
                          ? 5
                          : 6,
                    ),
                  ),
                  child: Text(
                    '${_filteredResults.length} results',
                    style: TextStyle(
                      fontSize: isLargeDesktop
                          ? 14
                          : isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 9
                          : 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),

            // Search Bar
            Container(
      decoration: BoxDecoration(
        color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
                    blurRadius: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 8
                        : isTablet
                        ? 7
                        : isSmallScreen
                        ? 4
                        : 6,
                    offset: const Offset(0, 2),
          ),
        ],
      ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search exams by name or subject...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : isSmallScreen
                        ? 12
                        : 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF6B5FFF),
                    size: isLargeDesktop
                        ? 28
                        : isDesktop
                        ? 24
                        : isTablet
                        ? 22
                        : isSmallScreen
                        ? 18
                        : 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: isLargeDesktop
                                ? 24
                                : isDesktop
                                ? 20
                                : isTablet
                                ? 19
                                : isSmallScreen
                                ? 16
                                : 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                          color: Colors.grey[400],
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 12
                        : 16,
                    vertical: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : isSmallScreen
                        ? 10
                        : 14,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),

            // Filter Chips
            SizedBox(
              height: isLargeDesktop
                  ? 52
                  : isDesktop
                  ? 44
                  : isTablet
                  ? 42
                  : isSmallScreen
                  ? 36
                  : 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _resultFilters.length,
                itemBuilder: (context, index) {
                  final filter = _resultFilters[index];
                  final isSelected = _selectedResultFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 10
                          : isTablet
                          ? 9
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    child: Container(
            decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B5FFF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          isLargeDesktop
                              ? 12
                              : isDesktop
                              ? 10
                              : isTablet
                              ? 9
                              : isSmallScreen
                              ? 6
                              : 8,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6B5FFF)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: isLargeDesktop
                                ? 8
                                : isDesktop
                                ? 6
                                : isTablet
                                ? 5
                                : isSmallScreen
                                ? 3
                                : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedResultFilter = filter;
                              _applyFilters();
                            });
                          },
                          borderRadius: BorderRadius.circular(
                            isLargeDesktop
                                ? 12
                                : isDesktop
                                ? 10
                                : isTablet
                                ? 9
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeDesktop
                                  ? 18
                                  : isDesktop
                                  ? 16
                                  : isTablet
                                  ? 15
                                  : isSmallScreen
                                  ? 10
                                  : 12,
                              vertical: isLargeDesktop
                                  ? 12
                                  : isDesktop
                                  ? 10
                                  : isTablet
                                  ? 9.5
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
            child: Text(
                              filter,
              style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 16
                                    : isDesktop
                                    ? 14
                                    : isTablet
                                    ? 13
                                    : isSmallScreen
                                    ? 10
                                    : 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernResultsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final result = _filteredResults[index];
        final delay = index * 100;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + delay),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.only(
                    left: isLargeDesktop
                        ? 32
                        : isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : isSmallScreen
                        ? 12
                        : 16,
                    right: isLargeDesktop
                        ? 32
                        : isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : isSmallScreen
                        ? 12
                        : 16,
                    bottom: index == _filteredResults.length - 1
                        ? 0
                        : (isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 16
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 8
                            : 12),
                  ),
                  child: _buildModernResultCard(result),
                ),
              ),
            );
          },
        );
      }, childCount: _filteredResults.length),
    );
  }

  Widget _buildModernResultCard(
    Map<String, dynamic> result,
  ) {
    final percentage = result['percentage'] as double;
    final status = result['status'] as String;
    final statusColor = _getStatusColor(status, percentage);
    final date = DateTime.tryParse(result['date']) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 10
                      : 14,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 16
                : isDesktop
                ? 12
                : isTablet
                ? 11
                : isSmallScreen
                ? 6
                : 8,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 6
                  : isDesktop
                  ? 4
                  : isTablet
                  ? 3
                  : isSmallScreen
                  ? 2
                  : 2,
            ),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showResultDetails(result),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : isSmallScreen
                        ? 10
                        : 14,
                  ),
                  child: Padding(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            child: Row(
                      children: [
                // Status Icon
                Container(
                  padding: EdgeInsets.all(
                    isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                  ),
                  child: Icon(
                                      _getStatusIcon(status, percentage),
                    size: isLargeDesktop
                        ? 32
                        : isDesktop
                        ? 28
                        : isTablet
                        ? 26
                        : isSmallScreen
                        ? 20
                        : 24,
                                      color: statusColor,
                                    ),
                ),
                SizedBox(
                  width: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 8
                      : 12,
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                              result['examTitle'],
                                style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 22
                                    : isDesktop
                                    ? 18
                                    : isTablet
                                    ? 17
                                    : isSmallScreen
                                    ? 14
                                    : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                                ),
                                maxLines: isLargeDesktop || isDesktop
                                    ? 2
                                    : isTablet
                                    ? 2
                                    : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 8
                                  : isTablet
                                  ? 7
                                  : isSmallScreen
                                  ? 5
                                  : 6,
                              vertical: isLargeDesktop
                                  ? 6
                                  : isDesktop
                                  ? 4
                                  : isTablet
                                  ? 3.5
                                  : isSmallScreen
                                  ? 2
                                  : 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isLargeDesktop
                                    ? 8
                                    : isDesktop
                                    ? 6
                                    : isTablet
                                    ? 5.5
                                    : isSmallScreen
                                    ? 4
                                    : 4,
                              ),
                            ),
                                        child: Text(
                              status,
                                          style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 12
                                    : isDesktop
                                    ? 10
                                    : isTablet
                                    ? 9.5
                                    : isSmallScreen
                                    ? 8
                                    : 9,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                      SizedBox(
                        height: isLargeDesktop || isDesktop
                            ? 6
                            : isTablet
                            ? 5
                            : isSmallScreen
                            ? 2
                            : 4,
                      ),
                                        Text(
                        result['subject'],
                                          style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 14
                              : isTablet
                              ? 13
                              : isSmallScreen
                              ? 11
                              : 12,
                                            color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: isLargeDesktop
                            ? 14
                            : isDesktop
                            ? 12
                            : isTablet
                            ? 11
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      Row(
                                          children: [
                          _buildModernInfoChip(
                            icon: Icons.percent_rounded,
                            label: '${percentage.toStringAsFixed(1)}%',
                          ),
                          SizedBox(
                            width: isLargeDesktop
                                ? 14
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          _buildModernInfoChip(
                            icon: Icons.quiz_rounded,
                            label:
                                          '${result['correctAnswers']}/${result['totalQuestions']}',
                                          ),
                          const Spacer(),
                                        Text(
                            formattedDate,
                                          style: TextStyle(
                                            fontSize: isLargeDesktop
                                                ? 14
                                                : isDesktop
                                                ? 12
                                                : isTablet
                                                ? 11
                                                : isSmallScreen
                                                ? 9
                                                : 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                  ),
                                ],
                              ),
                ),
                              SizedBox(
                                width: isLargeDesktop
                                    ? 14
                                    : isDesktop
                                    ? 12
                                    : isTablet
                                    ? 11
                                    : isSmallScreen
                                    ? 6
                                    : 8,
                              ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                  size: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 14
                      : 16,
                              color: const Color(0xFF6B5FFF),
                            ),
                          ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildModernInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 13
                : isSmallScreen
                ? 10
                : 12,
            color: Colors.grey[600],
          ),
        SizedBox(
          width: isLargeDesktop || isDesktop
              ? 4
              : isTablet
              ? 3
              : isSmallScreen
              ? 2
              : 2,
        ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
              fontSize: isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 9
                  : 11,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
    );
  }

  Color _getStatusColor(String status, double percentage) {
    if (status == 'Under Review') return const Color(0xFFFF9800);
    if (percentage >= 80) return const Color(0xFFFFD700);
    if (percentage >= 40) return const Color(0xFF4CAF50);
    return const Color(0xFFF44336);
  }

  IconData _getStatusIcon(String status, double percentage) {
    if (status == 'Under Review') return Icons.pending_actions_rounded;
    if (percentage >= 80) return Icons.workspace_premium_rounded;
    if (percentage >= 40) return Icons.check_circle_rounded;
    return Icons.cancel_rounded;
  }

  void _showResultDetails(
    Map<String, dynamic> result,
  ) {
    final percentage = result['percentage'] as double;
    final status = result['status'] as String;
    final statusColor = _getStatusColor(status, percentage);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 20
                : isSmallScreen
                ? 12
                : 16,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
              ),
              child: Icon(
                _getStatusIcon(status, percentage),
                color: Colors.white,
                size: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            Expanded(
              child: Text(
                result['examTitle'],
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 14
                      : 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.assessment_rounded,
                'Status',
                status,
                statusColor,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              _buildDetailRow(
                Icons.percent_rounded,
                'Percentage',
                '${percentage.toStringAsFixed(1)}%',
                statusColor,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              _buildDetailRow(
                Icons.grade_rounded,
                'Score',
                '${result['score'].toStringAsFixed(0)}/${result['totalMarks'].toStringAsFixed(0)}',
                const Color(0xFF6B5FFF),
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              _buildDetailRow(
                Icons.quiz_rounded,
                'Correct Answers',
                '${result['correctAnswers']}/${result['totalQuestions']}',
                const Color(0xFF6B5FFF),
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              _buildDetailRow(
                Icons.category_rounded,
                'Subject',
                result['subject'],
                const Color(0xFF6B5FFF),
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              _buildDetailRow(
                Icons.timer_outlined,
                'Time Taken',
                result['timeTaken'],
                const Color(0xFF6B5FFF),
              ),
              if (result['rank'] != null) ...[
                SizedBox(
                  height: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                _buildDetailRow(
                  Icons.emoji_events_rounded,
                  'Rank',
                  'Rank ${result['rank']}',
                  const Color(0xFFFFD700),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 12
                    : 13,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 9
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Detailed analysis coming soon!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF6B5FFF),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 12
                      : isDesktop
                      ? 10
                      : isTablet
                      ? 9
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 14
                        : 16,
                    vertical: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 10
                        : isTablet
                        ? 9
                        : isSmallScreen
                        ? 7
                        : 8,
                  ),
                  child: Text(
                    'View Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 15
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 12
                          : 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 19
              : isSmallScreen
              ? 16
              : 18,
          color: color,
        ),
        SizedBox(
          width: isLargeDesktop
              ? 16
              : isDesktop
              ? 12
              : isTablet
              ? 11
              : isSmallScreen
              ? 8
              : 10,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 15
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 11,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(
                height: isLargeDesktop || isDesktop
                    ? 4
                    : isTablet
                    ? 3
                    : isSmallScreen
                    ? 1
                    : 2,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 17
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 12
                      : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 18
                : isSmallScreen
                ? 12
                : 16,
          ),
          Text(
            'Loading results...',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 17
                  : isSmallScreen
                  ? 14
                  : 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isNoInternet = _errorMessage == 'No internet connection';
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64
              : isDesktop
              ? 48
              : isTablet
              ? 40
              : isSmallScreen
              ? 24
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: isLargeDesktop
                  ? 80
                  : isDesktop
                  ? 64
                  : isTablet
                  ? 60
                  : isSmallScreen
                  ? 48
                  : 56,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            Text(
              isNoInternet ? 'No internet connection' : 'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 19
                    : isSmallScreen
                    ? 16
                    : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (isNoInternet) ...[
              SizedBox(
                height: isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              Text(
                'Please check your connection and try again',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 11
                      : 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              SizedBox(
                height: isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              Text(
                _errorMessage ?? 'Unable to load results',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 11
                      : 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 26
                  : isSmallScreen
                  ? 20
                  : 24,
            ),
            ElevatedButton.icon(
              onPressed: () => _loadResults(forceRefresh: true),
              icon: Icon(
                Icons.refresh_rounded,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 40
                      : isDesktop
                      ? 32
                      : isTablet
                      ? 28
                      : isSmallScreen
                      ? 20
                      : 24,
                  vertical: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 10
                      : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 8
                        : 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters =
        _selectedResultFilter != 'All Results' ||
        _searchController.text.isNotEmpty;

    if (hasActiveFilters) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isLargeDesktop
                ? 64
                : isDesktop
                ? 48
                : isTablet
                ? 40
                : isSmallScreen
                ? 24
                : 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 24
                      : isTablet
                      ? 22
                      : isSmallScreen
                      ? 16
                      : 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: isLargeDesktop
                      ? 80
                      : isDesktop
                      ? 64
                      : isTablet
                      ? 60
                      : isSmallScreen
                      ? 48
                      : 56,
                  color: const Color(0xFF6B5FFF),
                ),
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              Text(
                'No Results Found',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 19
                      : isSmallScreen
                      ? 16
                      : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              Text(
                'Try adjusting your filters or search criteria',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 11
                      : 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 32
                    : isDesktop
                    ? 28
                    : isTablet
                    ? 26
                    : isSmallScreen
                    ? 20
                    : 24,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedResultFilter = 'All Results';
                    _selectedSortOption = 'Date';
                    _applyFilters();
                  });
                },
                icon: Icon(
                  Icons.clear_all_rounded,
                  size: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 22
                      : isTablet
                      ? 20
                      : isSmallScreen
                      ? 18
                      : 20,
                ),
                label: Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : isSmallScreen
                        ? 12
                        : 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 40
                        : isDesktop
                        ? 32
                        : isTablet
                        ? 28
                        : isSmallScreen
                        ? 20
                        : 24,
                    vertical: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : isSmallScreen
                        ? 10
                        : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64
              : isDesktop
              ? 48
              : isTablet
              ? 40
              : isSmallScreen
              ? 24
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 32
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B5FFF).withOpacity(0.2),
                    const Color(0xFF6B5FFF).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assessment_outlined,
                size: isLargeDesktop
                    ? 80
                    : isDesktop
                    ? 64
                    : isTablet
                    ? 60
                    : isSmallScreen
                    ? 48
                    : 56,
                color: const Color(0xFF6B5FFF),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            Text(
              'No Exam Results Yet',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 26
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 21
                    : isSmallScreen
                    ? 18
                    : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            Text(
              'Complete your first exam to see results here.\nYour performance metrics and detailed analytics will appear once you start taking exams.',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 13
                    : isSmallScreen
                    ? 11
                    : 12,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: isLargeDesktop || isDesktop
                  ? 4
                  : isTablet
                  ? 3
                  : 3,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 36
                  : isDesktop
                  ? 32
                  : isTablet
                  ? 30
                  : isSmallScreen
                  ? 24
                  : 28,
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onNavigateToExams != null) {
                  widget.onNavigateToExams!();
                } else {
                  // Fallback: navigate to exams page if callback not provided
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExamsPage(),
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.assignment_rounded,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              label: Text(
                'Browse Exams',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 12
                      : 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 40
                      : isDesktop
                      ? 32
                      : isTablet
                      ? 28
                      : isSmallScreen
                      ? 20
                      : 24,
                  vertical: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 10
                      : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 8
                        : 10,
                  ),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
