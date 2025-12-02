import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/core/services/internships_cache_service.dart';

class InternshipsPage extends StatefulWidget {
  const InternshipsPage({super.key});

  @override
  State<InternshipsPage> createState() => _InternshipsPageState();
}

class _InternshipsPageState extends State<InternshipsPage> {
  final TextEditingController _searchController = TextEditingController();
  final InternshipsCacheService _cacheService = InternshipsCacheService();
  List<Map<String, dynamic>> _allInternships = [];
  List<Map<String, dynamic>> _filteredInternships = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _activeInternships = 0;
  int _companies = 0;

  // Filter and sort states
  String _selectedCategory = 'All Categories';
  String _selectedSortBy = 'Most Recent';
  final List<String> _categories = [
    'All Categories',
    'Technology',
    'Marketing',
    'Finance',
    'Design',
    'Human Resources',
  ];
  final List<String> _sortOptions = [
    'Most Recent',
    'Oldest First',
    'Company A-Z',
    'Company Z-A',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadInternshipData();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInternshipData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedInternships = await _cacheService.getInternshipsData();
      if (cachedInternships != null &&
          cachedInternships.isNotEmpty &&
          mounted) {
        setState(() {
          _allInternships = cachedInternships;
          _calculateStats();
          _filteredInternships = List.from(_allInternships);
          _applyFilters();
          _isLoading = false;
          _errorMessage = null;
        });
        // Still fetch in background to update cache
        _fetchInternshipsInBackground();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch from API
    await _fetchInternshipsInBackground();
  }

  Future<void> _fetchInternshipsInBackground() async {
    try {
      final dashboardService = StudentDashboardService();

      // Fetch internships from backend (public endpoint, no auth needed)
      final internshipData = await dashboardService.getInternships({});

      // Transform backend data to match UI needs
      final transformedInternships = internshipData.map<Map<String, dynamic>>((
        internship,
      ) {
        // Extract work type from jobType field (backend uses: full-time, part-time, contract, internship)
        String workType = 'Internship';
        final jobTypeRaw = internship['jobType'] ?? '';
        switch (jobTypeRaw.toString().toLowerCase()) {
          case 'internship':
            workType = 'Internship';
            break;
          case 'part-time':
            workType = 'Part Time';
            break;
          case 'contract':
            workType = 'Contract';
            break;
          case 'full-time':
            workType = 'Full Time';
            break;
          default:
            workType = 'Internship';
        }

        // Format salary
        String salary = 'Not specified';
        if (internship['salary'] != null) {
          final salaryNum = internship['salary'] as num?;
          if (salaryNum != null && salaryNum > 0) {
            salary = '₹${salaryNum.toStringAsFixed(0)}';
          }
        }

        // Format posted date
        String postedDate = 'Recently';
        if (internship['createdAt'] != null) {
          try {
            final date = DateTime.parse(internship['createdAt']);
            final now = DateTime.now();
            final difference = now.difference(date);
            if (difference.inDays == 0) {
              postedDate = 'Today';
            } else if (difference.inDays == 1) {
              postedDate = '1 day ago';
            } else if (difference.inDays < 7) {
              postedDate = '${difference.inDays} days ago';
            } else if (difference.inDays < 30) {
              postedDate = '${(difference.inDays / 7).floor()} weeks ago';
            } else {
              postedDate = '${(difference.inDays / 30).floor()} months ago';
            }
          } catch (e) {
            postedDate = 'Recently';
          }
        }

        return {
          'id': internship['_id'] ?? internship['id'] ?? '',
          'title': internship['title'] ?? 'Untitled Internship',
          'company': internship['company'] ?? 'Company',
          'location': internship['location'] ?? 'Location',
          'workType': workType,
          'salary': salary,
          'description':
              internship['description'] ?? 'No description available',
          'postedDate': postedDate,
          'applicants': 0, // Backend doesn't track applicants count yet
          'applicationLink':
              internship['applicationLink'], // Include application link
          'category': internship['category'] ?? 'General', // Add category field
          'duration':
              internship['duration'] ?? 'Not specified', // Add duration field
          'stipend':
              internship['stipend'] ??
              salary, // Add stipend field (use salary as fallback)
        };
      }).toList();

      // Cache internships data
      await _cacheService.setInternshipsData(transformedInternships);

      if (mounted) {
        setState(() {
          _allInternships = transformedInternships;
          _calculateStats();
          _filteredInternships = List.from(_allInternships);
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
          final cachedInternships = await _cacheService.getInternshipsData();
          if (cachedInternships != null && cachedInternships.isNotEmpty) {
            setState(() {
              _allInternships = cachedInternships;
              _calculateStats();
              _filteredInternships = List.from(_allInternships);
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
            _errorMessage = 'Unable to load internships. Please try again.';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _calculateStats() {
    if (_allInternships.isNotEmpty) {
      _activeInternships = _allInternships.length;
      _companies = _allInternships
          .map((internship) => internship['company'])
          .toSet()
          .length;
    } else {
      _activeInternships = 0;
      _companies = 0;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInternships = _allInternships.where((internship) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            (internship['title'] ?? '').toLowerCase().contains(searchQuery) ||
            (internship['company'] ?? '').toLowerCase().contains(searchQuery) ||
            (internship['description'] ?? '').toLowerCase().contains(
              searchQuery,
            ) ||
            (internship['location'] ?? '').toLowerCase().contains(searchQuery);

        // Category filter
        final matchesCategory =
            _selectedCategory == 'All Categories' ||
            (internship['category'] ?? 'General') == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Apply sorting
      switch (_selectedSortBy) {
        case 'Most Recent':
          // Already sorted by default (createdAt desc from backend)
          break;
        case 'Oldest First':
          _filteredInternships = _filteredInternships.reversed.toList();
          break;
        case 'Company A-Z':
          _filteredInternships.sort(
            (a, b) =>
                a['company'].toString().compareTo(b['company'].toString()),
          );
          break;
        case 'Company Z-A':
          _filteredInternships.sort(
            (a, b) =>
                b['company'].toString().compareTo(a['company'].toString()),
          );
          break;
      }
    });
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
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
        ),
        title: Text(
          'Filter Options',
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
          ),
        ),
        contentPadding: EdgeInsets.all(
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
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
            SizedBox(
              height: isLargeDesktop || isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            Wrap(
              spacing: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 8
                  : isTablet
                  ? 7
                  : isSmallScreen
                  ? 4
                  : 6,
              runSpacing: isLargeDesktop || isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      fontSize: isLargeDesktop
                          ? 17
                          : isDesktop
                          ? 15
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 11
                          : 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF6B5FFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: isLargeDesktop
                        ? 17
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 11
                        : 13,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 8
                        : 10,
                    vertical: isLargeDesktop
                        ? 10
                        : isDesktop
                        ? 8
                        : isTablet
                        ? 7.5
                        : isSmallScreen
                        ? 5
                        : 6,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
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
            style: TextButton.styleFrom(
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
          ),
        ],
      ),
    );
  }

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
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

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64.0
              : isDesktop
              ? 48.0
              : isTablet
              ? 40.0
              : isSmallScreen
              ? 24.0
              : 32.0,
        ),
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
              'Loading internships...',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 32.0
            : isDesktop
            ? 24.0
            : isTablet
            ? 20.0
            : isSmallScreen
            ? 12.0
            : 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
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
          _buildStatsCards(),
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
          _buildSearchAndFilters(),
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
          _buildCategories(),
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
          _buildResultsCount(),
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
          _filteredInternships.isEmpty
              ? _buildEmptyState()
              : _buildInternshipsList(),
          SizedBox(
            height: isLargeDesktop
                ? 32
                : isDesktop
                ? 24
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 40
            : isDesktop
            ? 32
            : isTablet
            ? 28
            : isSmallScreen
            ? 20
            : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
        ),
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
              Icon(
                Icons.work_outline_rounded,
                color: Colors.white,
                size: isLargeDesktop
                    ? 40
                    : isDesktop
                    ? 32
                    : isTablet
                    ? 30
                    : isSmallScreen
                    ? 24
                    : 28,
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
                  'Internship Opportunities',
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
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop || isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 6
                : 10,
          ),
          Text(
            'Gain valuable experience and kickstart your career with exciting internship opportunities',
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
              height: 1.5,
            ),
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            value: '$_activeInternships',
            label: 'Active Internships',
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
          child: _buildStatCard(
            icon: Icons.business_rounded,
            value: '$_companies',
            label: 'Companies',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      height: isLargeDesktop
          ? 140
          : isDesktop
          ? 120
          : isTablet
          ? 110
          : isSmallScreen
          ? 90
          : 100,
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
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 14
                : isDesktop
                ? 10
                : isTablet
                ? 9
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
                  : 3,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF).withOpacity(0.1),
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
              color: const Color(0xFF6B5FFF),
              size: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 26
                  : isSmallScreen
                  ? 20
                  : 24,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    value,
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
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop || isDesktop
                      ? 6
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 2
                      : 3,
                ),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isLargeDesktop
                          ? 17
                          : isDesktop
                          ? 15
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 11
                          : 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: TextField(
              controller: _searchController,
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
                hintText: 'Search by title, company, or description...',
                hintStyle: TextStyle(
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
                  Icons.search_rounded,
                  color: Colors.grey,
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
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B5FFF),
                    width: 2,
                  ),
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
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 12
                : isTablet
                ? 11
                : isSmallScreen
                ? 6
                : 10,
          ),
          // Sort dropdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeDesktop
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 13
                    : isSmallScreen
                    ? 10
                    : 12,
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _selectedSortBy,
              underline: const SizedBox(),
              icon: Icon(
                Icons.unfold_more_rounded,
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
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 17
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 11
                    : 13,
              ),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 17
                            : isSmallScreen
                            ? 14
                            : 16,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        width: isLargeDesktop || isDesktop
                            ? 10
                            : isTablet
                            ? 9
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      Text(
                        option,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 17
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 11
                              : 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSortBy = value;
                    _applyFilters();
                  });
                }
              },
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
                ? 6
                : 10,
          ),
          // Filters button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 13
                    : isSmallScreen
                    ? 10
                    : 12,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list_rounded,
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
              onPressed: _showFiltersDialog,
              tooltip: 'Filters',
              padding: EdgeInsets.all(
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
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(
              right: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 6
                  : 10,
            ),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 17
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 11
                      : 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _applyFilters();
                });
              },
              selectedColor: const Color(0xFF6B5FFF),
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: isLargeDesktop
                    ? 17
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 11
                    : 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 20
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
                    ? 9
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
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
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Text(
        'Showing ${_filteredInternships.length} of ${_allInternships.length} internships',
        style: TextStyle(
          fontSize: isLargeDesktop
              ? 17
              : isDesktop
              ? 15
              : isTablet
              ? 14
              : isSmallScreen
              ? 11
              : 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInternshipsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredInternships.length,
      itemBuilder: (context, index) {
        final internship = _filteredInternships[index];
        return _buildInternshipCard(internship);
      },
    );
  }

  Widget _buildInternshipCard(Map<String, dynamic> internship) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 20
            : isDesktop
            ? 16
            : isTablet
            ? 15
            : isSmallScreen
            ? 10
            : 14,
      ),
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
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 15
              : isSmallScreen
              ? 10
              : 14,
        ),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 8
                : isTablet
                ? 7
                : isSmallScreen
                ? 4
                : 6,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 4
                  : isDesktop
                  ? 2
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo placeholder
              Container(
                width: isLargeDesktop
                    ? 72
                    : isDesktop
                    ? 60
                    : isTablet
                    ? 56
                    : isSmallScreen
                    ? 44
                    : 50,
                height: isLargeDesktop
                    ? 72
                    : isDesktop
                    ? 60
                    : isTablet
                    ? 56
                    : isSmallScreen
                    ? 44
                    : 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
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
                child: Center(
                  child: Text(
                    (internship['company'] ?? 'C')[0].toUpperCase(),
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
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ),
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
                      internship['title'],
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
                      maxLines: isLargeDesktop || isDesktop
                          ? 2
                          : isTablet
                          ? 2
                          : 1,
                      overflow: TextOverflow.ellipsis,
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
                      internship['company'],
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 17
                            : isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 11
                            : 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                      ? 8
                      : 10,
                  vertical: isLargeDesktop
                      ? 8
                      : isDesktop
                      ? 6
                      : isTablet
                      ? 5.5
                      : isSmallScreen
                      ? 4
                      : 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 14
                        : 16,
                  ),
                ),
                child: Text(
                  internship['category'],
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
                ? 15
                : isSmallScreen
                ? 10
                : 14,
          ),
          // Description
          Text(
            internship['description'],
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 17
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 11
                  : 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: isLargeDesktop || isDesktop
                ? 3
                : isTablet
                ? 2
                : 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 16
                : isTablet
                ? 15
                : isSmallScreen
                ? 10
                : 14,
          ),
          // Info chips
          Wrap(
            spacing: isLargeDesktop
                ? 16
                : isDesktop
                ? 12
                : isTablet
                ? 11
                : isSmallScreen
                ? 6
                : 10,
            runSpacing: isLargeDesktop || isDesktop
                ? 10
                : isTablet
                ? 9
                : isSmallScreen
                ? 6
                : 8,
            children: [
              _buildInfoChip(
                Icons.location_on_outlined,
                internship['location'],
              ),
              _buildInfoChip(Icons.access_time_rounded, internship['duration']),
              _buildInfoChip(Icons.payments_outlined, internship['stipend']),
              _buildInfoChip(
                Icons.people_outline_rounded,
                '${internship['applicants']} applicants',
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 16
                : isTablet
                ? 15
                : isSmallScreen
                ? 10
                : 14,
          ),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Posted ${internship['postedDate']}',
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
                  color: Colors.grey[500],
                ),
              ),
              ElevatedButton(
                onPressed: () => _applyForInternship(internship['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 32
                        : isDesktop
                        ? 24
                        : isTablet
                        ? 22
                        : isSmallScreen
                        ? 16
                        : 20,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 8
                          : isTablet
                          ? 7.5
                          : isSmallScreen
                          ? 6
                          : 7,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Now',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 14
            : isDesktop
            ? 12
            : isTablet
            ? 11
            : isSmallScreen
            ? 8
            : 10,
        vertical: isLargeDesktop
            ? 8
            : isDesktop
            ? 6
            : isTablet
            ? 5.5
            : isSmallScreen
            ? 4
            : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 14
              : 16,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 18
                : isDesktop
                ? 16
                : isTablet
                ? 15
                : isSmallScreen
                ? 12
                : 14,
            color: Colors.grey[600],
          ),
          SizedBox(
            width: isLargeDesktop || isDesktop
                ? 8
                : isTablet
                ? 7
                : isSmallScreen
                ? 4
                : 6,
          ),
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
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Check if filters are active
    final hasActiveSearch = _searchController.text.isNotEmpty;
    final hasActiveFilters = _selectedCategory != 'All Categories';
    final isFilteredEmpty = hasActiveSearch || hasActiveFilters;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64.0
              : isDesktop
              ? 48.0
              : isTablet
              ? 40.0
              : isSmallScreen
              ? 24.0
              : 32.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                isFilteredEmpty
                    ? Icons.search_off_rounded
                    : Icons.work_outline_rounded,
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
                  ? 32
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            Text(
              isFilteredEmpty
                  ? 'No Internships Found'
                  : 'Internship Feature Coming Soon',
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
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
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
            Text(
              isFilteredEmpty
                  ? 'Try adjusting your search or filter criteria to find more opportunities'
                  : 'The internship feature is currently under development. We\'re working hard to bring you exciting internship opportunities soon!',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 17
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 11
                    : 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: isLargeDesktop || isDesktop
                  ? 3
                  : isTablet
                  ? 2
                  : 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 40
                  : isDesktop
                  ? 32
                  : isTablet
                  ? 28
                  : isSmallScreen
                  ? 20
                  : 24,
            ),
            if (isFilteredEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'All Categories';
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
                  'Clear All Filters',
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
                  elevation: 0,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _loadInternshipData(forceRefresh: true),
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
                  'Refresh',
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5FFF),
                  side: const BorderSide(color: Color(0xFF6B5FFF), width: 1.5),
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

  Widget _buildErrorState() {
    final isNoInternet = _errorMessage == 'No internet connection';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64.0
              : isDesktop
              ? 48.0
              : isTablet
              ? 40.0
              : isSmallScreen
              ? 24.0
              : 32.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              isNoInternet ? 'No internet connection' : 'Something went wrong',
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
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 11
                      : 13,
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
                _errorMessage ?? 'Please try again later',
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
              onPressed: () => _loadInternshipData(forceRefresh: true),
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

  Future<void> _applyForInternship(String internshipId) async {
    // Find the internship data
    final internship = _allInternships.firstWhere(
      (item) => item['id'] == internshipId,
      orElse: () => {},
    );

    if (internship.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship not found'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final applicationLink = internship['applicationLink'];
    if (applicationLink == null || applicationLink.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No application link available for this internship'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Try to open the URL directly in browser
      final Uri url = Uri.parse(applicationLink.toString());

      // Skip canLaunchUrl check and try to launch directly
      bool launched = false;

      // Try platform default first
      try {
        launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        // Platform default failed, try next mode
      }

      // If platform default failed, try external application
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          // External application failed, try next mode
        }
      }

      // If external application failed, try in app web view
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (e) {
          // In app web view failed
        }
      }

      if (launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening application for ${internship['title']}...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _showApplicationLinkDialog(
          context,
          internship,
          applicationLink.toString(),
        );
      }
    } catch (e) {
      // If error, show dialog with copy option
      _showApplicationLinkDialog(
        context,
        internship,
        applicationLink.toString(),
      );
    }
  }

  void _showApplicationLinkDialog(
    BuildContext context,
    Map<String, dynamic> internship,
    String applicationLink,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Apply for ${internship['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application Link:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(
                applicationLink,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap the link above to copy it, then paste it in your browser to apply.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Copy to clipboard
                await Clipboard.setData(ClipboardData(text: applicationLink));
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application link copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
