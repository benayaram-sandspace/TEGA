import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/content_quiz_service.dart';
import '../../models/content_quiz_models.dart';

class SoftSkillScenariosPage extends StatefulWidget {
  const SoftSkillScenariosPage({super.key});

  @override
  State<SoftSkillScenariosPage> createState() => _SoftSkillScenariosPageState();
}

class _SoftSkillScenariosPageState extends State<SoftSkillScenariosPage> {
  final ContentQuizService _contentQuizService = ContentQuizService();
  final TextEditingController _searchController = TextEditingController();
  
  List<SoftSkillScenario> _allScenarios = [];
  List<SoftSkillScenario> _filteredScenarios = [];
  List<String> _categories = [];
  
  String? _selectedCategory;
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
      final scenarios = await _contentQuizService.getSoftSkillScenarios();
      final categories = await _contentQuizService.getUniqueCategories();
      
      setState(() {
        _allScenarios = scenarios;
        _filteredScenarios = scenarios;
        _categories = categories;
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
      _filteredScenarios = _allScenarios.where((scenario) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final matchesSearch = scenario.title.toLowerCase().contains(searchQuery) ||
              scenario.description.toLowerCase().contains(searchQuery) ||
              scenario.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
          if (!matchesSearch) return false;
        }
        
        // Category filter
        if (_selectedCategory != null && scenario.category != _selectedCategory) return false;
        
        // Difficulty filter
        if (_selectedDifficulty != null && scenario.difficulty != _selectedDifficulty) return false;
        
        return true;
      }).toList();
    });
  }

  // void _clearFilters() {
  //   setState(() {
  //     _selectedCategory = null;
  //     _selectedDifficulty = null;
  //     _searchController.clear();
  //     _filteredScenarios = _allScenarios;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text(
          'Soft Skill Scenario Library',
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
            onPressed: _addNewScenario,
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
                      hintText: 'Search scenario title or keyword',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.pureWhite,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ..._categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Scenarios list
                Expanded(
                  child: _filteredScenarios.isEmpty
                      ? const Center(
                          child: Text(
                            'No scenarios found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredScenarios.length,
                          itemBuilder: (context, index) {
                            return _buildScenarioCard(_filteredScenarios[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildScenarioCard(SoftSkillScenario scenario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.deepBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scenario.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.pureWhite,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warmOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scenario.tags.join(', '),
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Illustration
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getScenarioIcon(scenario.category),
                size: 40,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getScenarioIcon(String category) {
    switch (category.toLowerCase()) {
      case 'team management':
        return Icons.group;
      case 'communication':
        return Icons.chat;
      case 'project management':
        return Icons.assignment;
      case 'leadership':
        return Icons.leaderboard;
      case 'diversity & inclusion':
        return Icons.diversity_3;
      default:
        return Icons.psychology;
    }
  }

  void _addNewScenario() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new scenario functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

