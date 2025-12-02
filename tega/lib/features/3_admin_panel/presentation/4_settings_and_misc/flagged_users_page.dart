import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/students/student_profile_page.dart';
import 'package:tega/features/5_student_dashboard/data/models/student_model.dart';

class FlaggedUsersPage extends StatefulWidget {
  const FlaggedUsersPage({super.key});

  @override
  State<FlaggedUsersPage> createState() => _FlaggedUsersPageState();
}

class _FlaggedUsersPageState extends State<FlaggedUsersPage>
    with TickerProviderStateMixin {
  String _selectedStatus = 'Pending Review';
  String _selectedFlagReason = 'All';
  String _selectedCollege = 'All';
  String _selectedDateRange = 'Select Date Range';

  List<FlaggedUser> _flaggedUsers = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadFlaggedUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadFlaggedUsers() {
    _flaggedUsers = [
      FlaggedUser(
        name: 'Aarav Sharma',
        college: 'College of Engineering',
        status: 'Pending Review',
      ),
      FlaggedUser(
        name: 'Anika Verma',
        college: 'College of Arts and Sciences',
        status: 'Pending Review',
      ),
      FlaggedUser(
        name: 'Rohan Kapoor',
        college: 'School of Business',
        status: 'Pending Review',
      ),
      FlaggedUser(
        name: 'Ishaan Singh',
        college: 'College of Engineering',
        status: 'Pending Review',
      ),
      FlaggedUser(
        name: 'Diya Patel',
        college: 'College of Arts and Sciences',
        status: 'Pending Review',
      ),
      FlaggedUser(
        name: 'Arjun Malhotra',
        college: 'School of Business',
        status: 'Pending Review',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboardStyles.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
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

  FlaggedUser({
    required this.name,
    required this.college,
    required this.status,
  });
}
