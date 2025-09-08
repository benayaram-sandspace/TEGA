import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/content_quiz_service.dart';
import '../../models/content_quiz_models.dart';
import 'add_question_page.dart';
import 'create_skill_drill_page.dart';

class SkillDrillLibraryPage extends StatefulWidget {
  const SkillDrillLibraryPage({super.key});

  @override
  State<SkillDrillLibraryPage> createState() => _SkillDrillLibraryPageState();
}

class _SkillDrillLibraryPageState extends State<SkillDrillLibraryPage> {
  final ContentQuizService _contentQuizService = ContentQuizService();
  final TextEditingController _searchController = TextEditingController();
  
  List<SkillDrill> _allDrills = [];
  List<SkillDrill> _filteredDrills = [];
  List<String> _skills = [];
  List<String> _questionTypes = [];
  
  String? _selectedSkill;
  String? _selectedQuestionType;
  String? _selectedDifficulty;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final drills = await _contentQuizService.getSkillDrills();
      final skills = await _contentQuizService.getUniqueSkills();
      final questionTypes = await _contentQuizService.getUniqueQuestionTypes();
      
      setState(() {
        _allDrills = drills;
        _filteredDrills = drills;
        _skills = skills;
        _questionTypes = questionTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDrills = _allDrills.where((drill) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final matchesSearch = drill.question.toLowerCase().contains(searchQuery) ||
              drill.subject.toLowerCase().contains(searchQuery) ||
              drill.skill.toLowerCase().contains(searchQuery) ||
              drill.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
          if (!matchesSearch) return false;
        }
        
        // Skill filter
        if (_selectedSkill != null && drill.skill != _selectedSkill) return false;
        
        // Question type filter
        if (_selectedQuestionType != null && drill.questionType != _selectedQuestionType) return false;
        
        // Difficulty filter
        if (_selectedDifficulty != null && drill.difficulty != _selectedDifficulty) return false;
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSkill = null;
      _selectedQuestionType = null;
      _selectedDifficulty = null;
      _searchController.clear();
      _filteredDrills = _allDrills;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text(
          'Skill Drill Library',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateSkillDrillPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Question text or keyword',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
                ),
                
                // Filter section
                _buildFilterSection(),
                
                // Questions list
                Expanded(
                  child: _filteredDrills.isEmpty
                      ? const Center(
                          child: Text(
                            'No questions found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDrills.length,
                          itemBuilder: (context, index) {
                            return _buildQuestionCard(_filteredDrills[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddQuestionPage(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.pureWhite),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Drills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Skill dropdown
          DropdownButtonFormField<String>(
            value: _selectedSkill,
            decoration: const InputDecoration(
              labelText: 'Skill',
              border: OutlineInputBorder(),
            ),
            items: _skills.map((skill) {
              return DropdownMenuItem(
                value: skill,
                child: Text(
                  skill,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSkill = value;
              });
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Question Type dropdown
          DropdownButtonFormField<String>(
            value: _selectedQuestionType,
            decoration: const InputDecoration(
              labelText: 'Question Type',
              border: OutlineInputBorder(),
            ),
            items: _questionTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedQuestionType = value;
              });
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Difficulty levels
          const Text(
            'Difficulty Levels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDifficultyChip('Easy'),
              const SizedBox(width: 8),
              _buildDifficultyChip('Medium'),
              const SizedBox(width: 8),
              _buildDifficultyChip('Hard'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = isSelected ? null : difficulty;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGray,
          ),
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(SkillDrill drill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
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
          // Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: DecorationImage(
                image: NetworkImage(drill.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      drill.subject,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(', '),
                    Text(
                      drill.difficulty,
                      style: TextStyle(
                        color: _getDifficultyColor(drill.difficulty),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

