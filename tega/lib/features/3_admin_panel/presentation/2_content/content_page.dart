import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/2_content/onboarding_quiz_manager_page.dart';
import 'package:tega/features/3_admin_panel/presentation/2_content/skill_drill_library_page.dart';
import 'package:tega/features/3_admin_panel/presentation/2_content/soft_skill_scenarios_page.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboardStyles.background,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeaderCard(context),
                const SizedBox(height: 24),
                _buildSectionTitle("Management Areas"),
                const SizedBox(height: 16),
                _buildManagementOption(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Skill Drills',
                  subtitle: 'Create and manage coding exercises.',
                  color: AdminDashboardStyles.primary,
                  // TODO: Replace with your actual Skill Drills page
                  destinationPage: const SkillDrillLibraryPage(),
                ),
                const SizedBox(height: 16),
                _buildManagementOption(
                  context,
                  icon: Icons.account_tree_outlined,
                  title: 'Scenarios',
                  subtitle: 'Develop and edit situational challenges.',
                  color: AdminDashboardStyles.primaryLight,
                  // TODO: Replace with your actual Scenarios page
                  destinationPage: const SoftSkillScenariosPage(),
                ),
                const SizedBox(height: 16),
                _buildManagementOption(
                  context,
                  icon: Icons.quiz_outlined,
                  title: 'Onboarding Quizzes',
                  subtitle: 'Configure assessments for new students.',
                  color: AdminDashboardStyles.primary,
                  destinationPage: const OnboardingQuizManagerPage(),
                ),
              ]),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  /// A visually engaging header to introduce the page.
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdminDashboardStyles.primary,
            AdminDashboardStyles.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdminDashboardStyles.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.dynamic_feed,
            color: Colors.white.withValues(alpha: 0.8),
            size: 40,
          ),
          const SizedBox(height: 16),
          const Text(
            'Content & Quiz Manager',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage all educational materials, from skill drills to onboarding quizzes, in one centralized place.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// A title for different sections of the page.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AdminDashboardStyles.textDark,
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: 0.3);
  }

  /// A tappable card for each management option.
  Widget _buildManagementOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget destinationPage,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AdminDashboardStyles.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminDashboardStyles.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminDashboardStyles.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: 0.3);
  }
}
