import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class Student {
  final String name;
  final int grade;
  final double gpa;
  final String avatarUrl;
  final String status;
  final Color statusColor;
  final String? studentId;
  final String? id; // MongoDB _id (ObjectId)
  final DateTime? registeredAt;
  final String? email;
  final String? phone;

  const Student({
    required this.name,
    required this.grade,
    required this.gpa,
    required this.avatarUrl,
    required this.status,
    required this.statusColor,
    this.studentId,
    this.id,
    this.registeredAt,
    this.email,
    this.phone,
  });
}


class StudentDetailsPage extends StatefulWidget {
  final Student student;

  const StudentDetailsPage({super.key, required this.student});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  bool _isCollapsed = false;
  bool _isLoadingCourses = true;
  List<Map<String, dynamic>> _enrolledCourses = [];
  Map<String, dynamic>? _studentDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      final isCollapsed =
          _scrollController.hasClients &&
          _scrollController.offset > (200 - kToolbarHeight);
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    });

    _loadCourseEnrollments();
  }

  Future<void> _loadCourseEnrollments() async {
    try {
      // Use MongoDB _id for API call (required by backend)
      // The backend expects a MongoDB ObjectId (24 char hex), not the studentId string
      final mongoId = widget.student.id;
      if (mongoId == null || mongoId.isEmpty) {
        setState(() {
          _isLoadingCourses = false;
        });
        return;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.principalStudentById(mongoId)),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            if (data['courses'] != null) {
              _enrolledCourses = List<Map<String, dynamic>>.from(data['courses']);
            }
            if (data['student'] != null) {
              _studentDetails = Map<String, dynamic>.from(data['student']);
            }
            _isLoadingCourses = false;
          });
        } else {
          setState(() {
            _isLoadingCourses = false;
          });
        }
      } else {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedCard(index: 0, child: _buildStatsCard()),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  index: 1,
                  child: _buildCourseEnrollmentsCard(),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(index: 2, child: _buildCourseProgressCard()),
                const SizedBox(height: 20),
                _buildAnimatedCard(index: 3, child: _buildContactCard()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      stretch: true,
      backgroundColor: DashboardStyles.cardBackground,
      foregroundColor: DashboardStyles.textDark,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCollapsed ? 1.0 : 0.0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.student.avatarUrl),
            ),
            const SizedBox(width: 12),
            Text(
              widget.student.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.student.statusColor.withOpacity(0.2),
                DashboardStyles.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isCollapsed ? 0.0 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: kToolbarHeight / 2),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundImage: NetworkImage(widget.student.avatarUrl),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.student.name,
                  style: const TextStyle(
                    color: DashboardStyles.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int index}) {
    final double start = (0.15 * index).clamp(0.0, 1.0);
    final double end = (start + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildStatsCard() {
    String registeredAtText = 'N/A';
    if (widget.student.registeredAt != null) {
      try {
        final date = widget.student.registeredAt!;
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        registeredAtText = '$day/$month/${date.year}';
      } catch (e) {
        registeredAtText = 'N/A';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.badge_outlined,
            'Student ID',
            widget.student.studentId ?? 'N/A',
          ),
          _buildStatItem(
            Icons.calendar_today_outlined,
            'Registered At',
            registeredAtText,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: DashboardStyles.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCourseEnrollmentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Enrollments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_enrolledCourses.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DashboardStyles.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_enrolledCourses.length} ${_enrolledCourses.length == 1 ? 'Course' : 'Courses'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DashboardStyles.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingCourses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
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
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No enrolled courses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_enrolledCourses.length, (index) {
              final course = _enrolledCourses[index];
              final courseName = course['courseName'] as String? ?? 'Unknown Course';
              final category = course['category'] as String? ?? 'General';
              final progressPercentage = course['progressPercentage'] as int? ?? 0;
              final isCompleted = course['isCompleted'] as bool? ?? false;
              
              return Container(
                margin: EdgeInsets.only(bottom: index < _enrolledCourses.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DashboardStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book_rounded,
                        color: DashboardStyles.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressPercentage / 100,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCompleted
                                          ? DashboardStyles.accentGreen
                                          : DashboardStyles.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$progressPercentage%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? DashboardStyles.accentGreen
                                      : DashboardStyles.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DashboardStyles.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: DashboardStyles.accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DashboardStyles.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCourseProgressCard() {
    if (_isLoadingCourses) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DashboardStyles.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_enrolledCourses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DashboardStyles.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.trending_up_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No course progress available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...List.generate(_enrolledCourses.length, (index) {
            final course = _enrolledCourses[index];
            final courseName = course['courseName'] as String? ?? 'Unknown Course';
            final progressPercentage = course['progressPercentage'] as int? ?? 0;
            final totalLectures = course['totalLectures'] as int? ?? 0;
            final completedLectures = course['completedLectures'] as int? ?? 0;
            final totalModules = course['totalModules'] as int? ?? 0;
            final completedModules = course['completedModules'] as int? ?? 0;
            final isCompleted = course['isCompleted'] as bool? ?? false;
            
            return Container(
              margin: EdgeInsets.only(bottom: index < _enrolledCourses.length - 1 ? 16 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DashboardStyles.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: DashboardStyles.accentGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: DashboardStyles.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Overall Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '$progressPercentage%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted
                                        ? DashboardStyles.accentGreen
                                        : DashboardStyles.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressPercentage / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted
                                      ? DashboardStyles.accentGreen
                                      : DashboardStyles.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Modules and Lectures Progress
                  Row(
                    children: [
                      Expanded(
                        child: _buildProgressStat(
                          icon: Icons.library_books_outlined,
                          label: 'Modules',
                          completed: completedModules,
                          total: totalModules,
                          color: DashboardStyles.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProgressStat(
                          icon: Icons.play_circle_outline,
                          label: 'Lectures',
                          completed: completedLectures,
                          total: totalLectures,
                          color: DashboardStyles.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressStat({
    required IconData icon,
    required String label,
    required int completed,
    required int total,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completed / $total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    // Use email and phone from the Student object (from initial API call)
    // Fallback to _studentDetails if available, otherwise use defaults
    final email = widget.student.email ?? 
                  _studentDetails?['email'] as String? ?? 
                  widget.student.name.replaceAll(' ', '.').toLowerCase() + '@tega.edu';
    final phone = widget.student.phone ?? 
                  _studentDetails?['phone'] as String? ?? 
                  _studentDetails?['contactNumber'] as String?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {
              // TODO: Implement copy to clipboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text(
              phone ?? 'Not provided',
              style: TextStyle(
                color: phone == null ? Colors.grey.shade600 : null,
              ),
            ),
            trailing: phone != null
                ? const Icon(Icons.copy, size: 20)
                : null,
            onTap: phone != null
                ? () {
                    // TODO: Implement copy to clipboard
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
