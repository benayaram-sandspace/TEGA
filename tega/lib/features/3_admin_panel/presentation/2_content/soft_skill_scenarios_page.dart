import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/models/content_quiz_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/content_quiz_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class SoftSkillScenariosPage extends StatefulWidget {
  const SoftSkillScenariosPage({super.key});

  @override
  State<SoftSkillScenariosPage> createState() => _SoftSkillScenariosPageState();
}

class _SoftSkillScenariosPageState extends State<SoftSkillScenariosPage>
    with TickerProviderStateMixin {
  final ContentQuizRepository _contentQuizService = ContentQuizRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SoftSkillScenario> _allScenarios = [];
  List<SoftSkillScenario> _filteredScenarios = [];
  List<String> _categories = [];

  String? _selectedCategory;
  String? _selectedDifficulty;

  bool _isLoading = true;
  bool _isFilterExpanded = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final scenarios = await _contentQuizService.getSoftSkillScenarios();
      final categories = await _contentQuizService.getUniqueCategories();

      if (mounted) {
        setState(() {
          _allScenarios = scenarios;
          _filteredScenarios = scenarios;
          _categories = ["All Categories", ...categories];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredScenarios = _allScenarios.where((scenario) {
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final matchesSearch =
              scenario.title.toLowerCase().contains(searchQuery) ||
              scenario.description.toLowerCase().contains(searchQuery) ||
              scenario.tags.any(
                (tag) => tag.toLowerCase().contains(searchQuery),
              );
          if (!matchesSearch) return false;
        }

        if (_selectedCategory != null &&
            _selectedCategory != "All Categories" &&
            scenario.category != _selectedCategory) {
          return false;
        }

        if (_selectedDifficulty != null &&
            scenario.difficulty != _selectedDifficulty) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
      _searchController.clear();
      _applyFilters();
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != null && _selectedCategory != "All Categories") {
      count++;
    }
    if (_selectedDifficulty != null) count++;
    return count;
  }

  void _addNewScenario() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new scenario functionality coming soon!'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboardStyles.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildFilterSection()),
                    _buildContentSliver(),
                  ],
                ),
        ),
      ),
    );
  }


  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Search scenario title or keyword...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildFilterSection() {
    final activeFilterCount = _getActiveFilterCount();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        onExpansionChanged: (expanded) =>
            setState(() => _isFilterExpanded = expanded),
        title: Row(
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('$activeFilterCount Active'),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
                padding: EdgeInsets.zero,
                side: BorderSide.none,
              ),
            ],
          ],
        ),
        trailing: Icon(
          _isFilterExpanded ? Icons.expand_less : Icons.filter_list,
          color: AppColors.primary,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildDropdown(
                  _categories,
                  'Category',
                  _selectedCategory,
                  (val) => _selectedCategory = val,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    'Easy',
                    'Medium',
                    'Hard',
                  ].map(_buildDifficultyChip).toList(),
                ),
                const Divider(height: 24),
                if (activeFilterCount > 0)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear All Filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String label,
    String? selectedValue,
    Function(String?) onSelected,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => onSelected(value));
        _applyFilters();
      },
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    return ChoiceChip(
      label: Text(difficulty),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedDifficulty = selected ? difficulty : null);
        _applyFilters();
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.background,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildContentSliver() {
    if (_filteredScenarios.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Scenarios Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your search or filters.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildScenarioCard(_filteredScenarios[index]),
          childCount: _filteredScenarios.length,
        ),
      ),
    );
  }

  Widget _buildScenarioCard(SoftSkillScenario scenario) {
    final cardColor = _getDifficultyColor(scenario.difficulty.name);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to scenario details page
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor.withValues(alpha: 0.1), AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: cardColor.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -20,
                right: -20,
                child: Icon(
                  _getScenarioIcon(scenario.category),
                  size: 100,
                  color: cardColor.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: cardColor.withValues(alpha: 0.1),
                        child: Icon(
                          _getScenarioIcon(scenario.category),
                          size: 22,
                          color: cardColor,
                        ),
                      ),
                      title: Text(
                        scenario.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        scenario.category,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scenario.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: scenario.tags
                          .map((tag) => _buildInfoTag(tag, cardColor))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    // Handle menu actions
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'view',
                          child: ListTile(
                            leading: Icon(Icons.visibility_outlined),
                            title: Text('View Details'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text, Color color) {
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

  IconData _getScenarioIcon(String category) {
    switch (category.toLowerCase()) {
      case 'team management':
        return Icons.group_work_outlined;
      case 'communication':
        return Icons.forum_outlined;
      case 'project management':
        return Icons.assignment_turned_in_outlined;
      case 'leadership':
        return Icons.emoji_events_outlined;
      case 'diversity & inclusion':
        return Icons.diversity_3_outlined;
      default:
        return Icons.psychology_outlined;
    }
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
        return AppColors.info;
    }
  }
}
