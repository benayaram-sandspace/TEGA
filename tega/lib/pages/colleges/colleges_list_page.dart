import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/college_service.dart';
import 'college_details_page.dart';
import 'add_college_page.dart';
import 'bulk_import_colleges_page.dart';

class CollegesListPage extends StatefulWidget {
  const CollegesListPage({super.key});

  @override
  State<CollegesListPage> createState() => _CollegesListPageState();
}

class _CollegesListPageState extends State<CollegesListPage> {
  final CollegeService _collegeService = CollegeService();
  final TextEditingController _searchController = TextEditingController();
  List<College> _colleges = [];
  List<College> _filteredColleges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadColleges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final colleges = await _collegeService.loadColleges();
      setState(() {
        _colleges = colleges;
        _filteredColleges = colleges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load colleges: $e');
    }
  }

  void _filterColleges(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredColleges = _colleges;
      } else {
        _filteredColleges = _collegeService.searchColleges(query);
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Colleges',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCollegePage(),
                ),
              ).then((_) => _loadColleges());
            },
            child: const Text(
              '+ Add',
              style: TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterColleges,
              decoration: InputDecoration(
                hintText: 'Search by college name, city, or ID',
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

          // Colleges List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _filteredColleges.isEmpty
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
                              'No colleges found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or add a new college',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredColleges.length,
                        itemBuilder: (context, index) {
                          final college = _filteredColleges[index];
                          return _buildCollegeCard(college);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BulkImportCollegesPage(),
            ),
          ).then((_) => _loadColleges());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.pureWhite,
        icon: const Icon(Icons.upload_file),
        label: const Text('Add Bulk'),
      ),
    );
  }

  Widget _buildCollegeCard(College college) {
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CollegeDetailsPage(college: college),
            ),
          );
        },
        title: Text(
          college.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              college.city,
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${college.id} | ${college.totalStudents} students',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppColors.textSecondary,
          ),
          onSelected: (value) {
            switch (value) {
              case 'view':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CollegeDetailsPage(college: college),
                  ),
                );
                break;
              case 'edit':
                // TODO: Implement edit functionality
                break;
              case 'delete':
                _showDeleteDialog(college);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: AppColors.info),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(College college) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete College'),
        content: Text('Are you sure you want to delete ${college.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _collegeService.deleteCollege(college.id);
              if (success) {
                _loadColleges();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${college.name} deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                _showErrorDialog('Failed to delete college');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


