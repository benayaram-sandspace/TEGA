import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/student.dart';
import 'flagged_users_page.dart';
import 'student_profile_page.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCollege = 'All';
  String _selectedBranch = 'All';
  String _selectedStatus = 'Active';
  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    _students = [
      Student.basic('Arjun Reddy', 'College A, B.Tech CSE', 'Active'),
      Student.basic('Priya Sharma', 'College B, B.Com', 'Active'),
      Student.basic('Vikram Singh', 'College C, B.Sc', 'Active'),
      Student.basic('Anjali Verma', 'College A, B.Tech IT', 'Active'),
      Student.basic('Rohan Kapoor', 'College B, BBA', 'Active'),
      Student.basic('Divya Patel', 'College C, B.Sc', 'Active'),
      Student.basic('Siddharth Joshi', 'College A, B.Tech CSE', 'Active'),
      Student.basic('Neha Gupta', 'College B, B.Com', 'Active'),
      Student.basic('Karan Malhotra', 'College C, B.Sc', 'Active'),
      Student.basic('Ishita Khanna', 'College A, B.Tech IT', 'Active'),
      Student.basic('Varun Mehra', 'College B, BBA', 'Active'),
      Student.basic('Sakshi Rao', 'College C, B.Sc', 'Active'),
    ];
    _filteredStudents = List.from(_students);
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents = _students.where((student) {
        bool matchesSearch = student.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           student.college.toLowerCase().contains(_searchController.text.toLowerCase());
        bool matchesStatus = _selectedStatus == 'All' || student.status == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () {
                // Export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting student list...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Export List'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View Flagged Users Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FlaggedUsersPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Flagged Users'),
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Name, Email, or Student ID',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Filters Section
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // College and Branch Dropdowns
            Row(
              children: [
                Expanded(
                  child: _buildDropdown('College', _selectedCollege, ['All', 'College A', 'College B', 'College C'], (value) {
                    setState(() {
                      _selectedCollege = value!;
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown('Branch', _selectedBranch, ['All', 'B.Tech CSE', 'B.Tech IT', 'B.Com', 'BBA', 'B.Sc'], (value) {
                    setState(() {
                      _selectedBranch = value!;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Filter Buttons
            Row(
              children: [
                _buildStatusButton('Active', _selectedStatus == 'Active'),
                const SizedBox(width: 8),
                _buildStatusButton('Inactive', _selectedStatus == 'Inactive'),
                const SizedBox(width: 8),
                _buildStatusButton('Flagged', _selectedStatus == 'Flagged'),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCollege = 'All';
                        _selectedBranch = 'All';
                        _selectedStatus = 'Active';
                        _searchController.clear();
                        _applyFilters();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGray,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepBlue,
                      foregroundColor: AppColors.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Student List
            Text(
              'Student List (${_filteredStudents.length} results)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Student List Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return _buildStudentItem(student);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

  Widget _buildStatusButton(String status, bool isSelected) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedStatus = status;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.pureWhite,
          foregroundColor: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppColors.primary,
              width: isSelected ? 0 : 1,
            ),
          ),
        ),
        child: Text(status),
      ),
    );
  }

  Widget _buildStudentItem(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.college,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfilePage(student: student),
                ),
              );
            },
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

