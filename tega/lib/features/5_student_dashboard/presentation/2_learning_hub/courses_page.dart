import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/2_learning_hub/course_content_page.dart';
import 'package:tega/core/services/courses_cache_service.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasEnrolledCourses = false;
  final CoursesCacheService _cacheService = CoursesCacheService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _loadCourses();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
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

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    // If force refresh, clear cache first
    if (forceRefresh) {
      await _cacheService.clearCache();
    }

    // First, try to load from cache
    final cachedData = await _cacheService.getAllCachedData();

    if (cachedData != null && !forceRefresh) {
      // Cache is valid, use cached data immediately
      if (!mounted) return;
      _processCoursesData(
        cachedData['allCourses'] as List<dynamic>,
        cachedData['enrolledCourses'] as List<dynamic>,
      );
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } else if (forceRefresh) {
      // Force refresh: show loading state
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      // No cache, show loading
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // Fetch fresh data from API (in background if cache exists)
    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();

      final dashboardService = StudentDashboardService();

      // Always fetch all available courses
      final allCourses = await dashboardService.getAllCourses(headers);

      // Also fetch enrolled courses to mark which ones are enrolled
      final enrolledCourses = await dashboardService.getEnrolledCourses(
        headers,
      );

      // Update cache with fresh data
      await _cacheService.setAllData(
        allCourses: allCourses,
        enrolledCourses: enrolledCourses,
      );

      if (!mounted) return;
      _processCoursesData(allCourses, enrolledCourses);
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      // If API call fails and we have no cache, show error state
      if (!mounted) return;
      if (cachedData == null || forceRefresh) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          setState(() {
            _errorMessage = 'No internet connection';
            _courses = [];
            _filteredCourses = [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Unable to load courses. Please try again.';
            _courses = [];
            _filteredCourses = [];
            _isLoading = false;
          });
        }
      }
      // If we have cached data, keep showing it even if API fails
    }
  }

  void _processCoursesData(
    List<dynamic> allCourses,
    List<dynamic> enrolledCourses,
  ) {
    // Create a set of enrolled course IDs for quick lookup
    final enrolledCourseIds = <String>{};
    for (var enrolledCourse in enrolledCourses) {
      final courseId =
          enrolledCourse['id']?.toString() ??
          enrolledCourse['courseId']?.toString() ??
          enrolledCourse['_id']?.toString() ??
          '';
      if (courseId.isNotEmpty) {
        enrolledCourseIds.add(courseId);
      }
    }

    _hasEnrolledCourses = enrolledCourseIds.isNotEmpty;

    // Transform all courses and mark which ones are enrolled
    // Backend provides: Real-time course structure with modules and lectures
    _courses = allCourses.map<Map<String, dynamic>>((course) {
      final courseId =
          course['_id']?.toString() ?? course['id']?.toString() ?? '';
      final isEnrolled = enrolledCourseIds.contains(courseId);

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
        'id': courseId,
        'title': course['title']?.toString() ?? 'Untitled Course',
        'thumbnail': course['thumbnail']?.toString() ?? '',
        'createdBy':
            course['instructor'], // Real-time courses have instructor object
        'students': course['enrollmentCount'] ?? 0,
        'difficulty': course['level']?.toString() ?? 'Beginner',
        'duration': _formatRealTimeDuration(course['estimatedDuration']),
        'progress': 0, // Will be updated if progress data is available
        'category': course['category']?.toString() ?? 'General',
        'isStarted': isEnrolled, // Mark as started if enrolled
        'price': course['price'] ?? 0,
        'isFree': course['isFree'] ?? false,
        'description': course['description']?.toString() ?? '',
        'shortDescription': course['shortDescription']?.toString() ?? '',
        'hasVideoContent': firstVideoUrl.isNotEmpty,
        'videoUrl': firstVideoUrl, // First video from modules
        'videoLink': firstVideoUrl, // Same as videoUrl for compatibility
        'previewVideo': course['previewVideo']?.toString() ?? '',
        'modules':
            course['modules'] ?? [], // Store full modules for video navigation
        'isEnrolled': isEnrolled, // Add enrollment status
      };
    }).toList();

    if (mounted) {
      setState(() {
        _filteredCourses = List.from(_courses);
        _errorMessage = null;
      });
    }
  }

  /// Refresh courses data (force fetch from API)
  Future<void> refreshCourses() async {
    await _loadCourses(forceRefresh: true);
  }

  void _filterCourses() {
    setState(() {
      String searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isEmpty) {
        _filteredCourses = List.from(_courses);
      } else {
        _filteredCourses = _courses.where((course) {
          return (course['title']?.toString() ?? '').toLowerCase().contains(
                searchQuery,
              ) ||
              (course['createdBy']?.toString() ?? '').toLowerCase().contains(
                searchQuery,
              ) ||
              (course['category']?.toString() ?? '').toLowerCase().contains(
                searchQuery,
              ) ||
              (course['description']?.toString() ?? '').toLowerCase().contains(
                searchQuery,
              );
        }).toList();
      }
    });
  }

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Responsive getters
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
  bool get isLandscape =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RepaintBoundary(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
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
                child: _buildSearchBar(),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredCourses.isEmpty
                    ? _buildEmptyState()
                    : _buildCoursesList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _filterCourses(),
      style: TextStyle(
        fontSize: isLargeDesktop
            ? 18
            : isDesktop
            ? 16
            : isTablet
            ? 15
            : isSmallScreen
            ? 13
            : 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search courses...',
        hintStyle: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: isLargeDesktop
              ? 18
              : isDesktop
              ? 16
              : isTablet
              ? 15
              : isSmallScreen
              ? 13
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
              : 20,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 13
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
                : 12,
          ),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 13
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
              ? 12
              : 14,
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    // Use grid layout for desktop/large desktop, list for mobile/tablet
    if (isLargeDesktop || (isDesktop && isLandscape)) {
      return RepaintBoundary(
        child: GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeDesktop ? 32 : 24,
            vertical: isLargeDesktop ? 16 : 12,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: isLargeDesktop ? 24 : 20,
            mainAxisSpacing: isLargeDesktop ? 24 : 20,
            childAspectRatio: 0.75,
          ),
          itemCount: _filteredCourses.length,
          cacheExtent: 500, // Cache more items for smooth scrolling
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            return _buildCourseCard(course, index);
          },
        ),
      );
    } else if (isDesktop || (isTablet && isLandscape)) {
      return RepaintBoundary(
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemCount: _filteredCourses.length,
          cacheExtent: 500, // Cache more items for smooth scrolling
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            return _buildCourseCard(course, index);
          },
        ),
      );
    } else {
      return RepaintBoundary(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet
                ? 20
                : isSmallScreen
                ? 12
                : 16,
            vertical: isTablet ? 12 : 8,
          ),
          itemCount: _filteredCourses.length,
          cacheExtent: 500, // Cache more items for smooth scrolling
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            return _buildCourseCard(course, index);
          },
        ),
      );
    }
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
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
                  bottom: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : 16,
                  left: (isLargeDesktop || isDesktop) ? 4 : 0,
                  right: (isLargeDesktop || isDesktop) ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : 16,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.08),
                      blurRadius: isLargeDesktop
                          ? 24
                          : isDesktop
                          ? 20
                          : isTablet
                          ? 18
                          : 15,
                      offset: Offset(
                        0,
                        isLargeDesktop
                            ? 10
                            : isDesktop
                            ? 8
                            : isTablet
                            ? 7
                            : 6,
                      ),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.04),
                      blurRadius: isLargeDesktop
                          ? 48
                          : isDesktop
                          ? 40
                          : isTablet
                          ? 35
                          : 30,
                      offset: Offset(
                        0,
                        isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 16
                            : isTablet
                            ? 14
                            : 12,
                      ),
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
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 24
                          : isDesktop
                          ? 20
                          : isTablet
                          ? 18
                          : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              isLargeDesktop
                                  ? 24
                                  : isDesktop
                                  ? 20
                                  : isTablet
                                  ? 18
                                  : 16,
                            ),
                            topRight: Radius.circular(
                              isLargeDesktop
                                  ? 24
                                  : isDesktop
                                  ? 20
                                  : isTablet
                                  ? 18
                                  : 16,
                            ),
                          ),
                          child: Container(
                            height: isLargeDesktop
                                ? 240
                                : isDesktop
                                ? 200
                                : isTablet
                                ? 180
                                : isSmallScreen
                                ? 140
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
                                  CachedNetworkImage(
                                    imageUrl: course['thumbnail'].toString(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) =>
                                        _buildThumbnailPlaceholder(),
                                    errorWidget: (context, url, error) =>
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
                                          isLargeDesktop
                                              ? 20
                                              : isDesktop
                                              ? 16
                                              : isTablet
                                              ? 15
                                              : 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).cardColor.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(
                                                context,
                                              ).shadowColor.withOpacity(0.2),
                                              blurRadius: isLargeDesktop
                                                  ? 16
                                                  : isDesktop
                                                  ? 12
                                                  : 10,
                                              offset: Offset(
                                                0,
                                                isLargeDesktop
                                                    ? 6
                                                    : isDesktop
                                                    ? 4
                                                    : 3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: const Color(0xFF6B5FFF),
                                          size: isLargeDesktop
                                              ? 40
                                              : isDesktop
                                              ? 32
                                              : isTablet
                                              ? 30
                                              : 28,
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
                              // Course Title
                              Text(
                                course['title']?.toString() ??
                                    'Untitled Course',
                                style: TextStyle(
                                  fontSize: isLargeDesktop
                                      ? 24
                                      : isDesktop
                                      ? 22
                                      : isTablet
                                      ? 20
                                      : isSmallScreen
                                      ? 16
                                      : 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color ??
                                      const Color(0xFF1A1A1A),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                height: isLargeDesktop
                                    ? 14
                                    : isDesktop
                                    ? 12
                                    : isTablet
                                    ? 11
                                    : 10,
                              ),

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
                                        fontSize: isLargeDesktop
                                            ? 16
                                            : isDesktop
                                            ? 15
                                            : isTablet
                                            ? 14.5
                                            : isSmallScreen
                                            ? 12
                                            : 14,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isLargeDesktop
                                    ? 18
                                    : isDesktop
                                    ? 16
                                    : isTablet
                                    ? 15
                                    : 14,
                              ),

                              // Course Info Row
                              Row(
                                children: [
                                  // Hours
                                  Expanded(
                                    child: _buildModernInfoChip(
                                      Icons.access_time_rounded,
                                      course['duration']?.toString() ??
                                          '0 hours',
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
                                      _formatStudentCount(course['students']),
                                      const Color(0xFF4CAF50),
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
                                    : 16,
                              ),

                              // Enroll Button
                              _buildModernEnrollButton(course),
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
      ),
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
            ? 10
            : isDesktop
            ? 8
            : isTablet
            ? 7
            : isSmallScreen
            ? 6
            : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 12
              : isDesktop
              ? 10
              : isTablet
              ? 9
              : 8,
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: isLargeDesktop ? 1.5 : 1,
        ),
      ),
      child: Column(
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
            color: color,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 6
                : isDesktop
                ? 4
                : isTablet
                ? 3
                : 2,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 11
                  : isTablet
                  ? 10.5
                  : isSmallScreen
                  ? 9
                  : 10,
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

  Widget _buildModernEnrollButton(Map<String, dynamic> course) {
    final hasPrice = course['price'] != null && course['price'] > 0;
    final isEnrolled =
        course['isEnrolled'] == true || course['isStarted'] == true;

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
      height: isLargeDesktop
          ? 56
          : isDesktop
          ? 50
          : isTablet
          ? 48
          : isSmallScreen
          ? 42
          : 46,
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
                    fontSize: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15.5
                        : isSmallScreen
                        ? 13
                        : 15,
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
            strokeWidth: isLargeDesktop
                ? 4
                : isDesktop
                ? 3.5
                : 3,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : 14,
          ),
          Text(
            'Loading courses...',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 15
                  : isSmallScreen
                  ? 13
                  : 14,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  Colors.grey[600],
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
              ? 40.0
              : isDesktop
              ? 32.0
              : isTablet
              ? 28.0
              : isSmallScreen
              ? 20.0
              : 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: isLargeDesktop
                  ? 64
                  : isDesktop
                  ? 56
                  : isTablet
                  ? 50
                  : 44,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : 16,
            ),
            Text(
              isNoInternet
                  ? 'No internet connection'
                  : 'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 22
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 17
                    : isSmallScreen
                    ? 15
                    : 16,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : 8,
            ),
            Text(
              isNoInternet
                  ? 'Please check your connection and try again'
                  : (_errorMessage ?? 'Unable to load courses'),
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 15
                    : isDesktop
                    ? 13
                    : isTablet
                    ? 12.5
                    : isSmallScreen
                    ? 11
                    : 12,
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : 20,
            ),
            ElevatedButton.icon(
              onPressed: () => refreshCourses(),
              icon: Icon(
                Icons.refresh_rounded,
                size: isLargeDesktop
                    ? 22
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 19
                    : 18,
              ),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 24
                      : isTablet
                      ? 22
                      : isSmallScreen
                      ? 18
                      : 20,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 11
                      : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : 10,
                  ),
                ),
                textStyle: TextStyle(
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14.5
                      : isSmallScreen
                      ? 12
                      : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Different empty states based on search
    final hasActiveSearch = _searchController.text.isNotEmpty;

    if (hasActiveSearch) {
      // No results for current search/filter
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isLargeDesktop
                ? 40.0
                : isDesktop
                ? 32.0
                : isTablet
                ? 28.0
                : isSmallScreen
                ? 20.0
                : 24.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: isLargeDesktop
                      ? 64
                      : isDesktop
                      ? 56
                      : isTablet
                      ? 50
                      : 44,
                  color: const Color(0xFF6B5FFF),
                ),
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
              ),
              Text(
                'No courses found',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 15
                      : 16,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 9
                    : 8,
              ),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 15
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12.5
                      : isSmallScreen
                      ? 11
                      : 12,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _filterCourses();
                  });
                },
                icon: Icon(
                  Icons.clear_rounded,
                  size: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : 16,
                ),
                label: Text('Clear Search'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5FFF),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 14,
                    vertical: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 10
                        : isTablet
                        ? 9
                        : isSmallScreen
                        ? 8
                        : 9,
                  ),
                  textStyle: TextStyle(
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13.5
                        : isSmallScreen
                        ? 11
                        : 12,
                    fontWeight: FontWeight.w600,
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
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 40.0
              : isDesktop
              ? 32.0
              : isTablet
              ? 28.0
              : isSmallScreen
              ? 20.0
              : 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
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
                Icons.school_outlined,
                size: isLargeDesktop
                    ? 72
                    : isDesktop
                    ? 64
                    : isTablet
                    ? 58
                    : 52,
                color: const Color(0xFF6B5FFF),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : 16,
            ),
            Text(
              _hasEnrolledCourses
                  ? 'No courses available yet'
                  : 'Start Your Learning Journey',
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
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    const Color(0xFF333333),
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
                  : 10,
            ),
            Text(
              _hasEnrolledCourses
                  ? 'New courses will appear here once they are added to the platform.'
                  : 'You haven\'t enrolled in any courses yet. Check back soon for available courses!',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 15
                    : isDesktop
                    ? 13
                    : isTablet
                    ? 12.5
                    : isSmallScreen
                    ? 11
                    : 12,
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
