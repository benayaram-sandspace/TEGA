import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

// Helper class to organize the data for each card.
class _StatInfo {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatInfo(this.title, this.value, this.icon, this.color);
}

// Converted to a StatefulWidget to handle animations.
class StatsGrid extends StatefulWidget {
  const StatsGrid({super.key});

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> with TickerProviderStateMixin {
  // Lists to hold the controllers and animations for each card.
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  final List<_StatInfo> _stats = const [
    _StatInfo(
      'Enrolled Students',
      '3,125',
      Icons.people_outline,
      DashboardStyles.primary,
    ),
    _StatInfo('Engagement', '72%', Icons.timeline, DashboardStyles.accentGreen),
    _StatInfo(
      'AI',
      'course',
      Icons.school_outlined,
      DashboardStyles.accentOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize a controller for each card.
    _animationControllers = List.generate(
      _stats.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 450),
        vsync: this,
      ),
    );

    // Create a curved animation for each controller for the "pop-in" effect.
    _scaleAnimations = _animationControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
    }).toList();

    // Start the animations with a stagger.
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
    // IMPORTANT: Dispose all controllers to prevent memory leaks.
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stats.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 4 / 5,
      ),
      itemBuilder: (context, index) {
        final stat = _stats[index];
        // The card is now wrapped in a ScaleTransition widget.
        return ScaleTransition(
          scale: _scaleAnimations[index],
          child: _buildStatCard(stat.title, stat.value, stat.icon, stat.color),
        );
      },
    );
  }

  // NO CHANGES HERE: This is the fully beautified card from our last step.
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: DashboardStyles.statValue),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: DashboardStyles.statTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
