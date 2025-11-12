import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
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
    _loadJobs();
    _loadStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final headers = _authService.getAuthHeaders();
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
          setState(() {
            if (refresh || _currentPage == 1) {
              _jobs = List<Map<String, dynamic>>.from(data['data']);
            } else {
              _jobs.addAll(List<Map<String, dynamic>>.from(data['data']));
            }
            _totalPages = data['pagination']['totalPages'];
            _totalJobs = data['pagination']['totalJobs'];
            _loadStats();
          });
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to load jobs');
        }
      } else {
        _showErrorSnackBar('Failed to load jobs (${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading jobs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _loadStats() async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminJobsAll),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final allJobs = List<Map<String, dynamic>>.from(data['data']);
          setState(() {
            _stats = {
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
          });
        }
      }
    } catch (e) {
      // If stats loading fails, fall back to calculating from current jobs
      _calculateStats();
    }
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiEndpoints.adminDeleteJob(jobId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Job deleted successfully');
          _loadJobs(refresh: true);
          _loadStats();
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
      final headers = _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiEndpoints.adminUpdateJobStatus(jobId)),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Job status updated successfully');
          _loadJobs(refresh: true);
          _loadStats();
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadJobs(refresh: true);
    _loadStats();
  }

  void _onFilterChanged(String status, String type) {
    setState(() {
      _selectedStatus = status;
      _selectedType = type;
    });
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
                child: JobStatsWidget(stats: _stats),
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
                ),
              ),
              // Content with staggered animations
              _isLoading
                  ? _buildLoadingState()
                  : _jobs.isEmpty
                  ? _buildEmptyState()
                  : _buildJobsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAnimatedFAB(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6B5FFF).withValues(alpha: 0.3),
                          const Color(0xFF6B5FFF),
                          const Color(0xFF6B5FFF).withValues(alpha: 0.3),
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
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Loading jobs',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, dotValue, child) {
                        return Text(
                          '.' * (3 * dotValue).round(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B5FFF),
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

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first job posting to get started',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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

  Widget _buildJobsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                            _loadJobs(refresh: true);
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
                    child: _buildLoadMoreButton(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB() {
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
                _loadJobs(refresh: true);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Job'),
            backgroundColor: const Color(0xFF6B5FFF),
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

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreJobs,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B5FFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Load More Jobs'),
        ),
      ),
    );
  }
}
