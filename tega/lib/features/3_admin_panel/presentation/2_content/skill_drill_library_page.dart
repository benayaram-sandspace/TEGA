import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/models/content_quiz_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/content_quiz_repository.dart';
import 'create_skill_drill_page.dart';

class SkillDrillLibraryPage extends StatefulWidget {
  const SkillDrillLibraryPage({super.key});

  @override
  State<SkillDrillLibraryPage> createState() => _SkillDrillLibraryPageState();
}

class _SkillDrillLibraryPageState extends State<SkillDrillLibraryPage> {
  final ContentQuizRepository _contentQuizService = ContentQuizRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SkillDrill> _allDrills = [];
  List<SkillDrill> _filteredDrills = [];
  List<String> _skills = [];
  List<String> _questionTypes = [];

  String? _selectedSkill;
  String? _selectedQuestionType;
  String? _selectedDifficulty;

  bool _isLoading = true;
  bool _isFilterExpanded = false;

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

      if (mounted) {
        setState(() {
          _allDrills = drills;
          _filteredDrills = drills;
          _skills = ["All Skills", ...skills]; // Add "All" option
          _questionTypes = ["All Types", ...questionTypes]; // Add "All" option
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
      _filteredDrills = _allDrills.where((drill) {
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final matchesSearch =
              drill.title.toLowerCase().contains(searchQuery) ||
              drill.subject.toLowerCase().contains(searchQuery) ||
              drill.skill.toLowerCase().contains(searchQuery) ||
              drill.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
          if (!matchesSearch) return false;
        }
        if (_selectedSkill != null &&
            _selectedSkill != "All Skills" &&
            drill.skill != _selectedSkill) {
          return false;
        }
        if (_selectedQuestionType != null &&
            _selectedQuestionType != "All Types" &&
            drill.questionType != _selectedQuestionType) {
          return false;
        }
        if (_selectedDifficulty != null &&
            drill.difficulty != _selectedDifficulty) {
          return false;
        }
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
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildFilterSection()),
                _buildContentSliver(),
              ],
            ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      title: const Text(
        'Skill Drill Library',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      pinned: true,
      floating: true,
      elevation: 1.0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateSkillDrillPage(),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Search by question, subject, or tag...',
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
        title: const Text(
          'Filters',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
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
                  _skills,
                  'Skill',
                  _selectedSkill,
                  (val) => _selectedSkill = val,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  _questionTypes,
                  'Question Type',
                  _selectedQuestionType,
                  (val) => _selectedQuestionType = val,
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
    if (_filteredDrills.isEmpty) {
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
                'No Questions Found',
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
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildQuestionCard(_filteredDrills[index]),
          childCount: _filteredDrills.length,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(SkillDrill drill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to a detail or preview page
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(
                drill.imageUrls.isNotEmpty ? drill.imageUrls.first : '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(
                drill.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    _buildInfoTag(drill.subject, AppColors.mutedPurple),
                    const SizedBox(width: 8),
                    _buildInfoTag(
                      drill.difficulty,
                      _getDifficultyColor(drill.difficulty),
                    ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle menu item selection
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ),
          ],
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
