import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
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
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  final AuthService _auth = AuthService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  List<Map<String, dynamic>> _modules = [];

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadModules();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);

      final cachedModules = await _cacheService.getPlacementPrepModulesData();
      if (cachedModules != null && cachedModules.isNotEmpty) {
        setState(() {
          _modules = List<Map<String, dynamic>>.from(cachedModules);
          _isLoadingFromCache = false;
        });
      } else {
        setState(() => _isLoadingFromCache = false);
      }
    } catch (e) {
      setState(() => _isLoadingFromCache = false);
    }
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
  }

  Future<void> _loadModules({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _modules.isNotEmpty) {
      _loadModulesInBackground();
      return;
    }

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

            // Cache the data
            await _cacheService.setPlacementPrepModulesData(_modules);

            // Reset toast flag on successful load (internet is back)
            _cacheService.resetNoInternetToastFlag();
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch modules');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch modules: ${res.statusCode}',
        );
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedModules = await _cacheService.getPlacementPrepModulesData();
        if (cachedModules != null && cachedModules.isNotEmpty) {
          // Load from cache
          if (mounted) {
            setState(() {
              _modules = List<Map<String, dynamic>>.from(cachedModules);
              _isLoading = false;
              _errorMessage = null; // Clear error since we have cached data
            });
          }
          return;
        }

        // No cache available, show error
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection';
          });
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  Future<void> _loadModulesInBackground() async {
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementModules),
        headers: headers,
      );

      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list = (data['modules'] ?? data['data'] ?? []) as List<dynamic>;
          setState(() {
            _modules = List<Map<String, dynamic>>.from(list);
          });

          // Cache the data
          await _cacheService.setPlacementPrepModulesData(_modules);

          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  Future<void> _deleteModule(String moduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: const Text(
          'Are you sure you want to delete this module? This action cannot be undone.',
        ),
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
            const SnackBar(
              content: Text('Module deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadModules(forceRefresh: true);
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(
          errorData['message'] ?? 'Failed to delete module: ${res.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting module: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getIconColor(Map<String, dynamic> module) {
    // Use module color if available, otherwise use default colors
    if (module['color'] != null) {
      try {
        return Color(
          int.parse(module['color'].toString().replaceFirst('#', '0xFF')),
        );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            isMobile
                ? 24
                : isTablet
                ? 28
                : 32,
          ),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AdminDashboardStyles.primary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? 12
            : isTablet
            ? 16
            : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null && !_isLoadingFromCache)
            _buildErrorState(isMobile, isTablet, isDesktop)
          else if (_modules.isEmpty)
            _buildEmptyState(isMobile, isTablet, isDesktop)
          else
            _buildModulesGrid(isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isTablet
            ? 28
            : 32,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile
                  ? 56
                  : isTablet
                  ? 64
                  : 72,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
            ),
            Text(
              'Failed to load modules',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 19
                    : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 8
                  : isTablet
                  ? 9
                  : 10,
            ),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 20
                  : isTablet
                  ? 24
                  : 28,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadModules(forceRefresh: true);
              },
              icon: Icon(
                Icons.refresh,
                size: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? 20
                      : isTablet
                      ? 24
                      : 28,
                  vertical: isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 8
                        : isTablet
                        ? 9
                        : 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isTablet
            ? 28
            : 32,
      ),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(
          color: AdminDashboardStyles.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            color: AdminDashboardStyles.primary,
            size: isMobile
                ? 32
                : isTablet
                ? 36
                : 40,
          ),
          SizedBox(
            height: isMobile
                ? 8
                : isTablet
                ? 9
                : 10,
          ),
          Text(
            'No modules found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminDashboardStyles.textDark,
              fontSize: isMobile
                  ? 14
                  : isTablet
                  ? 15
                  : 16,
            ),
          ),
          SizedBox(height: isMobile ? 3 : 4),
          Text(
            'Create a new module to get started',
            style: TextStyle(
              fontSize: isMobile
                  ? 12
                  : isTablet
                  ? 12.5
                  : 13,
              color: AdminDashboardStyles.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(bool isMobile, bool isTablet, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
        final spacing = isMobile
            ? 8.0
            : isTablet
            ? 10.0
            : 12.0;
        final runSpacing = isMobile
            ? 8.0
            : isTablet
            ? 10.0
            : 12.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: isMobile
                ? 2.0
                : isTablet
                ? 2.05
                : 2.1,
          ),
          itemCount: _modules.length,
          itemBuilder: (context, index) {
            return _buildModuleCard(
              _modules[index],
              isMobile,
              isTablet,
              isDesktop,
            );
          },
        );
      },
    );
  }

  Widget _buildModuleCard(
    Map<String, dynamic> module,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final title = (module['title'] ?? 'Untitled Module').toString();
    final description = (module['description'] ?? '').toString();
    final moduleType = (module['moduleType'] ?? 'assessment').toString();
    final questionCount =
        module['questionCount'] ?? module['questions']?.length ?? 0;
    final isActive = module['isActive'] ?? true;
    final moduleId = (module['_id'] ?? module['id']).toString();

    final iconColor = _getIconColor(module);
    final iconBgColor = _getIconBackgroundColor(iconColor);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        isMobile
            ? 8
            : isTablet
            ? 9
            : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: isMobile
                    ? 36
                    : isTablet
                    ? 38
                    : 40,
                height: isMobile
                    ? 36
                    : isTablet
                    ? 38
                    : 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 6
                        : isTablet
                        ? 7
                        : 8,
                  ),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: iconColor,
                  size: isMobile
                      ? 18
                      : isTablet
                      ? 19
                      : 20,
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
                        const SnackBar(
                          content: Text('Edit module - Coming soon'),
                        ),
                      );
                    },
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                  SizedBox(
                    width: isMobile
                        ? 5
                        : isTablet
                        ? 5.5
                        : 6,
                  ),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    color: AdminDashboardStyles.statusError,
                    onTap: () => _deleteModule(moduleId),
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: isMobile
                ? 5
                : isTablet
                ? 5.5
                : 6,
          ),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile
                  ? 13
                  : isTablet
                  ? 14
                  : 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 2 : 2),
          // Subtitle (description)
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(
                fontSize: isMobile
                    ? 11
                    : isTablet
                    ? 11.5
                    : 12,
                color: AdminDashboardStyles.textLight,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(
            height: isMobile
                ? 5
                : isTablet
                ? 5.5
                : 6,
          ),
          // Details row
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: isMobile
                    ? 12
                    : isTablet
                    ? 13
                    : 14,
                color: AdminDashboardStyles.textLight,
              ),
              SizedBox(
                width: isMobile
                    ? 4
                    : isTablet
                    ? 4.5
                    : 5,
              ),
              Text(
                moduleType,
                style: TextStyle(
                  fontSize: isMobile
                      ? 11
                      : isTablet
                      ? 11.5
                      : 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
              SizedBox(
                width: isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              Icon(
                Icons.description_rounded,
                size: isMobile
                    ? 12
                    : isTablet
                    ? 13
                    : 14,
                color: AdminDashboardStyles.textLight,
              ),
              SizedBox(
                width: isMobile
                    ? 4
                    : isTablet
                    ? 4.5
                    : 5,
              ),
              Flexible(
                child: Text(
                  '$questionCount ${questionCount == 1 ? 'question' : 'questions'}',
                  style: TextStyle(
                    fontSize: isMobile
                        ? 11
                        : isTablet
                        ? 11.5
                        : 12,
                    color: AdminDashboardStyles.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 2 : 2),
          // Status badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 8
                    : isTablet
                    ? 9
                    : 10,
                vertical: isMobile
                    ? 3
                    : isTablet
                    ? 3.5
                    : 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(
                  isMobile
                      ? 18
                      : isTablet
                      ? 19
                      : 20,
                ),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: isMobile
                      ? 10
                      : isTablet
                      ? 10.5
                      : 11,
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
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        isMobile
            ? 5
            : isTablet
            ? 5.5
            : 6,
      ),
      child: Container(
        padding: EdgeInsets.all(
          isMobile
              ? 5
              : isTablet
              ? 5.5
              : 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            isMobile
                ? 5
                : isTablet
                ? 5.5
                : 6,
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          size: isMobile
              ? 14
              : isTablet
              ? 15
              : 16,
          color: color,
        ),
      ),
    );
  }
}
