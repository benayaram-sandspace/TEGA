import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/tabs/student_detailed_progress_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late List<StudentProgress> _allStudentProgress;
  List<StudentProgress> _filteredProgressList = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _allStudentProgress = _generateDummyProgressData();
    _filteredProgressList = _allStudentProgress;

    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
          _filterStudentProgress();
        });
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<StudentProgress> _generateDummyProgressData() {
    final names = [
      'Riya Sharma',
      'Amit Kumar',
      'Priya Singh',
      'Vikram Rathod',
      'Sneha Patil',
      'Arjun Verma',
      'Neha Gupta',
      'Rahul Desai',
      'Anjali Mehta',
      'Karan Joshi',
      'Sonia Reddy',
      'Raj Patel',
    ];
    return List.generate(names.length, (index) {
      final statusMap = _getStatus(index);
      return StudentProgress(
        student: Student(
          name: names[index],
          grade: 12 - (index % 5),
          gpa: (4.0 - (index % 8) * 0.15).clamp(2.5, 4.0),
          avatarUrl: 'https://i.pravatar.cc/150?img=${index + 1}',
          status: statusMap['text'] as String,
          statusColor: statusMap['color'] as Color,
        ),
        courseCompletion: (65 + index * 3) / 100,
        mockTestsTaken: 6 + (index % 5),
        totalMockTests: 10,
        engagementLevel: (70 + index * 2) / 100,
      );
    });
  }

  void _filterStudentProgress() {
    List<StudentProgress> results = _allStudentProgress;
    if (_searchQuery.isNotEmpty) {
      results = results
          .where(
            (data) => data.student.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }
    if (_selectedStatus != 'All') {
      results = results
          .where((data) => data.student.status == _selectedStatus)
          .toList();
    }
    setState(() {
      _filteredProgressList = results;
    });
  }

  Map<String, dynamic> _getStatus(int index) {
    switch (index % 3) {
      case 0:
        return {'text': 'Excellent', 'color': DashboardStyles.accentGreen};
      case 1:
        return {'text': 'Good', 'color': DashboardStyles.accentOrange};
      default:
        return {'text': 'Average', 'color': DashboardStyles.primary};
    }
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _filterStudentProgress();
    });
    _searchFocusNode.unfocus();
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopSearch,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by student name...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: DashboardStyles.textDark, fontSize: 16),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
      );
    } else {
      return AppBar(
        title: const Text(
          'Student Progress Tracking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          _buildFilterMenu(),
          IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _filteredProgressList.isEmpty
            ? _buildEmptyState()
            : _buildProgressList(),
      ),
    );
  }

  Widget _buildFilterMenu() {
    final filterOptions = ['All', 'Excellent', 'Good', 'Average'];
    return Stack(
      alignment: Alignment.center,
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (String status) {
            setState(() {
              _selectedStatus = status;
              _filterStudentProgress();
            });
          },
          itemBuilder: (BuildContext context) {
            return filterOptions.map((String choice) {
              return PopupMenuItem<String>(value: choice, child: Text(choice));
            }).toList();
          },
        ),
        if (_selectedStatus != 'All')
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: DashboardStyles.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressList() {
    return ListView.builder(
      key: ValueKey(_filteredProgressList.length),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProgressList.length,
      itemBuilder: (context, index) {
        return _buildAnimatedProgressTile(_filteredProgressList[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Students Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressTile(StudentProgress progressData, int index) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (0.1 * index).clamp(0.0, 1.0),
        (0.5 + 0.1 * index).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: _buildStudentProgressTile(progressData, animation),
      ),
    );
  }

  Widget _buildStudentProgressTile(
    StudentProgress progressData,
    Animation<double> animation,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.cardBackground,
            Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.02)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudentProgressDetailsPage(progressData: progressData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(
                        progressData.student.avatarUrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progressData.student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grade: ${progressData.student.grade} | GPA: ${progressData.student.gpa.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem(
                      'Completion',
                      progressData.courseCompletion,
                      DashboardStyles.accentGreen,
                      animation,
                    ),
                    _buildMetricItem(
                      'Mock Tests',
                      progressData.mockTestsTaken / progressData.totalMockTests,
                      DashboardStyles.primary,
                      animation,
                      isTest: true,
                      progressData: progressData,
                    ),
                    _buildMetricItem(
                      'Engagement',
                      progressData.engagementLevel,
                      DashboardStyles.accentOrange,
                      animation,
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

  Widget _buildMetricItem(
    String label,
    double value,
    Color color,
    Animation<double> animation, {
    bool isTest = false,
    StudentProgress? progressData,
  }) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: isTest ? 1 : (value * animation.value),
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTest ? Colors.grey.shade200 : color,
                        ),
                      ),
                    ),
                    if (isTest && progressData != null)
                      Text(
                        '${progressData.mockTestsTaken}/${progressData.totalMockTests}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      )
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: animation.value * value),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, animatedValue, child) => Text(
                          '${(animatedValue * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
