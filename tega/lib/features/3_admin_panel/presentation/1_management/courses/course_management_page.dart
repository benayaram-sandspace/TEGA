import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/data/models/course_model.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/courses/edit_course_page.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage>
    with TickerProviderStateMixin {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  List<Course> _courses = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;

  // Animation controllers
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadCourses();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _cacheService.getCoursesData();

      if (cachedData != null) {
        setState(() {
          _isLoadingFromCache = true;
        });

        final coursesData = cachedData['courses'] as List<dynamic>?;

        if (coursesData != null) {
          setState(() {
            _courses = coursesData
                .map((course) => Course.fromJson(course))
                .toList();
            _isLoading = false;
            _isLoadingFromCache = false;
          });
          _startStaggeredAnimations();
        }
      }
    } catch (e) {
      // Silently fail cache loading
      setState(() {
        _isLoadingFromCache = false;
      });
    }
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      50, // Maximum expected courses
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
        .toList();

    _slideAnimations = _animationControllers
        .map(
          (controller) =>
              Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    try {
      // Skip cache if force refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getCoursesData();
        if (cachedData != null && !_isLoadingFromCache) {
          // Already loaded from cache, just update in background
          _loadCoursesInBackground();
          return;
        }
      }

      if (!_isLoadingFromCache) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final result = await _dashboardService.getAllCourses();

      if (result['success'] == true) {
        // Cache the courses data
        await _cacheService.setCoursesData(result);

        setState(() {
          final coursesData = result['courses'] as List<dynamic>;
          _courses = coursesData
              .map((course) => Course.fromJson(course))
              .toList();
          _isLoading = false;
          _isLoadingFromCache = false;
        });
        _startStaggeredAnimations();
      } else {
        throw Exception(result['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getCoursesData();
        if (cachedData != null) {
          final coursesData = cachedData['courses'] as List<dynamic>?;
          if (coursesData != null && coursesData.isNotEmpty) {
            // Load from cache and show toast
            setState(() {
              _courses = coursesData
                  .map((course) => Course.fromJson(course))
                  .toList();
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = null; // Clear error since we have cached data
            });
            _startStaggeredAnimations();
            return;
          }
        }

        // No cache available, show error
        setState(() {
          _errorMessage = 'No internet connection';
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      } else {
        // Other errors
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      }
    }
  }

  Future<void> _loadCoursesInBackground() async {
    try {
      final result = await _dashboardService.getAllCourses();
      if (result['success'] == true) {
        await _cacheService.setCoursesData(result);

        final coursesData = result['courses'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _courses = coursesData
                .map((course) => Course.fromJson(course))
                .toList();
          });
          _startStaggeredAnimations();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  void _startStaggeredAnimations() {
    for (
      int i = 0;
      i < _animationControllers.length && i < _courses.length;
      i++
    ) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      final result = await _dashboardService.deleteCourse(courseId);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCourses(forceRefresh: true); // Refresh the list
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to delete course');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete course: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCourse(course.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light background
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AdminDashboardStyles.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null && !_isLoadingFromCache) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 20
                : isTablet
                ? 40
                : 60,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: isMobile
                    ? 56
                    : isTablet
                    ? 64
                    : 72,
                color: Colors.grey[400],
              ),
              SizedBox(
                height: isMobile
                    ? 16
                    : isTablet
                    ? 18
                    : 20,
              ),
              Text(
                'Failed to load courses',
                style: TextStyle(
                  fontSize: isMobile
                      ? 18
                      : isTablet
                      ? 19
                      : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(
                height: isMobile
                    ? 8
                    : isTablet
                    ? 9
                    : 10,
              ),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: isMobile
                    ? 24
                    : isTablet
                    ? 28
                    : 32,
              ),
              ElevatedButton.icon(
                onPressed: () => _loadCourses(forceRefresh: true),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: isMobile
                      ? 16
                      : isTablet
                      ? 17
                      : 18,
                ),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminDashboardStyles.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 20
                : isTablet
                ? 40
                : 60,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: isMobile ? 56 : 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'No courses found',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Courses will appear here once they are created',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildCoursesList();
  }

  Widget _buildCoursesList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return ListView.builder(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
      ),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final animationIndex = index % _animationControllers.length;

        return AnimatedBuilder(
          animation: _animationControllers[animationIndex],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[animationIndex].value,
              child: SlideTransition(
                position: _slideAnimations[animationIndex],
                child: _buildCourseCard(course, isMobile, isTablet),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseCard(Course course, bool isMobile, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
          onTap: () => _navigateToEditCourse(course),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Header Section
              _buildThumbnailHeader(course, isMobile, isTablet),
              // Content Section
              Padding(
                padding: EdgeInsets.all(
                  isMobile
                      ? 16
                      : isTablet
                      ? 18
                      : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isMobile
                            ? 16
                            : isTablet
                            ? 17
                            : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    // Course Description
                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    // Course Tags and Info
                    _buildCourseInfoRow(course, isMobile),
                    SizedBox(height: isMobile ? 12 : 16),
                    // Price and Enrollment
                    _buildPriceAndEnrollmentRow(course, isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    // Action Buttons
                    _buildActionButtons(course, isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailHeader(Course course, bool isMobile, bool isTablet) {
    return Container(
      height: isMobile
          ? 160
          : isTablet
          ? 180
          : 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMobile ? 14 : 16),
          topRight: Radius.circular(isMobile ? 14 : 16),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminDashboardStyles.primary.withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 14 : 16),
                  topRight: Radius.circular(isMobile ? 14 : 16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AdminDashboardStyles.primary.withOpacity(0.05),
                    const Color(0xFF8B5CF6).withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
          // Status Badge
          Positioned(
            top: isMobile ? 12 : 16,
            right: isMobile ? 12 : 16,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: isMobile ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(course.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusLabel(course.status),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Course Thumbnail
          if (course.thumbnail != null &&
              course.thumbnail!.isNotEmpty &&
              course.thumbnail!.startsWith('http'))
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 14 : 16),
                  topRight: Radius.circular(isMobile ? 14 : 16),
                ),
                child: CachedNetworkImage(
                  imageUrl: course.thumbnail!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AdminDashboardStyles.primary.withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AdminDashboardStyles.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AdminDashboardStyles.primary.withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: isMobile ? 60 : 80,
                        height: isMobile ? 60 : 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.2,
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: AdminDashboardStyles.primary,
                          size: isMobile ? 30 : 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            // Fallback to icon when no thumbnail
            Center(
              child: Container(
                width: isMobile ? 60 : 80,
                height: isMobile ? 60 : 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AdminDashboardStyles.primary.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AdminDashboardStyles.primary,
                  size: isMobile ? 30 : 40,
                ),
              ),
            ),
          // Instructor Avatar (if available)
          if (course.instructor.avatar != null &&
              course.instructor.avatar!.isNotEmpty &&
              course.instructor.avatar!.startsWith('http'))
            Positioned(
              bottom: isMobile ? 12 : 16,
              right: isMobile ? 12 : 16,
              child: Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
                  child: CachedNetworkImage(
                    imageUrl: course.instructor.avatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[400],
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      color: Colors.grey[600],
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoRow(Course course, bool isMobile) {
    return Wrap(
      spacing: isMobile ? 6 : 8,
      runSpacing: isMobile ? 6 : 8,
      children: [
        // Level Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            course.level,
            style: TextStyle(
              color: const Color(0xFF10B981),
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Duration
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                color: const Color(0xFFF59E0B),
                size: isMobile ? 11 : 12,
              ),
              SizedBox(width: isMobile ? 3 : 4),
              Text(
                course.estimatedDuration.formattedDuration,
                style: TextStyle(
                  color: const Color(0xFFF59E0B),
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Modules Count
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book,
                color: Colors.grey[600],
                size: isMobile ? 11 : 12,
              ),
              SizedBox(width: isMobile ? 3 : 4),
              Text(
                '${course.modules?.length ?? 0} modules',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndEnrollmentRow(Course course, bool isMobile) {
    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      alignment: WrapAlignment.spaceBetween,
      children: [
        // Price
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: AdminDashboardStyles.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_rupee,
                color: Colors.white,
                size: isMobile ? 14 : 16,
              ),
              Text(
                '${course.price.toInt()}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Enrollment Count
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people,
                color: Colors.grey[600],
                size: isMobile ? 14 : 16,
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                '${course.enrollmentCount ?? 0}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Date
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                color: Colors.grey[600],
                size: isMobile ? 14 : 16,
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                course.createdAt != null
                    ? '${course.createdAt!.day}/${course.createdAt!.month}/${course.createdAt!.year}'
                    : 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Course course, bool isMobile) {
    return Row(
      children: [
        // Edit Button
        Expanded(
          child: Container(
            height: isMobile ? 36 : 40,
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _navigateToEditCourse(course),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: isMobile ? 14 : 16,
                    ),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        // Delete Button
        Expanded(
          child: Container(
            height: isMobile ? 36 : 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showDeleteConfirmation(course),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: isMobile ? 14 : 16,
                    ),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'published':
        return const Color(0xFF10B981);
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'archived':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'published':
        return 'Published';
      case 'draft':
        return 'Draft';
      case 'archived':
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  void _navigateToEditCourse(Course course) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditCoursePage(course: course.toJson()),
          ),
        )
        .then((_) {
          _loadCourses(forceRefresh: true); // Refresh the list when returning
        });
  }
}
