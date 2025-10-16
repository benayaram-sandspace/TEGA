import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

class MyResultsPage extends StatefulWidget {
  const MyResultsPage({super.key});

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
    _loadResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final dashboardService = StudentDashboardService();

      // Fetch exam results from backend
      final results = await dashboardService.getExamResults(headers);

      if (mounted) {
        _allResults = results.map<Map<String, dynamic>>((result) {
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

        _calculateStats();
        setState(() {
          _filteredResults = List.from(_allResults);
          _applyFilters();
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load results. Please try again.';
          _allResults = [];
          _filteredResults = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState(isDesktop, isTablet)
          : _filteredResults.isEmpty
          ? _buildEmptyState(isDesktop, isTablet)
          : _buildModernResultsPage(isDesktop, isTablet),
    );
  }

  Widget _buildModernResultsPage(bool isDesktop, bool isTablet) {
    return CustomScrollView(
      slivers: [
        // Modern Header
        _buildModernHeader(isDesktop, isTablet),

        // Stats Overview
        _buildStatsOverview(isDesktop, isTablet),

        // Search and Filters
        _buildModernSearchAndFilters(isDesktop, isTablet),

        // Results List
        _buildModernResultsList(isDesktop, isTablet),

        // Bottom padding
        SliverToBoxAdapter(child: SizedBox(height: isDesktop ? 40 : 32)),
      ],
    );
  }

  Widget _buildModernHeader(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        padding: EdgeInsets.all(
          isDesktop
              ? 32
              : isTablet
              ? 28
              : 24,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5FFF), Color(0xFF9C88FF), Color(0xFFB19CD9)],
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5FFF).withOpacity(0.3),
              blurRadius: isDesktop ? 20 : 16,
              offset: Offset(0, isDesktop ? 8 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                  ),
                  child: Icon(
                    Icons.assessment_rounded,
                    color: Colors.white,
                    size: isDesktop ? 32 : 28,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Results',
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 2),
                      Text(
                        'Track your exam performance and progress',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
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
                    size: isDesktop ? 20 : 18,
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                  Expanded(
                    child: Text(
                      'View detailed analytics and performance insights',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
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

  Widget _buildStatsOverview(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _buildModernStatsRow(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatsRow(bool isDesktop, bool isTablet) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: isDesktop ? 16 : 12,
                    offset: Offset(0, isDesktop ? 6 : 4),
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
                      isDesktop: isDesktop,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isDesktop ? 60 : 50,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildModernStatItem(
                      icon: Icons.check_circle_rounded,
                      value: _passedExams.toString(),
                      label: 'Passed',
                      color: const Color(0xFF4CAF50),
                      isDesktop: isDesktop,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isDesktop ? 60 : 50,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildModernStatItem(
                      icon: Icons.workspace_premium_rounded,
                      value: _qualifiedExams.toString(),
                      label: 'Qualified',
                      color: const Color(0xFFFFD700),
                      isDesktop: isDesktop,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isDesktop ? 60 : 50,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildModernStatItem(
                      icon: Icons.pending_actions_rounded,
                      value: _underReviewExams.toString(),
                      label: 'Under Review',
                      color: const Color(0xFFFF9800),
                      isDesktop: isDesktop,
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
    required bool isDesktop,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 12 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          ),
          child: Icon(icon, color: color, size: isDesktop ? 24 : 20),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: isDesktop ? 4 : 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModernSearchAndFilters(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
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
                    fontSize: isDesktop ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 8,
                    vertical: isDesktop ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5FFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                  ),
                  child: Text(
                    '${_filteredResults.length} results',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 16 : 12),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: isDesktop ? 8 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: TextStyle(fontSize: isDesktop ? 16 : 14),
                decoration: InputDecoration(
                  hintText: 'Search exams by name or subject...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isDesktop ? 16 : 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF6B5FFF),
                    size: isDesktop ? 24 : 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                          color: Colors.grey[400],
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 20 : 16,
                    vertical: isDesktop ? 16 : 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),

            // Filter Chips
            SizedBox(
              height: isDesktop ? 44 : 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _resultFilters.length,
                itemBuilder: (context, index) {
                  final filter = _resultFilters[index];
                  final isSelected = _selectedResultFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: isDesktop ? 10 : 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B5FFF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6B5FFF)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: isDesktop ? 6 : 4,
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
                            isDesktop ? 10 : 8,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16 : 12,
                              vertical: isDesktop ? 10 : 8,
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
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
            SizedBox(height: isDesktop ? 20 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernResultsList(bool isDesktop, bool isTablet) {
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
                    left: isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : 16,
                    right: isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : 16,
                    bottom: index == _filteredResults.length - 1
                        ? 0
                        : (isDesktop ? 16 : 12),
                  ),
                  child: _buildModernResultCard(result, isDesktop, isTablet),
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
    bool isDesktop,
    bool isTablet,
  ) {
    final percentage = result['percentage'] as double;
    final status = result['status'] as String;
    final statusColor = _getStatusColor(status, percentage);
    final date = DateTime.tryParse(result['date']) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isDesktop ? 12 : 8,
            offset: Offset(0, isDesktop ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showResultDetails(result, isDesktop, isTablet),
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                // Status Icon
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                  ),
                  child: Icon(
                    _getStatusIcon(status, percentage),
                    size: isDesktop ? 28 : 24,
                    color: statusColor,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),

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
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 8 : 6,
                              vertical: isDesktop ? 4 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 6 : 4,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: isDesktop ? 10 : 9,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 6 : 4),
                      Text(
                        result['subject'],
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      Row(
                        children: [
                          _buildModernInfoChip(
                            icon: Icons.percent_rounded,
                            label: '${percentage.toStringAsFixed(1)}%',
                            isDesktop: isDesktop,
                          ),
                          SizedBox(width: isDesktop ? 12 : 8),
                          _buildModernInfoChip(
                            icon: Icons.quiz_rounded,
                            label:
                                '${result['correctAnswers']}/${result['totalQuestions']}',
                            isDesktop: isDesktop,
                          ),
                          const Spacer(),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: isDesktop ? 12 : 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isDesktop ? 18 : 16,
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
    required bool isDesktop,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isDesktop ? 14 : 12, color: Colors.grey[600]),
        SizedBox(width: isDesktop ? 4 : 2),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 11,
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
    bool isDesktop,
    bool isTablet,
  ) {
    final percentage = result['percentage'] as double;
    final status = result['status'] as String;
    final statusColor = _getStatusColor(status, percentage);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(status, percentage),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result['examTitle'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
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
                isDesktop,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.percent_rounded,
                'Percentage',
                '${percentage.toStringAsFixed(1)}%',
                statusColor,
                isDesktop,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.grade_rounded,
                'Score',
                '${result['score'].toStringAsFixed(0)}/${result['totalMarks'].toStringAsFixed(0)}',
                const Color(0xFF6B5FFF),
                isDesktop,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.quiz_rounded,
                'Correct Answers',
                '${result['correctAnswers']}/${result['totalQuestions']}',
                const Color(0xFF6B5FFF),
                isDesktop,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.category_rounded,
                'Subject',
                result['subject'],
                const Color(0xFF6B5FFF),
                isDesktop,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.timer_outlined,
                'Time Taken',
                result['timeTaken'],
                const Color(0xFF6B5FFF),
                isDesktop,
              ),
              if (result['rank'] != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.emoji_events_rounded,
                  'Rank',
                  'Rank ${result['rank']}',
                  const Color(0xFFFFD700),
                  isDesktop,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'View Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
    bool isDesktop,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isDesktop ? 20 : 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isDesktop ? 13 : 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isDesktop ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
                maxLines: 2,
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
          const SizedBox(height: 16),
          Text(
            'Loading results...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDesktop, bool isTablet) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isDesktop
              ? 48
              : isTablet
              ? 40
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isDesktop ? 64 : 56,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unable to load results',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24,
                  vertical: isDesktop ? 16 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop, bool isTablet) {
    final hasActiveFilters =
        _selectedResultFilter != 'All Results' ||
        _searchController.text.isNotEmpty;

    if (hasActiveFilters) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isDesktop
                ? 48
                : isTablet
                ? 40
                : 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 24 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: isDesktop ? 64 : 56,
                  color: const Color(0xFF6B5FFF),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Results Found',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Try adjusting your filters or search criteria',
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedResultFilter = 'All Results';
                    _selectedSortOption = 'Date';
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.clear_all_rounded, size: 20),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 24,
                    vertical: isDesktop ? 16 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
          isDesktop
              ? 48
              : isTablet
              ? 40
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
                size: isDesktop ? 64 : 56,
                color: const Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Exam Results Yet',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first exam to see results here.\nYour performance metrics and detailed analytics will appear once you start taking exams.',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Exams page to start!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF6B5FFF),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_rounded, size: 20),
              label: const Text('Browse Exams'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24,
                  vertical: isDesktop ? 16 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
