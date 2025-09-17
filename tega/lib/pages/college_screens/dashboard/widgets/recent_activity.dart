import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _ActivityInfo {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityInfo({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class RecentActivity extends StatefulWidget {
  const RecentActivity({super.key});

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _animationStarted = false;

  final List<_ActivityInfo> _activities = const [
    _ActivityInfo(
      title: 'John Smith submitted an assignment',
      time: '2 minutes ago',
      icon: Icons.assignment_turned_in_outlined,
      color: DashboardStyles.accentGreen,
    ),
    _ActivityInfo(
      title: 'New message from Emma Wilson',
      time: '15 minutes ago',
      icon: Icons.message_outlined,
      color: DashboardStyles.primary,
    ),
    _ActivityInfo(
      title: 'Quiz results available for Math 101',
      time: '1 hour ago',
      icon: Icons.quiz_outlined,
      color: DashboardStyles.accentOrange,
    ),
    _ActivityInfo(
      title: 'Sarah Johnson joined the class',
      time: '3 hours ago',
      icon: Icons.person_add_outlined,
      color: DashboardStyles.accentPurple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('recent-activity-card'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_animationStarted) {
          setState(() {
            _animationStarted = true;
            _animationController.forward();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity', style: DashboardStyles.sectionTitle),
            const SizedBox(height: 8),
            ...List.generate(_activities.length, (index) {
              return _buildAnimatedActivityItem(
                _activities[index],
                index,
                isLast: index == _activities.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedActivityItem(
    _ActivityInfo activity,
    int index, {
    bool isLast = false,
  }) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2 * index, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation),
        child: _buildActivityItem(activity, isLast: isLast),
      ),
    );
  }

  Widget _buildActivityItem(_ActivityInfo activity, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.icon, color: activity.color, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: DashboardStyles.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (!isLast) const Divider(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
