import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/data/models/learning_activity_student_model.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class ActivityFeedSection extends StatelessWidget {
  final AnimationController animationController;
  final List<Activity> filteredActivities;
  final String selectedCategory;

  const ActivityFeedSection({
    super.key,
    required this.animationController,
    required this.filteredActivities,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: filteredActivities.isEmpty
          ? SizedBox(
              key: const ValueKey('empty-activity-feed'),
              height: 150,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 50,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No activities found for this filter.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              key: ValueKey(selectedCategory),
              children: List.generate(filteredActivities.length, (index) {
                final animation = CurvedAnimation(
                  parent: animationController,
                  curve: Interval(
                    (0.1 * index).clamp(0.0, 1.0),
                    (0.5 + 0.1 * index).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: _buildActivityCard(filteredActivities[index]),
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(activity.studentAvatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: DashboardStyles.textDark,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: activity.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' ${activity.title.split(' ').first.toLowerCase()} an activity',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timestamp,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, color: activity.color, size: 20),
          ),
        ],
      ),
    );
  }
}
