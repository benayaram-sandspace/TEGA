import 'package:flutter/material.dart';
import 'package:tega/pages/student_screens/student_quiz_page.dart';

class DrillDetailPage extends StatelessWidget {
  const DrillDetailPage({super.key});

  // ---- Design tokens tuned to the screenshot ----
  static const Color kPrimary = Color(0xFF5E4FDB); // purple
  static const Color kPrimaryDark = Color(0xFF4A47A3);
  static const Color kBadgeBg = Color(0xFFF2EEFF); // pale purple
  static const Color kSurface = Colors.white;
  static const Color kBorder = Color(0xFFE9E9EF);
  static const Color kText = Color(0xFF222222);
  static const Color kTextSecondary = Color(0xFF6F6F7A);
  static const double kCardRadius = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Daily Skill Drill',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---- Streak Badge ----
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: kBadgeBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_fire_department, size: 28, color: kPrimary),
                  SizedBox(height: 4),
                  Text(
                    '5',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Days',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Current Streak',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            // ---- Drill of the Day Card ----
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drill of the Day',
                    style: TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.event, size: 18, color: kTextSecondary),
                      SizedBox(width: 8),
                      Text(
                        'June 15, 2023',
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Topic
                  _InfoRow(
                    iconBg: Color(0xFFEDEBFE),
                    iconColor: kPrimary,
                    icon: Icons.psychology_alt_outlined,
                    title: 'Topic',
                    subtitle: 'Logical Reasoning Puzzle',
                  ),
                  const SizedBox(height: 12),

                  // Effort
                  _InfoRow(
                    iconBg: Color(0xFFEAEFFF),
                    iconColor: kPrimaryDark,
                    icon: Icons.timer_outlined,
                    title: 'Effort',
                    subtitle: '5 Questions, Est. 2 mins',
                  ),
                  const SizedBox(height: 12),

                  // Reward
                  _InfoRow(
                    iconBg: Color(0xFFE9F7F0),
                    iconColor: Color(0xFF22A36F),
                    icon: Icons.workspace_premium_outlined,
                    title: 'Reward',
                    subtitle: '+50 XP',
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuestionPage(),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Start Drill',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- Previous Results Card ----
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header row
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Previous Results',
                          style: TextStyle(
                            color: kText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // row item 1
                  _ResultRow(
                    iconBg: Color(0xFFE6F4F1),
                    iconColor: Color(0xFF1AA084),
                    icon: Icons.code,
                    title: 'Python Basics',
                    subtitle: 'Yesterday',
                    score: '4/5',
                  ),
                  const SizedBox(height: 10),

                  // row item 2
                  _ResultRow(
                    iconBg: Color(0xFFFFF1DE),
                    iconColor: Color(0xFFE3A33A),
                    icon: Icons.storage_rounded,
                    title: 'SQL Queries',
                    subtitle: '2 days ago',
                    score: '5/5',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Reusable widgets ----------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: DrillDetailPage.kSurface,
        borderRadius: BorderRadius.circular(DrillDetailPage.kCardRadius),
        border: Border.all(color: DrillDetailPage.kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DrillDetailPage.kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DrillDetailPage.kTextSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String score;

  const _ResultRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F1F4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DrillDetailPage.kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DrillDetailPage.kTextSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: const TextStyle(
              color: DrillDetailPage.kText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
