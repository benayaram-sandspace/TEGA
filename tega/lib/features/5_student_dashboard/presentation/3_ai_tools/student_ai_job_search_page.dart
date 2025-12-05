import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/core/services/jobs_cache_service.dart';

class JobRecommendationScreen extends StatefulWidget {
  const JobRecommendationScreen({super.key});

  @override
  State<JobRecommendationScreen> createState() =>
      _JobRecommendationScreenState();
}

class _JobRecommendationScreenState extends State<JobRecommendationScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final JobsCacheService _cacheService = JobsCacheService();

  bool _isLoading = true;
  String? _errorMessage;

  // Filter states
  String _selectedWorkType = 'All Types';
  String _selectedLocation = 'All Locations';

  // Filter options
  final List<String> _workTypes = [
    'All Types',
    'Internship',
    'Full Time',
    'Part Time',
    'Contract',
    'Hybrid',
    'Remote',
  ];

  final List<String> _locations = [
    'All Locations',
    'Hyderabad',
    'Delhi',
    'Mumbai',
    'Pune',
    'Bangalore',
  ];

  // Stats
  int _activeJobs = 0;
  int _companies = 0;

  // Jobs list
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadJobData();
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadJobData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedJobs = await _cacheService.getJobsData();
      if (cachedJobs != null && cachedJobs.isNotEmpty && mounted) {
        setState(() {
          _allJobs = cachedJobs;
          _calculateStats();
          _filteredJobs = List.from(_allJobs);
          _applyFilters();
          _isLoading = false;
          _errorMessage = null;
        });
        // Still fetch in background to update cache
        _fetchJobsInBackground();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch from API
    await _fetchJobsInBackground();
  }

  Future<void> _fetchJobsInBackground() async {
    try {
      final dashboardService = StudentDashboardService();

      // Fetch jobs from backend (public endpoint, no auth needed)
      final jobs = await dashboardService.getJobs({});

      // Transform backend data to match UI needs
      final transformedJobs = jobs.map<Map<String, dynamic>>((job) {
        // Extract work type from jobType field (backend uses: full-time, part-time, contract, internship)
        String workType = 'Full Time';
        final jobTypeRaw = job['jobType'] ?? '';
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
            workType = 'Full Time';
        }

        // Format salary
        String salary = 'Not specified';
        if (job['salary'] != null) {
          final salaryNum = job['salary'] as num?;
          if (salaryNum != null && salaryNum > 0) {
            salary = '₹${salaryNum.toStringAsFixed(0)}';
          }
        }

        // Format posted date
        String postedDate = 'Recently';
        if (job['createdAt'] != null) {
          try {
            final date = DateTime.parse(job['createdAt']);
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
          'id': job['_id'] ?? job['id'] ?? '',
          'title': job['title'] ?? 'Untitled Job',
          'company': job['company'] ?? 'Company',
          'location': job['location'] ?? 'Location',
          'workType': workType,
          'salary': salary,
          'description': job['description'] ?? 'No description available',
          'postedDate': postedDate,
          'applicants': 0, // Backend doesn't track applicants count yet
          'applicationLink': job['applicationLink'], // Include application link
        };
      }).toList();

      // Cache jobs data
      await _cacheService.setJobsData(transformedJobs);

      if (mounted) {
        setState(() {
          _allJobs = transformedJobs;
          _calculateStats();
          _filteredJobs = List.from(_allJobs);
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
          final cachedJobs = await _cacheService.getJobsData();
          if (cachedJobs != null && cachedJobs.isNotEmpty) {
            setState(() {
              _allJobs = cachedJobs;
              _calculateStats();
              _filteredJobs = List.from(_allJobs);
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
            _errorMessage = 'Unable to load jobs. Please try again.';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _calculateStats() {
    if (_allJobs.isNotEmpty) {
      _activeJobs = _allJobs.length;
      _companies = _allJobs.map((job) => job['company']).toSet().length;
    } else {
      _activeJobs = 0;
      _companies = 0;
    }
  }

  void _applyFilters() {
    setState(() {
      String searchQuery = _searchController.text.toLowerCase();
      _filteredJobs = _allJobs.where((job) {
        bool matchesSearch =
            searchQuery.isEmpty ||
            job['title'].toString().toLowerCase().contains(searchQuery) ||
            job['company'].toString().toLowerCase().contains(searchQuery);

        bool matchesWorkType =
            _selectedWorkType == 'All Types' ||
            job['workType'] == _selectedWorkType;

        bool matchesLocation =
            _selectedLocation == 'All Locations' ||
            job['location'] == _selectedLocation;

        return matchesSearch && matchesWorkType && matchesLocation;
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
          // Header Card
          _buildHeaderCard(),
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

          // Stats Cards
          _buildStatsCards(),
          SizedBox(
            height: isLargeDesktop
                ? 36
                : isDesktop
                ? 32
                : isTablet
                ? 28
                : isSmallScreen
                ? 20
                : 24,
          ),

          // Search and Filters Section
          _buildSearchAndFilters(),
          SizedBox(
            height: isLargeDesktop
                ? 36
                : isDesktop
                ? 32
                : isTablet
                ? 28
                : isSmallScreen
                ? 20
                : 24,
          ),

          // Jobs Section
          _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : _filteredJobs.isEmpty
              ? _buildEmptyState()
              : _buildJobsList(),

          SizedBox(
            height: isLargeDesktop
                ? 48
                : isDesktop
                ? 40
                : isTablet
                ? 32
                : isSmallScreen
                ? 24
                : 32,
          ),

          // Newsletter Section
          _buildNewsletterSection(),
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
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Theme.of(context).primaryColor, Color(0xFF6B5FFF)],
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
            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your Dream Job',
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
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop || isDesktop
                      ? 10
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 4
                      : 6,
                ),
                Text(
                  'Discover opportunities that match your skills',
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
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (isLargeDesktop || isDesktop || isTablet)
            Icon(
              Icons.work_outline_rounded,
              size: isLargeDesktop
                  ? 72
                  : isDesktop
                  ? 60
                  : isTablet
                  ? 54
                  : 50,
              color: Colors.white.withOpacity(0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isLargeDesktop || isDesktop
          ? 2
          : isTablet
          ? 2
          : 2,
      crossAxisSpacing: isLargeDesktop
          ? 20
          : isDesktop
          ? 16
          : isTablet
          ? 14
          : isSmallScreen
          ? 8
          : 12,
      mainAxisSpacing: isLargeDesktop
          ? 20
          : isDesktop
          ? 16
          : isTablet
          ? 14
          : isSmallScreen
          ? 8
          : 12,
      childAspectRatio: isLargeDesktop
          ? 2.8
          : isDesktop
          ? 2.5
          : isTablet
          ? 2.2
          : isSmallScreen
          ? 1.6
          : 1.8,
      children: [
        _buildStatCard(
          title: 'Active Jobs',
          value: _activeJobs.toString(),
          icon: Icons.work_rounded,
          color: Colors.green,
          gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent]),
        ),
        _buildStatCard(
          title: 'Companies',
          value: _companies.toString(),
          icon: Icons.business_rounded,
          color: Colors.blue,
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
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
  }) {
    return Container(
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
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
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
              color: Colors.white,
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
                Text(
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
                  title,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 9
                        : 11,
                    color: Colors.grey[600],
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

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
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
            hintText: 'Search jobs by title or company...',
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
              color: Theme.of(context).primaryColor,
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
            filled: true,
            fillColor: Colors.white,
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
              borderSide: BorderSide.none,
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
              borderSide: BorderSide(color: Colors.grey[200]!),
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
              borderSide: const BorderSide(color: Color(0xFF6B5FFF), width: 2),
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
        SizedBox(
          height: isLargeDesktop
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 14
              : isSmallScreen
              ? 10
              : 14,
        ),

        // Filter Dropdowns
        Row(
          children: [
            // Work Type Filter
            Expanded(
              child: _buildDropdownFilter(
                label: 'Work Type',
                value: _selectedWorkType,
                items: _workTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedWorkType = value!;
                    _applyFilters();
                  });
                },
                icon: Icons.work_outline_rounded,
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
            // Location Filter
            Expanded(
              child: _buildDropdownFilter(
                label: 'Location',
                value: _selectedLocation,
                items: _locations,
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value!;
                    _applyFilters();
                  });
                },
                icon: Icons.location_on_outlined,
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
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 20
            : isDesktop
            ? 16
            : isTablet
            ? 14
            : isSmallScreen
            ? 10
            : 12,
        vertical: isLargeDesktop || isDesktop
            ? 6
            : isTablet
            ? 5
            : isSmallScreen
            ? 2
            : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
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
                    size: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 18
                        : isTablet
                        ? 17
                        : isSmallScreen
                        ? 14
                        : 16,
                    color: value == item
                        ? const Color(0xFF6B5FFF)
                        : Colors.grey[600],
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
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
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
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Jobs',
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
                    ? 6
                    : isDesktop
                    ? 4
                    : isTablet
                    ? 3.5
                    : isSmallScreen
                    ? 2
                    : 3,
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
                '${_filteredJobs.length} Jobs',
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
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B5FFF),
                ),
              ),
            ),
          ],
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredJobs.length,
          itemBuilder: (context, index) {
            final job = _filteredJobs[index];
            return _buildJobCard(job, index);
          },
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, int index) {
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening ${job['title']}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
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
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6B5FFF),
                                    Color(0xFF8F7FFF),
                                  ],
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
                                Icons.work_rounded,
                                color: Colors.white,
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
                                children: [
                                  Text(
                                    job['title'],
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
                                    job['company'],
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
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  isLargeDesktop
                                      ? 10
                                      : isDesktop
                                      ? 8
                                      : isTablet
                                      ? 7.5
                                      : isSmallScreen
                                      ? 6
                                      : 7,
                                ),
                              ),
                              child: Text(
                                job['workType'],
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
                                  color: const Color(0xFF4CAF50),
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

                        // Job Details
                        Wrap(
                          spacing: isLargeDesktop
                              ? 20
                              : isDesktop
                              ? 16
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 8
                              : 12,
                          runSpacing: isLargeDesktop || isDesktop
                              ? 10
                              : isTablet
                              ? 9
                              : isSmallScreen
                              ? 6
                              : 8,
                          children: [
                            _buildJobDetail(
                              Icons.location_on_outlined,
                              job['location'],
                            ),
                            _buildJobDetail(
                              Icons.attach_money_rounded,
                              job['salary'],
                            ),
                            _buildJobDetail(
                              Icons.access_time_rounded,
                              job['postedDate'],
                            ),
                            _buildJobDetail(
                              Icons.people_outline_rounded,
                              '${job['applicants']} applicants',
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

                        // Apply Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final applicationLink = job['applicationLink'];
                              if (applicationLink == null ||
                                  applicationLink.toString().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No application link available for this job',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                // Try to open the URL directly in browser
                                final Uri url = Uri.parse(
                                  applicationLink.toString(),
                                );

                                // Skip canLaunchUrl check and try to launch directly
                                bool launched = false;

                                // Try platform default first
                                try {
                                  launched = await launchUrl(
                                    url,
                                    mode: LaunchMode.platformDefault,
                                  );
                                } catch (e) {
                                  // Platform default failed, try next mode
                                }

                                // If platform default failed, try external application
                                if (!launched) {
                                  try {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (e) {
                                    // External application failed, try next mode
                                  }
                                }

                                // If external application failed, try in app web view
                                if (!launched) {
                                  try {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.inAppWebView,
                                    );
                                  } catch (e) {
                                    // In app web view failed
                                  }
                                }

                                if (launched && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Opening application for ${job['title']}...',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  _showApplicationLinkDialog(
                                    context,
                                    job,
                                    applicationLink.toString(),
                                  );
                                }
                              } catch (e) {
                                // If error, show dialog with copy option
                                _showApplicationLinkDialog(
                                  context,
                                  job,
                                  applicationLink.toString(),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5FFF),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isLargeDesktop
                                    ? 18
                                    : isDesktop
                                    ? 14
                                    : isTablet
                                    ? 13
                                    : isSmallScreen
                                    ? 10
                                    : 12,
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
                            child: Text(
                              'Apply Now',
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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

  Widget _buildJobDetail(IconData icon, String text) {
    return Row(
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
          color: const Color(0xFF6B5FFF),
        ),
        SizedBox(
          width: isLargeDesktop || isDesktop
              ? 6
              : isTablet
              ? 5
              : isSmallScreen
              ? 3
              : 4,
        ),
        Text(
          text,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsletterSection() {
    return Container(
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B5FFF).withOpacity(0.1),
            const Color(0xFF8F7FFF).withOpacity(0.05),
          ],
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
        border: Border.all(
          color: const Color(0xFF6B5FFF).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.email_outlined,
            size: isLargeDesktop
                ? 56
                : isDesktop
                ? 48
                : isTablet
                ? 44
                : isSmallScreen
                ? 32
                : 40,
            color: const Color(0xFF6B5FFF),
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
          Text(
            'Subscribe to Job Updates',
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
            height: isLargeDesktop || isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 4
                : 6,
          ),
          Text(
            'Get the latest job opportunities delivered to your inbox',
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
            textAlign: TextAlign.center,
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 2,
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
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
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: isLargeDesktop
                          ? 17
                          : isDesktop
                          ? 15
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 12
                          : 13,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: const Color(0xFF6B5FFF),
                      size: isLargeDesktop
                          ? 26
                          : isDesktop
                          ? 22
                          : isTablet
                          ? 21
                          : isSmallScreen
                          ? 18
                          : 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                    enabledBorder: OutlineInputBorder(
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
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
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
                    ? 20
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 8
                    : 12,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_emailController.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Subscribed with ${_emailController.text}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _emailController.clear();
                  }
                },
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
                child: Text(
                  'Subscribe',
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              'Loading jobs...',
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
              isNoInternet
                  ? 'No internet connection'
                  : 'Oops! Something went wrong',
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
                _errorMessage ?? 'Unable to load jobs',
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
              onPressed: () => _loadJobData(forceRefresh: true),
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
    // Check if filters are active
    final hasActiveSearch = _searchController.text.isNotEmpty;
    final hasActiveFilters =
        _selectedWorkType != 'All Types' ||
        _selectedLocation != 'All Locations';
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
              isFilteredEmpty ? 'No Jobs Found' : 'No Jobs Available',
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
                  : 'There are currently no job postings available. Check back soon for new opportunities!',
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
                    _selectedWorkType = 'All Types';
                    _selectedLocation = 'All Locations';
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
                onPressed: () => _loadJobData(forceRefresh: true),
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

  void _showApplicationLinkDialog(
    BuildContext context,
    Map<String, dynamic> job,
    String applicationLink,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Apply for ${job['title']}'),
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
