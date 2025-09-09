import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/content_quiz_models.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _explanationController = TextEditingController();

  String _selectedSubject = 'General Knowledge';
  String _selectedSkill = 'General Knowledge';
  String _selectedDifficulty = 'Easy';
  String _selectedQuestionType = 'Multiple Choice';
  int _correctAnswer = 0;

  final List<String> _subjects = [
    'General Knowledge',
    'Mathematics',
    'Science',
    'Literature',
    'Geography',
    'History',
    'Computer Science',
    'Business',
  ];

  final List<String> _skills = [
    'General Knowledge',
    'Mathematics',
    'Science',
    'English Literature',
    'Geography',
    'History',
    'Computer Science',
    'Business',
    'Communication',
    'Leadership',
  ];

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _questionTypes = [
    'Multiple Choice',
    'True/False',
    'Fill in the Blank',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text(
          'Add Question',
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
          icon: const Icon(Icons.close),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question field
              const Text(
                'Question',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What is the Capital of France?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.lightGray.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Options
              const Text(
                'Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              _buildOptionField('Option 1', _option1Controller, 0),
              const SizedBox(height: 12),
              _buildOptionField('Option 2', _option2Controller, 1),
              const SizedBox(height: 12),
              _buildOptionField('Option 3', _option3Controller, 2),
              const SizedBox(height: 12),
              _buildOptionField('Option 4', _option4Controller, 3),

              const SizedBox(height: 24),

              // Correct Answer dropdown
              const Text(
                'Correct Answer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _correctAnswer,
                    isExpanded: true,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.pureWhite,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(
                          'Option 1${_option1Controller.text.isNotEmpty ? ': ${_option1Controller.text}' : ''}',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          'Option 2${_option2Controller.text.isNotEmpty ? ': ${_option2Controller.text}' : ''}',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                          'Option 3${_option3Controller.text.isNotEmpty ? ': ${_option3Controller.text}' : ''}',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(
                          'Option 4${_option4Controller.text.isNotEmpty ? ': ${_option4Controller.text}' : ''}',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _correctAnswer = value ?? 0;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category fields
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Subject',
                      _selectedSubject,
                      _subjects,
                      (value) => setState(() => _selectedSubject = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      'Skill',
                      _selectedSkill,
                      _skills,
                      (value) => setState(() => _selectedSkill = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Difficulty',
                      _selectedDifficulty,
                      _difficulties,
                      (value) => setState(() => _selectedDifficulty = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      'Type',
                      _selectedQuestionType,
                      _questionTypes,
                      (value) => setState(() => _selectedQuestionType = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Explanation field
              const Text(
                'Explanation (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _explanationController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Explain why this is the correct answer...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.lightGray.withOpacity(0.1),
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
                      onPressed: _saveQuestion,
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
      ),
    );
  }

  Widget _buildOptionField(
    String label,
    TextEditingController controller,
    int index,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.lightGray.withOpacity(0.1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.lightGray.withOpacity(0.1),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      // Create new skill drill
      final newDrill = SkillDrill(
        id: 'drill_${DateTime.now().millisecondsSinceEpoch}',
        question: _questionController.text,
        subject: _selectedSubject,
        difficulty: _selectedDifficulty,
        skill: _selectedSkill,
        questionType: _selectedQuestionType,
        options: [
          _option1Controller.text,
          _option2Controller.text,
          _option3Controller.text,
          _option4Controller.text,
        ],
        correctAnswer: _correctAnswer,
        explanation: _explanationController.text,
        imageUrl:
            'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
        isActive: true,
        createdAt: DateTime.now().toIso8601String().split('T')[0],
        tags: [_selectedSubject.toLowerCase(), _selectedSkill.toLowerCase()],
      );

      // In a real app, you would save this to the backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question "${newDrill.question}" saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    }
  }
}
