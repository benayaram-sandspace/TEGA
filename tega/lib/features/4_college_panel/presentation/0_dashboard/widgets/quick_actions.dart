import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/1_student_management/add_college_students.dart';

class QuickActions extends StatefulWidget {
  const QuickActions({super.key});

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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    final isHovered = _hoveredIndex == index;
    final isPressed = _pressedIndex == index;

    // Define gradient colors based on the action
    final gradientColors = _getGradientColors(index);

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
                onTap();
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isHovered ? 56 : 52,
                              height: isHovered ? 56 : 52,
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
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    icon,
                                    key: ValueKey(isHovered),
                                    color: Colors.white,
                                    size: isHovered ? 28 : 26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isHovered ? 14 : 13,
                                fontWeight: isHovered
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                letterSpacing: 0.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isHovered)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(top: 6),
                                height: 2,
                                width: 30,
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
  }

  List<Color> _getGradientColors(int index) {
    switch (index) {
      case 0:
        return [
          DashboardStyles.primary,
          DashboardStyles.primary.withOpacity(0.8),
        ];
      case 1:
        return [
          DashboardStyles.accentGreen,
          DashboardStyles.accentGreen.withOpacity(0.8),
        ];
      case 2:
        return [
          DashboardStyles.accentOrange,
          DashboardStyles.accentOrange.withOpacity(0.8),
        ];
      case 3:
        return [
          DashboardStyles.accentPurple,
          DashboardStyles.accentPurple.withOpacity(0.8),
        ];
      default:
        return [Colors.blue, Colors.blue.withOpacity(0.8)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 24.0;
    final spacing = 14.0;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final cardWidth = (availableWidth - spacing) / 2;
    final cardHeight = cardWidth * 0.85;

    final actions = [
      {
        'icon': Icons.person_add_alt_1_rounded,
        'label': 'Add Student',
        'color': DashboardStyles.primary,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
        },
      },
      {
        'icon': Icons.quiz_rounded,
        'label': 'Create Test',
        'color': DashboardStyles.accentGreen,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create Test feature coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      },
      {
        'icon': Icons.event_note_rounded,
        'label': 'Schedule',
        'color': DashboardStyles.accentOrange,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule feature coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      },
      {
        'icon': Icons.mail_rounded,
        'label': 'Messages',
        'color': DashboardStyles.accentPurple,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Messages feature coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium header with animations
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DashboardStyles.primary,
                                DashboardStyles.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: DashboardStyles.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: DashboardStyles.sectionTitle,
                            ),
                            Text(
                              'Access frequently used features',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.purple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apps_rounded,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '4 Actions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
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
        ),
        const SizedBox(height: 24),

        // 2x2 Grid with refined layout
        SizedBox(
          height: cardHeight * 2 + spacing,
          child: Column(
            children: [
              // First row
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: actions[0]['icon'] as IconData,
                        label: actions[0]['label'] as String,
                        color: actions[0]['color'] as Color,
                        onTap: actions[0]['onTap'] as VoidCallback,
                        index: 0,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: actions[1]['icon'] as IconData,
                        label: actions[1]['label'] as String,
                        color: actions[1]['color'] as Color,
                        onTap: actions[1]['onTap'] as VoidCallback,
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
                      child: _buildQuickActionCard(
                        icon: actions[2]['icon'] as IconData,
                        label: actions[2]['label'] as String,
                        color: actions[2]['color'] as Color,
                        onTap: actions[2]['onTap'] as VoidCallback,
                        index: 2,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: actions[3]['icon'] as IconData,
                        label: actions[3]['label'] as String,
                        color: actions[3]['color'] as Color,
                        onTap: actions[3]['onTap'] as VoidCallback,
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
