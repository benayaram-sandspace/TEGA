import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'insight_details_page.dart'; // Import the new page

// Helper class for insight data
class InsightInfo {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String priority;
  final Color priorityColor;
  final Color priorityTextColor;

  const InsightInfo({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.priority,
    required this.priorityColor,
    required this.priorityTextColor,
  });
}

class ActionableInsights extends StatefulWidget {
  const ActionableInsights({super.key});

  @override
  State<ActionableInsights> createState() => _ActionableInsightsState();
}

class _ActionableInsightsState extends State<ActionableInsights>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _animationStarted = false;

  final List<InsightInfo> _insights = const [
    InsightInfo(
      icon: Icons.school_outlined,
      iconColor: DashboardStyles.accentOrange,
      title: '5 students require academic advising',
      priority: 'High priority',
      priorityColor: DashboardStyles.priorityHighBg,
      priorityTextColor: DashboardStyles.priorityHighText,
    ),
    InsightInfo(
      icon: Icons.book_outlined,
      iconColor: DashboardStyles.primary,
      title: 'New curriculum update available',
      priority: 'Medium priority',
      priorityColor: DashboardStyles.priorityMediumBg,
      priorityTextColor: DashboardStyles.priorityMediumText,
    ),
    InsightInfo(
      icon: Icons.trending_up_outlined,
      iconColor: DashboardStyles.accentGreen,
      title: 'Enrollment trends for Q4 are available',
      priority: 'Low',
      priorityColor: DashboardStyles.priorityLowBg,
      priorityTextColor: DashboardStyles.priorityLowText,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
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
      key: const Key('actionable-insights-list'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_animationStarted) {
          setState(() {
            _animationStarted = true;
            _animationController.forward();
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actionable Insights',
            style: DashboardStyles.sectionTitle,
          ),
          const SizedBox(height: 16),
          ...List.generate(_insights.length, (index) {
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
                child: _buildInsightCard(_insights[index]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightCard(InsightInfo insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // MODIFICATION: onTap now navigates to the new details page
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InsightDetailsPage(insight: insight),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DashboardStyles.cardBackground,
                Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.02)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: insight.iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(insight.icon, color: insight.iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.title, style: DashboardStyles.insightTitle),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: insight.priorityColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        insight.priority,
                        style: DashboardStyles.priorityTag.copyWith(
                          color: insight.priorityTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
