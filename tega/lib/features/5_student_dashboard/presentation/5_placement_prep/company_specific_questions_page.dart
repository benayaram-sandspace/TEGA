import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompanySpecificQuestionsPage extends StatefulWidget {
  const CompanySpecificQuestionsPage({super.key});

  @override
  State<CompanySpecificQuestionsPage> createState() =>
      _CompanySpecificQuestionsPageState();
}

class _CompanySpecificQuestionsPageState
    extends State<CompanySpecificQuestionsPage> {
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  bool _isLoading = false;

  final List<String> _categories = [
    'All',
    'Technical',
    'Aptitude',
    'Reasoning',
    'Verbal',
    'HR',
    'Coding',
  ];

  final List<String> _difficulties = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF6B5FFF),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6B5FFF).withOpacity(0.08),
                    const Color(0xFF8F7FFF).withOpacity(0.04),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 16 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B5FFF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: isDesktop ? 32 : 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice & Excel',
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 20
                                : isTablet
                                ? 18
                                : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Master company-specific questions and ace your interviews',
                          style: TextStyle(
                            fontSize: isDesktop ? 13 : 12,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filters Section
            Container(
              padding: EdgeInsets.all(
                isDesktop
                    ? 20
                    : isTablet
                    ? 16
                    : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Category',
                      value: _selectedCategory,
                      items: _categories,
                      icon: Icons.category_rounded,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12),
                  // Difficulty Dropdown
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Difficulty',
                      value: _selectedDifficulty,
                      items: _difficulties,
                      icon: Icons.speed_rounded,
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      getDifficultyColor: true,
                    ),
                  ),
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B5FFF),
                      ),
                    )
                  : _buildQuestionsList(isDesktop, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required bool isDesktop,
    required bool isTablet,
    bool getDifficultyColor = false,
  }) {
    Color getColor(String item) {
      if (!getDifficultyColor) return const Color(0xFF6B5FFF);
      switch (item) {
        case 'Easy':
          return const Color(0xFF4CAF50);
        case 'Medium':
          return const Color(0xFFFF9800);
        case 'Hard':
          return const Color(0xFFF44336);
        default:
          return const Color(0xFF6B5FFF);
      }
    }

    final currentColor = getColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: isDesktop ? 16 : 14, color: currentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isDesktop ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: isDesktop ? 42 : 38,
          decoration: BoxDecoration(
            color: currentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: currentColor),
              style: TextStyle(
                fontSize: isDesktop ? 13 : 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 12 : 10,
                vertical: 0,
              ),
              isDense: true,
              items: items.map((String item) {
                final itemColor = getColor(item);
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: itemColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontWeight: item == value
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList(bool isDesktop, bool isTablet) {
    // TODO: Replace with actual data from backend
    // final hasQuestions = false;

    // For now, always show empty state until backend integration
    if (true) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isDesktop
                ? 40
                : isTablet
                ? 32
                : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 32 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6B5FFF).withOpacity(0.1),
                      const Color(0xFF8F7FFF).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: isDesktop
                      ? 80
                      : isTablet
                      ? 70
                      : 60,
                  color: const Color(0xFF6B5FFF),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Questions Available',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 22
                      : isTablet
                      ? 20
                      : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedCategory != 'All' || _selectedDifficulty != 'All'
                    ? 'Try adjusting your filters or check back later'
                    : 'Questions will be available soon',
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_selectedCategory != 'All' || _selectedDifficulty != 'All')
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B5FFF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _selectedDifficulty = 'All';
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 28 : 24,
                            vertical: isDesktop ? 16 : 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Clear Filters',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isDesktop ? 15 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // TODO: When data is available from backend, implement questions list here
    // return ListView.builder(
    //   padding: EdgeInsets.all(isDesktop ? 20 : isTablet ? 16 : 12),
    //   itemCount: questions.length,
    //   itemBuilder: (context, index) {
    //     return QuestionCard(question: questions[index]);
    //   },
    // );
  }
}
