import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class AddQuestionTab extends StatefulWidget {
  const AddQuestionTab({super.key});

  @override
  State<AddQuestionTab> createState() => _AddQuestionTabState();
}

class _AddQuestionTabState extends State<AddQuestionTab> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();

  final AuthService _auth = AuthService();

  String _selectedCategory = 'technical';
  String _selectedDifficulty = 'medium';

  // Dynamic options with one correct selection (MCQ)
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctIndex = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _companyController.dispose();
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: icon != null
          ? Icon(icon, color: AdminDashboardStyles.textLight, size: 18)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Build options list and validate at least one non-empty option
    final options = <Map<String, dynamic>>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isNotEmpty) {
        options.add({'text': text, 'isCorrect': i == _correctIndex});
      }
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least two answer options.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!options.any((o) => o['isCorrect'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark one option as the correct answer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final headers = await _auth.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final payload = {
        'companyName': _companyController.text.trim(),
        'questionText': _questionController.text.trim(),
        'questionType': 'mcq',
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'options': options,
        'explanation': _explanationController.text.trim(),
        'points': 10,
      };

      final res = await http.post(
        Uri.parse(ApiEndpoints.adminCompanyQuestionsCreate),
        headers: headers,
        body: json.encode(payload),
      );

      final data = json.decode(res.body);
      if (res.statusCode == 201 || (data is Map && data['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      } else {
        throw Exception(data['message'] ?? 'Failed to save question');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _companyController.clear();
    _questionController.clear();
    _explanationController.clear();
    for (final c in _optionControllers) {
      c.clear();
    }
    setState(() => _correctIndex = 0);
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      if (_correctIndex == index) _correctIndex = 0;
      _optionControllers.removeAt(index).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Company Name *',
              icon: Icons.business_rounded,
              child: TextFormField(
                controller: _companyController,
                decoration: _inputDecoration(
                  hint: 'e.g., TCS, Infosys, Microsoft',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Company name is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Question Text *',
              icon: Icons.article_rounded,
              child: TextFormField(
                controller: _questionController,
                minLines: 6,
                maxLines: 12,
                decoration: _inputDecoration(
                  hint:
                      'Enter your question here... (You can paste complete question with formatting) ',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Question text is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryDifficultyRow(),
            const SizedBox(height: 16),
            _buildOptionsSection(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Explanation (Optional)',
              icon: Icons.info_outline_rounded,
              child: TextFormField(
                controller: _explanationController,
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecoration(
                  hint: 'Explain why this answer is correct...',
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AdminDashboardStyles.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryDifficultyRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                child: _buildSection(
                  title: 'Category',
                  icon: Icons.menu_book_rounded,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text('Technical'),
                      ),
                      DropdownMenuItem(
                        value: 'aptitude',
                        child: Text('Aptitude'),
                      ),
                      DropdownMenuItem(
                        value: 'reasoning',
                        child: Text('Reasoning'),
                      ),
                      DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
                      DropdownMenuItem(value: 'coding', child: Text('Coding')),
                      DropdownMenuItem(value: 'hr', child: Text('HR')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? 'technical'),
                    decoration: _inputDecoration(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSection(
                  title: 'Difficulty',
                  icon: Icons.workspace_premium_rounded,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedDifficulty = v ?? 'medium'),
                    decoration: _inputDecoration(),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSection(
                title: 'Category',
                icon: Icons.menu_book_rounded,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'technical',
                      child: Text('Technical'),
                    ),
                    DropdownMenuItem(
                      value: 'aptitude',
                      child: Text('Aptitude'),
                    ),
                    DropdownMenuItem(
                      value: 'reasoning',
                      child: Text('Reasoning'),
                    ),
                    DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
                    DropdownMenuItem(value: 'coding', child: Text('Coding')),
                    DropdownMenuItem(value: 'hr', child: Text('HR')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v ?? 'technical'),
                  decoration: _inputDecoration(),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Difficulty',
                icon: Icons.workspace_premium_rounded,
                child: DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedDifficulty = v ?? 'medium'),
                  decoration: _inputDecoration(),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildOptionsSection() {
    return _buildSection(
      title: 'Answer Options *  (Click radio to mark correct answer)',
      icon: Icons.rule_rounded,
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _optionControllers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Radio<int>(
                      value: index,
                      groupValue: _correctIndex,
                      onChanged: (v) => setState(() => _correctIndex = v ?? 0),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _optionControllers[index],
                      decoration: _inputDecoration(
                        hint: 'Enter option ${String.fromCharCode(65 + index)}',
                      ),
                      validator: (v) {
                        // Only validate the first two options strictly; others can be empty
                        if (index < 2 && (v == null || v.trim().isEmpty)) {
                          return 'Option ${String.fromCharCode(65 + index)} is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_optionControllers.length > 2)
                    IconButton(
                      tooltip: 'Remove option',
                      onPressed: () => _removeOption(index),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addOption,
              icon: Icon(
                Icons.add_circle_rounded,
                color: AdminDashboardStyles.primary,
              ),
              label: const Text('Add More Options'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : _resetForm,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveQuestion,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Question'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminDashboardStyles.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
