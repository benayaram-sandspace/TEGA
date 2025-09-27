import 'package:flutter/material.dart';
nimport 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/widgets/admin_analytics_chart.dart';

class _StatCardInfo {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCardInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}

class DashboardHomeTab extends StatefulWidget {
  final AuthService authService;

  const DashboardHomeTab({super.key, required this.authService});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab>
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  int? _pressedIndex;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  static final Map<String, Map<String, String>> _translations = {
    'EN': {
      'welcome_back': 'Welcome Back,',
      'total_colleges': 'Total Colleges',
      'total_students': 'Total Students',
      'content_modules': 'Content Modules',
      'support_tickets': 'Support Tickets',
    },
  };

  String _tr(String key) => _translations['EN']![key] ?? key;

  late final List<_StatCardInfo> _statItems;

  @override
  void initState() {
    super.initState();

    _statItems = [
      _StatCardInfo(
        icon: Icons.school_rounded,
        title: _tr('total_colleges'),
        value: '150',
        color: AdminDashboardStyles.primary,
      ),
      _StatCardInfo(
        icon: Icons.people_rounded,
        title: _tr('total_students'),
        value: '12,500',
        color: AdminDashboardStyles.accentGreen,
      ),
      _StatCardInfo(
        icon: Icons.content_copy_rounded,
        title: _tr('content_modules'),
        value: '85',
        color: AdminDashboardStyles.accentBlue,
      ),
      _StatCardInfo(
        icon: Icons.support_agent_rounded,
        title: _tr('support_tickets'),
        value: '25',
        color: AdminDashboardStyles.accentRed,
      ),
    ];

    _animationControllers = List.generate(
      _statItems.length,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _animationControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 150), () {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildCardsGridView(),
          const SizedBox(height: 32),
          AdminAnalyticsChart(animationController: _animationControllers.first),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String adminName = widget.authService.currentUser?.name ?? 'Admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AdminDashboardStyles.primary,
                    AdminDashboardStyles.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AdminDashboardStyles.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_tr('welcome_back')} $adminName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AdminDashboardStyles.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16, 
                      color: AdminDashboardStyles.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.3);
  }

  Widget _buildCardsGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: _statItems.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildStatCard(item: _statItems[index], index: index);
      },
    );
  }

  List<Color> _getGradientColors(Color baseColor) {
    return [baseColor.withOpacity(0.8), baseColor];
  }

  Widget _buildStatCard({required _StatCardInfo item, required int index}) {
    final isHovered = _hoveredIndex == index;
    final isPressed = _pressedIndex == index;
    final gradientColors = _getGradientColors(item.color);

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
              onTapUp: (_) => setState(() => _pressedIndex = null),
              onTapCancel: () => setState(() => _pressedIndex = null),
              onTap: () {},
              child: AnimatedContainer(
                duration: AdminDashboardStyles.shortAnimation,
                curve: AdminDashboardStyles.defaultCurve,
                transform: Matrix4.identity()
                  ..scale(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isHovered ? 24 : 20),
                  boxShadow: [
                    if (isHovered)
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isHovered ? 24 : 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background decoration
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon, 
                                size: 32, 
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
}