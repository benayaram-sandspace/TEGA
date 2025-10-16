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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern Header with Hero Section
          _buildModernHeader(isDesktop, isTablet),

          // Stats Overview Section
          _buildStatsOverview(isDesktop, isTablet),

          // Main Actions Section
          _buildMainActionsSection(isDesktop, isTablet),

          // Bottom Spacing
          SliverToBoxAdapter(child: SizedBox(height: isDesktop ? 40 : 32)),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        padding: EdgeInsets.all(
          isDesktop
              ? 32
              : isTablet
              ? 28
              : 24,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5FFF), Color(0xFF9C88FF), Color(0xFFB19CD9)],
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5FFF).withOpacity(0.3),
              blurRadius: isDesktop ? 20 : 16,
              offset: Offset(0, isDesktop ? 8 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: isDesktop ? 32 : 28,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Placement Prep',
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 2),
                      Text(
                        'Ready to land your dream job?',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: isDesktop ? 20 : 18,
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                  Expanded(
                    child: Text(
                      'Track your progress and boost your skills',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _buildModernStatsRow(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatsRow(bool isDesktop, bool isTablet) {
    final stats = [
      {
        'value': '${_placementData['learningStreak'] ?? 0}',
        'label': 'Day Streak',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF6B6B),
        'bgColor': const Color(0xFFFFF5F5),
      },
      {
        'value': '${_placementData['problemsSolved'] ?? 0}',
        'label': 'Problems Solved',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF4ECDC4),
        'bgColor': const Color(0xFFF0FFFE),
      },
      {
        'value': '${_placementData['mockInterviews'] ?? 0}',
        'label': 'Mock Interviews',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFFFFBE0B),
        'bgColor': const Color(0xFFFFFDF0),
      },
      {
        'value': '${_placementData['totalPoints'] ?? 0}',
        'label': 'Total Points',
        'icon': Icons.stars_rounded,
        'color': const Color(0xFF6B5FFF),
        'bgColor': const Color(0xFFF8F5FF),
      },
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stat == stats.last ? 0 : (isDesktop ? 12 : 8),
            ),
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            decoration: BoxDecoration(
              color: stat['bgColor'] as Color,
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
              border: Border.all(
                color: (stat['color'] as Color).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 12 : 10),
                  decoration: BoxDecoration(
                    color: stat['color'] as Color,
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: Colors.white,
                    size: isDesktop ? 24 : 20,
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : 8),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 2),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainActionsSection(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice & Improve',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _buildModernActionCards(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionCards(bool isDesktop, bool isTablet) {
    final actions = [
      {
        'title': 'Take Skill Assessment',
        'description':
            'Evaluate your technical skills with comprehensive tests',
        'icon': Icons.assessment_rounded,
        'color': const Color(0xFF667eea),
        'onTap': _handleTakeSkillAssessment,
        'status': 'Coming Soon',
        'isAvailable': false,
      },
      {
        'title': 'Company Specific Revision',
        'description': 'Practice questions tailored for specific companies',
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFF11998e),
        'onTap': _handleCompanySpecificRevision,
        'status': 'Available',
        'isAvailable': true,
      },
      {
        'title': 'Start Mock Interview',
        'description': 'AI-powered interview practice with real-time feedback',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFFee0979),
        'onTap': _handleStartMockInterview,
        'status': 'Available',
        'isAvailable': true,
      },
      {
        'title': 'Solve Coding Problems',
        'description': 'Sharpen your coding skills with algorithmic challenges',
        'icon': Icons.code_rounded,
        'color': const Color(0xFF0575E6),
        'onTap': _handleSolveCodingProblems,
        'status': 'Under Development',
        'isAvailable': false,
      },
    ];

    return Column(
      children: actions.map((action) {
        return Container(
          margin: EdgeInsets.only(
            bottom: action == actions.last ? 0 : (isDesktop ? 16 : 12),
          ),
          child: _buildModernActionCard(
            title: action['title'] as String,
            description: action['description'] as String,
            icon: action['icon'] as IconData,
            color: action['color'] as Color,
            onTap: action['onTap'] as VoidCallback,
            status: action['status'] as String,
            isAvailable: action['isAvailable'] as bool,
            isDesktop: isDesktop,
            isTablet: isTablet,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String status,
    required bool isAvailable,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isDesktop ? 12 : 8,
                offset: Offset(0, isDesktop ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                ),
                child: Icon(icon, color: color, size: isDesktop ? 28 : 24),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6,
                            vertical: isDesktop ? 4 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 8 : 6,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: isDesktop ? 10 : 9,
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 6 : 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 12 : 8),
              Icon(
                isAvailable
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_rounded,
                color: isAvailable ? color : Colors.grey[400],
                size: isDesktop ? 18 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
