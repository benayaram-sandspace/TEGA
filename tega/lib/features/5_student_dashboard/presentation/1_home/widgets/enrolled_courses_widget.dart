import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/presentation/2_learning_hub/course_content_page.dart';

class EnrolledCoursesWidget extends StatefulWidget {
  const EnrolledCoursesWidget({super.key});

  @override
  State<EnrolledCoursesWidget> createState() => _EnrolledCoursesWidgetState();
}

class _EnrolledCoursesWidgetState extends State<EnrolledCoursesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;
  List<dynamic> _enrolledCourses = [];
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _loadEnrolledCourses();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledCourses() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final service = StudentDashboardService();

      // Fetch paid courses from the API
      final paidCourses = await service.getEnrolledCourses(headers);

      // Get progress data to merge with paid courses
      final progressData = await service.getAllProgress(headers);

      // Create a map of courseId -> progress for quick lookup
      final progressMap = <String, dynamic>{};
      for (var progress in progressData) {
        final courseId = progress['courseId']?.toString() ?? '';
        if (courseId.isNotEmpty) {
          progressMap[courseId] = progress;
        }
      }

      // Merge paid courses with progress data
      final mergedCourses = paidCourses.map((course) {
        final courseId =
            course['courseId']?.toString() ??
            course['id']?.toString() ??
            course['_id']?.toString() ??
            '';
        final progress = progressMap[courseId];

        if (progress != null) {
          final mergedCourse = Map<String, dynamic>.from(course);
          mergedCourse['progress'] = progress['overallProgress'] ?? 0;
          mergedCourse['lastAccessedAt'] = progress['lastAccessedAt'];
          mergedCourse['completedLectures'] =
              progress['completedLectures'] ?? 0;
          mergedCourse['totalLectures'] = progress['totalLectures'] ?? 0;
          // Add thumbnail from progress if not present in course
          if ((mergedCourse['thumbnail'] == null ||
                  mergedCourse['thumbnail'].toString().isEmpty) &&
              progress['thumbnail'] != null) {
            mergedCourse['thumbnail'] = progress['thumbnail'];
          }
          // Add title from progress if not present in course
          if ((mergedCourse['title'] == null ||
                  mergedCourse['title'].toString().isEmpty) &&
              progress['courseTitle'] != null) {
            mergedCourse['title'] = progress['courseTitle'];
          }
          return mergedCourse;
        }
        return course;
      }).toList();

      // Sort by lastAccessedAt or enrolledAt (most recent first)
      final sortedCourses = mergedCourses
        ..sort((a, b) {
          final aDate =
              a['lastAccessedAt'] ?? a['enrolledAt'] ?? a['createdAt'];
          final bDate =
              b['lastAccessedAt'] ?? b['enrolledAt'] ?? b['createdAt'];
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return DateTime.parse(
            bDate.toString(),
          ).compareTo(DateTime.parse(aDate.toString()));
        });

      if (mounted) {
        setState(() {
          _enrolledCourses = sortedCourses.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _getProgressPercentage(dynamic course) {
    // Try multiple possible progress fields
    final progress =
        course['progress'] ??
        course['overallProgress']?['percentage'] ??
        course['overallProgress']?['progressPercentage'] ??
        course['progressPercentage'] ??
        0.0;

    if (progress is num) {
      return progress.toDouble().clamp(0.0, 100.0);
    }
    return 0.0;
  }

  String _getCourseTitle(dynamic course) {
    // Handle case where courseId might be a String (ID) or an object
    if (course['courseId'] is Map) {
      return course['courseId']?['title']?.toString() ??
          course['courseName']?.toString() ??
          course['title']?.toString() ??
          'Untitled Course';
    }
    // If courseId is a String, use other fields
    return course['courseName']?.toString() ??
        course['title']?.toString() ??
        course['name']?.toString() ??
        'Untitled Course';
  }

  String? _getCourseThumbnail(dynamic course) {
    // Handle case where courseId might be a String (ID) or an object
    if (course['courseId'] is Map) {
      return course['courseId']?['thumbnail']?.toString() ??
          course['thumbnail']?.toString();
    }
    // If courseId is a String, use thumbnail directly
    return course['thumbnail']?.toString();
  }

  String _getCourseCategory(dynamic course) {
    // Handle case where courseId might be a String (ID) or an object
    if (course['courseId'] is Map) {
      return course['courseId']?['category']?.toString() ??
          course['category']?.toString() ??
          'General';
    }
    // If courseId is a String, use category directly
    return course['category']?.toString() ?? 'General';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color.lerp(Colors.white, Colors.black, 0.02)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.05),
                  blurRadius: _isHovered ? 18 : 15,
                  offset: Offset(0, _isHovered ? 5 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B5FFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF6B5FFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Enrolled Courses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6B5FFF),
                        ),
                      ),
                    ),
                  )
                else if (_enrolledCourses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No enrolled courses yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start exploring courses to begin learning',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._enrolledCourses
                      .map((course) => _buildCourseCard(course))
                      .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final progress = _getProgressPercentage(course);
    final title = _getCourseTitle(course);
    final thumbnail = _getCourseThumbnail(course);
    final category = _getCourseCategory(course);

    // Get course ID for navigation
    final courseId =
        course['id']?.toString() ??
        course['courseId']?.toString() ??
        course['_id']?.toString() ??
        '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (courseId.isNotEmpty) {
              // Navigate to course content page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseContentPage(
                    course: {
                      'id': courseId,
                      'title': title,
                      'thumbnail': thumbnail,
                      'category': category,
                      'modules': course['modules'] ?? [],
                    },
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to open course. Course ID not found.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Course Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: thumbnail != null && thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF6B5FFF),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.school_rounded,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          )
                        : Icon(
                            Icons.school_rounded,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Course Info and Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 100
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF6B5FFF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: progress >= 100
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF6B5FFF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Continue Button
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
