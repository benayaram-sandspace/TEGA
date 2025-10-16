import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/2_learning_hub/course_content_page.dart';

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
      // Backend provides: id, title, instructor, thumbnail, enrolledDate
      _courses = enrolledCourses.map<Map<String, dynamic>>((course) {
        // Get the first video URL from modules if available (real-time structure)
        String firstVideoUrl = '';
        if (course['modules'] != null && course['modules'] is List) {
          final modules = course['modules'] as List;
          if (modules.isNotEmpty) {
            final firstModule = modules[0];
            if (firstModule['lectures'] != null &&
                firstModule['lectures'] is List) {
              final lectures = firstModule['lectures'] as List;
              if (lectures.isNotEmpty) {
                final firstLecture = lectures[0];
                if (firstLecture['videoContent'] != null &&
                    firstLecture['videoContent']['r2Url'] != null) {
                  firstVideoUrl = firstLecture['videoContent']['r2Url']
                      .toString();
                }
              }
            }
          }
        }

        final transformedCourse = {
          'id': course['id']?.toString() ?? course['_id']?.toString() ?? '',
          'title': course['title']?.toString() ?? 'Untitled Course',
          'thumbnail': course['thumbnail']?.toString() ?? '',
          'createdBy':
              course['instructor'], // Keep as-is, will be handled by _getInstructorName
          'students': course['enrollmentCount'] ?? 0,
          'difficulty': course['level']?.toString() ?? 'Beginner',
          'duration': _formatRealTimeDuration(course['estimatedDuration']),
          'progress': 0, // Not provided by enrolled courses endpoint
          'category': course['category']?.toString() ?? 'General',
          'isStarted': false, // Will be updated if progress data is available
          'enrolledDate': course['enrolledDate'], // Available from backend
          'videoUrl': firstVideoUrl.isNotEmpty
              ? firstVideoUrl
              : (course['videoUrl'] ?? ''),
          'videoLink': firstVideoUrl.isNotEmpty
              ? firstVideoUrl
              : (course['videoLink'] ?? ''),
          'modules':
              course['modules'] ??
              [], // Store full modules for video navigation
        };
        return transformedCourse;
      }).toList();

      _hasEnrolledCourses = _courses.isNotEmpty;

      // If no enrolled courses, fetch available courses
      if (_courses.isEmpty) {
        final allCourses = await dashboardService.getAllCourses(headers);

        // Backend provides: Real-time course structure with modules and lectures
        _courses = allCourses.map<Map<String, dynamic>>((course) {
          // Get the first video URL from the first lecture of the first module
          String firstVideoUrl = '';
          if (course['modules'] != null && course['modules'] is List) {
            final modules = course['modules'] as List;
            if (modules.isNotEmpty) {
              final firstModule = modules[0];
              if (firstModule['lectures'] != null &&
                  firstModule['lectures'] is List) {
                final lectures = firstModule['lectures'] as List;
                if (lectures.isNotEmpty) {
                  final firstLecture = lectures[0];
                  if (firstLecture['videoContent'] != null &&
                      firstLecture['videoContent']['r2Url'] != null) {
                    firstVideoUrl = firstLecture['videoContent']['r2Url']
                        .toString();
                  }
                }
              }
            }
          }

          return {
            'id': course['_id']?.toString() ?? course['id']?.toString() ?? '',
            'title': course['title']?.toString() ?? 'Untitled Course',
            'thumbnail': course['thumbnail']?.toString() ?? '',
            'createdBy':
                course['instructor'], // Real-time courses have instructor object
            'students': course['enrollmentCount'] ?? 0,
            'difficulty': course['level']?.toString() ?? 'Beginner',
            'duration': _formatRealTimeDuration(course['estimatedDuration']),
            'progress': 0, // Not applicable for available courses
            'category': course['category']?.toString() ?? 'General',
            'isStarted': false, // Not applicable for available courses
            'price': course['price'] ?? 0,
            'isFree': course['isFree'] ?? false,
            'description': course['description']?.toString() ?? '',
            'shortDescription': course['shortDescription']?.toString() ?? '',
            'hasVideoContent': firstVideoUrl.isNotEmpty,
            'videoUrl': firstVideoUrl, // First video from modules
            'videoLink': firstVideoUrl, // Same as videoUrl for compatibility
            'previewVideo': course['previewVideo']?.toString() ?? '',
            'modules':
                course['modules'] ??
                [], // Store full modules for video navigation
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
            (course['title']?.toString() ?? '').toLowerCase().contains(
              searchQuery,
            ) ||
            (course['createdBy']?.toString() ?? '').toLowerCase().contains(
              searchQuery,
            );

        bool matchesFilter =
            _selectedFilter == 'All Courses' ||
            (_selectedFilter == 'Ongoing Courses' &&
                (course['progress'] ?? 0) > 0) ||
            (course['category']?.toString() ?? '') == _selectedFilter;

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

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.all(
                isDesktop
                    ? 24.0
                    : isTablet
                    ? 20.0
                    : 16.0,
              ),
              child: Column(children: [_buildSearchAndFilters(screenWidth)]),
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
        ),
      ],
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
                  selectedColor: const Color(0xFF6B5FFF),
                  labelStyle: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: isSelected ? Colors.white : Colors.grey[700],
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
              margin: EdgeInsets.only(
                bottom: isDesktop ? 20 : 16,
                left: isDesktop ? 4 : 0,
                right: isDesktop ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: isDesktop ? 20 : 15,
                    offset: Offset(0, isDesktop ? 8 : 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: isDesktop ? 40 : 30,
                    offset: Offset(0, isDesktop ? 16 : 12),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseContentPage(course: course),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isDesktop ? 20 : 16),
                          topRight: Radius.circular(isDesktop ? 20 : 16),
                        ),
                        child: Container(
                          height: isDesktop
                              ? 200
                              : isTablet
                              ? 180
                              : 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF6B5FFF).withOpacity(0.1),
                                const Color(0xFF6B5FFF).withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Course Image
                              if (course['thumbnail'] != null &&
                                  course['thumbnail'].toString().isNotEmpty)
                                Image.network(
                                  course['thumbnail'].toString(),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildThumbnailPlaceholder(),
                                )
                              else
                                _buildThumbnailPlaceholder(),

                              // Play Button Overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isDesktop ? 16 : 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: const Color(0xFF6B5FFF),
                                        size: isDesktop ? 32 : 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Course Details
                      Padding(
                        padding: EdgeInsets.all(isDesktop ? 20 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Title
                            Text(
                              course['title']?.toString() ?? 'Untitled Course',
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 22
                                    : isTablet
                                    ? 20
                                    : 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isDesktop ? 12 : 10),

                            // Lecturer Name
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6B5FFF,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: Color(0xFF6B5FFF),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getInstructorName(course),
                                    style: TextStyle(
                                      fontSize: isDesktop ? 15 : 14,
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

                            // Course Info Row
                            Row(
                              children: [
                                // Hours
                                Expanded(
                                  child: _buildModernInfoChip(
                                    Icons.access_time_rounded,
                                    course['duration']?.toString() ?? '0 hours',
                                    const Color(0xFF2196F3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Difficulty
                                Expanded(
                                  child: _buildModernInfoChip(
                                    Icons.signal_cellular_alt_rounded,
                                    course['difficulty']?.toString() ??
                                        'Beginner',
                                    const Color(0xFFFF9800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Students
                                Expanded(
                                  child: _buildModernInfoChip(
                                    Icons.people_outline_rounded,
                                    '${_formatStudentCount(course['students'])}',
                                    const Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isDesktop ? 20 : 18),

                            // Enroll Button
                            _buildModernEnrollButton(course, isDesktop),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B5FFF).withOpacity(0.1),
            const Color(0xFF6B5FFF).withOpacity(0.05),
          ],
        ),
      ),
      child: const Icon(
        Icons.play_circle_outline_rounded,
        size: 64,
        color: Color(0xFF6B5FFF),
      ),
    );
  }

  Widget _buildModernInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernEnrollButton(Map<String, dynamic> course, bool isDesktop) {
    final hasPrice = course['price'] != null && course['price'] > 0;
    final isEnrolled = _hasEnrolledCourses;

    String buttonText;
    Color buttonColor;
    IconData buttonIcon;

    if (isEnrolled) {
      buttonText = 'Continue Learning';
      buttonColor = const Color(0xFF4CAF50);
      buttonIcon = Icons.play_arrow_rounded;
    } else if (hasPrice) {
      buttonText = 'Enroll Now';
      buttonColor = const Color(0xFF6B5FFF);
      buttonIcon = Icons.shopping_cart_rounded;
    } else {
      buttonText = 'Start Free';
      buttonColor = const Color(0xFF4CAF50);
      buttonIcon = Icons.play_arrow_rounded;
    }

    return Container(
      width: double.infinity,
      height: isDesktop ? 50 : 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [buttonColor, buttonColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleEnrollButton(course, buttonText),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleEnrollButton(Map<String, dynamic> course, String buttonText) {
    if (buttonText == 'Enroll Now' || buttonText == 'Start Free') {
      // Navigate to course content page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseContentPage(course: course),
        ),
      );
    } else if (buttonText == 'Continue Learning') {
      // Navigate to course content page for enrolled courses
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseContentPage(course: course),
        ),
      );
    } else {
      // Show snackbar for other actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$buttonText for ${course['title']?.toString() ?? 'Course'}',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _getInstructorName(Map<String, dynamic> course) {
    // Handle different possible instructor field structures
    final instructor = course['createdBy'] ?? course['instructor'];

    if (instructor == null) {
      return 'TEGA Instructor';
    }

    // If it's already a string, return it
    if (instructor is String) {
      return instructor;
    }

    // If it's a Map/object, try to extract name
    if (instructor is Map<String, dynamic>) {
      return instructor['name']?.toString() ??
          instructor['fullName']?.toString() ??
          instructor['firstName']?.toString() ??
          'TEGA Instructor';
    }

    // Fallback to string conversion
    return instructor.toString();
  }

  String _formatRealTimeDuration(dynamic estimatedDuration) {
    if (estimatedDuration == null) return '0 hours';

    if (estimatedDuration is Map<String, dynamic>) {
      final hours = estimatedDuration['hours'] ?? 0;
      final minutes = estimatedDuration['minutes'] ?? 0;

      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else if (minutes > 0) {
        return '${minutes}m';
      }
    }

    return '0 hours';
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
                  : 'You haven\'t enrolled in any courses yet. Check back soon for available courses!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
