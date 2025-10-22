import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/5_student_dashboard/data/models/student_model.dart';
import 'package:tega/data/colleges_data.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/create_student_page.dart';
import 'student_profile_page.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AdminDashboardService _dashboardService = AdminDashboardService();

  String _selectedCollege = 'All';
  String _selectedBranch = 'All';
  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // Enhanced animation controllers
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  // Get colleges list with "All" option
  List<String> get collegeOptions => ['All', ...collegesData];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchStudentsFromAPI();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      50, // Maximum expected students
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 30)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
        .toList();

    _slideAnimations = _animationControllers
        .map(
          (controller) =>
              Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              ),
        )
        .toList();
  }

  void _startStaggeredAnimations() {
    for (
      int i = 0;
      i < _filteredStudents.length && i < _animationControllers.length;
      i++
    ) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  void _navigateToCreateStudentPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateStudentPage(
          onStudentCreated: () {
            _fetchStudentsFromAPI(); // Refresh student data
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchStudentsFromAPI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;

      // Use college-specific API if a specific college is selected
      if (_selectedCollege != 'All') {
        data = await _dashboardService.getStudentsByCollege(_selectedCollege);
      } else {
        data = await _dashboardService.getAllStudents();
      }

      if (data['success'] == true) {
        final List<dynamic> studentsJson = data['students'] ?? [];

        setState(() {
          _students = studentsJson.map((json) {
            return Student(
              id: json['_id'] ?? json['id'] ?? '',
              name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'
                  .trim(),
              email: json['email'] ?? '',
              college: json['institute'] ?? json['college'] ?? 'No Institute',
              branch: json['branch'] ?? 'Not specified',
              year: json['yearOfStudy']?.toString() ?? json['year']?.toString(),
              studentId: json['studentId'] ?? json['id'],
              status: json['status'] ?? 'Active',
              cgpa: json['cgpa']?.toDouble(),
              percentage: json['percentage']?.toDouble(),
              jobReadiness: json['jobReadiness']?.toDouble(),
            );
          }).toList();
          _isLoading = false;
          _applyFilters();
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load students');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        // Use empty list on error
        _students = [];
        _filteredStudents = [];
      });
    }
  }

  void _applyFilters() {
    for (var controller in _animationControllers) {
      controller.reset();
    }
    setState(() {
      _filteredStudents = _students.where((student) {
        // Search filter
        bool matchesSearch =
            _searchController.text.isEmpty ||
            student.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            student.college.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (student.email?.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false) ||
            (student.studentId?.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false);

        // Branch filter (since college filter is handled by API)
        bool matchesBranch =
            _selectedBranch == 'All' ||
            (student.branch?.toLowerCase().contains(
                  _selectedBranch.toLowerCase(),
                ) ??
                false);

        return matchesSearch && matchesBranch;
      }).toList();
    });
    _startStaggeredAnimations();
  }

  void _onCollegeChanged(String? newValue) {
    if (newValue != null && newValue != _selectedCollege) {
      setState(() {
        _selectedCollege = newValue;
      });
      // Refresh data when college changes
      _fetchStudentsFromAPI();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _buildCreateStudentFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: GestureDetector(
        onTap: () {
          // Unfocus any text fields when tapping outside
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // Filter Section
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 12 : 16,
              ),
              child: _buildFilterSection(screenWidth),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState(screenWidth)
                  : _filteredStudents.isEmpty
                  ? _buildEmptyState(screenWidth)
                  : _buildStudentList(screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AdminDashboardStyles.primary.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Search Bar
            GestureDetector(
              onTap: () {
                // Prevent parent GestureDetector from unfocusing
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _applyFilters(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: isSmallScreen
                        ? 'Search students...'
                        : 'Search students by name or college...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AdminDashboardStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        size: isSmallScreen ? 18 : 20,
                        color: AdminDashboardStyles.primary,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: isSmallScreen ? 18 : 20,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 14 : 16),
            // Filters Label
            Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: isSmallScreen ? 14 : 16,
                  color: AdminDashboardStyles.textLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AdminDashboardStyles.textLight,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            // Responsive Filter Dropdowns
            GestureDetector(
              onTap: () {
                // Prevent parent GestureDetector from unfocusing
              },
              child: isSmallScreen
                  ? Column(
                      children: [
                        _buildSearchableCollegeDropdown(
                          'College',
                          _selectedCollege,
                          Icons.school_rounded,
                          screenWidth,
                        ),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          'Branch',
                          _selectedBranch,
                          [
                            'All',
                            'B.Tech CSE',
                            'B.Tech IT',
                            'B.Com',
                            'BBA',
                            'B.Sc',
                          ],
                          (value) {
                            setState(() => _selectedBranch = value!);
                            _applyFilters();
                          },
                          Icons.category_rounded,
                          screenWidth,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildSearchableCollegeDropdown(
                            'College',
                            _selectedCollege,
                            Icons.school_rounded,
                            screenWidth,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            'Branch',
                            _selectedBranch,
                            [
                              'All',
                              'B.Tech CSE',
                              'B.Tech IT',
                              'B.Com',
                              'BBA',
                              'B.Sc',
                            ],
                            (value) {
                              setState(() => _selectedBranch = value!);
                              _applyFilters();
                            },
                            Icons.category_rounded,
                            screenWidth,
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

  Widget _buildSearchableCollegeDropdown(
    String label,
    String value,
    IconData icon,
    double screenWidth,
  ) {
    final isSmallScreen = screenWidth < 600;

    return GestureDetector(
      onTap: () => _showCollegeSearchDialog(screenWidth),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 10 : 12,
                isSmallScreen ? 8 : 10,
                isSmallScreen ? 10 : 12,
                isSmallScreen ? 4 : 6,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: isSmallScreen ? 13 : 14,
                    color: AdminDashboardStyles.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: AdminDashboardStyles.textLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 10 : 12,
                0,
                isSmallScreen ? 10 : 12,
                isSmallScreen ? 8 : 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    Icons.search_rounded,
                    size: isSmallScreen ? 18 : 20,
                    color: AdminDashboardStyles.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollegeSearchDialog(double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    final searchController = TextEditingController();
    List<String> filteredColleges = collegeOptions;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
              ),
              backgroundColor: Colors.white,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: isSmallScreen ? double.infinity : 500,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: AdminDashboardStyles.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isSmallScreen ? 20 : 24),
                          topRight: Radius.circular(isSmallScreen ? 20 : 24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AdminDashboardStyles.primary.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: AdminDashboardStyles.primary,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select College',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: AdminDashboardStyles.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${filteredColleges.length} colleges available',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: AdminDashboardStyles.textLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                            color: AdminDashboardStyles.textLight,
                          ),
                        ],
                      ),
                    ),
                    // Search Field
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: !isSmallScreen,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value.isEmpty) {
                                filteredColleges = collegeOptions;
                              } else {
                                filteredColleges = collegeOptions
                                    .where(
                                      (college) => college
                                          .toLowerCase()
                                          .contains(value.toLowerCase()),
                                    )
                                    .toList();
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search colleges...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AdminDashboardStyles.primary,
                              size: isSmallScreen ? 20 : 22,
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      size: isSmallScreen ? 18 : 20,
                                      color: Colors.grey.shade400,
                                    ),
                                    onPressed: () {
                                      searchController.clear();
                                      setDialogState(() {
                                        filteredColleges = collegeOptions;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // List
                    Flexible(
                      child: filteredColleges.isEmpty
                          ? _buildEmptySearchState(isSmallScreen)
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredColleges.length,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: 8,
                              ),
                              itemBuilder: (context, index) {
                                final college = filteredColleges[index];
                                final isSelected = college == _selectedCollege;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AdminDashboardStyles.primary
                                              .withOpacity(0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AdminDashboardStyles.primary
                                                .withOpacity(0.3)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 4 : 6,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AdminDashboardStyles.primary
                                            : AdminDashboardStyles.primary
                                                  .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        college == 'All'
                                            ? Icons.apps_rounded
                                            : Icons.school_rounded,
                                        size: isSmallScreen ? 16 : 18,
                                        color: isSelected
                                            ? Colors.white
                                            : AdminDashboardStyles.primary,
                                      ),
                                    ),
                                    title: Text(
                                      college,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AdminDashboardStyles.primary
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: AdminDashboardStyles.primary,
                                            size: isSmallScreen ? 20 : 22,
                                          )
                                        : null,
                                    onTap: () {
                                      _onCollegeChanged(college);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySearchState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: isSmallScreen ? 40 : 48,
                color: AdminDashboardStyles.primary.withOpacity(0.6),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'No colleges found',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textDark,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: AdminDashboardStyles.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
    double screenWidth,
  ) {
    final isSmallScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 10 : 12,
              isSmallScreen ? 8 : 10,
              isSmallScreen ? 10 : 12,
              isSmallScreen ? 4 : 6,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: isSmallScreen ? 13 : 14,
                  color: AdminDashboardStyles.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: AdminDashboardStyles.textLight,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 10 : 12,
              0,
              isSmallScreen ? 10 : 12,
              isSmallScreen ? 8 : 10,
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: isSmallScreen ? 18 : 20,
                color: AdminDashboardStyles.primary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: Colors.white,
              menuMaxHeight: 400,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return RefreshIndicator(
      onRefresh: _fetchStudentsFromAPI,
      color: AdminDashboardStyles.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
        itemCount: _filteredStudents.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          if (index >= _animationControllers.length)
            return _buildStudentItem(student, screenWidth);

          return AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index].value,
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: _buildStudentItem(student, screenWidth),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentItem(Student student, double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    final gradientColors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],
      [const Color(0xFFFF9A9E), const Color(0xFFFECAB0)],
    ];

    final selectedGradient =
        gradientColors[student.name.hashCode % gradientColors.length];

    Color statusColor;
    IconData statusIcon;
    switch (student.status) {
      case 'Active':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Inactive':
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.remove_circle_rounded;
        break;
      case 'Flagged':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.help_rounded;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: selectedGradient[0].withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentProfilePage(student: student),
              ),
            );
          },
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: isSmallScreen ? 50 : (isMediumScreen ? 55 : 60),
                  height: isSmallScreen ? 50 : (isMediumScreen ? 55 : 60),
                  decoration: BoxDecoration(
                    color: selectedGradient[0],
                    borderRadius: BorderRadius.circular(
                      isSmallScreen ? 14 : 18,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selectedGradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Expanded(
                            child: Text(
                              student.college,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                // Status Badge
                if (!isSmallScreen || screenWidth > 380)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 10 : 12,
                      ),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: isSmallScreen ? 12 : 14,
                          color: statusColor,
                        ),
                        if (!isSmallScreen) ...[
                          const SizedBox(width: 6),
                          Text(
                            student.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                SizedBox(width: isSmallScreen ? 4 : 8),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AdminDashboardStyles.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Students...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the data',
            style: TextStyle(
              fontSize: 14,
              color: AdminDashboardStyles.textLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
        padding: EdgeInsets.all(isSmallScreen ? 32 : 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isSmallScreen ? 40 : 48,
                color: const Color(0xFFEF4444),
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            Text(
              'Failed to Load Students',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w800,
                color: AdminDashboardStyles.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),
            ElevatedButton.icon(
              onPressed: _fetchStudentsFromAPI,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildEmptyState(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
        padding: EdgeInsets.all(isSmallScreen ? 32 : 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon with Clean Background
            Container(
              width: isSmallScreen ? 100 : 120,
              height: isSmallScreen ? 100 : 120,
              decoration: BoxDecoration(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.search_off_rounded,
                  size: isSmallScreen ? 50 : 60,
                  color: AdminDashboardStyles.primary.withOpacity(0.6),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),
            Text(
              'No Students Found',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: AdminDashboardStyles.textDark,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              isSmallScreen
                  ? 'No students match your search.\nTry adjusting your filters.'
                  : 'We couldn\'t find any students matching your search criteria.\nTry adjusting your filters or search terms.',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            // Suggestions
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        size: isSmallScreen ? 16 : 18,
                        color: AdminDashboardStyles.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          color: AdminDashboardStyles.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 12),
                  _buildSuggestionItem(
                    'Clear your search query',
                    isSmallScreen,
                  ),
                  _buildSuggestionItem(
                    'Reset filter selections',
                    isSmallScreen,
                  ),
                  _buildSuggestionItem(
                    'Check spelling and try again',
                    isSmallScreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildSuggestionItem(String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 5 : 6,
            height: isSmallScreen ? 5 : 6,
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primary.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateStudentFAB() {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreateStudentPage,
            backgroundColor: AdminDashboardStyles.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text(
              'Create Student',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms, delay: 300.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}
