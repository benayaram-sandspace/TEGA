import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/company_specific_questions_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/student_ai_interview_page.dart';

class PlacementPrepPage extends StatefulWidget {
  const PlacementPrepPage({super.key});

  @override
  State<PlacementPrepPage> createState() => _PlacementPrepPageState();
}

class _PlacementPrepPageState extends State<PlacementPrepPage> {
  bool _isLoading = true;
  Map<String, dynamic> _placementData = {};

  @override
  void initState() {
    super.initState();
    _loadPlacementData();
  }

  Future<void> _loadPlacementData() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();

      // Fetch placement-specific data
      final dashboardData = await api.getDashboard(headers);

      if (mounted) {
        setState(() {
          _placementData = dashboardData['placementProgress'] ?? {};
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

  void _handleTakeSkillAssessment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skill Assessment - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF6B5FFF),
      ),
    );
  }

  void _handleCompanySpecificRevision() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CompanySpecificQuestionsPage(),
      ),
    );
  }

  void _handleStartMockInterview() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AiInterviewPage()));
  }

  void _handleSolveCodingProblems() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coding Problems - Under Development!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF6B5FFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
      );
    }

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
          // Header Section
          _buildHeader(isDesktop, isTablet),
          SizedBox(
            height: isDesktop
                ? 24
                : isTablet
                ? 20
                : 16,
          ),

          // Stats Cards - Compact Design
          _buildCompactStats(isDesktop, isTablet),
          SizedBox(
            height: isDesktop
                ? 24
                : isTablet
                ? 20
                : 16,
          ),

          // Quick Actions Section Header
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: isDesktop ? 6 : 4),
          Text(
            'Choose an action to boost your placement readiness',
            style: TextStyle(
              fontSize: isDesktop
                  ? 13
                  : isTablet
                  ? 12
                  : 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: isDesktop
                ? 20
                : isTablet
                ? 16
                : 14,
          ),

          // Quick Actions - Large Cards
          _buildQuickActionCards(isDesktop, isTablet),
          SizedBox(
            height: isDesktop
                ? 24
                : isTablet
                ? 20
                : 16,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 20
            : isTablet
            ? 18
            : 16,
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
            blurRadius: isDesktop ? 20 : 15,
            offset: Offset(0, isDesktop ? 8 : 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: isDesktop
                  ? 32
                  : isTablet
                  ? 28
                  : 24,
            ),
          ),
          SizedBox(
            width: isDesktop
                ? 16
                : isTablet
                ? 14
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Placement Preparation',
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 24
                          : isTablet
                          ? 20
                          : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 2),
                Text(
                  'Track your progress and ace your interviews',
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(bool isDesktop, bool isTablet) {
    final stats = [
      {
        'value': '${_placementData['learningStreak'] ?? 0}',
        'label': 'Day Streak',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'value': '${_placementData['problemsSolved'] ?? 0}',
        'label': 'Problems Solved',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'value': '${_placementData['mockInterviews'] ?? 0}',
        'label': 'Mock Interviews',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFFFFBE0B),
      },
      {
        'value': '${_placementData['totalPoints'] ?? 0}',
        'label': 'Total Points',
        'icon': Icons.stars_rounded,
        'color': const Color(0xFF6B5FFF),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop
            ? 4
            : isTablet
            ? 4
            : 2,
        crossAxisSpacing: isDesktop
            ? 10
            : isTablet
            ? 8
            : 6,
        mainAxisSpacing: isDesktop
            ? 10
            : isTablet
            ? 8
            : 6,
        childAspectRatio: isDesktop
            ? 1.6
            : isTablet
            ? 1.4
            : 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildCompactStatCard(
          value: stat['value'] as String,
          label: stat['label'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildCompactStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 12
            : isTablet
            ? 10
            : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isDesktop
              ? 12
              : isTablet
              ? 10
              : 8,
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: isDesktop ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: isDesktop ? 6 : 4,
            offset: Offset(0, isDesktop ? 2 : 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isDesktop ? 32 : 28),
          SizedBox(height: isDesktop ? 12 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isDesktop ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(bool isDesktop, bool isTablet) {
    final actions = [
      {
        'title': 'Take Skill Assessment',
        'description': 'Evaluate your technical skills',
        'icon': Icons.assessment_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        'onTap': _handleTakeSkillAssessment,
      },
      {
        'title': 'Company Specific Revision',
        'description': 'Practice company-wise questions',
        'icon': Icons.business_center_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        ),
        'onTap': _handleCompanySpecificRevision,
      },
      {
        'title': 'Start Mock Interview',
        'description': 'AI-powered interview practice',
        'icon': Icons.videocam_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFee0979), Color(0xFFff6a00)],
        ),
        'onTap': _handleStartMockInterview,
      },
      {
        'title': 'Solve Coding Problems',
        'description': 'Sharpen your coding skills',
        'icon': Icons.code_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF0575E6), Color(0xFF021B79)],
        ),
        'onTap': _handleSolveCodingProblems,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop
            ? 2
            : isTablet
            ? 2
            : 1,
        crossAxisSpacing: isDesktop
            ? 16
            : isTablet
            ? 14
            : 12,
        mainAxisSpacing: isDesktop
            ? 16
            : isTablet
            ? 14
            : 12,
        childAspectRatio: isDesktop
            ? 3.0
            : isTablet
            ? 2.5
            : 3.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(
          title: action['title'] as String,
          description: action['description'] as String,
          icon: action['icon'] as IconData,
          gradient: action['gradient'] as Gradient,
          onTap: action['onTap'] as VoidCallback,
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: isDesktop ? 16 : 12,
                offset: Offset(0, isDesktop ? 8 : 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -25,
                right: -25,
                child: Container(
                  width: isDesktop ? 80 : 60,
                  height: isDesktop ? 80 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: isDesktop ? 60 : 50,
                  height: isDesktop ? 60 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(
                  isDesktop
                      ? 20
                      : isTablet
                      ? 16
                      : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        isDesktop
                            ? 12
                            : isTablet
                            ? 10
                            : 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 14 : 12,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: isDesktop ? 1.5 : 1.2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isDesktop
                            ? 28
                            : isTablet
                            ? 26
                            : 24,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop
                          ? 16
                          : isTablet
                          ? 14
                          : 12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 16
                                  : isTablet
                                  ? 15
                                  : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isDesktop ? 4 : 2),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 12
                                  : isTablet
                                  ? 11
                                  : 10,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.2,
                            ),
                            maxLines: isDesktop ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: isDesktop
                          ? 18
                          : isTablet
                          ? 16
                          : 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
