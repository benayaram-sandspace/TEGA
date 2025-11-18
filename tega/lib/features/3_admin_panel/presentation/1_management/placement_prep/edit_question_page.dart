import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class EditQuestionPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const EditQuestionPage({super.key, required this.question});

  @override
  State<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<EditQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicController = TextEditingController();
  final _timeController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final List<bool> _optionCorrect = [];

  final AuthService _auth = AuthService();
  bool _isLoading = false;
  bool _isLoadingQuestion = true;

  String? _selectedType;
  String? _selectedCategory;
  String? _selectedDifficulty;
  Map<String, dynamic>? _questionData;

  @override
  void initState() {
    super.initState();
    _loadQuestionData();
  }

  Future<void> _loadQuestionData() async {
    try {
      final questionId = (widget.question['_id'] ?? widget.question['id'])
          .toString();
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementQuestionById(questionId)),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          _questionData = data['question'] ?? data['data'];
          _populateForm();
        } else {
          throw Exception(data['message'] ?? 'Failed to load question');
        }
      } else {
        throw Exception('Failed to load question: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuestion = false);
      }
    }
  }

  void _populateForm() {
    if (_questionData == null) return;

    _titleController.text = _questionData!['title']?.toString() ?? '';
    _descriptionController.text =
        _questionData!['description']?.toString() ?? '';
    _topicController.text = _questionData!['topic']?.toString() ?? '';
    _timeController.text = (_questionData!['timeLimit'] ?? 30).toString();

    _selectedType = _questionData!['type']?.toString().toLowerCase() ?? 'mcq';
    _selectedCategory =
        _questionData!['category']?.toString().toLowerCase() ?? 'assessment';
    _selectedDifficulty =
        _questionData!['difficulty']?.toString().toLowerCase() ?? 'easy';

    // Load options for MCQ
    final options = _questionData!['options'] ?? [];
    if (options is List && options.isNotEmpty) {
      for (var opt in options) {
        _optionControllers.add(
          TextEditingController(text: opt['text']?.toString() ?? ''),
        );
        _optionCorrect.add(opt['isCorrect'] == true);
      }
    } else {
      // Initialize with 4 empty options
      for (int i = 0; i < 4; i++) {
        _optionControllers.add(TextEditingController());
        _optionCorrect.add(false);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    _timeController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one correct option for MCQ
    if (_selectedType == 'mcq' && !_optionCorrect.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one correct answer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questionId = (widget.question['_id'] ?? widget.question['id'])
          .toString();
      final questionType = _questionData!['questionType'] ?? 'placement';

      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'topic': _topicController.text.trim(),
        'timeLimit': int.tryParse(_timeController.text) ?? 30,
      };

      // Add options for MCQ
      if (_selectedType == 'mcq') {
        updateData['options'] = _optionControllers
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return {
                'text': controller.text.trim(),
                'isCorrect': _optionCorrect[index],
              };
            })
            .where((opt) => opt['text'].toString().isNotEmpty)
            .toList();
      }

      final headers = await _auth.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final uri = Uri.parse(
        ApiEndpoints.adminUpdatePlacementQuestion(questionId),
      ).replace(queryParameters: {'questionType': questionType});

      final res = await http.put(
        uri,
        headers: headers,
        body: json.encode(updateData),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Question updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to update question');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(
          errorData['message'] ??
              'Failed to update question: ${res.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardStyles.background,
      appBar: AppBar(
        backgroundColor: AdminDashboardStyles.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Question'),
        elevation: 0,
      ),
      body: _isLoadingQuestion
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      label: 'Question Title *',
                      icon: Icons.chat_bubble_outline_rounded,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: _buildInputDecoration(
                          hintText: 'Enter question title',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter question title';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Description *',
                      icon: Icons.description_rounded,
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(
                          hintText: 'Enter question description',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 700;
                        if (narrow) {
                          return Column(
                            children: [
                              _buildFormField(
                                label: 'Type *',
                                icon: Icons.description_rounded,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select type',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'mcq',
                                      child: Text('MCQ'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'coding',
                                      child: Text('Coding'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'subjective',
                                      child: Text('Subjective'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'behavioral',
                                      child: Text('Behavioral'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _selectedType = value),
                                  validator: (value) => value == null
                                      ? 'Please select type'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFormField(
                                label: 'Category *',
                                icon: Icons.book_outlined,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select category',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'assessment',
                                      child: Text('Assessment'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'technical',
                                      child: Text('Technical'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'interview',
                                      child: Text('Interview'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'aptitude',
                                      child: Text('Aptitude'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'logical',
                                      child: Text('Logical'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'verbal',
                                      child: Text('Verbal'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _selectedCategory = value),
                                  validator: (value) => value == null
                                      ? 'Please select category'
                                      : null,
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                label: 'Type *',
                                icon: Icons.description_rounded,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select type',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'mcq',
                                      child: Text('MCQ'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'coding',
                                      child: Text('Coding'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'subjective',
                                      child: Text('Subjective'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'behavioral',
                                      child: Text('Behavioral'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _selectedType = value),
                                  validator: (value) => value == null
                                      ? 'Please select type'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                label: 'Category *',
                                icon: Icons.book_outlined,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select category',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'assessment',
                                      child: Text('Assessment'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'technical',
                                      child: Text('Technical'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'interview',
                                      child: Text('Interview'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'aptitude',
                                      child: Text('Aptitude'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'logical',
                                      child: Text('Logical'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'verbal',
                                      child: Text('Verbal'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _selectedCategory = value),
                                  validator: (value) => value == null
                                      ? 'Please select category'
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 700;
                        if (narrow) {
                          return Column(
                            children: [
                              _buildFormField(
                                label: 'Difficulty *',
                                icon: Icons.shield_outlined,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDifficulty,
                                  isExpanded: true,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select difficulty',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'easy',
                                      child: Text('Easy'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'medium',
                                      child: Text('Medium'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'hard',
                                      child: Text('Hard'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _selectedDifficulty = value,
                                  ),
                                  validator: (value) => value == null
                                      ? 'Please select difficulty'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFormField(
                                label: 'Time (min)',
                                icon: Icons.access_time_rounded,
                                child: TextFormField(
                                  controller: _timeController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'e.g., 30',
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                label: 'Difficulty *',
                                icon: Icons.shield_outlined,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDifficulty,
                                  isExpanded: true,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select difficulty',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'easy',
                                      child: Text('Easy'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'medium',
                                      child: Text('Medium'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'hard',
                                      child: Text('Hard'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _selectedDifficulty = value,
                                  ),
                                  validator: (value) => value == null
                                      ? 'Please select difficulty'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                label: 'Time (min)',
                                icon: Icons.access_time_rounded,
                                child: TextFormField(
                                  controller: _timeController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'e.g., 30',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Topic *',
                      icon: Icons.topic_rounded,
                      child: TextFormField(
                        controller: _topicController,
                        decoration: _buildInputDecoration(
                          hintText: 'Enter topic',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter topic';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_selectedType == 'mcq') ...[
                      const SizedBox(height: 20),
                      _buildOptionsSection(),
                    ],
                    const SizedBox(height: 20),
                    _buildInfoBox(),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveQuestion,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_isLoading ? 'Saving...' : 'Save Question'),
                        style: AdminDashboardStyles.getPrimaryButtonStyle()
                            .copyWith(
                              padding: const MaterialStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AdminDashboardStyles.primary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options (Check the correct answer)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AdminDashboardStyles.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Checkbox(
                  value: _optionCorrect[index],
                  onChanged: (value) {
                    setState(() => _optionCorrect[index] = value ?? false);
                  },
                  activeColor: AdminDashboardStyles.primary,
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: _buildInputDecoration(
                      hintText: 'Option ${index + 1}',
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminDashboardStyles.accentBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.psychology_rounded,
            color: AdminDashboardStyles.accentBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skill Assessment Question',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AdminDashboardStyles.accentBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This question will appear in the Skill Assessment module. Keep it simple and focused on testing core skills.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminDashboardStyles.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
