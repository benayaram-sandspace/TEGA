import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Courses';
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasEnrolledCourses = false;

  final List<String> _filterOptions = [
    'All Courses',
    'Ongoing Courses',
    'Programming Language',
    'Web Technologies',
    'Microsoft Office',
    'Full Stack Development',
    'Artificial Intelligence',
    'Cloud Computing',
    'Cyber Security',
    'Personality Development',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final dashboardService = StudentDashboardService();

      // Fetch enrolled courses from backend
      final enrolledCourses = await dashboardService.getEnrolledCourses(
        headers,
      );

      // Transform backend data to match UI needs
      _courses = enrolledCourses.map<Map<String, dynamic>>((course) {
        return {
          'id': course['id'] ?? '',
          'title': course['title'] ?? 'Untitled Course',
          'thumbnail': course['thumbnail'] ?? '',
          'createdBy': course['instructor'] ?? 'TEGA Instructor',
          'students': course['enrolledCount'] ?? 0,
          'difficulty': course['level'] ?? 'Beginner',
          'duration': course['duration'] ?? '0 hours',
          'progress': course['progress'] ?? 0,
          'category': course['category'] ?? 'General',
          'isStarted': (course['progress'] ?? 0) > 0,
        };
      }).toList();

      _hasEnrolledCourses = _courses.isNotEmpty;

      // If no enrolled courses, fetch available courses
      if (_courses.isEmpty) {
        final allCourses = await dashboardService.getAllCourses(headers);
        _courses = allCourses.map<Map<String, dynamic>>((course) {
          return {
            'id': course['_id'] ?? course['id'] ?? '',
            'title': course['title'] ?? 'Untitled Course',
            'thumbnail': course['thumbnail'] ?? '',
            'createdBy': course['instructor'] ?? 'TEGA Instructor',
            'students': course['enrollmentCount'] ?? 0,
            'difficulty': course['level'] ?? 'Beginner',
            'duration': course['duration'] ?? '0 hours',
            'progress': 0,
            'category': course['category'] ?? 'General',
            'isStarted': false,
          };
        }).toList();
      }

      if (mounted) {
        setState(() {
          _filteredCourses = List.from(_courses);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load courses. Please try again.';
          _courses = [];
          _filteredCourses = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterCourses() {
    setState(() {
      String searchQuery = _searchController.text.toLowerCase();
      _filteredCourses = _courses.where((course) {
        bool matchesSearch =
            course['title'].toString().toLowerCase().contains(searchQuery) ||
            course['createdBy'].toString().toLowerCase().contains(searchQuery);

        bool matchesFilter =
            _selectedFilter == 'All Courses' ||
            (_selectedFilter == 'Ongoing Courses' && course['progress'] > 0) ||
            course['category'] == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
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
              _buildTopSection(screenWidth),
              SizedBox(height: isDesktop ? 20 : 16),
              _buildSearchAndFilters(screenWidth),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : _filteredCourses.isEmpty
              ? _buildEmptyState()
              : _buildCoursesList(screenWidth),
        ),
      ],
    );
  }

  Widget _buildTopSection(double screenWidth) {
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 24
            : isTablet
            ? 20
            : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color.lerp(Colors.white, Colors.black, 0.02)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                color: const Color(0xFF6B5FFF),
                size: isDesktop
                    ? 32
                    : isTablet
                    ? 28
                    : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'My Courses',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 28
                      : isTablet
                      ? 24
                      : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Continue Learning and Browse All - Side by side
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Continue Learning',
                  Icons.play_circle_outline_rounded,
                  const Color(0xFF6B5FFF),
                  () {
                    final ongoingCourse = _courses.firstWhere(
                      (c) => c['progress'] > 0,
                      orElse: () => {},
                    );
                    if (ongoingCourse.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Resuming ${ongoingCourse['title']}...',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No ongoing courses found'),
                        ),
                      );
                    }
                  },
                  isLarge: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Browse All',
                  Icons.explore_outlined,
                  const Color(0xFF2196F3),
                  () {
                    setState(() {
                      _selectedFilter = 'All Courses';
                      _filterCourses();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isLarge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isLarge
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isLarge ? null : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLarge ? color : color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: isLarge
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isLarge ? Colors.white : color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLarge ? Colors.white : color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(double screenWidth) {
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return Column(
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (_) => _filterCourses(),
          style: TextStyle(fontSize: isDesktop ? 16 : 14),
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isDesktop ? 16 : 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF6B5FFF),
              size: isDesktop ? 24 : 20,
            ),
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
        // Filter Chips
        SizedBox(
          height: isDesktop
              ? 44
              : isTablet
              ? 42
              : 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final filter = _filterOptions[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: EdgeInsets.only(right: isDesktop ? 10 : 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _filterCourses();
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF6B5FFF).withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: isSelected
                        ? const Color(0xFF6B5FFF)
                        : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6B5FFF)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                    vertical: isDesktop ? 10 : 8,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesList(double screenWidth) {
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop
            ? 24
            : isTablet
            ? 20
            : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return _buildCourseCard(course, index, screenWidth);
      },
    );
  }

  Widget _buildCourseCard(
    Map<String, dynamic> course,
    int index,
    double screenWidth,
  ) {
    final isStarted = course['progress'] > 0;
    final progress = (course['progress'] as num).toDouble() / 100.0;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      SnackBar(content: Text('Opening ${course['title']}...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
                  child: Padding(
                    padding: EdgeInsets.all(
                      isDesktop
                          ? 16
                          : isTablet
                          ? 14
                          : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 14 : 12,
                          ),
                          child: Container(
                            width: isDesktop
                                ? 140
                                : isTablet
                                ? 130
                                : 110,
                            height: isDesktop
                                ? 140
                                : isTablet
                                ? 130
                                : 110,
                            color: const Color(0xFF6B5FFF).withOpacity(0.1),
                            child:
                                course['thumbnail'] != null &&
                                    course['thumbnail'].toString().isNotEmpty
                                ? Image.network(
                                    course['thumbnail'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.image_outlined,
                                              size: 40,
                                              color: Color(0xFF6B5FFF),
                                            ),
                                  )
                                : const Icon(
                                    Icons.play_circle_outline_rounded,
                                    size: 40,
                                    color: Color(0xFF6B5FFF),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Course Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['title'],
                                style: TextStyle(
                                  fontSize: isDesktop
                                      ? 18
                                      : isTablet
                                      ? 17
                                      : 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF333333),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Color(0xFF6B5FFF),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      course['createdBy'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildInfoChip(
                                    Icons.people_outline,
                                    _formatStudentCount(course['students']),
                                  ),
                                  _buildInfoChip(
                                    Icons.signal_cellular_alt,
                                    course['difficulty'],
                                  ),
                                  _buildInfoChip(
                                    Icons.access_time,
                                    course['duration'],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress or Action Button
                              if (isStarted)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 6,
                                              backgroundColor: Colors.grey[200],
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFF6B5FFF)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${course['progress']}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B5FFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6B5FFF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            size: 16,
                                            color: Color(0xFF6B5FFF),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Continue Course',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6B5FFF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline_rounded,
                                        size: 16,
                                        color: Color(0xFF4CAF50),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Start Course',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStudentCount(dynamic count) {
    final num students = (count is int)
        ? count
        : int.tryParse(count.toString()) ?? 0;
    if (students >= 1000) {
      return '${(students / 1000).toStringAsFixed(0)}K';
    }
    return students.toString();
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
            'Loading courses...',
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

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unable to load courses',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourses,
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

  Widget _buildEmptyState() {
    // Different empty states based on filters and search
    final hasActiveSearch = _searchController.text.isNotEmpty;
    final hasActiveFilter = _selectedFilter != 'All Courses';

    if (hasActiveSearch || hasActiveFilter) {
      // No results for current search/filter
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: Color(0xFF6B5FFF),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No courses found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Try adjusting your search or filter criteria',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedFilter = 'All Courses';
                    _filterCourses();
                  });
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5FFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No courses in database
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B5FFF).withOpacity(0.2),
                    const Color(0xFF6B5FFF).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 64,
                color: Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _hasEnrolledCourses
                  ? 'No courses available yet'
                  : 'Start Your Learning Journey',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _hasEnrolledCourses
                  ? 'New courses will appear here once they are added to the platform.'
                  : 'You haven\'t enrolled in any courses yet. Explore our course catalog to begin your learning adventure!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to course catalog or marketplace
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course catalog coming soon!')),
                );
              },
              icon: const Icon(Icons.explore_rounded, size: 20),
              label: const Text('Explore Courses'),
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
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
