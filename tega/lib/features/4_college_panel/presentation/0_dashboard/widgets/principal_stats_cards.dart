import 'package:flutter/material.dart';

class PrincipalStatsCards extends StatefulWidget {
  final int totalStudents;
  final int activeStudents;
  final int recentRegistrations;
  final int uniqueCourses;
  final double totalStudentsTrend;
  final double activeStudentsTrend;
  final double recentRegistrationsTrend;
  final double uniqueCoursesTrend;

  const PrincipalStatsCards({
    super.key,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.recentRegistrations = 0,
    this.uniqueCourses = 0,
    this.totalStudentsTrend = 0.0,
    this.activeStudentsTrend = 0.0,
    this.recentRegistrationsTrend = 0.0,
    this.uniqueCoursesTrend = 0.0,
  });

  @override
  State<PrincipalStatsCards> createState() => _PrincipalStatsCardsState();
}

class _PrincipalStatsCardsState extends State<PrincipalStatsCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimations = List.generate(
      4,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15,
            0.5 + (index * 0.15),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color iconColor,
    required double trend,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnimations[index],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[index].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimations[index].value)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 12,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${trend.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _calculateProgress(value, title),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: [
        _buildStatCard(
          title: 'Total Students',
          value: widget.totalStudents,
          icon: Icons.people_rounded,
          iconColor: const Color(0xFF3B82F6),
          trend: widget.totalStudentsTrend,
          index: 0,
        ),
        _buildStatCard(
          title: 'Active Students',
          value: widget.activeStudents,
          icon: Icons.person_outline,
          iconColor: const Color(0xFF10B981),
          trend: widget.activeStudentsTrend,
          index: 1,
        ),
        _buildStatCard(
          title: 'Recent Registrations',
          value: widget.recentRegistrations,
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF8B5CF6),
          trend: widget.recentRegistrationsTrend,
          index: 2,
        ),
        _buildStatCard(
          title: 'Unique Courses',
          value: widget.uniqueCourses,
          icon: Icons.book_rounded,
          iconColor: const Color(0xFFF59E0B),
          trend: widget.uniqueCoursesTrend,
          index: 3,
        ),
      ],
    );
  }
}

