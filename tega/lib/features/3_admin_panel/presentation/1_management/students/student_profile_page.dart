import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/5_student_dashboard/data/models/student_model.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';

class StudentProfilePage extends StatefulWidget {
  final Student student;

  const StudentProfilePage({super.key, required this.student});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  final AdminDashboardService _dashboardService = AdminDashboardService();
  bool _isCollapsed = false;

  // Student data
  Map<String, dynamic>? _detailedStudentData;

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

    _fetchDetailedStudentData();
  }

  Future<void> _fetchDetailedStudentData() async {
    try {
      final data = await _dashboardService.getStudentById(
        widget.student.id ?? '',
      );

      if (data['success'] == true) {
        setState(() {
          _detailedStudentData = data['student'];
        });
      }
    } catch (e) {
      // Handle error silently for now
      print('Error fetching student details: $e');
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
      backgroundColor: AdminDashboardStyles.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 16 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedCard(index: 0, child: _buildStatsCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                ),
                _buildAnimatedCard(index: 1, child: _buildAcademicCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                ),
                _buildAnimatedCard(index: 2, child: _buildPersonalInfoCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                ),
                _buildAnimatedCard(index: 3, child: _buildSkillsCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                ),
                _buildAnimatedCard(index: 4, child: _buildContactCard()),
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
      backgroundColor: AdminDashboardStyles.cardBackground,
      foregroundColor: AdminDashboardStyles.textDark,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AdminDashboardStyles.textDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCollapsed ? 1.0 : 0.0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AdminDashboardStyles.primary,
              child: Text(
                widget.student.name.isNotEmpty
                    ? widget.student.name[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.student.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminDashboardStyles.primary.withValues(alpha: 0.2),
                AdminDashboardStyles.background,
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
                    backgroundColor: AdminDashboardStyles.primary,
                    child: Text(
                      widget.student.name.isNotEmpty
                          ? widget.student.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.student.name,
                    style: const TextStyle(
                      color: AdminDashboardStyles.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.student.college.isNotEmpty
                        ? widget.student.college
                        : 'Student',
                    style: const TextStyle(
                      color: AdminDashboardStyles.textLight,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    final studentData = _detailedStudentData;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Student Statistics',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          isSmallScreen
              ? Column(
                  children: [
                    _buildStatItem(
                      Icons.trending_up,
                      'Job Readiness',
                      '${(widget.student.jobReadiness ?? 0).toInt()}%',
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.school,
                          'CGPA',
                          widget.student.cgpa?.toStringAsFixed(1) ?? 'N/A',
                          const Color(0xFF3B82F6),
                        ),
                        _buildStatItem(
                          Icons.percent,
                          'Percentage',
                          '${(widget.student.percentage ?? 0).toInt()}%',
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.trending_up,
                      'Job Readiness',
                      '${(widget.student.jobReadiness ?? 0).toInt()}%',
                      const Color(0xFF10B981),
                    ),
                    _buildStatItem(
                      Icons.school,
                      'CGPA',
                      widget.student.cgpa?.toStringAsFixed(1) ?? 'N/A',
                      const Color(0xFF3B82F6),
                    ),
                    _buildStatItem(
                      Icons.percent,
                      'Percentage',
                      '${(widget.student.percentage ?? 0).toInt()}%',
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'active':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
      case 'suspended':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAcademicCard() {
    final studentData = _detailedStudentData;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Student ID',
            widget.student.studentId ?? widget.student.id ?? 'N/A',
          ),
          _buildInfoRow('Username', studentData?['username'] ?? 'N/A'),
          _buildInfoRow(
            'College',
            studentData?['institute'] ??
                widget.student.college ??
                'Not specified',
          ),
          _buildInfoRow('Course', studentData?['course'] ?? 'Not specified'),
          _buildInfoRow(
            'Major',
            studentData?['major'] ?? widget.student.branch ?? 'Not specified',
          ),
          _buildInfoRow(
            'Year of Study',
            studentData?['yearOfStudy']?.toString() ??
                widget.student.yearOfStudy ??
                'Not specified',
          ),
          _buildInfoRow(
            'CGPA',
            widget.student.cgpa?.toStringAsFixed(2) ?? 'Not available',
          ),
          _buildInfoRow(
            'Percentage',
            widget.student.percentage?.toStringAsFixed(1) ?? 'Not available',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final studentData = _detailedStudentData;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Full Name', _getFullName(studentData)),
          _buildInfoRow(
            'Date of Birth',
            studentData?['dob'] != null
                ? _formatDate(studentData!['dob'])
                : 'Not specified',
          ),
          _buildInfoRow('Gender', studentData?['gender'] ?? 'Not specified'),
          _buildInfoRow('Address', studentData?['address'] ?? 'Not specified'),
          _buildInfoRow('City', studentData?['city'] ?? 'Not specified'),
          _buildInfoRow(
            'District',
            studentData?['district'] ?? 'Not specified',
          ),
          _buildInfoRow('Zipcode', studentData?['zipcode'] ?? 'Not specified'),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    final studentData = _detailedStudentData;
    final skills = studentData?['skills'] as List<dynamic>? ?? [];
    final projects = studentData?['projects'] as List<dynamic>? ?? [];
    final achievements = studentData?['achievements'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Achievements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Skills Section
          if (skills.isNotEmpty) ...[
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.take(10).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AdminDashboardStyles.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AdminDashboardStyles.primary.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Text(
                    '${skill['name'] ?? 'Skill'} (${skill['level'] ?? 'Intermediate'})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Projects Section
          if (projects.isNotEmpty) ...[
            const Text(
              'Projects',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textLight,
              ),
            ),
            const SizedBox(height: 8),
            ...projects.take(3).map((project) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['title'] ?? 'Project',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (project['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        project['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Achievements Section
          if (achievements.isNotEmpty) ...[
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textLight,
              ),
            ),
            const SizedBox(height: 8),
            ...achievements.take(3).map((achievement) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'] ?? 'Achievement',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (achievement['issuer'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'by ${achievement['issuer']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          if (skills.isEmpty && projects.isEmpty && achievements.isEmpty)
            const Text(
              'No skills or achievements available',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final studentData = _detailedStudentData;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
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
            subtitle: Text(
              studentData?['email'] ?? widget.student.email ?? 'Not available',
            ),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text(studentData?['phone'] ?? 'Not available'),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('College'),
            subtitle: Text(
              studentData?['institute'] ??
                  widget.student.college ??
                  'Not specified',
            ),
            trailing: const Icon(Icons.info_outline, size: 20),
            onTap: () {},
          ),
          if (studentData?['linkedin'] != null)
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('LinkedIn'),
              subtitle: Text(studentData!['linkedin']),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () {},
            ),
          if (studentData?['github'] != null)
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: Text(studentData!['github']),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () {},
            ),
        ],
      ),
    );
  }

  String _getFullName(Map<String, dynamic>? studentData) {
    final firstName = studentData?['firstName'] ?? '';
    final lastName = studentData?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Not specified' : fullName;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
