import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';
import 'add_college_admin_page.dart';

class CollegeAdminsPage extends StatefulWidget {
  final College college;

  const CollegeAdminsPage({super.key, required this.college});

  @override
  State<CollegeAdminsPage> createState() => _CollegeAdminsPageState();
}

class _CollegeAdminsPageState extends State<CollegeAdminsPage> {
  // final CollegeService _collegeService = CollegeService(); // Unused for now

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Admins',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.college.admins.length} admin(s) assigned',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AddCollegeAdminPage(college: widget.college),
                          ),
                        )
                        .then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Add Admin',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Admins List
          Expanded(
            child: widget.college.admins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No admins assigned',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add an admin to manage this college',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) => AddCollegeAdminPage(
                                      college: widget.college,
                                    ),
                                  ),
                                )
                                .then((_) => setState(() {}));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Admin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.college.admins.length,
                    itemBuilder: (context, index) {
                      final admin = widget.college.admins[index];
                      return _buildAdminCard(admin);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(CollegeAdmin admin) {
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
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          admin.name,
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
              admin.email,
              style: const TextStyle(color: AppColors.pureWhite, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              admin.phone,
              style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: admin.status == 'Active'
                ? AppColors.success
                : AppColors.error,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            admin.status,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          _showAdminDetails(admin);
        },
      ),
    );
  }

  void _showAdminDetails(CollegeAdmin admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', admin.email),
            _buildDetailRow('Phone', admin.phone),
            _buildDetailRow('Role', admin.role),
            _buildDetailRow('Status', admin.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditAdminDialog(admin);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAdminDialog(CollegeAdmin admin) {
    // TODO: Implement edit admin functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit admin functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
