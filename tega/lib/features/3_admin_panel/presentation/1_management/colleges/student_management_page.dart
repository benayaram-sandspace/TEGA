import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/students/student_profile_page.dart';
import 'package:tega/features/3_admin_panel/presentation/4_settings_and_misc/flagged_users_page.dart';
import 'package:tega/features/5_student_dashboard/data/models/student_model.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCollege = 'All';
  String _selectedBranch = 'All';
  String _selectedStatus = 'Active';
  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadStudents();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    // Using sample data as in the original code
    _students = [
      Student.basic('Arjun Reddy', 'College A, B.Tech CSE', 'Active'),
      Student.basic('Priya Sharma', 'College B, B.Com', 'Active'),
      Student.basic('Vikram Singh', 'College C, B.Sc', 'Flagged'),
      Student.basic('Anjali Verma', 'College A, B.Tech IT', 'Active'),
      Student.basic('Rohan Kapoor', 'College B, BBA', 'Inactive'),
      Student.basic('Divya Patel', 'College C, B.Sc', 'Active'),
      Student.basic('Siddharth Joshi', 'College A, B.Tech CSE', 'Active'),
      Student.basic('Neha Gupta', 'College B, B.Com', 'Active'),
      Student.basic('Karan Malhotra', 'College C, B.Sc', 'Inactive'),
      Student.basic('Ishita Khanna', 'College A, B.Tech IT', 'Flagged'),
      Student.basic('Varun Mehra', 'College B, BBA', 'Active'),
      Student.basic('Sakshi Rao', 'College C, B.Sc', 'Active'),
    ];
    _applyFilters(); // Apply default filters on initial load
  }

  void _applyFilters() {
    _animationController.reset();
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
            );

        // College filter
        bool matchesCollege =
            _selectedCollege == 'All' ||
            student.college.contains(_selectedCollege);

        // Branch filter
        bool matchesBranch =
            _selectedBranch == 'All' ||
            student.college.contains(_selectedBranch);

        // Status filter
        bool matchesStatus = student.status == _selectedStatus;

        return matchesSearch &&
            matchesCollege &&
            matchesBranch &&
            matchesStatus;
      }).toList();
    });
    _animationController.forward();
  }

  void _clearFilters() {
    _animationController.reset();
    setState(() {
      _selectedCollege = 'All';
      _selectedBranch = 'All';
      _selectedStatus = 'Active';
      _searchController.clear();
      _applyFilters();
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          // Back functionality to go to the admin dashboard
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Student Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting student list...')),
              );
            },
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildFilterSection(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students (${_filteredStudents.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Flagged Users'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlaggedUsersPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredStudents.isEmpty
                ? _buildEmptyState()
                : _buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by name or college...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'College',
                    _selectedCollege,
                    ['All', 'College A', 'College B', 'College C'],
                    (value) {
                      setState(() => _selectedCollege = value!);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    'Branch',
                    _selectedBranch,
                    ['All', 'B.Tech CSE', 'B.Tech IT', 'B.Com', 'BBA', 'B.Sc'],
                    (value) {
                      setState(() => _selectedBranch = value!);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('Active'),
                  _buildStatusChip('Inactive'),
                  _buildStatusChip('Flagged'),
                ],
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    bool isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(status),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedStatus = status);
            _applyFilters();
          }
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderLight),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (1 / _filteredStudents.length) * index,
              1.0,
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: _buildStudentItem(student),
          ),
        );
      },
    );
  }

  Widget _buildStudentItem(Student student) {
    final color = Colors
        .primaries[student.name.hashCode % Colors.primaries.length]
        .withOpacity(0.9);

    Color statusColor;
    switch (student.status) {
      case 'Active':
        statusColor = AppColors.success;
        break;
      case 'Inactive':
        statusColor = AppColors.textSecondary;
        break;
      case 'Flagged':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProfilePage(student: student),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Text(
                  student.name.isNotEmpty ? student.name[0] : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(student.status),
                backgroundColor: statusColor.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No Students Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
