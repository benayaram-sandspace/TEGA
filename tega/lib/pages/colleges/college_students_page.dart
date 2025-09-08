import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/college_service.dart' as college_service;
import '../../models/student.dart';
import '../student_profile_page.dart';

class CollegeStudentsPage extends StatefulWidget {
  final college_service.College college;

  const CollegeStudentsPage({super.key, required this.college});

  @override
  State<CollegeStudentsPage> createState() => _CollegeStudentsPageState();
}

class _CollegeStudentsPageState extends State<CollegeStudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<college_service.Student> _filteredStudents = [];

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

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = widget.college.students;
      } else {
        _filteredStudents = widget.college.students.where((student) {
          return student.name.toLowerCase().contains(query.toLowerCase()) ||
                 student.course.toLowerCase().contains(query.toLowerCase()) ||
                 student.year.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStudents,
                decoration: InputDecoration(
                  hintText: 'Search students',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Students List
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.college.students.isEmpty
                              ? 'No students enrolled'
                              : 'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.college.students.isEmpty
                              ? 'Students will appear here once they enroll'
                              : 'Try adjusting your search',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(student);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(college_service.Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              student.course,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Year: ${student.year}',
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${student.skillScore}%',
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              'Skill Score',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        onTap: () {
          _navigateToStudentProfile(student);
        },
      ),
    );
  }

  void _navigateToStudentProfile(college_service.Student jsonStudent) {
    // Convert JSON Student to app Student model
    final appStudent = Student.detailed(
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

  // void _showStudentDetails(college_service.Student student) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(student.name),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildDetailRow('Course', student.course),
  //           _buildDetailRow('Year', student.year.toString()),
  //           _buildDetailRow('Email', student.email),
  //           _buildDetailRow('Phone', student.phone),
  //           _buildDetailRow('Skill Score', '${student.skillScore}%'),
  //           _buildDetailRow('Interview Practices', student.interviewPractices.toString()),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Close'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             _showEditStudentDialog(student);
  //           },
  //           child: const Text('Edit'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(college_service.Student student) {
    // TODO: Implement edit student functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit student functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}


