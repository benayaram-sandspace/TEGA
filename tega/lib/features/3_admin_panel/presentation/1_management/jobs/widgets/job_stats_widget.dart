import 'package:flutter/material.dart';

class JobStatsWidget extends StatelessWidget {
  final Map<String, int> stats;

  const JobStatsWidget({super.key, required this.stats});

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
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  const Text(
                    'Total Jobs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: stats['total'] ?? 0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, child) {
                      return Text(
                        animatedValue.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B5FFF),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // 2. Secondary Stats with staggered animation
                  _buildAnimatedStatRow(
                    'Active',
                    stats['active'] ?? 0,
                    const Color(0xFF48BB78),
                    Icons.check_circle,
                    0,
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedStatRow(
                    'Closed',
                    stats['closed'] ?? 0,
                    const Color(0xFFF56565),
                    Icons.cancel,
                    100,
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedStatRow(
                    'Jobs',
                    stats['jobs'] ?? 0,
                    const Color(0xFF4299E1),
                    Icons.business,
                    200,
                  ),
                  const SizedBox(height: 12),
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
                      child: Icon(icon, color: color, size: 20),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
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
