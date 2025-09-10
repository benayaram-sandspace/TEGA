import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/services/college_service.dart';
import 'package:tega/models/student.dart' as app_models;
import 'package:tega/pages/admin_screens/admin_student_pages/student_profile_page.dart';

class CollegeStudentManagement extends StatefulWidget {
  final College college;

  const CollegeStudentManagement({super.key, required this.college});

  @override
  State<CollegeStudentManagement> createState() => _CollegeStudentManagementState();
}

class _CollegeStudentManagementState extends State<CollegeStudentManagement> {
  final TextEditingController _searchController = TextEditingController();
  List<Student> _filteredStudents = [];
  String _selectedFilter = 'All';
  String _selectedSort = 'Name';
  bool _isGridView = false;

  final List<String> _filterOptions = [
    'All',
    'High Performers (80%+)',
    'Average Performers (40-79%)',
    'Need Support (<40%)',
    'Active',
    'Inactive',
  ];

  final List<String> _sortOptions = [
    'Name',
    'Skill Score',
    'Course',
    'Year',
    'Recent Activity',
  ];

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.college.students;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with Search and Filters
          _buildHeader(),
          
          // Student List/Grid
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          // Title and View Toggle
          Row(
            children: [
              const Text(
                'Student Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(Icons.list, !_isGridView),
                    _buildViewToggleButton(Icons.grid_view, _isGridView),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search and Filters Row
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterStudents,
                    decoration: const InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  items: _filterOptions.map((String filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButton<String>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  items: _sortOptions.map((String sort) {
                    return DropdownMenuItem<String>(
                      value: sort,
                      child: Text(sort),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSort = newValue;
                        _sortStudents();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          // Summary Stats
          const SizedBox(height: 16),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isGridView = icon == Icons.grid_view;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.pureWhite : AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        _buildStatCard(
          'Total Students',
          '${widget.college.students.length}',
          Icons.people,
          AppColors.info,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'High Performers',
          '${_getHighPerformersCount()}',
          Icons.star,
          AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Need Support',
          '${_getNeedSupportCount()}',
          Icons.support_agent,
          AppColors.error,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Avg. Score',
          '${_getAverageScore()}%',
          Icons.trending_up,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
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

  Widget _buildListView() {
    if (_filteredStudents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentListItem(student);
      },
    );
  }

  Widget _buildGridView() {
    if (_filteredStudents.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentGridItem(student);
      },
    );
  }

  Widget _buildStudentListItem(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildStudentAvatar(student),
        title: Text(
          student.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              student.course,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Year ${student.year}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getScoreColor(student.skillScore).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getScoreColor(student.skillScore).withValues(alpha: 0.3)),
              ),
              child: Text(
                '${student.skillScore}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getScoreColor(student.skillScore),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Skill Score',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToStudentProfile(student),
      ),
    );
  }

  Widget _buildStudentGridItem(Student student) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToStudentProfile(student),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and Score
                Row(
                  children: [
                    _buildStudentAvatar(student, size: 40),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getScoreColor(student.skillScore).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getScoreColor(student.skillScore).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${student.skillScore}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(student.skillScore),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Student Name
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Course
                Text(
                  student.course,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Year
                Text(
                  'Year ${student.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                
                // Performance Indicator
                Row(
                  children: [
                    Icon(
                      _getPerformanceIcon(student.skillScore),
                      color: _getScoreColor(student.skillScore),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPerformanceText(student.skillScore),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getScoreColor(student.skillScore),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildStudentAvatar(Student student, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.pureWhite,
        size: 24,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = widget.college.students;
      } else {
        _filteredStudents = widget.college.students.where((student) {
          return student.name.toLowerCase().contains(query.toLowerCase()) ||
              student.course.toLowerCase().contains(query.toLowerCase()) ||
              student.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      switch (_selectedFilter) {
        case 'High Performers (80%+)':
          _filteredStudents = _filteredStudents.where((student) => student.skillScore >= 80).toList();
          break;
        case 'Average Performers (40-79%)':
          _filteredStudents = _filteredStudents.where((student) => 
              student.skillScore >= 40 && student.skillScore < 80).toList();
          break;
        case 'Need Support (<40%)':
          _filteredStudents = _filteredStudents.where((student) => student.skillScore < 40).toList();
          break;
        case 'Active':
          _filteredStudents = _filteredStudents.where((student) => student.skillScore > 0).toList();
          break;
        case 'Inactive':
          _filteredStudents = _filteredStudents.where((student) => student.skillScore == 0).toList();
          break;
        default:
          // 'All' - no additional filtering
          break;
      }
      _sortStudents();
    });
  }

  void _sortStudents() {
    setState(() {
      switch (_selectedSort) {
        case 'Name':
          _filteredStudents.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Skill Score':
          _filteredStudents.sort((a, b) => b.skillScore.compareTo(a.skillScore));
          break;
        case 'Course':
          _filteredStudents.sort((a, b) => a.course.compareTo(b.course));
          break;
        case 'Year':
          _filteredStudents.sort((a, b) => a.year.compareTo(b.year));
          break;
        case 'Recent Activity':
          // For now, sort by skill score as a proxy for activity
          _filteredStudents.sort((a, b) => b.skillScore.compareTo(a.skillScore));
          break;
      }
    });
  }

  void _navigateToStudentProfile(Student jsonStudent) {
    // Convert JSON Student to app Student model
    final appStudent = app_models.Student.detailed(
      name: jsonStudent.name,
      college: widget.college.name,
      status: 'Active',
      email: jsonStudent.email,
      studentId: jsonStudent.id,
      branch: jsonStudent.course,
      yearOfStudy: jsonStudent.year.toString(),
      jobReadiness: (jsonStudent.skillScore / 100.0), // Convert to 0-1 scale
    );

    // Navigate to student profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfilePage(student: appStudent),
      ),
    );
  }

  // Helper methods
  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    if (score >= 40) return AppColors.info;
    return AppColors.error;
  }

  IconData _getPerformanceIcon(int score) {
    if (score >= 80) return Icons.star;
    if (score >= 60) return Icons.trending_up;
    if (score >= 40) return Icons.trending_flat;
    return Icons.trending_down;
  }

  String _getPerformanceText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    return 'Needs Support';
  }

  int _getHighPerformersCount() {
    return widget.college.students.where((student) => student.skillScore >= 80).length;
  }

  int _getNeedSupportCount() {
    return widget.college.students.where((student) => student.skillScore < 40).length;
  }

  int _getAverageScore() {
    if (widget.college.students.isEmpty) return 0;
    final totalScore = widget.college.students.fold<int>(
      0,
      (sum, student) => sum + student.skillScore,
    );
    return (totalScore / widget.college.students.length).round();
  }
}
