import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/admin_models.dart';
import 'package:tega/services/admin_service.dart';

import 'add_admin_modal.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminService _adminService = AdminService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<AdminUser> _allAdmins = [];
  List<AdminUser> _filteredAdmins = [];
  String _selectedRole = '';
  String _selectedStatus = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    
    await _adminService.loadData();
    _allAdmins = _adminService.getAllAdmins();
    _filteredAdmins = _allAdmins;
    
    setState(() => _isLoading = false);
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
        _filteredAdmins = _filteredAdmins.where((admin) => admin.role == _selectedRole).toList();
      }
      
      // Apply status filter
      if (_selectedStatus.isNotEmpty) {
        _filteredAdmins = _filteredAdmins.where((admin) => admin.status == _selectedStatus).toList();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = '';
      _selectedStatus = '';
      _filteredAdmins = _allAdmins;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surface,
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
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No admins found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
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
                            return _buildAdminCard(admin);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdminModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.pureWhite),
        label: const Text(
          'Add New Admin',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w600,
          ),
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
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(admin.status).withValues(alpha: 0.1),
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
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 18),
                    SizedBox(width: 8),
                    Text('Deactivate'),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
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
      case 'deactivate':
        _showDeactivateDialog(admin);
        break;
    }
  }

  void _showAdminDetails(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', admin.email),
            _buildDetailRow('Role', admin.role),
            _buildDetailRow('Status', admin.status),
            _buildDetailRow('Created', _formatDate(admin.createdAt)),
            _buildDetailRow('Last Login', _formatDate(admin.lastLogin)),
            const SizedBox(height: 8),
            const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...admin.permissions.map((permission) => Text('• $permission')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
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
    // TODO: Implement edit admin modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${admin.name} - Coming Soon')),
    );
  }

  void _showDeactivateDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Admin'),
        content: Text('Are you sure you want to deactivate ${admin.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement deactivation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${admin.name} deactivated')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Deactivate', style: TextStyle(color: AppColors.pureWhite)),
          ),
        ],
      ),
    );
  }
}
