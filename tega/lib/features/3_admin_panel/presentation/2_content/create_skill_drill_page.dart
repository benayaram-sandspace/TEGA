import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/models/content_quiz_model.dart';
import 'add_question_page.dart';

class CreateSkillDrillPage extends StatefulWidget {
  const CreateSkillDrillPage({super.key});

  @override
  State<CreateSkillDrillPage> createState() => _CreateSkillDrillPageState();
}

class _CreateSkillDrillPageState extends State<CreateSkillDrillPage> {
  // Combined list to manage all questions for the UI
  final List<SkillDrill> _questions = [];

  @override
  void initState() {
    super.initState();
    // Initialize with mock data
    _questions.addAll([
      SkillDrill(
        id: 'review_001',
        title: 'What is the capital of France?',
        description: 'Test your knowledge of European capitals',
        subject: 'Geography',
        difficulty: 'Easy',
        skill: 'General Knowledge',
        questionType: 'Multiple Choice',
        category: 'General Knowledge',
        questions: ['What is the capital of France?'],
        options: ['London', 'Berlin', 'Paris', 'Madrid'],
        correctAnswers: [2],
        explanations: ['Paris is the capital and largest city of France.'],
        imageUrls: [
          'https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400',
        ],
        isActive: true,
        createdAt: DateTime.parse('2024-01-15'),
        createdBy: 'admin',
        tags: ['geography', 'capitals', 'europe'],
        estimatedTime: 60,
      ),
      SkillDrill(
        id: 'review_002',
        title: 'Solve for x: 2x + 3 = 7',
        description: 'Basic algebraic equation solving',
        subject: 'Algebra',
        difficulty: 'Medium',
        skill: 'Mathematics',
        questionType: 'Multiple Choice',
        category: 'Mathematics',
        questions: ['Solve for x: 2x + 3 = 7'],
        options: ['x = 1', 'x = 2', 'x = 3', 'x = 4'],
        correctAnswers: [1],
        explanations: ['2x + 3 = 7, so 2x = 4, therefore x = 2'],
        imageUrls: [
          'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400',
        ],
        isActive: true,
        createdAt: DateTime.parse('2024-01-16'),
        createdBy: 'admin',
        tags: ['algebra', 'equations', 'math'],
        estimatedTime: 90,
      ),
      SkillDrill(
        id: 'review_003',
        title: 'Who wrote \'Romeo and Juliet\'?',
        description: 'Test your knowledge of classic literature',
        subject: 'Literature',
        difficulty: 'Medium',
        skill: 'English Literature',
        questionType: 'Multiple Choice',
        category: 'Literature',
        questions: ['Who wrote \'Romeo and Juliet\'?'],
        options: [
          'Charles Dickens',
          'William Shakespeare',
          'Jane Austen',
          'Mark Twain',
        ],
        correctAnswers: [1],
        explanations: [
          'William Shakespeare wrote the famous tragedy \'Romeo and Juliet\'.',
        ],
        imageUrls: [
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
        ],
        isActive: true,
        createdAt: DateTime.parse('2024-01-17'),
        createdBy: 'admin',
        tags: ['literature', 'shakespeare', 'drama'],
        estimatedTime: 75,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              'Create Skill Drill',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            elevation: 1,
            pinned: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('Questions'),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (_questions.isEmpty)
                  _buildEmptyState()
                else
                  _buildQuestionsList(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _bulkUpload,
            icon: const Icon(Icons.upload_file_outlined, size: 20),
            label: const Text('Bulk Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.list_alt_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Questions Added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click on "Add Question" to start building your skill drill.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final question = _questions[index];
        return _buildQuestionCard(question, index);
      },
    );
  }

  Widget _buildQuestionCard(SkillDrill question, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTag(question.subject, AppColors.primary),
              const SizedBox(width: 8),
              _buildTag(question.difficulty, AppColors.info),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  // TODO: Implement edit functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () {
                  setState(() => _questions.removeAt(index));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveSkillDrill,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveSkillDrill() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question to save.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skill drill saved with ${_questions.length} questions!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }
}
