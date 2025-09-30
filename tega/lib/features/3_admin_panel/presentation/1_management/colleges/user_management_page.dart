import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final List<Map<String, dynamic>> _fakeUsers = [
    {
      'id': '1',
      'name': 'Benayaram',
      'email': 'admin@tega.com',
      'role': UserRole.admin,
      'status': 'Active',
      'lastLogin': '2024-01-15 10:30',
      'createdAt': '2024-01-01',
    },
    {
      'id': '2',
      'name': 'Moderator User',
      'email': 'moderator@tega.com',
      'role': UserRole.moderator,
      'status': 'Active',
      'lastLogin': '2024-01-15 09:15',
      'createdAt': '2024-01-05',
    },
    {
      'id': '3',
      'name': 'Regular User',
      'email': 'user@tega.com',
      'role': UserRole.user,
      'status': 'Active',
      'lastLogin': '2024-01-15 08:45',
      'createdAt': '2024-01-10',
    },
    {
      'id': '4',
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'role': UserRole.user,
      'status': 'Inactive',
      'lastLogin': '2024-01-10 14:20',
      'createdAt': '2024-01-12',
    },
    {
      'id': '5',
      'name': 'Jane Smith',
      'email': 'jane.smith@example.com',
      'role': UserRole.user,
      'status': 'Active',
      'lastLogin': '2024-01-15 11:00',
      'createdAt': '2024-01-13',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA726),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // User Stats
              Row(
                children: [
                  Expanded(
                    child: _buildUserStatCard(
                      title: 'Total Users',
                      value: _fakeUsers.length.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUserStatCard(
                      title: 'Active Users',
                      value: _fakeUsers
                          .where((user) => user['status'] == 'Active')
                          .length
                          .toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUserStatCard(
                      title: 'Admins',
                      value: _fakeUsers
                          .where((user) => user['role'] == UserRole.admin)
                          .length
                          .toString(),
                      icon: Icons.admin_panel_settings,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUserStatCard(
                      title: 'Moderators',
                      value: _fakeUsers
                          .where((user) => user['role'] == UserRole.moderator)
                          .length
                          .toString(),
                      icon: Icons.shield,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Users Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Role',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Last Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _fakeUsers.length,
                          itemBuilder: (context, index) {
                            final user = _fakeUsers[index];
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: _authService
                                              .getRoleColor(user['role']),
                                          child: Text(
                                            user['name'][0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          user['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      user['email'],
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _authService
                                            .getRoleColor(user['role'])
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _authService.getRoleDisplayName(
                                          user['role'],
                                        ),
                                        style: TextStyle(
                                          color: _authService.getRoleColor(
                                            user['role'],
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user['status'] == 'Active'
                                            ? AdminDashboardStyles.statusActive.withValues(alpha: 0.1)
                                            : AdminDashboardStyles.statusError.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['status'],
                                        style: TextStyle(
                                          color: user['status'] == 'Active'
                                              ? AdminDashboardStyles.statusActive
                                              : AdminDashboardStyles.statusError,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      user['lastLogin'],
                                      style: TextStyle(
                                        color: AdminDashboardStyles.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _editUser(user),
                                          icon: const Icon(Icons.edit, size: 18),
                                          color: AdminDashboardStyles.primary,
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteUser(user),
                                          icon: const Icon(Icons.delete, size: 18),
                                          color: AdminDashboardStyles.statusError,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text(
          'This feature will be implemented with real backend integration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Text('Edit user: ${user['name']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement delete functionality
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
