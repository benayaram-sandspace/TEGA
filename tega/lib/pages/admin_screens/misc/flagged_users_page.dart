import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/student.dart';
import 'package:tega/pages/admin_screens/admin_student_pages/student_profile_page.dart';

class FlaggedUsersPage extends StatefulWidget {
  const FlaggedUsersPage({super.key});

  @override
  State<FlaggedUsersPage> createState() => _FlaggedUsersPageState();
}

class _FlaggedUsersPageState extends State<FlaggedUsersPage> {
  String _selectedStatus = 'Pending Review';
  String _selectedFlagReason = 'All';
  String _selectedCollege = 'All';
  String _selectedDateRange = 'Select Date Range';

  List<FlaggedUser> _flaggedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadFlaggedUsers();
  }

  void _loadFlaggedUsers() {
    _flaggedUsers = [
      FlaggedUser('Aarav Sharma', 'College of Engineering', 'Pending Review'),
      FlaggedUser(
        'Anika Verma',
        'College of Arts and Sciences',
        'Pending Review',
      ),
      FlaggedUser('Rohan Kapoor', 'School of Business', 'Pending Review'),
      FlaggedUser('Ishaan Singh', 'College of Engineering', 'Pending Review'),
      FlaggedUser(
        'Diya Patel',
        'College of Arts and Sciences',
        'Pending Review',
      ),
      FlaggedUser('Arjun Malhotra', 'School of Business', 'Pending Review'),
    ];
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
          'Flagged Users List',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, color: AppColors.warning, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '${_flaggedUsers.length} users pending review',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filters Section
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Filter by Status
            _buildFilterDropdown(
              'Filter by Status',
              _selectedStatus,
              ['Pending Review', 'Under Investigation', 'Resolved', 'All'],
              (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filter by Flag Reason
            _buildFilterDropdown(
              'Filter by Flag Reason',
              _selectedFlagReason,
              [
                'All',
                'Inappropriate Content',
                'Suspicious Activity',
                'Policy Violation',
                'Academic Misconduct',
              ],
              (value) {
                setState(() {
                  _selectedFlagReason = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filter by College
            _buildFilterDropdown(
              'Filter by College',
              _selectedCollege,
              [
                'All',
                'College of Engineering',
                'College of Arts and Sciences',
                'School of Business',
              ],
              (value) {
                setState(() {
                  _selectedCollege = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date Range
            _buildFilterDropdown(
              'Date Range',
              _selectedDateRange,
              [
                'Select Date Range',
                'Last 7 days',
                'Last 30 days',
                'Last 3 months',
                'Custom Range',
              ],
              (value) {
                setState(() {
                  _selectedDateRange = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Flagged Users List
            const Text(
              'Flagged Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // User List Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _flaggedUsers.length,
              itemBuilder: (context, index) {
                final user = _flaggedUsers[index];
                return _buildUserItem(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserItem(FlaggedUser user) {
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
          // User Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.college,
                  style: TextStyle(fontSize: 14, color: AppColors.info),
                ),
              ],
            ),
          ),

          // View Profile Button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfilePage(
                    student: Student.basic(
                      user.name,
                      user.college,
                      user.status,
                    ),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }
}

class FlaggedUser {
  final String name;
  final String college;
  final String status;

  FlaggedUser(this.name, this.college, this.status);
}
