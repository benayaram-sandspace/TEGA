import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class JobStatsWidget extends StatelessWidget {
  final Map<String, int> stats;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const JobStatsWidget({
    super.key,
    required this.stats,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: EdgeInsets.fromLTRB(
                isMobile ? 12 : isTablet ? 14 : 16,
                isMobile ? 12 : isTablet ? 14 : 16,
                isMobile ? 12 : isTablet ? 14 : 16,
                isMobile ? 6 : isTablet ? 7 : 8,
              ),
              padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Primary Stat (Total)
                  Text(
                    'Total Jobs',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF718096),
                    ),
                  ),
                  SizedBox(height: isMobile ? 3 : 4),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: stats['total'] ?? 0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, child) {
                      return Text(
                        animatedValue.toString(),
                        style: TextStyle(
                          fontSize: isMobile ? 26 : isTablet ? 29 : 32,
                          fontWeight: FontWeight.bold,
                          color: AdminDashboardStyles.primary,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),

                  // 2. Secondary Stats with staggered animation
                  _buildAnimatedStatRow(
                    'Active',
                    stats['active'] ?? 0,
                    const Color(0xFF48BB78),
                    Icons.check_circle,
                    0,
                  ),
                  SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
                  _buildAnimatedStatRow(
                    'Expired',
                    stats['expired'] ?? 0,
                    const Color(0xFFF56565),
                    Icons.cancel,
                    100,
                  ),
                  SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
                  _buildAnimatedStatRow(
                    'Jobs',
                    stats['jobs'] ?? 0,
                    const Color(0xFF4299E1),
                    Icons.business,
                    200,
                  ),
                  SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
                  _buildAnimatedStatRow(
                    'Internships',
                    stats['internships'] ?? 0,
                    const Color(0xFFED8936),
                    Icons.school,
                    300,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatRow(
    String label,
    int value,
    Color color,
    IconData icon,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + delay),
                  curve: Curves.elasticOut,
                  builder: (context, scaleValue, child) {
                    return Transform.scale(
                      scale: scaleValue,
                      child: Icon(
                        icon,
                        color: color,
                        size: isMobile ? 18 : isTablet ? 19 : 20,
                      ),
                    );
                  },
                ),
                SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: Duration(milliseconds: 800 + delay),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) {
                    return Text(
                      animatedValue.toString(),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
