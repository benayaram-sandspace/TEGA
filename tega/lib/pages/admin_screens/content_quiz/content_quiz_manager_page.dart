import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/content_quiz_models.dart';
import 'package:tega/services/content_quiz_service.dart';
import 'skill_drill_library_page.dart';
import 'soft_skill_scenarios_page.dart';
import 'onboarding_quiz_manager_page.dart';

class ContentQuizManagerPage extends StatefulWidget {
  const ContentQuizManagerPage({super.key});

  @override
  State<ContentQuizManagerPage> createState() => _ContentQuizManagerPageState();
}

class _ContentQuizManagerPageState extends State<ContentQuizManagerPage> {
  final ContentQuizService _contentQuizService = ContentQuizService();
  ContentQuizStatistics? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _contentQuizService.getStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load statistics: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text(
          'Content & Quiz Manager',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildSkillDrillLibraryCard(),
                  const SizedBox(height: 20),
                  _buildSoftSkillScenarioCard(),
                  const SizedBox(height: 20),
                  _buildOnboardingQuizCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSkillDrillLibraryCard() {
    return _buildManagerCard(
      title: 'Skill Drill Library',
      description:
          'Manage the library of quick quizzes, puzzles, and challenges used in the Daily Skill Drill feature',
      count: 'Total Active Drills: ${_statistics?.totalActiveDrills ?? 0}+',
      buttonText: 'Manage Library',
      imageUrl:
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SkillDrillLibraryPage(),
          ),
        );
      },
    );
  }

  Widget _buildSoftSkillScenarioCard() {
    return _buildManagerCard(
      title: 'Soft Skill Scenario Editor',
      description:
          'Create and edit interactive, real-world scenarios for the Soft Skills Transformation module',
      count: 'Total Scenarios: ${_statistics?.totalScenarios ?? 0}',
      buttonText: 'Manage Scenarios',
      imageUrl:
          'https://images.unsplash.com/photo-1552664730-d307ca884978?w=400',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SoftSkillScenariosPage(),
          ),
        );
      },
    );
  }

  Widget _buildOnboardingQuizCard() {
    return _buildManagerCard(
      title: 'Onboarding Quiz Manager',
      description:
          'Edit the questions and logic for the initial quiz presented to new students upon registration',
      count: 'Total Questions: ${_statistics?.totalQuestions ?? 0}',
      buttonText: 'Manage Quiz',
      imageUrl:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=400',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingQuizManagerPage(),
          ),
        );
      },
    );
  }

  Widget _buildManagerCard({
    required String title,
    required String description,
    required String count,
    required String buttonText,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.deepBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        color: AppColors.warmOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmOrange,
                          foregroundColor: AppColors.pureWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
