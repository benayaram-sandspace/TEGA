import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

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
  int _happyCandidates = 0;

  // Jobs list
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadJobData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final dashboardService = StudentDashboardService();

      // Fetch jobs from backend
      final jobs = await dashboardService.getJobs(headers);

      // Debug: Print what we got from backend
      print('Jobs received from backend: ${jobs.length}');
      if (jobs.isNotEmpty) {
        print('First job data: ${jobs.first}');
      }

      // Transform backend data to match UI needs
      _allJobs = jobs.map<Map<String, dynamic>>((job) {
        // Extract work type from jobType or type field
        String workType = 'Full Time';
        final jobTypeRaw = job['jobType'] ?? job['type'] ?? '';
        if (jobTypeRaw.toString().toLowerCase().contains('intern')) {
          workType = 'Internship';
        } else if (jobTypeRaw.toString().toLowerCase().contains('part')) {
          workType = 'Part Time';
        } else if (jobTypeRaw.toString().toLowerCase().contains('contract')) {
          workType = 'Contract';
        } else if (jobTypeRaw.toString().toLowerCase().contains('hybrid')) {
          workType = 'Hybrid';
        } else if (jobTypeRaw.toString().toLowerCase().contains('remote')) {
          workType = 'Remote';
        } else if (jobTypeRaw.toString().toLowerCase().contains('full')) {
          workType = 'Full Time';
        }

        // Format salary
        String salary = job['salary']?.toString() ?? 'Not specified';
        if (!salary.contains('₹') && salary != 'Not specified') {
          salary = '₹$salary';
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
          'title': job['title'] ?? job['jobTitle'] ?? 'Untitled Job',
          'company': job['company'] ?? job['companyName'] ?? 'Company',
          'location':
              job['location'] ?? job['city'] ?? job['state'] ?? 'Location',
          'workType': workType,
          'salary': salary,
          'description':
              job['description'] ??
              job['details'] ??
              'No description available',
          'postedDate': postedDate,
          'applicants': job['applicants'] ?? job['applicantCount'] ?? 0,
        };
      }).toList();

      // Calculate stats from actual data
      if (_allJobs.isNotEmpty) {
        _activeJobs = _allJobs.where((job) => job['id'] != '').length;
        _companies = _allJobs.map((job) => job['company']).toSet().length;
        _happyCandidates = _allJobs.fold(
          0,
          (sum, job) => sum + (job['applicants'] as int),
        );
        print('SUCCESS: Loaded ${_allJobs.length} jobs from backend');
      } else {
        print('INFO: No jobs found in database - showing empty state');
        _activeJobs = 0;
        _companies = 0;
        _happyCandidates = 0;
      }

      if (mounted) {
        setState(() {
          _filteredJobs = List.from(_allJobs);
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading jobs: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load jobs. Please try again. Error: $e';
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isDesktop
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0,
      ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Card
          _buildHeaderCard(isDesktop, isTablet),
          SizedBox(height: isDesktop ? 24 : 20),

          // Stats Cards
          _buildStatsCards(isDesktop, isTablet),
          SizedBox(height: isDesktop ? 32 : 24),

          // Search and Filters Section
          _buildSearchAndFilters(isDesktop, isTablet),
          SizedBox(height: isDesktop ? 32 : 24),

          // Jobs Section
          _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState(isDesktop, isTablet)
              : _filteredJobs.isEmpty
              ? _buildEmptyState(isDesktop, isTablet)
              : _buildJobsList(isDesktop, isTablet),

          SizedBox(height: isDesktop ? 40 : 32),

          // Newsletter Section
          _buildNewsletterSection(isDesktop, isTablet),
          SizedBox(height: isDesktop ? 24 : 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 24
            : isTablet
            ? 20
            : 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5FFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    fontSize: isDesktop
                        ? 28
                        : isTablet
                        ? 24
                        : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isDesktop ? 8 : 6),
                Text(
                  'Discover opportunities that match your skills',
                  style: TextStyle(
                    fontSize: isDesktop ? 15 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop || isTablet)
            Icon(
              Icons.work_outline_rounded,
              size: isDesktop ? 60 : 50,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
    );
  }

  Widget _buildStatsCards(bool isDesktop, bool isTablet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop
          ? 3
          : isTablet
          ? 3
          : 1,
      crossAxisSpacing: isDesktop ? 16 : 12,
      mainAxisSpacing: isDesktop ? 16 : 12,
      childAspectRatio: isDesktop
          ? 2.5
          : isTablet
          ? 2.0
          : 4.0,
      children: [
        _buildStatCard(
          title: 'Active Jobs',
          value: _activeJobs.toString(),
          icon: Icons.work_rounded,
          color: const Color(0xFF4CAF50),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        _buildStatCard(
          title: 'Companies',
          value: _companies.toString(),
          icon: Icons.business_rounded,
          color: const Color(0xFF2196F3),
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          ),
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
        _buildStatCard(
          title: 'Happy Candidates',
          value: _happyCandidates.toString(),
          icon: Icons.emoji_emotions_rounded,
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
            ? 20
            : isTablet
            ? 18
            : 16,
      ),
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : 22,
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 28
                        : isTablet
                        ? 24
                        : 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 13
                        : isTablet
                        ? 12
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

  Widget _buildSearchAndFilters(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (_) => _applyFilters(),
          style: TextStyle(fontSize: isDesktop ? 16 : 14),
          decoration: InputDecoration(
            hintText: 'Search jobs by title or company...',
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
                isDesktop: isDesktop,
                isTablet: isTablet,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
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
          dropdownColor: Colors.white,
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

  Widget _buildJobsList(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Jobs',
              style: TextStyle(
                fontSize: isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              child: Text(
                '${_filteredJobs.length} Jobs',
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B5FFF),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 20 : 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredJobs.length,
          itemBuilder: (context, index) {
            final job = _filteredJobs[index];
            return _buildJobCard(job, index, isDesktop, isTablet);
          },
        ),
      ],
    );
  }

  Widget _buildJobCard(
    Map<String, dynamic> job,
    int index,
    bool isDesktop,
    bool isTablet,
  ) {
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening ${job['title']}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
                  child: Padding(
                    padding: EdgeInsets.all(
                      isDesktop
                          ? 20
                          : isTablet
                          ? 18
                          : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        // Header Row
          Row(
            children: [
              Container(
                              padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6B5FFF),
                                    Color(0xFF8F7FFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.work_rounded,
                                color: Colors.white,
                                size: isDesktop ? 28 : 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
          Text(
                                    job['title'],
                                    style: TextStyle(
                                      fontSize: isDesktop
                                          ? 20
                                          : isTablet
                                          ? 18
                                          : 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
          Text(
                                    job['company'],
            style: TextStyle(
                                      fontSize: isDesktop ? 14 : 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                job['workType'],
            style: TextStyle(
                                  fontSize: isDesktop ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4CAF50),
                                ),
            ),
          ),
        ],
                        ),
                        SizedBox(height: isDesktop ? 16 : 14),

                        // Job Details
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildJobDetail(
                              Icons.location_on_outlined,
                              job['location'],
                              isDesktop,
                            ),
                            _buildJobDetail(
                              Icons.attach_money_rounded,
                              job['salary'],
                              isDesktop,
                            ),
                            _buildJobDetail(
                              Icons.access_time_rounded,
                              job['postedDate'],
                              isDesktop,
                            ),
                            _buildJobDetail(
                              Icons.people_outline_rounded,
                              '${job['applicants']} applicants',
                              isDesktop,
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 16 : 14),

                        // Apply Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final jobId = job['id'];
                              if (jobId == null || jobId.toString().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid job ID'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                final authService = AuthService();
                                final headers = authService.getAuthHeaders();
                                final dashboardService =
                                    StudentDashboardService();

                                final result = await dashboardService
                                    .applyForJob(jobId.toString(), headers);

                                if (mounted) {
                                  if (result['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ??
                                              'Successfully applied to ${job['title']}',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ??
                                              'Failed to apply. Please try again.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error applying for job. Please try again.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5FFF),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 14 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply Now',
                              style: TextStyle(
                                fontSize: isDesktop ? 16 : 15,
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

  Widget _buildJobDetail(IconData icon, String text, bool isDesktop) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isDesktop ? 16 : 14, color: const Color(0xFF6B5FFF)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: isDesktop ? 13 : 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsletterSection(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 32
            : isTablet
            ? 28
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
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        border: Border.all(
          color: const Color(0xFF6B5FFF).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.email_outlined,
            size: isDesktop ? 48 : 40,
            color: const Color(0xFF6B5FFF),
          ),
          SizedBox(height: isDesktop ? 16 : 14),
          Text(
            'Subscribe to Job Updates',
            style: TextStyle(
              fontSize: isDesktop
                  ? 24
                  : isTablet
                  ? 20
                  : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 8 : 6),
          Text(
            'Get the latest job opportunities delivered to your inbox',
            style: TextStyle(
              fontSize: isDesktop ? 15 : 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 24 : 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: isDesktop ? 15 : 14,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: const Color(0xFF6B5FFF),
                      size: isDesktop ? 22 : 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6B5FFF),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 20 : 16,
                      vertical: isDesktop ? 16 : 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
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
                    horizontal: isDesktop ? 32 : 24,
                    vertical: isDesktop ? 16 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Subscribe',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 15,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDesktop, bool isTablet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: isDesktop ? 64 : 56,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load jobs',
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadJobData,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
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
    // Check if filters are active
    final hasActiveSearch = _searchController.text.isNotEmpty;
    final hasActiveFilters =
        _selectedWorkType != 'All Types' ||
        _selectedLocation != 'All Locations';
    final isFilteredEmpty = hasActiveSearch || hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
            shape: BoxShape.circle,
              ),
              child: Icon(
                isFilteredEmpty
                    ? Icons.search_off_rounded
                    : Icons.work_outline_rounded,
                size: isDesktop ? 64 : 56,
                color: const Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFilteredEmpty ? 'No Jobs Found' : 'No Jobs Available',
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isFilteredEmpty
                  ? 'Try adjusting your search or filter criteria to find more opportunities'
                  : 'There are currently no job postings available. Check back soon for new opportunities!',
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
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
                icon: const Icon(Icons.clear_all_rounded, size: 20),
                label: const Text('Clear All Filters'),
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
                  elevation: 0,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _loadJobData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5FFF),
                  side: const BorderSide(color: Color(0xFF6B5FFF), width: 1.5),
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
}
