import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class _StatInfo {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatInfo(this.title, this.value, this.icon, this.color);
}

class StatsGrid extends StatefulWidget {
  final int totalStudents;
  final int activeStudents;
  final int recentRegistrations;
  final int uniqueCourses;

  const StatsGrid({
    super.key,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.recentRegistrations = 0,
    this.uniqueCourses = 0,
  });

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  List<_StatInfo> get _stats => [
    _StatInfo(
      'Total Students',
      widget.totalStudents.toString(),
      Icons.people_rounded,
      const Color(0xFF3B82F6),
    ),
    _StatInfo(
      'Active Students',
      widget.activeStudents.toString(),
      Icons.person_outline,
      const Color(0xFF10B981),
    ),
    _StatInfo(
      'Recent Registrations',
      widget.recentRegistrations.toString(),
      Icons.access_time_rounded,
      const Color(0xFF8B5CF6),
    ),
    _StatInfo(
      'Unique Courses',
      widget.uniqueCourses.toString(),
      Icons.book_rounded,
      const Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with 4 controllers for 4 stats
    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 450),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
    }).toList();

    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) {
          _animationControllers[i].forward();
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

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: List.generate(_stats.length, (index) {
        final stat = _stats[index];
        return ScaleTransition(
          scale: _scaleAnimations[index],
          child: _buildStatCard(stat.title, stat.value, stat.icon, stat.color),
        );
      }),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.cardBackground,
            Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.04)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(value, style: DashboardStyles.statValue),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    title,
                    style: DashboardStyles.statTitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
