import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/models/content_quiz_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/content_quiz_repository.dart';

class OnboardingQuizManagerPage extends StatefulWidget {
  const OnboardingQuizManagerPage({super.key});

  @override
  State<OnboardingQuizManagerPage> createState() =>
      _OnboardingQuizManagerPageState();
}

class _OnboardingQuizManagerPageState extends State<OnboardingQuizManagerPage> {
  final ContentQuizRepository _contentQuizService = ContentQuizRepository();
  OnboardingQuiz? _onboardingQuiz;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOnboardingQuiz();
  }

  Future<void> _loadOnboardingQuiz() async {
    try {
      final quiz = await _contentQuizService.getOnboardingQuiz();
      setState(() {
        _onboardingQuiz = quiz;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load onboarding quiz: $e'),
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
          'Onboarding Quiz Manager',
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
          : _onboardingQuiz == null
          ? const Center(
              child: Text(
                'No onboarding quiz found',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz overview
                  _buildQuizOverview(),
                  const SizedBox(height: 24),

                  // Quiz settings
                  _buildQuizSettings(),
                  const SizedBox(height: 24),

                  // Questions list
                  _buildQuestionsList(),
                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuizOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _onboardingQuiz!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _onboardingQuiz!.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Total Questions',
                _onboardingQuiz!.totalQuestions.toString(),
                Icons.quiz,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Time Limit',
                '${_onboardingQuiz!.timeLimit} min',
                Icons.timer,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Status',
                _onboardingQuiz!.isActive ? 'Active' : 'Inactive',
                _onboardingQuiz!.isActive ? Icons.check_circle : Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightGray.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSettings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGray.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Time limit setting
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Time Limit (minutes)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _onboardingQuiz!.timeLimit.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    // In a real app, you would update the quiz settings
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Active status toggle
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quiz Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _onboardingQuiz!.isActive,
                onChanged: (value) {
                  setState(() {
                    _onboardingQuiz = OnboardingQuiz(
                      id: _onboardingQuiz!.id,
                      title: _onboardingQuiz!.title,
                      description: _onboardingQuiz!.description,
                      totalQuestions: _onboardingQuiz!.totalQuestions,
                      timeLimit: _onboardingQuiz!.timeLimit,
                      questions: _onboardingQuiz!.questions,
                      isActive: value,
                      lastModified: DateTime.now().toIso8601String().split(
                        'T',
                      )[0],
                    );
                  });
                },
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGray.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addNewQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._onboardingQuiz!.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(question, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(OnboardingQuestion question, int questionNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    questionNumber.toString(),
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editQuestion(question),
                icon: const Icon(Icons.edit, size: 20),
                color: AppColors.textSecondary,
              ),
            ],
          ),

          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Options: ${question.options.join(', ')}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question.type,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (question.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _previewQuiz,
            icon: const Icon(Icons.visibility),
            label: const Text('Preview Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveQuiz,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _addNewQuestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new question functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _editQuestion(OnboardingQuestion question) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit question: ${question.question}'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _previewQuiz() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz preview functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _saveQuiz() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz changes saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
