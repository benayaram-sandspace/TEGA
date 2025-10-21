import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/data/models/principal_model.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';

class PrincipalProfilePage extends StatefulWidget {
  final Principal principal;

  const PrincipalProfilePage({super.key, required this.principal});

  @override
  State<PrincipalProfilePage> createState() => _PrincipalProfilePageState();
}

class _PrincipalProfilePageState extends State<PrincipalProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  final AdminDashboardService _dashboardService = AdminDashboardService();
  bool _isCollapsed = false;

  // Principal data
  Map<String, dynamic>? _detailedPrincipalData;

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

    _fetchDetailedPrincipalData();
  }

  Future<void> _fetchDetailedPrincipalData() async {
    try {
      final data = await _dashboardService.getPrincipalById(
        widget.principal.id,
      );

      if (data['success'] == true) {
        setState(() {
          _detailedPrincipalData = data['principal'];
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
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
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 16 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedCard(index: 0, child: _buildStatsCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                ),
                _buildAnimatedCard(index: 1, child: _buildPersonalInfoCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                ),
                _buildAnimatedCard(index: 2, child: _buildContactCard()),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 40 : 60,
                ),
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
        icon: const Icon(
          Icons.arrow_back,
          color: AdminDashboardStyles.textDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCollapsed ? 1.0 : 0.0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AdminDashboardStyles.primary,
              child: Text(
                widget.principal.name.isNotEmpty
                    ? widget.principal.name[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.principal.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
                      widget.principal.name.isNotEmpty
                          ? widget.principal.name[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.principal.name,
                    style: const TextStyle(
                      color: AdminDashboardStyles.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.principal.university.isNotEmpty
                        ? widget.principal.university
                        : 'Principal',
                    style: const TextStyle(
                      color: AdminDashboardStyles.textLight,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    final principalData = _detailedPrincipalData;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Principal Statistics',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          isSmallScreen
              ? Column(
                  children: [
                    _buildStatItem(
                      Icons.admin_panel_settings,
                      'Role',
                      'Principal',
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.person,
                          'Gender',
                          principalData?['gender'] ?? widget.principal.gender,
                          const Color(0xFF8B5CF6),
                        ),
                        _buildStatItem(
                          Icons.verified,
                          'Status',
                          principalData?['isActive'] == true
                              ? 'Active'
                              : 'Inactive',
                          _getStatusColor(principalData?['isActive']),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.admin_panel_settings,
                      'Role',
                      'Principal',
                      const Color(0xFF3B82F6),
                    ),
                    _buildStatItem(
                      Icons.person,
                      'Gender',
                      principalData?['gender'] ?? widget.principal.gender,
                      const Color(0xFF8B5CF6),
                    ),
                    _buildStatItem(
                      Icons.verified,
                      'Status',
                      principalData?['isActive'] == true
                          ? 'Active'
                          : 'Inactive',
                      _getStatusColor(principalData?['isActive']),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic isActive) {
    if (isActive == true) {
      return const Color(0xFF10B981);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    final principalData = _detailedPrincipalData;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildInfoRow('Full Name', _getFullName(principalData)),
          _buildInfoRow(
            'Principal Name',
            principalData?['principalName'] ?? widget.principal.principalName,
          ),
          _buildInfoRow(
            'Gender',
            principalData?['gender'] ?? widget.principal.gender,
          ),
          _buildInfoRow(
            'University',
            principalData?['university'] ?? widget.principal.university,
          ),
          _buildInfoRow(
            'Role',
            principalData?['role'] ?? widget.principal.role,
          ),
          _buildInfoRow(
            'Created At',
            principalData?['createdAt'] != null
                ? _formatDate(principalData!['createdAt'])
                : 'Not available',
          ),
          _buildInfoRow(
            'Updated At',
            principalData?['updatedAt'] != null
                ? _formatDate(principalData!['updatedAt'])
                : 'Not available',
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final principalData = _detailedPrincipalData;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8.0 : 12.0,
              vertical: isSmallScreen ? 8.0 : 12.0,
            ),
            child: Text(
              'Contact Information',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(principalData?['email'] ?? widget.principal.email),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('University'),
            subtitle: Text(
              principalData?['university'] ?? widget.principal.university,
            ),
            trailing: const Icon(Icons.info_outline, size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  String _getFullName(Map<String, dynamic>? principalData) {
    final firstName = principalData?['firstName'] ?? widget.principal.firstName;
    final lastName = principalData?['lastName'] ?? widget.principal.lastName;
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Not specified' : fullName;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
