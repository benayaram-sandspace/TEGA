import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class ManageQuestionsTab extends StatefulWidget {
  const ManageQuestionsTab({super.key});

  @override
  State<ManageQuestionsTab> createState() => _ManageQuestionsTabState();
}

class _ManageQuestionsTabState extends State<ManageQuestionsTab> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _questions = [];
  List<String> _companies = [];
  
  String? _selectedCompany;
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _loadQuestions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminCompanyList),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final companies = (data['companies'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _companies = companies.map((c) {
                // Extract company name from object or use string directly
                if (c is Map<String, dynamic>) {
                  return (c['name'] ?? c['companyName'] ?? '').toString();
                }
                return c.toString();
              }).where((name) => name.isNotEmpty).toList();
            });
          }
        }
      }
    } catch (e) {
      // Silently fail - companies list is optional
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminCompanyQuestionsAll),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
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

  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.delete(
        Uri.parse(ApiEndpoints.adminCompanyQuestionDelete(questionId)),
        headers: headers,
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question deleted successfully'), backgroundColor: Colors.green),
          );
          _loadQuestions();
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to delete question: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting question: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  List<Map<String, dynamic>> _getFilteredQuestions() {
    Iterable<Map<String, dynamic>> items = _questions;

    // Company filter
    if (_selectedCompany != null) {
      items = items.where((q) {
        final company = (q['companyName'] ?? '').toString();
        return company == _selectedCompany;
      });
    }

    // Category filter
    if (_selectedCategory != null) {
      items = items.where((q) {
        final category = (q['category'] ?? '').toString();
        return category == _selectedCategory;
      });
    }

    // Difficulty filter
    if (_selectedDifficulty != null) {
      items = items.where((q) {
        final difficulty = (q['difficulty'] ?? '').toString().toLowerCase();
        return difficulty == _selectedDifficulty?.toLowerCase();
      });
    }

    return items.toList();
  }

  double _calculateSuccessRate(Map<String, dynamic> question) {
    final totalAttempts = (question['totalAttempts'] ?? 0) as int;
    final correctAttempts = (question['correctAttempts'] ?? 0) as int;
    if (totalAttempts == 0) return 0.0;
    return (correctAttempts / totalAttempts) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: 20),
          _buildQuestionList(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
                  color: AdminDashboardStyles.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.filter_alt_rounded, color: AdminDashboardStyles.accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Search & Filter Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    Expanded(child: _buildCompanyDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDifficultyDropdown()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCompanyDropdown(),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 12),
                    _buildDifficultyDropdown(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCompany,
      isExpanded: true,
      decoration: _inputDecoration(
        hintText: 'All Companies',
        prefixIcon: Icons.business_rounded,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Companies')),
        ..._companies.map((company) => DropdownMenuItem(
              value: company,
              child: Text(company, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (value) => setState(() => _selectedCompany = value),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      isExpanded: true,
      decoration: _inputDecoration(
        hintText: 'All Categories',
        prefixIcon: Icons.book_outlined,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Categories')),
        DropdownMenuItem(value: 'technical', child: Text('Technical')),
        DropdownMenuItem(value: 'aptitude', child: Text('Aptitude')),
        DropdownMenuItem(value: 'reasoning', child: Text('Reasoning')),
        DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
        DropdownMenuItem(value: 'coding', child: Text('Coding')),
        DropdownMenuItem(value: 'hr', child: Text('HR')),
      ],
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      isExpanded: true,
      decoration: _inputDecoration(
        hintText: 'All Difficulties',
        prefixIcon: Icons.person_rounded,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Difficulties')),
        DropdownMenuItem(value: 'easy', child: Text('Easy')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'hard', child: Text('Hard')),
      ],
      onChanged: (value) => setState(() => _selectedDifficulty = value),
    );
  }


  InputDecoration _inputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(prefixIcon, color: AdminDashboardStyles.textLight, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
    );
  }

  Widget _buildQuestionList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredQuestions = _getFilteredQuestions();

    if (filteredQuestions.isEmpty) {
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
            Text(
              'No questions found',
              style: TextStyle(fontWeight: FontWeight.w700, color: AdminDashboardStyles.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting filters or add new questions',
              style: AdminDashboardStyles.statTitle,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredQuestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildQuestionCard(filteredQuestions[index]);
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final companyName = (question['companyName'] ?? '').toString();
    final difficulty = (question['difficulty'] ?? 'medium').toString();
    final category = (question['category'] ?? 'technical').toString();
    final questionText = (question['questionText'] ?? question['question'] ?? '').toString();
    final questionType = (question['questionType'] ?? 'mcq').toString();
    final points = (question['points'] ?? 10).toString();
    final successRate = _calculateSuccessRate(question);
    final questionId = (question['_id'] ?? question['id']).toString();

    Color getDifficultyColor(String diff) {
      switch (diff.toLowerCase()) {
        case 'hard':
          return const Color(0xFFEF4444);
        case 'medium':
          return const Color(0xFFF59E0B);
        case 'easy':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF6B7280);
      }
    }

    Color getCategoryColor(String cat) {
      switch (cat.toLowerCase()) {
        case 'technical':
          return const Color(0xFF8B5CF6);
        case 'coding':
          return const Color(0xFF3B82F6);
        case 'aptitude':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF6B7280);
      }
    }

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
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(companyName, const Color(0xFFDBEAFE)),
                    _buildTag(difficulty, getDifficultyColor(difficulty).withOpacity(0.2)),
                    _buildTag(category, getCategoryColor(category).withOpacity(0.2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteQuestion(questionId),
                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Flexible(
                      child: _buildMetadataItem(
                        icon: Icons.description_rounded,
                        label: 'Type',
                        value: questionType,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: _buildMetadataItem(
                        icon: Icons.person_rounded,
                        label: 'Points',
                        value: points,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: _buildMetadataItem(
                        icon: Icons.trending_up_rounded,
                        label: 'Success Rate',
                        value: '${successRate.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataItem(
                      icon: Icons.description_rounded,
                      label: 'Type',
                      value: questionType,
                    ),
                    const SizedBox(height: 8),
                    _buildMetadataItem(
                      icon: Icons.person_rounded,
                      label: 'Points',
                      value: points,
                    ),
                    const SizedBox(height: 8),
                    _buildMetadataItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Success Rate',
                      value: '${successRate.toStringAsFixed(0)}%',
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AdminDashboardStyles.textLight),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: AdminDashboardStyles.textLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
