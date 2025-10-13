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
    'Programming Languages',
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
            exam['category'].toString().toLowerCase() ==
                _selectedFilter.toLowerCase();

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
        : SingleChildScrollView(
            padding: EdgeInsets.all(
              isDesktop
                  ? 24
                  : isTablet
                  ? 20
                  : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tega Main Exam - Featured
                _buildTegaMainExam(isDesktop, isTablet),
                SizedBox(height: isDesktop ? 40 : 32),

                // Course Exams Section
                if (_courseExams.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Course Exams',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${_filteredExams.length} exams',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search and Filters
                  _buildSearchAndFilters(isDesktop, isTablet),
                  SizedBox(height: isDesktop ? 24 : 20),

                  // Exams Grid
                  _filteredExams.isNotEmpty
                      ? _buildCourseExams(isDesktop, isTablet)
                      : _buildNoResultsFound(isDesktop, isTablet),
                ] else ...[
                  _buildNoCourseExams(isDesktop, isTablet),
                ],
              ],
            ),
          );
  }

  Widget _buildTegaMainExam(bool isDesktop, bool isTablet) {
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
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B5FFF).withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _showMainExamDialog(context, isDesktop, isTablet),
                  borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                  child: Padding(
                    padding: EdgeInsets.all(
                      isDesktop
                          ? 40
                          : isTablet
                          ? 32
                          : 24,
                    ),
                    child: Column(
                      children: [
                        // Icon and Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 12 : 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: isDesktop ? 32 : 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                'Tega Main Exam',
                                style: TextStyle(
                                  fontSize: isDesktop
                                      ? 32
                                      : isTablet
                                      ? 28
                                      : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 20 : 16),

                        // Divider
                        Container(
                          height: 3,
                          width: isDesktop ? 100 : 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: isDesktop ? 24 : 20),

                        // Description
                        Text(
                          'Welcome to the comprehensive Tega Main Exam - your gateway to demonstrating mastery across all core technical domains. This flagship assessment evaluates your proficiency in programming, web development, artificial intelligence, cloud computing, cybersecurity, and office productivity tools.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : 14,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 32 : 24),

                        // Features Grid
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: isDesktop ? 24 : 16,
                          runSpacing: 16,
                          children: [
                            _buildFeatureCard(
                              icon: Icons.library_books_rounded,
                              title: 'Comprehensive Coverage',
                              description:
                                  'Tests knowledge across 6 major technical domains with 200+ carefully crafted questions',
                              isDesktop: isDesktop,
                              isTablet: isTablet,
                            ),
                            _buildFeatureCard(
                              icon: Icons.timer_rounded,
                              title: 'Extended Duration',
                              description:
                                  '3-hour comprehensive exam with adaptive difficulty based on your performance',
                              isDesktop: isDesktop,
                              isTablet: isTablet,
                            ),
                            _buildFeatureCard(
                              icon: Icons.emoji_events_rounded,
                              title: 'Premium Certification',
                              description:
                                  'Earn the prestigious Tega Master Certification upon successful completion',
                              isDesktop: isDesktop,
                              isTablet: isTablet,
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 32 : 24),

                        // Start Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 16,
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
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 48 : 40,
                                  vertical: isDesktop ? 18 : 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Start Tega Main Exam',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 18 : 16,
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
                        SizedBox(height: isDesktop ? 16 : 12),

                        // Exam Info
                        Text(
                          'Estimated time: 3 hours • 200 questions • Advanced difficulty',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 13,
                            color: Colors.white.withOpacity(0.8),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      width: isDesktop
          ? 280
          : isTablet
          ? 240
          : double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: isDesktop ? 40 : 36, color: const Color(0xFFFFD700)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: isDesktop ? 13 : 12,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search exams...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isDesktop ? 15 : 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: const Color(0xFF6B5FFF),
                size: isDesktop ? 24 : 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                      color: Colors.grey[400],
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
          height: isDesktop ? 48 : 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: EdgeInsets.only(right: isDesktop ? 12 : 10),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF6B5FFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: isDesktop ? 14 : 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF6B5FFF)
                          : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  showCheckmark: false,
                  elevation: isSelected ? 2 : 0,
                  pressElevation: 4,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseExams(bool isDesktop, bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop
            ? 3
            : isTablet
            ? 2
            : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop
            ? 1.3
            : isTablet
            ? 1.2
            : 1.4,
      ),
      itemCount: _filteredExams.length,
      itemBuilder: (context, index) {
        final exam = _filteredExams[index];
        final delay = index * 100;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + delay),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildExamCard(exam, isDesktop, isTablet),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExamCard(
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExamDialog(context, exam, isDesktop, isTablet),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6B5FFF),
                            const Color(0xFF8F7FFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        size: isDesktop ? 24 : 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam['courseName'],
                            style: TextStyle(
                              fontSize: isDesktop ? 12 : 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exam['difficulty'],
                              style: TextStyle(
                                fontSize: 10,
                                color: difficultyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  exam['title'],
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Exam Info
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: exam['duration'],
                      isDesktop: isDesktop,
                    ),
                    _buildInfoChip(
                      icon: Icons.quiz_outlined,
                      label: exam['questions'],
                      isDesktop: isDesktop,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress
                Row(
                  children: [
                    Text(
                      'Attempts: ${exam['attempts']}/${exam['maxAttempts']}',
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDesktop,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isDesktop ? 14 : 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : 11,
            color: Colors.grey[600],
          ),
        ),
      ],
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
