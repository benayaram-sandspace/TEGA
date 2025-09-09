import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/content_quiz_models.dart';
import 'add_question_page.dart';

class CreateSkillDrillPage extends StatefulWidget {
  const CreateSkillDrillPage({super.key});

  @override
  State<CreateSkillDrillPage> createState() => _CreateSkillDrillPageState();
}

class _CreateSkillDrillPageState extends State<CreateSkillDrillPage> {
  final List<SkillDrill> _questions = [];
  final List<SkillDrill> _reviewQuestions = [
    SkillDrill(
      id: 'review_001',
      question: 'What is the capital of France?',
      subject: 'Geography',
      difficulty: 'Easy',
      skill: 'General Knowledge',
      questionType: 'Multiple Choice',
      options: ['London', 'Berlin', 'Paris', 'Madrid'],
      correctAnswer: 2,
      explanation: 'Paris is the capital and largest city of France.',
      imageUrl:
          'https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400',
      isActive: true,
      createdAt: '2024-01-15',
      tags: ['geography', 'capitals', 'europe'],
    ),
    SkillDrill(
      id: 'review_002',
      question: 'Solve for x: 2x + 3 = 7',
      subject: 'Algebra',
      difficulty: 'Medium',
      skill: 'Mathematics',
      questionType: 'Multiple Choice',
      options: ['x = 1', 'x = 2', 'x = 3', 'x = 4'],
      correctAnswer: 1,
      explanation: '2x + 3 = 7, so 2x = 4, therefore x = 2',
      imageUrl:
          'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400',
      isActive: true,
      createdAt: '2024-01-16',
      tags: ['algebra', 'equations', 'math'],
    ),
    SkillDrill(
      id: 'review_003',
      question: 'Who wrote \'Romeo and Juliet\'?',
      subject: 'Literature',
      difficulty: 'Medium',
      skill: 'English Literature',
      questionType: 'Multiple Choice',
      options: [
        'Charles Dickens',
        'William Shakespeare',
        'Jane Austen',
        'Mark Twain',
      ],
      correctAnswer: 1,
      explanation:
          'William Shakespeare wrote the famous tragedy \'Romeo and Juliet\'.',
      imageUrl:
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
      isActive: true,
      createdAt: '2024-01-17',
      tags: ['literature', 'shakespeare', 'drama'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text(
          'Create Skill Drill',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Questions section
            const Text(
              'Add Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Question placeholders
            _buildQuestionPlaceholder('Question 1'),
            const SizedBox(height: 12),
            _buildQuestionPlaceholder('Question 2'),
            const SizedBox(height: 12),
            _buildQuestionPlaceholder('Question 3'),

            const SizedBox(height: 16),

            // Add Question and Bulk Upload buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _bulkUpload,
                    icon: const Icon(Icons.upload),
                    label: const Text('Bulk Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Review section
            const Text(
              'Review',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Review questions
            ..._reviewQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Column(
                children: [
                  _buildReviewQuestionCard(question, index + 1),
                  if (index < _reviewQuestions.length - 1)
                    const SizedBox(height: 12),
                ],
              );
            }).toList(),

            const SizedBox(height: 16),

            // Add New Question button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add New Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSkillDrill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPlaceholder(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGray,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQuestionCard(SkillDrill question, int questionNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGray.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question $questionNumber',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddQuestionPage()),
    ).then((result) {
      if (result != null && result is SkillDrill) {
        setState(() {
          _questions.add(result);
        });
      }
    });
  }

  void _bulkUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulk upload functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _saveSkillDrill() {
    if (_questions.isEmpty && _reviewQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Skill drill saved with ${_questions.length + _reviewQuestions.length} questions!',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}
