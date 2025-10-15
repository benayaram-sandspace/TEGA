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

  final List<String> _sortOptions = ['Date', 'Subject', 'Score'];

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

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(
            isDesktop
                ? 24.0
                : isTablet
                ? 20.0
                : 16.0,
          ),
          child: Column(
            children: [
              _buildSearchAndFilters(screenWidth, isDesktop, isTablet),
              SizedBox(height: isDesktop ? 24 : 20),
              if (!_isLoading && _errorMessage == null)
                _buildStatsCards(screenWidth, isDesktop, isTablet),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState(isDesktop, isTablet)
              : _filteredResults.isEmpty
              ? _buildEmptyState(isDesktop, isTablet)
              : _buildResultsList(screenWidth, isDesktop, isTablet),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    double screenWidth,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Search Bar
        TextField(
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
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
              borderSide: const BorderSide(color: Color(0xFF6B5FFF), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 16 : 14,
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 14),

        // Dropdown Filters
        Row(
          children: [
            // Result Filter Dropdown
            Expanded(
              child: _buildDropdownFilter(
                label: 'Filter by Result',
                value: _selectedResultFilter,
                items: _resultFilters,
                onChanged: (value) {
                  setState(() {
                    _selectedResultFilter = value!;
                    _applyFilters();
                  });
                },
                icon: Icons.filter_list_rounded,
                isDesktop: isDesktop,
                isTablet: isTablet,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            // Sort Dropdown
            Expanded(
              child: _buildDropdownFilter(
                label: 'Sort by',
                value: _selectedSortOption,
                items: _sortOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedSortOption = value!;
                    _applyFilters();
                  });
                },
                icon: Icons.sort_rounded,
                isDesktop: isDesktop,
                isTablet: isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF6B5FFF),
            size: isDesktop ? 24 : 20,
          ),
          style: TextStyle(
            fontSize: isDesktop ? 15 : 14,
            color: const Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: isDesktop ? 18 : 16,
                    color: value == item
                        ? const Color(0xFF6B5FFF)
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatsCards(double screenWidth, bool isDesktop, bool isTablet) {
    final isSmallMobile = screenWidth < 360;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop
          ? 4
          : isTablet
          ? 2
          : isSmallMobile
          ? 1
          : 2,
      crossAxisSpacing: isDesktop
          ? 16
          : isTablet
          ? 12
          : 10,
      mainAxisSpacing: isDesktop
          ? 16
          : isTablet
          ? 12
          : 10,
      childAspectRatio: isDesktop
          ? 1.5
          : isTablet
          ? 1.4
          : isSmallMobile
          ? 2.2
          : 1.3,
      children: [
        _buildStatCard(
          title: 'Total Exams',
          value: _totalExams.toString(),
          icon: Icons.assignment_rounded,
          color: const Color(0xFF6B5FFF),
          gradient: const LinearGradient(
            colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
          ),
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        _buildStatCard(
          title: 'Passed',
          value: _passedExams.toString(),
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF4CAF50),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        _buildStatCard(
          title: 'Qualified',
          value: _qualifiedExams.toString(),
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFFFD700),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        _buildStatCard(
          title: 'Under Review',
          value: _underReviewExams.toString(),
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFFF9800),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          ),
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 12
            : isTablet
            ? 10
            : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 10 : 8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isDesktop
                  ? 24
                  : isTablet
                  ? 20
                  : 18,
            ),
          ),
          SizedBox(height: isDesktop ? 10 : 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isDesktop
                    ? 32
                    : isTablet
                    ? 28
                    : 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isDesktop
                    ? 13
                    : isTablet
                    ? 12
                    : 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(double screenWidth, bool isDesktop, bool isTablet) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 24
            : isTablet
            ? 20
            : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final result = _filteredResults[index];
        return _buildResultCard(
          result,
          index,
          screenWidth,
          isDesktop,
          isTablet,
        );
      },
    );
  }

  Widget _buildResultCard(
    Map<String, dynamic> result,
    int index,
    double screenWidth,
    bool isDesktop,
    bool isTablet,
  ) {
    final percentage = result['percentage'] as double;
    final status = result['status'] as String;
    final statusColor = _getStatusColor(status, percentage);
    final date = DateTime.tryParse(result['date']) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(bottom: isDesktop ? 16 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showResultDetails(result, isDesktop, isTablet),
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
                  child: Padding(
                    padding: EdgeInsets.all(
                      isDesktop
                          ? 20
                          : isTablet
                          ? 16
                          : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Status Badge
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(status, percentage),
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: isDesktop ? 13 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Date
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: isDesktop ? 13 : 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 16 : 14),

                        // Exam Title
                        Text(
                          result['examTitle'],
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 20
                                : isTablet
                                ? 18
                                : 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Subject
                        Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 16,
                              color: const Color(0xFF6B5FFF),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                result['subject'],
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 16 : 14),

                        // Score Section
                        screenWidth < 400
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Score Display
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${result['score'].toStringAsFixed(0)}/${result['totalMarks'].toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Question Stats
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6B5FFF,
                                      ).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.quiz_rounded,
                                          color: const Color(0xFF6B5FFF),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${result['correctAnswers']}/${result['totalQuestions']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6B5FFF),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Correct',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${percentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: isDesktop
                                                      ? 32
                                                      : isTablet
                                                      ? 28
                                                      : 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                '${result['score'].toStringAsFixed(0)}/${result['totalMarks'].toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: isDesktop ? 16 : 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Progress Bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            minHeight: 8,
                                            backgroundColor: Colors.grey[200],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  statusColor,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isDesktop ? 20 : 16),
                                  // Question Stats
                                  Container(
                                    padding: EdgeInsets.all(
                                      isDesktop
                                          ? 16
                                          : isTablet
                                          ? 14
                                          : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6B5FFF,
                                      ).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.quiz_rounded,
                                          color: const Color(0xFF6B5FFF),
                                          size: isDesktop ? 28 : 24,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${result['correctAnswers']}/${result['totalQuestions']}',
                                          style: TextStyle(
                                            fontSize: isDesktop ? 16 : 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF6B5FFF),
                                          ),
                                        ),
                                        Text(
                                          'Correct',
                                          style: TextStyle(
                                            fontSize: isDesktop ? 12 : 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        SizedBox(height: isDesktop ? 16 : 14),

                        // Bottom Info
                        Row(
                          children: [
                            Flexible(
                              child: _buildInfoChip(
                                icon: Icons.timer_outlined,
                                label: result['timeTaken'],
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                            ),
                            if (result['rank'] != null) ...[
                              SizedBox(width: isDesktop ? 12 : 8),
                              Flexible(
                                child: _buildInfoChip(
                                  icon: Icons.emoji_events_rounded,
                                  label: 'Rank ${result['rank']}',
                                  isDesktop: isDesktop,
                                  isTablet: isTablet,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: isDesktop ? 16 : 14,
                              color: const Color(0xFF6B5FFF),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 10 : 8,
        vertical: isDesktop ? 6 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 14 : 12, color: Colors.grey[600]),
          SizedBox(width: isDesktop ? 6 : 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
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
