import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/courses/create_course_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/courses/edit_course_page.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage>
    with TickerProviderStateMixin {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controllers
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCourses();
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

  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _dashboardService.getCourses();

      if (result['success'] == true) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
        _startStaggeredAnimations();
      } else {
        throw Exception(result['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
          _loadCourses(); // Refresh the list
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

  void _showDeleteConfirmation(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course['courseName']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCourse(course['_id']);
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildContent(),
      floatingActionButton: _buildCreateCourseFAB(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first course to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateCourse,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return _buildCoursesList();
  }

  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
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
                child: _buildCourseCard(course),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AdminDashboardStyles.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToEditCourse(course),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Course Icon with enhanced styling
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AdminDashboardStyles.primary,
                            AdminDashboardStyles.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Course Title and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ??
                                course['courseName'] ??
                                'Untitled Course',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A202C),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course['description'] ?? 'No description available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Actions Menu
                    _buildCourseActions(course),
                  ],
                ),
                const SizedBox(height: 20),
                // Course Info Chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildEnhancedCourseInfoChip(
                      icon: Icons.category_rounded,
                      label: course['category'] ?? 'Uncategorized',
                      color: const Color(0xFF3B82F6),
                    ),
                    _buildEnhancedCourseInfoChip(
                      icon: Icons.trending_up_rounded,
                      label: course['level'] ?? 'Beginner',
                      color: const Color(0xFF10B981),
                    ),
                    _buildEnhancedCourseInfoChip(
                      icon: Icons.access_time_rounded,
                      label:
                          '${course['estimatedDuration']?['hours'] ?? course['duration'] ?? 0} hours',
                      color: const Color(0xFFF59E0B),
                    ),
                    if (course['enrollmentCount'] != null)
                      _buildEnhancedCourseInfoChip(
                        icon: Icons.people_rounded,
                        label: '${course['enrollmentCount']} students',
                        color: const Color(0xFF8B5CF6),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bottom Row with Price and Status
                Row(
                  children: [
                    // Price Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AdminDashboardStyles.primary,
                            AdminDashboardStyles.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.currency_rupee_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          Text(
                            '${course['price'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          course['status'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(
                            course['status'],
                          ).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(course['status']),
                        style: TextStyle(
                          color: _getStatusColor(course['status']),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                // Instructor Info
                if (course['instructor'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instructor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                course['instructor'] is Map
                                    ? course['instructor']['name'] ?? 'Unknown'
                                    : course['instructor'].toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCourseInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  Widget _buildCourseActions(Map<String, dynamic> course) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _navigateToEditCourse(course);
            break;
          case 'delete':
            _showDeleteConfirmation(course);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCourseFAB() {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreateCourse,
            backgroundColor: AdminDashboardStyles.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Create Course',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms, delay: 300.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  void _navigateToCreateCourse() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CreateCoursePage()))
        .then((_) {
          _loadCourses(); // Refresh the list when returning
        });
  }

  void _navigateToEditCourse(Map<String, dynamic> course) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditCoursePage(course: course),
          ),
        )
        .then((_) {
          _loadCourses(); // Refresh the list when returning
        });
  }
}
