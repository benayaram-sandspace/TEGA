import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/company_specific_questions_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/skill_assessment_modules_page.dart';
import 'package:tega/core/services/placement_prep_cache_service.dart';
// import removed: mock interview is locked for now

class PlacementPrepPage extends StatefulWidget {
  const PlacementPrepPage({super.key});

  @override
  State<PlacementPrepPage> createState() => _PlacementPrepPageState();
}

class _PlacementPrepPageState extends State<PlacementPrepPage> {
  bool _isLoading = true;
  final PlacementPrepCacheService _cacheService = PlacementPrepCacheService();

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadPlacementData();
  }

  Future<void> _loadPlacementData({bool forceRefresh = false}) async {
    try {
      // Try to load from cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedData = await _cacheService.getPlacementPrepData();
        if (cachedData != null && mounted) {
          setState(() {
            _isLoading = false;
          });
          // Still fetch in background to update cache
          _fetchPlacementDataInBackground();
          return;
        }
      }

      // Fetch from API
      await _fetchPlacementDataInBackground();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPlacementDataInBackground() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();

      // Fetch placement-specific data
      final data = await api.getDashboard(headers);
      
      // Cache the data
      await _cacheService.setPlacementPrepData(data ?? {});

      if (mounted) {
        setState(() {
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SkillAssessmentModulesPage(),
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
    // Locked for now - same behavior as skill assessment
    _handleTakeSkillAssessment();
  }

  // Removed: Solve Coding Problems action is no longer shown

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern Header with Hero Section
          _buildModernHeader(),

          // Main Actions Section
          _buildMainActionsSection(),

          // Bottom Spacing
          SliverToBoxAdapter(
            child: SizedBox(
              height: isLargeDesktop
                  ? 48
                  : isDesktop
                  ? 40
                  : isTablet
                  ? 32
                  : isSmallScreen
                  ? 20
                  : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
          vertical: isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5FFF), Color(0xFF9C88FF), Color(0xFFB19CD9)],
          ),
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 20
                : isSmallScreen
                ? 12
                : 16,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5FFF).withOpacity(0.3),
              blurRadius: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 8
                  : 12,
              offset: Offset(
                0,
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 8
                    : isTablet
                    ? 6
                    : isSmallScreen
                    ? 3
                    : 4,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 18
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: isLargeDesktop
                    ? 36
                    : isDesktop
                    ? 28
                    : isTablet
                    ? 26
                    : isSmallScreen
                    ? 20
                    : 24,
              ),
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            Expanded(
              child: Text(
                'Ready to land your dream job?',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 14
                      : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed progress stats section

  Widget _buildMainActionsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice & Improve',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            _buildModernActionCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionCards() {
    final actions = [
      {
        'title': 'Take Skill Assessment',
        'description':
            'Evaluate your technical skills with comprehensive tests',
        'icon': Icons.assessment_rounded,
        'color': const Color(0xFF667eea),
        'onTap': _handleTakeSkillAssessment,
        'status': 'Available',
        'isAvailable': true,
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
        'status': 'Coming Soon',
        'isAvailable': false,
      },
    ];

    return Column(
      children: actions.map((action) {
        return Container(
          margin: EdgeInsets.only(
            bottom: action == actions.last
                ? 0
                : (isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 10
                    : 12),
          ),
          child: _buildModernActionCard(
            title: action['title'] as String,
            description: action['description'] as String,
            icon: action['icon'] as IconData,
            color: action['color'] as Color,
            onTap: action['onTap'] as VoidCallback,
            status: action['status'] as String,
            isAvailable: action['isAvailable'] as bool,
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 14
              : isSmallScreen
              ? 10
              : 12,
        ),
        child: Container(
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 10
                    : isSmallScreen
                    ? 6
                    : 8,
                offset: Offset(
                  0,
                  isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 4
                      : isTablet
                      ? 3
                      : isSmallScreen
                      ? 2
                      : 2,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 10
                        : isSmallScreen
                        ? 8
                        : 9,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isLargeDesktop
                      ? 36
                      : isDesktop
                      ? 28
                      : isTablet
                      ? 26
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 8
                    : 12,
              ),
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
                              fontSize: isLargeDesktop
                                  ? 22
                                  : isDesktop
                                  ? 20
                                  : isTablet
                                  ? 18
                                  : isSmallScreen
                                  ? 14
                                  : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: isLargeDesktop || isDesktop
                                ? 3
                                : isTablet
                                ? 2
                                : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeDesktop
                                ? 10
                                : isDesktop
                                ? 8
                                : isTablet
                                ? 7
                                : isSmallScreen
                                ? 5
                                : 6,
                            vertical: isLargeDesktop
                                ? 6
                                : isDesktop
                                ? 4
                                : isTablet
                                ? 3.5
                                : isSmallScreen
                                ? 2
                                : 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 8
                                  : isTablet
                                  ? 7
                                  : isSmallScreen
                                  ? 5
                                  : 6,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: isLargeDesktop
                                  ? 12
                                  : isDesktop
                                  ? 11
                                  : isTablet
                                  ? 10
                                  : isSmallScreen
                                  ? 8
                                  : 9,
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: isLargeDesktop
                          ? 8
                          : isDesktop
                          ? 6
                          : isTablet
                          ? 5
                          : isSmallScreen
                          ? 3
                          : 4,
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 16
                            : isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 11
                            : 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: isLargeDesktop || isDesktop
                          ? 4
                          : isTablet
                          ? 3
                          : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 10
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Icon(
                isAvailable
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_rounded,
                color: isAvailable ? color : Colors.grey[400],
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 14
                    : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
