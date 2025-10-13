import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/models/admin_model.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });
}

class AdminProfilePage extends StatefulWidget {
  final AdminUser admin;

  const AdminProfilePage({super.key, required this.admin});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      final isCollapsed =
          _scrollController.hasClients &&
          _scrollController.offset > (200 - kToolbarHeight);
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardStyles.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedCard(index: 0, child: _buildStatsCard()),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  index: 1,
                  child: _buildPermissionsCard(),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(index: 2, child: _buildRecentActivityCard()),
                const SizedBox(height: 20),
                _buildAnimatedCard(index: 3, child: _buildContactCard()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      stretch: true,
      backgroundColor: AdminDashboardStyles.cardBackground,
      foregroundColor: AdminDashboardStyles.textDark,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AdminDashboardStyles.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: AdminDashboardStyles.textDark),
          onPressed: () {
            // TODO: Navigate to edit admin page
          },
        ),
      ],
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCollapsed ? 1.0 : 0.0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AdminDashboardStyles.primary,
              child: Text(
                widget.admin.name.isNotEmpty ? widget.admin.name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.admin.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminDashboardStyles.primary.withValues(alpha: 0.2),
                AdminDashboardStyles.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isCollapsed ? 0.0 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: kToolbarHeight / 2),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: AdminDashboardStyles.primary,
                    child: Text(
                      widget.admin.name.isNotEmpty ? widget.admin.name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.admin.name,
                  style: const TextStyle(
                    color: AdminDashboardStyles.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.admin.role,
                  style: const TextStyle(
                    color: AdminDashboardStyles.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int index}) {
    final double start = (0.15 * index).clamp(0.0, 1.0);
    final double end = (start + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.admin_panel_settings,
            'Role Level',
            _getRoleLevel(widget.admin.role),
          ),
          _buildStatItem(
            Icons.business,
            'Department',
            widget.admin.department.isNotEmpty ? widget.admin.department : 'General',
          ),
          _buildStatItem(
            Icons.work,
            'Designation',
            widget.admin.designation.isNotEmpty ? widget.admin.designation : 'Admin',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AdminDashboardStyles.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPermissionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Permissions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPermissionItem('User Management', _hasPermission('user_management'), Icons.people),
          _buildPermissionItem('Content Management', _hasPermission('content_management'), Icons.content_copy),
          _buildPermissionItem('College Management', _hasPermission('college_management'), Icons.school),
          _buildPermissionItem('Analytics Access', _hasPermission('analytics'), Icons.analytics),
          _buildPermissionItem('System Settings', _hasPermission('system_settings'), Icons.settings),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final activities = [
      _ActivityItem(
        icon: Icons.security,
        color: AdminDashboardStyles.primary,
        title: 'Updated user permissions',
        time: '2 hours ago',
      ),
      _ActivityItem(
        icon: Icons.school,
        color: AdminDashboardStyles.accentGreen,
        title: 'Created new college',
        time: '1 day ago',
      ),
      _ActivityItem(
        icon: Icons.analytics,
        color: AdminDashboardStyles.accentBlue,
        title: 'Generated analytics report',
        time: '2 days ago',
      ),
      _ActivityItem(
        icon: Icons.settings,
        color: AdminDashboardStyles.accentOrange,
        title: 'Modified content settings',
        time: '3 days ago',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(activities.length, (index) {
            return _buildActivityTimelineTile(
              activities[index],
              isLast: index == activities.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(widget.admin.email),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
          if (widget.admin.phoneNumber.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone'),
              subtitle: Text(widget.admin.phoneNumber),
              trailing: const Icon(Icons.copy, size: 20),
              onTap: () {},
            ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Member Since'),
            subtitle: Text(_formatDate(widget.admin.createdAt)),
            trailing: const Icon(Icons.info_outline, size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineTile(
    _ActivityItem activity, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.icon, color: activity.color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (!isLast) const Divider(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission, bool hasPermission, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasPermission ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permission,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textDark,
              ),
            ),
          ),
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? AppColors.success : AppColors.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _getRoleLevel(String role) {
    switch (role.toLowerCase()) {
      case 'super admin':
        return 'Level 5';
      case 'content manager':
        return 'Level 4';
      case 'user manager':
        return 'Level 3';
      case 'college manager':
        return 'Level 3';
      case 'analytics manager':
        return 'Level 2';
      default:
        return 'Level 1';
    }
  }

  bool _hasPermission(String permission) {
    switch (widget.admin.role.toLowerCase()) {
      case 'super admin':
        return true;
      case 'content manager':
        return permission == 'content_management';
      case 'user manager':
        return permission == 'user_management';
      case 'college manager':
        return permission == 'college_management';
      case 'analytics manager':
        return permission == 'analytics';
      default:
        return false;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
