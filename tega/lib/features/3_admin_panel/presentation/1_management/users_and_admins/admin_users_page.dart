import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/models/admin_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/admin_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

import 'add_admin_modal.dart';
import 'edit_admin_modal.dart';
import 'admin_profile_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with TickerProviderStateMixin {
  final AdminRepository _adminService = AdminRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  List<AdminUser> _allAdmins = [];
  List<AdminUser> _filteredAdmins = [];
  String _selectedRole = '';
  String _selectedStatus = '';
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _itemAnimationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAdmins();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _itemAnimationControllers = List.generate(
      20, // Max items to animate
      (index) => AnimationController(
        vsync: this,
        duration: AdminDashboardStyles.mediumAnimation,
      ),
    );

    _scaleAnimations = _itemAnimationControllers
        .map(
          (controller) => Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          ),
        )
        .toList();

    _slideAnimations = _itemAnimationControllers
        .map(
          (controller) =>
              Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              ),
        )
        .toList();

    _animationController.forward();
  }

  void _startStaggeredAnimations() {
    for (
      int i = 0;
      i < _itemAnimationControllers.length && i < _filteredAdmins.length;
      i++
    ) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _itemAnimationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);

    await _adminService.loadData();
    _allAdmins = _adminService.getAllAdmins();
    _filteredAdmins = _allAdmins;

    setState(() => _isLoading = false);
    _startStaggeredAnimations();
  }

  void _applyFilters() {
    setState(() {
      _filteredAdmins = _allAdmins;

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        _filteredAdmins = _adminService.searchAdmins(_searchController.text);
      }

      // Apply role filter
      if (_selectedRole.isNotEmpty) {
        _filteredAdmins = _filteredAdmins
            .where((admin) => admin.role == _selectedRole)
            .toList();
      }

      // Apply status filter
      if (_selectedStatus.isNotEmpty) {
        _filteredAdmins = _filteredAdmins
            .where((admin) => admin.status == _selectedStatus)
            .toList();
      }
    });
    _startStaggeredAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardStyles.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AdminDashboardStyles.primary,
                ),
              )
            : Column(
                children: [
                  // Search and Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText: 'Search by name or email...',
                            hintStyle: TextStyle(
                              color: AdminDashboardStyles.textLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AdminDashboardStyles.textLight,
                            ),
                            filled: true,
                            fillColor: AdminDashboardStyles.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filter Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterDropdown(
                                'Filter by Role',
                                _selectedRole,
                                _adminService.getAvailableRoles(),
                                (value) {
                                  setState(() => _selectedRole = value ?? '');
                                  _applyFilters();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterDropdown(
                                'Filter by Status',
                                _selectedStatus,
                                _adminService.getAvailableStatuses(),
                                (value) {
                                  setState(() => _selectedStatus = value ?? '');
                                  _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Admin Users List
                  Expanded(
                    child: _filteredAdmins.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 64,
                                  color: AdminDashboardStyles.textLight,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No admins found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AdminDashboardStyles.textLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredAdmins.length,
                            itemBuilder: (context, index) {
                              final admin = _filteredAdmins[index];
                              if (index < _itemAnimationControllers.length) {
                                return AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _scaleAnimations[index],
                                    _slideAnimations[index],
                                  ]),
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimations[index].value,
                                      child: SlideTransition(
                                        position: _slideAnimations[index],
                                        child: _buildAdminCard(admin),
                                      ),
                                    );
                                  },
                                );
                              }
                              return _buildAdminCard(admin);
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdminModal(),
        backgroundColor: AdminDashboardStyles.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add New Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAdminCard(AdminUser admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              admin.name.split(' ').map((n) => n[0]).join(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Admin Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (admin.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    admin.phoneNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (admin.department.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    admin.department,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(admin.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        admin.role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(admin.role),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          admin.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        admin.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(admin.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Options Menu
          PopupMenuButton<String>(
            onSelected: (value) => _handleAdminAction(value, admin),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Admin', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Super Admin':
        return AppColors.error;
      case 'Content Manager':
        return AppColors.warning;
      case 'User Manager':
        return AppColors.info;
      case 'College Manager':
        return AppColors.success;
      case 'Analytics Manager':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleAdminAction(String action, AdminUser admin) {
    switch (action) {
      case 'view':
        _showAdminDetails(admin);
        break;
      case 'edit':
        _showEditAdminModal(admin);
        break;
      case 'delete':
        _showDeleteDialog(admin);
        break;
    }
  }

  void _showAdminDetails(AdminUser admin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminProfilePage(admin: admin)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddAdminModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAdminModal(),
    ).then((_) => _loadAdmins());
  }

  void _showEditAdminModal(AdminUser admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAdminModal(admin: admin),
    ).then((updatedAdmin) {
      if (updatedAdmin != null) {
        _loadAdmins(); // Refresh the list
      }
    });
  }

  void _showDeleteDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text(
          'Are you sure you want to permanently delete ${admin.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAdmin(admin);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdmin(AdminUser admin) async {
    try {
      final success = await _adminService.deleteAdmin(admin.id);

      if (success) {
        _loadAdmins(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${admin.name} deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete admin'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting admin: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
