import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/placement_prep/edit_question_page.dart';

class QuestionsTab extends StatefulWidget {
  const QuestionsTab({super.key});

  @override
  State<QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<QuestionsTab> {
  final _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedCategory;
  String? _selectedDifficulty;

  bool _isLoading = false;
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _questions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          _buildQuestionList(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AdminDashboardStyles.textDark,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.filter_alt_rounded, color: AdminDashboardStyles.accentBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Search & Filter Questions', style: labelStyle),
            ],
          ),
          const SizedBox(height: 16),

          // Stack fields vertically to avoid overflow on small screens
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildTypeDropdown(),
          const SizedBox(height: 12),
          _buildCategoryDropdown(),
          const SizedBox(height: 12),
          _buildDifficultyDropdown(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: _inputDecoration(
        hintText: 'Search questions...',
        prefixIcon: Icons.search_rounded,
      ),
      onChanged: (_) {
        // Will hook into search later
        setState(() {});
      },
    );
  }

  Widget _buildTypeDropdown() {
    final items = const [
      DropdownMenuItem(value: null, child: Text('All Types')),
      DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
      DropdownMenuItem(value: 'coding', child: Text('Coding')),
      DropdownMenuItem(value: 'subjective', child: Text('Subjective')),
      DropdownMenuItem(value: 'behavioral', child: Text('Behavioral')),
    ];
    return DropdownButtonFormField<String?>(
      value: _selectedType,
      isExpanded: true,
      decoration: _inputDecoration(hintText: 'All Types', prefixIcon: Icons.description_rounded),
      items: items,
      onChanged: (v) => setState(() => _selectedType = v),
    );
  }

  Widget _buildCategoryDropdown() {
    final items = const [
      DropdownMenuItem(value: null, child: Text('All Categories')),
      DropdownMenuItem(value: 'assessment', child: Text('Assessment')),
      DropdownMenuItem(value: 'technical', child: Text('Technical')),
      DropdownMenuItem(value: 'interview', child: Text('Interview')),
      DropdownMenuItem(value: 'aptitude', child: Text('Aptitude')),
      DropdownMenuItem(value: 'logical', child: Text('Logical')),
      DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
    ];
    return DropdownButtonFormField<String?>(
      value: _selectedCategory,
      isExpanded: true,
      decoration: _inputDecoration(hintText: 'All Categories', prefixIcon: Icons.book_outlined),
      items: items,
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _buildDifficultyDropdown() {
    final items = const [
      DropdownMenuItem(value: null, child: Text('All Difficulties')),
      DropdownMenuItem(value: 'easy', child: Text('Easy')),
      DropdownMenuItem(value: 'medium', child: Text('Medium')),
      DropdownMenuItem(value: 'hard', child: Text('Hard')),
    ];
    return DropdownButtonFormField<String?>(
      value: _selectedDifficulty,
      isExpanded: true,
      decoration: _inputDecoration(hintText: 'All Difficulties', prefixIcon: Icons.military_tech_rounded),
      items: items,
      onChanged: (v) => setState(() => _selectedDifficulty = v),
    );
  }

  InputDecoration _inputDecoration({required String hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AdminDashboardStyles.textLight, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(Uri.parse(ApiEndpoints.adminPlacementQuestions), headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          // Backend returns 'questions' array (not 'data')
          final list = (data['questions'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _questions = List<Map<String, dynamic>>.from(list);
              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch questions');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch questions: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildQuestionList() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    // Simple client-side filter (search/type/category/difficulty) for now
    Iterable<Map<String, dynamic>> items = _questions;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((e) =>
          (e['title'] ?? '').toString().toLowerCase().contains(q) ||
          (e['question'] ?? e['description'] ?? '').toString().toLowerCase().contains(q));
    }
    if (_selectedType != null) {
      items = items.where((e) {
        final questionType = (e['type'] ?? '').toString().toLowerCase();
        return questionType == _selectedType?.toLowerCase();
      });
    }
    if (_selectedCategory != null) {
      items = items.where((e) => (e['category'] ?? '').toString() == _selectedCategory);
    }
    if (_selectedDifficulty != null) {
      items = items.where((e) => (e['difficulty'] ?? '').toString().toLowerCase() == _selectedDifficulty);
    }

    final list = items.toList();
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.live_help_rounded, color: AdminDashboardStyles.primary, size: 40),
            const SizedBox(height: 10),
            Text('No questions found', style: TextStyle(fontWeight: FontWeight.w700, color: AdminDashboardStyles.textDark)),
            const SizedBox(height: 4),
            Text('Try adjusting filters or add new questions', style: AdminDashboardStyles.statTitle),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildQuestionCard(item);
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Untitled').toString();
    final desc = (item['question'] ?? item['description'] ?? '').toString();
    final difficulty = (item['difficulty'] ?? 'easy').toString().toLowerCase();
    final type = (item['questionType'] ?? item['type'] ?? 'mcq').toString().toLowerCase();
    final source = (item['source'] ?? 'Skill Assessment').toString();
    final module = (item['module'] is Map) ? (item['module']['title'] ?? 'assessment') : (item['module'] ?? 'assessment');
    final category = (item['category'] ?? 'General').toString();

    Color diffColor;
    switch (difficulty) {
      case 'medium':
        diffColor = const Color(0xFFFFC107);
        break;
      case 'hard':
        diffColor = const Color(0xFFEF4444);
        break;
      default:
        diffColor = const Color(0xFF22C55E);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3FF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminDashboardStyles.borderLight),
            ),
            child: Icon(Icons.psychology_alt_rounded, color: AdminDashboardStyles.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionIcon(Icons.edit_rounded, AdminDashboardStyles.accentBlue, onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditQuestionPage(question: item),
                        ),
                      );
                      if (result == true) {
                        _loadQuestions(); // Reload questions after successful update
                      }
                    }),
                    const SizedBox(width: 8),
                    _actionIcon(Icons.delete_rounded, AdminDashboardStyles.statusError, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete not implemented')));
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(difficulty, diffColor),
                    _chip(type, const Color(0xFF60A5FA)),
                    _chip(source, const Color(0xFFA7F3D0)),
                  ],
                ),
                const SizedBox(height: 12),
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: AdminDashboardStyles.statTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.badge_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(module.toString(), style: AdminDashboardStyles.statTitle),
                    const SizedBox(width: 16),
                    const Icon(Icons.category_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(category, style: AdminDashboardStyles.statTitle),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _readableColorOn(color.withOpacity(0.15), fallback: color),
        ),
      ),
    );
  }

  Color _readableColorOn(Color background, {required Color fallback}) {
    // Quick contrast check; if background is light, return darker text (fallback)
    final luminance = background.computeLuminance();
    return luminance > 0.6 ? Colors.black87 : fallback;
  }

  Widget _actionIcon(IconData icon, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

