import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/pages/admin_screens/admin_related_pages/widgets/admin_analytics_chart.dart';
import 'package:tega/services/auth_service.dart';

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
        color: Colors.blue,
      ),
      _StatCardInfo(
        icon: Icons.people_rounded,
        title: _tr('total_students'),
        value: '12,500',
        color: Colors.green,
      ),
      _StatCardInfo(
        icon: Icons.content_copy_rounded,
        title: _tr('content_modules'),
        value: '85',
        color: Colors.orange,
      ),
      _StatCardInfo(
        icon: Icons.support_agent_rounded,
        title: _tr('support_tickets'),
        value: '25',
        color: Colors.red,
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
          const SizedBox(height: 24),
          _buildCardsGridView(),
          const SizedBox(height: 24),
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
        Text(
          '${_tr('welcome_back')} $adminName!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCardsGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
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
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
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
                        color: item.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isHovered ? 24 : 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 28, color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
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
