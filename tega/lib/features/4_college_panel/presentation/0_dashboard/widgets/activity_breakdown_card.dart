import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class ActivityBreakdownCard extends StatefulWidget {
  final AnimationController animationController;
  const ActivityBreakdownCard({super.key, required this.animationController});

  @override
  State<ActivityBreakdownCard> createState() => _ActivityBreakdownCardState();
}

class _ActivityBreakdownCardState extends State<ActivityBreakdownCard> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    final List<Map<String, dynamic>> breakdownData = [
      {'title': 'Videos', 'value': 40.0, 'color': DashboardStyles.primary},
      {
        'title': 'Quizzes',
        'value': 25.0,
        'color': DashboardStyles.accentOrange,
      },
      {
        'title': 'Assignments',
        'value': 20.0,
        'color': DashboardStyles.accentGreen,
      },
      {
        'title': 'Reading',
        'value': 15.0,
        'color': DashboardStyles.accentPurple,
      },
    ];

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DashboardStyles.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Activity Breakdown',
                style: DashboardStyles.sectionTitle,
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.8,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(breakdownData.length, (i) {
                      final isTouched = i == _touchedPieIndex;
                      final radius = isTouched ? 60.0 : 50.0;
                      return PieChartSectionData(
                        color: breakdownData[i]['color'],
                        value: breakdownData[i]['value'],
                        title: '${breakdownData[i]['value'].toInt()}%',
                        radius: radius,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 2),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.0,
                runSpacing: 8.0,
                children: breakdownData
                    .map((data) => _buildLegend(data['color'], data['title']))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
