import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class ModulesTab extends StatefulWidget {
  const ModulesTab({super.key});

  @override
  State<ModulesTab> createState() => _ModulesTabState();
}

class _ModulesTabState extends State<ModulesTab> {
  bool _isLoading = false;
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _modules = [];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementModules),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list = (data['modules'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _modules = List<Map<String, dynamic>>.from(list);
              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch modules');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch modules: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading modules: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteModule(String moduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: const Text('Are you sure you want to delete this module? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.delete(
        Uri.parse(ApiEndpoints.adminDeletePlacementModule(moduleId)),
        headers: headers,
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Module deleted successfully'), backgroundColor: Colors.green),
          );
          _loadModules();
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to delete module: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting module: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getIconColor(Map<String, dynamic> module) {
    // Use module color if available, otherwise use default colors
    if (module['color'] != null) {
      try {
        return Color(int.parse(module['color'].toString().replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to default
      }
    }
    // Default colors based on module type or index
    final moduleType = (module['moduleType'] ?? '').toString().toLowerCase();
    switch (moduleType) {
      case 'assessment':
        return const Color(0xFFEF4444); // Red
      case 'technical':
        return const Color(0xFF3B82F6); // Blue
      case 'interview':
        return const Color(0xFF10B981); // Green
      default:
        return AdminDashboardStyles.primary;
    }
  }

  Color _getIconBackgroundColor(Color iconColor) {
    return iconColor.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_modules.isEmpty)
            _buildEmptyState()
          else
            _buildModulesGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, color: AdminDashboardStyles.primary, size: 40),
          const SizedBox(height: 10),
          Text(
            'No modules found',
            style: TextStyle(fontWeight: FontWeight.w700, color: AdminDashboardStyles.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a new module to get started',
            style: AdminDashboardStyles.statTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
        final spacing = 8.0;
        final runSpacing = 8.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 2.1,
          ),
          itemCount: _modules.length,
          itemBuilder: (context, index) {
            return _buildModuleCard(_modules[index]);
          },
        );
      },
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    final title = (module['title'] ?? 'Untitled Module').toString();
    final description = (module['description'] ?? '').toString();
    final moduleType = (module['moduleType'] ?? 'assessment').toString();
    final questionCount = module['questionCount'] ?? module['questions']?.length ?? 0;
    final isActive = module['isActive'] ?? true;
    final moduleId = (module['_id'] ?? module['id']).toString();

    final iconColor = _getIconColor(module);
    final iconBgColor = _getIconBackgroundColor(iconColor);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: AdminDashboardStyles.accentBlue,
                    onTap: () {
                      // TODO: Navigate to edit module page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit module - Coming soon')),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    color: AdminDashboardStyles.statusError,
                    onTap: () => _deleteModule(moduleId),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Subtitle (description)
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AdminDashboardStyles.textLight,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 6),
          // Details row
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: AdminDashboardStyles.textLight),
              const SizedBox(width: 5),
              Text(
                moduleType,
                style: TextStyle(
                  fontSize: 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.description_rounded, size: 14, color: AdminDashboardStyles.textLight),
              const SizedBox(width: 5),
              Text(
                '$questionCount ${questionCount == 1 ? 'question' : 'questions'}',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Status badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
