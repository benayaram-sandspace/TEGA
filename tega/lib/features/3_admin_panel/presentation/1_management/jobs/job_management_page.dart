import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/jobs/create_job_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/jobs/edit_job_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/jobs/job_details_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/jobs/widgets/job_card.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/jobs/widgets/job_filters.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/jobs/widgets/job_stats_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobManagementPage extends StatefulWidget {
  const JobManagementPage({super.key});

  @override
  State<JobManagementPage> createState() => _JobManagementPageState();
}

class _JobManagementPageState extends State<JobManagementPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalJobs = 0;

  // Stats
  Map<String, int> _stats = {
    'total': 0,
    'active': 0,
    'expired': 0,
    'jobs': 0,
    'internships': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();
    
    // Try to load from cache first
    await _loadFromCache();
    
    // Then load fresh data
    await _loadJobs();
    await _loadStats();
    _animationController.forward();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);
      
      // Load jobs from cache
      final cachedJobsData = await _cacheService.getJobsData(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        type: _selectedType == 'all' ? null : _selectedType,
        page: _currentPage,
      );
      
      if (cachedJobsData != null) {
        setState(() {
          _jobs = List<Map<String, dynamic>>.from(cachedJobsData['data'] ?? []);
          _totalPages = cachedJobsData['pagination']?['totalPages'] ?? 1;
          _totalJobs = cachedJobsData['pagination']?['totalJobs'] ?? 0;
          _isLoadingFromCache = false;
        });
      }

      // Load stats from cache
      final cachedStats = await _cacheService.getJobsStats();
      if (cachedStats != null && cachedStats.isNotEmpty) {
        setState(() {
          _stats = cachedStats;
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs({bool refresh = false, bool forceRefresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
      });
    }

    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && !refresh && _jobs.isNotEmpty) {
      _loadJobsInBackground();
      return;
    }

    if (!refresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '10',
      };

      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_selectedStatus != 'all') {
        queryParams['status'] = _selectedStatus;
      }
      if (_selectedType != 'all') {
        queryParams['postingType'] = _selectedType;
      }

      final uri = Uri.parse(
        ApiEndpoints.adminJobsAll,
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final jobsList = List<Map<String, dynamic>>.from(data['data']);
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          setState(() {
            if (refresh || _currentPage == 1) {
              _jobs = jobsList;
            } else {
              _jobs.addAll(jobsList);
            }
            _totalPages = pagination['totalPages'] ?? 1;
            _totalJobs = pagination['totalJobs'] ?? 0;
            _isLoading = false;
          });
          
          // Cache the data
          await _cacheService.setJobsData(
            jobs: jobsList,
            pagination: pagination,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
            status: _selectedStatus == 'all' ? null : _selectedStatus,
            type: _selectedType == 'all' ? null : _selectedType,
            page: _currentPage,
          );
          
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
          
          if (refresh || _currentPage == 1) {
            _loadStats();
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load jobs';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load jobs (${response.statusCode})';
        });
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedJobsData = await _cacheService.getJobsData(
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          status: _selectedStatus == 'all' ? null : _selectedStatus,
          type: _selectedType == 'all' ? null : _selectedType,
          page: _currentPage,
        );
        if (cachedJobsData != null) {
          // Load from cache
      setState(() {
            _jobs = List<Map<String, dynamic>>.from(cachedJobsData['data'] ?? []);
            _totalPages = cachedJobsData['pagination']?['totalPages'] ?? 1;
            _totalJobs = cachedJobsData['pagination']?['totalJobs'] ?? 0;
        _isLoading = false;
            _errorMessage = null; // Clear error since we have cached data
          });
          return;
        }
        
        // No cache available, show error
        setState(() {
          _isLoading = false;
          _errorMessage = 'No internet connection';
        });
      } else {
        // Other errors
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadJobsInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '10',
      };

      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_selectedStatus != 'all') {
        queryParams['status'] = _selectedStatus;
      }
      if (_selectedType != 'all') {
        queryParams['postingType'] = _selectedType;
      }

      final uri = Uri.parse(
        ApiEndpoints.adminJobsAll,
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final jobsList = List<Map<String, dynamic>>.from(data['data']);
          final pagination = data['pagination'] as Map<String, dynamic>;
          
          setState(() {
            if (_currentPage == 1) {
              _jobs = jobsList;
            } else {
              _jobs.addAll(jobsList);
            }
            _totalPages = pagination['totalPages'] ?? 1;
            _totalJobs = pagination['totalJobs'] ?? 0;
          });
          
          // Cache the data
          await _cacheService.setJobsData(
            jobs: jobsList,
            pagination: pagination,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
            status: _selectedStatus == 'all' ? null : _selectedStatus,
            type: _selectedType == 'all' ? null : _selectedType,
            page: _currentPage,
          );
          
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  void _calculateStats() {
    // Calculate stats from all jobs, not just filtered ones
    _stats = {
      'total': _totalJobs,
      'active': _jobs
          .where((job) => job['status'] == 'open' || job['status'] == 'active')
          .length,
      'expired': _jobs
          .where(
            (job) => job['status'] == 'expired' || job['status'] == 'closed',
          )
          .length,
      'jobs': _jobs.where((job) => job['postingType'] == 'job').length,
      'internships': _jobs
          .where((job) => job['postingType'] == 'internship')
          .length,
    };
  }

  Future<void> _loadStats({bool forceRefresh = false}) async {
    // If we have cached stats and not forcing refresh, load in background
    if (!forceRefresh && _stats['total']! > 0) {
      _loadStatsInBackground();
      return;
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminJobsAll),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final allJobs = List<Map<String, dynamic>>.from(data['data']);
          final stats = {
              'total': allJobs.length,
              'active': allJobs
                  .where(
                    (job) =>
                        job['status'] == 'open' || job['status'] == 'active',
                  )
                  .length,
              'expired': allJobs
                  .where(
                    (job) =>
                        job['status'] == 'expired' || job['status'] == 'closed',
                  )
                  .length,
              'jobs': allJobs
                  .where((job) => job['postingType'] == 'job')
                  .length,
              'internships': allJobs
                  .where((job) => job['postingType'] == 'internship')
                  .length,
            };
          
          setState(() {
            _stats = stats;
          });
          
          // Cache the stats
          await _cacheService.setJobsStats(stats);
          
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedStats = await _cacheService.getJobsStats();
        if (cachedStats != null && cachedStats.isNotEmpty) {
          setState(() {
            _stats = cachedStats;
          });
          return;
        }
      }
      // If stats loading fails, fall back to calculating from current jobs
      _calculateStats();
    }
  }

  Future<void> _loadStatsInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminJobsAll),
        headers: headers,
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final allJobs = List<Map<String, dynamic>>.from(data['data']);
          final stats = {
            'total': allJobs.length,
            'active': allJobs
                .where(
                  (job) =>
                      job['status'] == 'open' || job['status'] == 'active',
                )
                .length,
            'expired': allJobs
                .where(
                  (job) =>
                      job['status'] == 'expired' || job['status'] == 'closed',
                )
                .length,
            'jobs': allJobs
                .where((job) => job['postingType'] == 'job')
                .length,
            'internships': allJobs
                .where((job) => job['postingType'] == 'internship')
                .length,
          };
          
          setState(() {
            _stats = stats;
          });
          
          // Cache the stats
          await _cacheService.setJobsStats(stats);
          
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiEndpoints.adminDeleteJob(jobId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Job deleted successfully');
          _loadJobs(refresh: true, forceRefresh: true);
          _loadStats(forceRefresh: true);
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to delete job');
        }
      } else {
        _showErrorSnackBar('Failed to delete job (${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting job: $e');
    }
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiEndpoints.adminUpdateJobStatus(jobId)),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Job status updated successfully');
          _loadJobs(refresh: true, forceRefresh: true);
          _loadStats(forceRefresh: true);
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to update job status');
        }
      } else {
        _showErrorSnackBar(
          'Failed to update job status (${response.statusCode})',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error updating job status: $e');
    }
  }

  void _showDeleteConfirmation(String jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "$jobTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(jobId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(String jobId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Job Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new status:'),
            const SizedBox(height: 16),
            ...['open', 'active', 'expired', 'paused'].map(
              (status) => ListTile(
                title: Text(status.toUpperCase()),
                leading: Radio<String>(
                  value: status,
                  groupValue: currentStatus,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _updateJobStatus(jobId, value!);
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    
    // Try to load from cache first
    try {
      final cachedJobsData = await _cacheService.getJobsData(
        searchQuery: query.isEmpty ? null : query,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        type: _selectedType == 'all' ? null : _selectedType,
        page: 1,
      );
      
      if (cachedJobsData != null) {
        setState(() {
          _jobs = List<Map<String, dynamic>>.from(cachedJobsData['data'] ?? []);
          _totalPages = cachedJobsData['pagination']?['totalPages'] ?? 1;
          _totalJobs = cachedJobsData['pagination']?['totalJobs'] ?? 0;
        });
      }
    } catch (e) {
      // Silently handle cache errors
    }
    
    // Then load fresh data
    _loadJobs(refresh: true);
    _loadStats();
  }

  void _onFilterChanged(String status, String type) async {
    setState(() {
      _selectedStatus = status;
      _selectedType = type;
      _currentPage = 1;
    });
    
    // Try to load from cache first
    try {
      final cachedJobsData = await _cacheService.getJobsData(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        status: status == 'all' ? null : status,
        type: type == 'all' ? null : type,
        page: 1,
      );
      
      if (cachedJobsData != null) {
        setState(() {
          _jobs = List<Map<String, dynamic>>.from(cachedJobsData['data'] ?? []);
          _totalPages = cachedJobsData['pagination']?['totalPages'] ?? 1;
          _totalJobs = cachedJobsData['pagination']?['totalJobs'] ?? 0;
        });
      }
    } catch (e) {
      // Silently handle cache errors
    }
    
    // Then load fresh data
    _loadJobs(refresh: true);
    _loadStats();
  }

  void _loadMoreJobs() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminDashboardStyles.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Stats with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: JobStatsWidget(stats: _stats, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
              ),
              // Filters with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: JobFilters(
                  onSearchChanged: _onSearchChanged,
                  onFilterChanged: _onFilterChanged,
                  selectedStatus: _selectedStatus,
                  selectedType: _selectedType,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
              // Content with staggered animations
              _isLoading && !_isLoadingFromCache
                  ? _buildLoadingState(isMobile, isTablet, isDesktop)
                  : _errorMessage != null && !_isLoadingFromCache
                  ? _buildErrorState(isMobile, isTablet, isDesktop)
                  : _jobs.isEmpty
                  ? _buildEmptyState(isMobile, isTablet, isDesktop)
                  : _buildJobsList(isMobile, isTablet, isDesktop),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAnimatedFAB(isMobile, isTablet, isDesktop),
    );
  }

  Widget _buildLoadingState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Container(
                    width: isMobile ? 40 : isTablet ? 45 : 50,
                    height: isMobile ? 40 : isTablet ? 45 : 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AdminDashboardStyles.primary.withValues(alpha: 0.3),
                          AdminDashboardStyles.primary,
                          AdminDashboardStyles.primary.withValues(alpha: 0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Loading jobs',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, dotValue, child) {
                        return Text(
                          '.' * (3 * dotValue).round(),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        color: AdminDashboardStyles.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
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
              'Failed to load jobs',
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
                _loadJobs(refresh: true, forceRefresh: true);
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, scaleValue, child) {
                        return Transform.scale(
                          scale: scaleValue,
                          child: Icon(
                            Icons.work_outline,
                            size: isMobile ? 60 : isTablet ? 70 : 80,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                    Text(
                      'No jobs found',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'Create your first job posting to get started',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobsList(bool isMobile, bool isTablet, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
      child: Column(
        children: [
          ..._jobs.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> job = entry.value;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(
                milliseconds: (300 + (index * 100)).clamp(100, 2000),
              ),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: JobCard(
                        job: job,
                        onEdit: () async {
                          HapticFeedback.lightImpact();
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditJobPage(job: job),
                            ),
                          );
                          if (result == true) {
                            _loadJobs(refresh: true, forceRefresh: true);
                            _loadStats(forceRefresh: true);
                          }
                        },
                        onView: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailsPage(job: job),
                            ),
                          );
                        },
                        onDelete: () {
                          HapticFeedback.mediumImpact();
                          _showDeleteConfirmation(job['_id'], job['title']);
                        },
                        onStatusUpdate: () {
                          HapticFeedback.lightImpact();
                          _showStatusUpdateDialog(job['_id'], job['status']);
                        },
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          if (_currentPage < _totalPages)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildLoadMoreButton(isMobile, isTablet, isDesktop),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB(bool isMobile, bool isTablet, bool isDesktop) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: FloatingActionButton.extended(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateJobPage()),
              );
              if (result == true) {
                _loadJobs(refresh: true, forceRefresh: true);
                _loadStats(forceRefresh: true);
              }
            },
            icon: Icon(Icons.add, size: isMobile ? 20 : isTablet ? 22 : 24),
            label: Text(
              'Add Job',
              style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
            ),
            backgroundColor: AdminDashboardStyles.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            hoverElevation: 12,
            focusElevation: 12,
            highlightElevation: 12,
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 12 : isTablet ? 14 : 16),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreJobs,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminDashboardStyles.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : isTablet ? 22 : 24,
              vertical: isMobile ? 10 : isTablet ? 11 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
            ),
          ),
          child: Text(
            'Load More Jobs',
            style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
          ),
        ),
      ),
    );
  }
}

