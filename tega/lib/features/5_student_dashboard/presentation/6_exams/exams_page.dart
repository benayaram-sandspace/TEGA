import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courseExams = [];
  List<Map<String, dynamic>> _filteredExams = [];
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Exams';

  final List<String> _filters = [
    'All Exams',
    'Attempted Exams',
    'Programming Language',
    'Web Technologies',
    'Microsoft Office',
    'Full Stack Development',
    'Artificial Intelligence',
    'Cloud Computing',
    'Cyber Security',
    'Personality Development',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadExams();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredExams = _courseExams.where((exam) {
        final matchesSearch =
            exam['title'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            exam['courseName'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        final matchesFilter =
            _selectedFilter == 'All Exams' ||
            (_selectedFilter == 'Attempted Exams' && exam['attempts'] > 0) ||
            exam['category'] == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _loadExams() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();

      // Fetch enrolled courses to generate exams
      final courses = await api.getEnrolledCourses(headers);

      if (mounted) {
        setState(() {
          _courseExams = courses.map<Map<String, dynamic>>((course) {
            return {
              'id': course['_id'] ?? '',
              'title': '${course['title'] ?? 'Course'} Final Exam',
              'courseName': course['title'] ?? 'Unknown Course',
              'duration': '2 hours',
              'questions': '50 questions',
              'difficulty': course['difficulty'] ?? 'Intermediate',
              'category': course['category'] ?? 'Technical',
              'attempts': 0,
              'maxAttempts': 3,
              'passingScore': 70,
            };
          }).toList();
          _filteredExams = _courseExams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
          )
        : Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: CustomScrollView(
              slivers: [
                // Modern Header with Hero Section
                _buildModernHeader(isDesktop, isTablet),

                // Main Exam Section
                _buildMainExamSection(isDesktop, isTablet),

                // Course Exams Section
                if (_courseExams.isNotEmpty) ...[
                  _buildCourseExamsSection(isDesktop, isTablet),
                ] else ...[
                  _buildNoCourseExamsSection(isDesktop, isTablet),
                ],

                // Bottom Spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: isDesktop ? 40 : 32),
                ),
              ],
            ),
          );
  }

  Widget _buildModernHeader(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        padding: EdgeInsets.all(
          isDesktop
              ? 32
              : isTablet
              ? 28
              : 24,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5FFF), Color(0xFF9C88FF), Color(0xFFB19CD9)],
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5FFF).withOpacity(0.3),
              blurRadius: isDesktop ? 20 : 16,
              offset: Offset(0, isDesktop ? 8 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: isDesktop ? 32 : 28,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exams & Assessments',
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 2),
                      Text(
                        'Test your knowledge and earn certifications',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: isDesktop ? 20 : 18,
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                  Expanded(
                    child: Text(
                      'Complete exams to unlock achievements and certificates',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainExamSection(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Exam',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _buildModernMainExam(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMainExam(bool isDesktop, bool isTablet) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B5FFF),
                    Color(0xFF8F7FFF),
                    Color(0xFFB39DFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B5FFF).withOpacity(0.3),
                    blurRadius: isDesktop ? 20 : 16,
                    offset: Offset(0, isDesktop ? 8 : 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _showMainExamDialog(context, isDesktop, isTablet),
                  borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 28 : 24),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 16 : 12,
                                ),
                              ),
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: isDesktop ? 32 : 28,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tega Main Exam',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 4 : 2),
                                  Text(
                                    'Comprehensive assessment across all domains',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 14 : 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 12 : 8,
                                vertical: isDesktop ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 8 : 6,
                                ),
                              ),
                              child: Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: isDesktop ? 12 : 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 24 : 20),

                        // Features
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernFeatureCard(
                                icon: Icons.library_books_rounded,
                                title: '200+ Questions',
                                subtitle: 'Comprehensive coverage',
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 12 : 8),
                            Expanded(
                              child: _buildModernFeatureCard(
                                icon: Icons.timer_rounded,
                                title: '3 Hours',
                                subtitle: 'Extended duration',
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 12 : 8),
                            Expanded(
                              child: _buildModernFeatureCard(
                                icon: Icons.emoji_events_rounded,
                                title: 'Certificate',
                                subtitle: 'Master certification',
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 24 : 20),

                        // Start Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 12 : 10,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                blurRadius: isDesktop ? 12 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showMainExamDialog(
                                context,
                                isDesktop,
                                isTablet,
                              ),
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 12 : 10,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 20,
                                  vertical: isDesktop ? 16 : 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                    SizedBox(width: isDesktop ? 8 : 6),
                                    Text(
                                      'Start Tega Main Exam',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      height: isDesktop ? 120 : 100, // Fixed height for all cards
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        children: [
          Icon(icon, size: isDesktop ? 24 : 20, color: const Color(0xFFFFD700)),
          SizedBox(height: isDesktop ? 8 : 6),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isDesktop ? 2 : 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseExamsSection(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course Exams',
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 8,
                    vertical: isDesktop ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5FFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                  ),
                  child: Text(
                    '${_filteredExams.length} exams',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 16 : 12),

            // Search and Filters
            _buildModernSearchAndFilters(isDesktop, isTablet),
            SizedBox(height: isDesktop ? 20 : 16),

            // Exams List
            _filteredExams.isNotEmpty
                ? _buildModernCourseExams(isDesktop, isTablet)
                : _buildNoResultsFound(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchAndFilters(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isDesktop ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            style: TextStyle(fontSize: isDesktop ? 16 : 14),
            decoration: InputDecoration(
              hintText: 'Search exams...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isDesktop ? 16 : 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF6B5FFF),
                size: isDesktop ? 24 : 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 16 : 14,
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // Category Filters
        SizedBox(
          height: isDesktop ? 44 : 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: EdgeInsets.only(right: isDesktop ? 10 : 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B5FFF) : Colors.white,
                    borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6B5FFF)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: isDesktop ? 6 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : 12,
                          vertical: isDesktop ? 10 : 8,
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernCourseExams(bool isDesktop, bool isTablet) {
    return Column(
      children: _filteredExams.map((exam) {
        final index = _filteredExams.indexOf(exam);
        final delay = index * 100;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + delay),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: index == _filteredExams.length - 1
                        ? 0
                        : (isDesktop ? 16 : 12),
                  ),
                  child: _buildModernExamCard(exam, isDesktop, isTablet),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildModernExamCard(
    Map<String, dynamic> exam,
    bool isDesktop,
    bool isTablet,
  ) {
    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'easy':
        case 'beginner':
          return const Color(0xFF4CAF50);
        case 'medium':
        case 'intermediate':
          return const Color(0xFFFF9800);
        case 'hard':
        case 'advanced':
          return const Color(0xFFF44336);
        default:
          return const Color(0xFF6B5FFF);
      }
    }

    final difficultyColor = getDifficultyColor(exam['difficulty']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isDesktop ? 12 : 8,
            offset: Offset(0, isDesktop ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExamDialog(context, exam, isDesktop, isTablet),
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6B5FFF),
                        const Color(0xFF8F7FFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    size: isDesktop ? 28 : 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exam['title'],
                              style: TextStyle(
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 8 : 6,
                              vertical: isDesktop ? 4 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 6 : 4,
                              ),
                            ),
                            child: Text(
                              exam['difficulty'],
                              style: TextStyle(
                                fontSize: isDesktop ? 10 : 9,
                                color: difficultyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 6 : 4),
                      Text(
                        exam['courseName'],
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      Row(
                        children: [
                          Flexible(
                            child: _buildModernInfoChip(
                              icon: Icons.timer_outlined,
                              label: exam['duration'],
                              isDesktop: isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 12 : 8),
                          Flexible(
                            child: _buildModernInfoChip(
                              icon: Icons.quiz_outlined,
                              label: exam['questions'],
                              isDesktop: isDesktop,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              '${exam['attempts']}/${exam['maxAttempts']} attempts',
                              style: TextStyle(
                                fontSize: isDesktop ? 12 : 11,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isDesktop ? 18 : 16,
                  color: const Color(0xFF6B5FFF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoChip({
    required IconData icon,
    required String label,
    required bool isDesktop,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isDesktop ? 14 : 12, color: Colors.grey[600]),
        SizedBox(width: isDesktop ? 4 : 2),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 11,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCourseExamsSection(bool isDesktop, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isDesktop
              ? 24
              : isTablet
              ? 20
              : 16,
        ),
        child: _buildNoCourseExams(isDesktop, isTablet),
      ),
    );
  }

  Widget _buildNoResultsFound(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 48
            : isTablet
            ? 40
            : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B5FFF).withOpacity(0.1),
                  const Color(0xFF8F7FFF).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: isDesktop ? 64 : 56,
              color: const Color(0xFF6B5FFF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Exams Found',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
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
                    _searchController.clear();
                    _selectedFilter = 'All Exams';
                    _applyFilters();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 24,
                    vertical: isDesktop ? 14 : 12,
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
        ],
      ),
    );
  }

  Widget _buildNoCourseExams(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop
            ? 48
            : isTablet
            ? 40
            : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B5FFF).withOpacity(0.1),
                  const Color(0xFF8F7FFF).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school_outlined,
              size: isDesktop ? 64 : 56,
              color: const Color(0xFF6B5FFF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Course Exams Yet',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enroll in courses to unlock course-specific exams',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMainExamDialog(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Start Tega Main Exam',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you ready to begin the comprehensive Tega Main Exam?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildDialogInfo(
              Icons.timer_rounded,
              'Duration: 3 hours',
              isDesktop,
            ),
            const SizedBox(height: 8),
            _buildDialogInfo(Icons.quiz_rounded, 'Questions: 200', isDesktop),
            const SizedBox(height: 8),
            _buildDialogInfo(
              Icons.trending_up_rounded,
              'Difficulty: Advanced',
              isDesktop,
            ),
            const SizedBox(height: 8),
            _buildDialogInfo(
              Icons.verified_rounded,
              'Passing Score: 75%',
              isDesktop,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tega Main Exam - Coming Soon!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF6B5FFF),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Start Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExamDialog(
    BuildContext context,
    Map<String, dynamic> exam,
    bool isDesktop,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                exam['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course: ${exam['courseName']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildDialogInfo(
              Icons.timer_rounded,
              'Duration: ${exam['duration']}',
              isDesktop,
            ),
            const SizedBox(height: 8),
            _buildDialogInfo(
              Icons.quiz_rounded,
              'Questions: ${exam['questions']}',
              isDesktop,
            ),
            const SizedBox(height: 8),
            _buildDialogInfo(
              Icons.trending_up_rounded,
              'Difficulty: ${exam['difficulty']}',
              isDesktop,
            ),
            const SizedBox(height: 8),
            _buildDialogInfo(
              Icons.verified_rounded,
              'Passing Score: ${exam['passingScore']}%',
              isDesktop,
            ),
            const SizedBox(height: 8),
            _buildDialogInfo(
              Icons.replay_rounded,
              'Attempts: ${exam['attempts']}/${exam['maxAttempts']}',
              isDesktop,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${exam['title']} - Coming Soon!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF6B5FFF),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Start Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(IconData icon, String text, bool isDesktop) {
    return Row(
      children: [
        Icon(icon, size: isDesktop ? 18 : 16, color: const Color(0xFF6B5FFF)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
