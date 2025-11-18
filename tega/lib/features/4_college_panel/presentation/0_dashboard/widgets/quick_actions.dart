import 'package:flutter/material.dart';

class QuickActions extends StatefulWidget {
  final int totalStudents;
  final int activeStudents;
  final int recentRegistrations;
  final int uniqueCourses;

  const QuickActions({
    super.key,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.recentRegistrations = 0,
    this.uniqueCourses = 0,
  });

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions>
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  int? _pressedIndex;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

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
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
    required int index,
  }) {
    final isHovered = _hoveredIndex == index;
    final isPressed = _pressedIndex == index;

    // Define gradient colors based on the stat
    final gradientColors = _getGradientColors(index);

    return AnimatedBuilder(
      animation: _scaleAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[index].value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            cursor: SystemMouseCursors.basic,
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
                  borderRadius: BorderRadius.circular(isHovered ? 20 : 18),
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
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isHovered ? 40 : 36,
                                height: isHovered ? 40 : 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
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
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      icon,
                                      key: ValueKey(isHovered),
                                      color: color,
                                      size: isHovered ? 20 : 18,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 9,
                                      color: color,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _getTrendPercentage(index),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              value.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isHovered ? 24 : 22,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isHovered ? 11 : 10,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _calculateProgress(value, title),
                              minHeight: 3,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.6),
                              ),
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
        );
      },
    );
  }

  List<Color> _getGradientColors(int index) {
    switch (index) {
      case 0:
        return [
          const Color(0xFF3B82F6),
          const Color(0xFF3B82F6).withOpacity(0.8),
        ];
      case 1:
        return [
          const Color(0xFF10B981),
          const Color(0xFF10B981).withOpacity(0.8),
        ];
      case 2:
        return [
          const Color(0xFF8B5CF6),
          const Color(0xFF8B5CF6).withOpacity(0.8),
        ];
      case 3:
        return [
          const Color(0xFFF59E0B),
          const Color(0xFFF59E0B).withOpacity(0.8),
        ];
      default:
        return [Colors.blue, Colors.blue.withOpacity(0.8)];
    }
  }

  String _getTrendPercentage(int index) {
    switch (index) {
      case 0:
        return '12%';
      case 1:
        return '8%';
      case 2:
        return '5%';
      case 3:
        return '3%';
      default:
        return '0%';
    }
  }

  double _calculateProgress(int value, String title) {
    // Calculate progress based on title and value
    if (title == 'Total Students') {
      return (value / 100).clamp(0.0, 1.0);
    } else if (title == 'Active Students') {
      return (value / 50).clamp(0.0, 1.0);
    } else if (title == 'Recent Registrations') {
      return (value / 10).clamp(0.0, 1.0);
    } else if (title == 'Unique Courses') {
      return (value / 20).clamp(0.0, 1.0);
    }
    return 0.3;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final spacing = isMobile ? 12.0 : 14.0;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final cardWidth = (availableWidth - spacing) / 2;
    final cardHeight =
        cardWidth * 0.75; // Reduced height for more compact cards

    final stats = [
      {
        'icon': Icons.people_rounded,
        'title': 'Total Students',
        'value': widget.totalStudents,
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.person_outline,
        'title': 'Active Students',
        'value': widget.activeStudents,
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.access_time_rounded,
        'title': 'Recent Registrations',
        'value': widget.recentRegistrations,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.book_rounded,
        'title': 'Unique Courses',
        'value': widget.uniqueCourses,
        'color': const Color(0xFFF59E0B),
      },
    ];

    // 2x2 Grid for all screen sizes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: cardHeight * 2 + spacing,
          child: Column(
            children: [
              // First row
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: stats[0]['icon'] as IconData,
                        title: stats[0]['title'] as String,
                        value: stats[0]['value'] as int,
                        color: stats[0]['color'] as Color,
                        index: 0,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildStatCard(
                        icon: stats[1]['icon'] as IconData,
                        title: stats[1]['title'] as String,
                        value: stats[1]['value'] as int,
                        color: stats[1]['color'] as Color,
                        index: 1,
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
                        icon: stats[2]['icon'] as IconData,
                        title: stats[2]['title'] as String,
                        value: stats[2]['value'] as int,
                        color: stats[2]['color'] as Color,
                        index: 2,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildStatCard(
                        icon: stats[3]['icon'] as IconData,
                        title: stats[3]['title'] as String,
                        value: stats[3]['value'] as int,
                        color: stats[3]['color'] as Color,
                        index: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
