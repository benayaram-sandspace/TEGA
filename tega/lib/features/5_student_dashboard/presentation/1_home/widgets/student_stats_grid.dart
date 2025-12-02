import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

class _StatInfo {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatInfo(this.title, this.value, this.icon, this.color);
}

class StudentStatsGrid extends StatefulWidget {
  const StudentStatsGrid({super.key});

  @override
  State<StudentStatsGrid> createState() => _StudentStatsGridState();
}

class _StudentStatsGridState extends State<StudentStatsGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  List<_StatInfo> _stats = [];
  bool _isLoadingStats = true;
  int? _hoveredIndex;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();

    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
        .toList();

    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();
      final dashData = await api.getDashboard(headers);

      // Fetch enrolled courses count
      final enrolledCourses = await api.getEnrolledCourses(headers);
      final enrolledCount = enrolledCourses.length;

      if (!mounted) return;

      final userProgress = dashData['userProgress'] ?? {};

      if (!mounted) return;
      setState(() {
        _stats = [
          _StatInfo(
            'Completed Courses',
            '${userProgress['completedCourses'] ?? 0}',
            Icons.check_circle_outline_rounded,
            const Color(0xFF6B5FFF),
          ),
          _StatInfo(
            'In Progress',
            '$enrolledCount',
            Icons.pending_actions_rounded,
            const Color(0xFF4CAF50),
          ),
          _StatInfo(
            'Certifications',
            '${userProgress['certificates'] ?? 0}',
            Icons.workspace_premium_rounded,
            const Color(0xFFFF9800),
          ),
          _StatInfo(
            'Study Hours',
            '${userProgress['totalHours'] ?? 0}',
            Icons.access_time_rounded,
            const Color(0xFF2196F3),
          ),
        ];
        _isLoadingStats = false;
      });

      // Start animations with stagger
      Future.delayed(Duration.zero, () {
        for (int i = 0; i < _animationControllers.length; i++) {
          Future.delayed(Duration(milliseconds: i * 100), () {
            if (mounted) {
              _animationControllers[i].forward();
            }
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stats = [
          const _StatInfo(
            'Completed Courses',
            '0',
            Icons.check_circle_outline_rounded,
            Color(0xFF6B5FFF),
          ),
          const _StatInfo(
            'In Progress',
            '0',
            Icons.pending_actions_rounded,
            Color(0xFF4CAF50),
          ),
          const _StatInfo(
            'Certifications',
            '0',
            Icons.workspace_premium_rounded,
            Color(0xFFFF9800),
          ),
          const _StatInfo(
            'Study Hours',
            '0',
            Icons.access_time_rounded,
            Color(0xFF2196F3),
          ),
        ];
        _isLoadingStats = false;
      });

      Future.delayed(Duration.zero, () {
        for (int i = 0; i < _animationControllers.length; i++) {
          Future.delayed(Duration(milliseconds: i * 100), () {
            if (mounted) {
              _animationControllers[i].forward();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Color> _getGradientColors(int index) {
    switch (index) {
      case 0:
        return [
          const Color(0xFF6B5FFF),
          const Color(0xFF6B5FFF).withOpacity(0.8),
        ];
      case 1:
        return [
          const Color(0xFF4CAF50),
          const Color(0xFF4CAF50).withOpacity(0.8),
        ];
      case 2:
        return [
          const Color(0xFFFF9800),
          const Color(0xFFFF9800).withOpacity(0.8),
        ];
      case 3:
        return [
          const Color(0xFF2196F3),
          const Color(0xFF2196F3).withOpacity(0.8),
        ];
      default:
        return [Colors.blue, Colors.blue.withOpacity(0.8)];
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int index,
  ) {
    final isHovered = _hoveredIndex == index;
    final isPressed = _pressedIndex == index;
    final gradientColors = _getGradientColors(index);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600;
        final isDesktop = screenWidth >= 1024;
        final isLargeDesktop = screenWidth >= 1440;
        final isSmallScreen = screenWidth < 400;

        return AnimatedBuilder(
          animation: _scaleAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressedIndex = index),
                  onTapUp: (_) {
                    setState(() => _pressedIndex = null);
                    // Add tap functionality here if needed
                  },
                  onTapCancel: () => setState(() => _pressedIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()
                      ..scale(isPressed ? 0.94 : (isHovered ? 1.03 : 1.0))
                      ..rotateZ(isHovered ? 0.005 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(
                          isHovered ? 20 : 18,
                        ),
                        boxShadow: [
                          if (isHovered) ...[
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: color.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                              spreadRadius: 4,
                            ),
                          ] else ...[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            left: -30,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          // Glass morphism layer
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                isHovered ? 20 : 18,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: EdgeInsets.all(
                              isLargeDesktop
                                  ? 16
                                  : isDesktop
                                  ? 14
                                  : isTablet
                                  ? 12
                                  : isSmallScreen
                                  ? 8
                                  : 10,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: isHovered
                                        ? (isLargeDesktop
                                              ? 56
                                              : isDesktop
                                              ? 52
                                              : isTablet
                                              ? 48
                                              : isSmallScreen
                                              ? 36
                                              : 40)
                                        : (isLargeDesktop
                                              ? 52
                                              : isDesktop
                                              ? 48
                                              : isTablet
                                              ? 44
                                              : isSmallScreen
                                              ? 32
                                              : 36),
                                    height: isHovered
                                        ? (isLargeDesktop
                                              ? 56
                                              : isDesktop
                                              ? 52
                                              : isTablet
                                              ? 48
                                              : isSmallScreen
                                              ? 36
                                              : 40)
                                        : (isLargeDesktop
                                              ? 52
                                              : isDesktop
                                              ? 48
                                              : isTablet
                                              ? 44
                                              : isSmallScreen
                                              ? 32
                                              : 36),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Icon(
                                          icon,
                                          key: ValueKey(isHovered),
                                          color: Colors.white,
                                          size: isHovered
                                              ? (isLargeDesktop
                                                    ? 28
                                                    : isDesktop
                                                    ? 26
                                                    : isTablet
                                                    ? 24
                                                    : isSmallScreen
                                                    ? 18
                                                    : 20)
                                              : (isLargeDesktop
                                                    ? 26
                                                    : isDesktop
                                                    ? 24
                                                    : isTablet
                                                    ? 22
                                                    : isSmallScreen
                                                    ? 16
                                                    : 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: isLargeDesktop
                                      ? 12
                                      : isDesktop
                                      ? 10
                                      : isTablet
                                      ? 8
                                      : 6,
                                ),
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isHovered
                                            ? (isLargeDesktop
                                                  ? 32
                                                  : isDesktop
                                                  ? 28
                                                  : isTablet
                                                  ? 26
                                                  : isSmallScreen
                                                  ? 20
                                                  : 22)
                                            : (isLargeDesktop
                                                  ? 30
                                                  : isDesktop
                                                  ? 26
                                                  : isTablet
                                                  ? 24
                                                  : isSmallScreen
                                                  ? 18
                                                  : 20),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 2.0 : 4.0,
                                        ),
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isHovered
                                                ? (isLargeDesktop
                                                      ? 16
                                                      : isDesktop
                                                      ? 15
                                                      : isTablet
                                                      ? 14
                                                      : isSmallScreen
                                                      ? 10
                                                      : 12)
                                                : (isLargeDesktop
                                                      ? 15
                                                      : isDesktop
                                                      ? 14
                                                      : isTablet
                                                      ? 13
                                                      : isSmallScreen
                                                      ? 9
                                                      : 11),
                                            fontWeight: isHovered
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            letterSpacing: 0.4,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                offset: const Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isHovered)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(top: 3),
                                    height: 2,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Shine effect overlay
                          if (isHovered)
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: const Alignment(-1, -0.5),
                                    end: const Alignment(1, 0.5),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    final isSmallScreen = screenWidth < 400;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive spacing and sizing
        final spacing = isLargeDesktop
            ? 20.0
            : isDesktop
            ? 18.0
            : isTablet
            ? 16.0
            : isSmallScreen
            ? 8.0
            : 12.0;

        final horizontalPadding = isLargeDesktop
            ? 0.0
            : isDesktop
            ? 0.0
            : isTablet
            ? 0.0
            : isSmallScreen
            ? 8.0
            : 10.0;

        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        final cardWidth = (availableWidth - spacing) / 2;

        // Responsive card height with better aspect ratio
        final cardHeight =
            cardWidth *
            (isLargeDesktop
                ? 0.8
                : isDesktop
                ? 0.78
                : isTablet
                ? 0.75
                : isSmallScreen
                ? 0.7
                : 0.72);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            height: cardHeight * 2 + spacing,
            child: Column(
              children: [
                // First row
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          _stats[0].title,
                          _stats[0].value,
                          _stats[0].icon,
                          _stats[0].color,
                          0,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: _buildStatCard(
                          _stats[1].title,
                          _stats[1].value,
                          _stats[1].icon,
                          _stats[1].color,
                          1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                // Second row
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          _stats[2].title,
                          _stats[2].value,
                          _stats[2].icon,
                          _stats[2].color,
                          2,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: _buildStatCard(
                          _stats[3].title,
                          _stats[3].value,
                          _stats[3].icon,
                          _stats[3].color,
                          3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
