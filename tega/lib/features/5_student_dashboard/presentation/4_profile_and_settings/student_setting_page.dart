import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/settings_cache_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Responsive breakpoints
  static double get mobileBreakpoint => 600;
  static double get tabletBreakpoint => 1024;
  static double get desktopBreakpoint => 1440;
  
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  static bool isLargeDesktop(BuildContext context) => MediaQuery.of(context).size.width >= desktopBreakpoint;
  static bool isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    final isLargeDesktop = SettingsPage.isLargeDesktop(context);
    final isDesktop = SettingsPage.isDesktop(context);
    final isTablet = SettingsPage.isTablet(context);
    final isSmallScreen = SettingsPage.isSmallScreen(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            vertical: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 6
                : 8,
            horizontal: isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 16
                : isSmallScreen
                ? 8
                : 12,
          ),
          children: [
            _buildItem(
              context,
              icon: Icons.person_outline,
              label: 'Account',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsPage(),
                  ),
                );
              },
              selected: true,
            ),
            _divider(),
            _buildItem(
              context,
              icon: Icons.shield_outlined,
              label: 'Security',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SecuritySettingsPage(),
                  ),
                );
              },
            ),
            _divider(),
            _buildItem(
              context,
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),
            _divider(),
            _buildItem(
              context,
              icon: Icons.visibility_outlined,
              label: 'Privacy',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsPage(),
                  ),
                );
              },
            ),
            _divider(),
            _buildItem(
              context,
              icon: Icons.palette_outlined,
              label: 'Appearance',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AppearanceSettingsPage(),
                  ),
                );
              },
            ),
            _divider(),
            _buildItem(
              context,
              icon: Icons.storage_outlined,
              label: 'Data & Storage',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DataStorageSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final isLargeDesktop = SettingsPage.isLargeDesktop(context);
    final isDesktop = SettingsPage.isDesktop(context);
    final isTablet = SettingsPage.isTablet(context);
    final isSmallScreen = SettingsPage.isSmallScreen(context);
    
    final Color primary = const Color(0xFF6B5FFF);
    final Color text = const Color(0xFF111827);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 16
            : isDesktop
            ? 14
            : isTablet
            ? 12
            : isSmallScreen
            ? 6
            : 8,
        vertical: isLargeDesktop
            ? 8
            : isDesktop
            ? 7
            : isTablet
            ? 6
            : isSmallScreen
            ? 4
            : 5,
      ),
      decoration: BoxDecoration(
        color: selected ? primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
          vertical: isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 8
              : 10,
        ),
        leading: Icon(
          icon,
          color: selected ? primary : const Color(0xFF6B7280),
          size: isLargeDesktop
              ? 28
              : isDesktop
              ? 26
              : isTablet
              ? 24
              : isSmallScreen
              ? 20
              : 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? primary : text,
            fontWeight: FontWeight.w600,
            fontSize: isLargeDesktop
                ? 18
                : isDesktop
                ? 17
                : isTablet
                ? 16
                : isSmallScreen
                ? 14
                : 15,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: const Color(0xFF9CA3AF),
          size: isLargeDesktop
              ? 28
              : isDesktop
              ? 26
              : isTablet
              ? 24
              : isSmallScreen
              ? 20
              : 22,
        ),
      ),
    );
  }

  Widget _divider() {
    return const SizedBox(height: 2);
  }
}

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _twoFactorEnabled = false;
  bool _loginNotifications = true;
  String _sessionTimeout = '30 Minutes';
  final List<String> _timeoutOptions = [
    '15 Minutes',
    '30 Minutes',
    '1 Hour',
    '2 Hours',
    'Never',
  ];

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Security & Authentication',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 19
                : isSmallScreen
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 26
                : isTablet
                ? 24
                : isSmallScreen
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            _buildSecurityCard(
              title: 'Two-Factor Authentication (2FA)',
              description: 'Add an extra layer of security to your account.',
              value: _twoFactorEnabled,
              onChanged: (value) => setState(() => _twoFactorEnabled = value),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildSecurityCard(
              title: 'Login Notifications',
              description:
                  'Receive email alerts for new logins to your account.',
              value: _loginNotifications,
              onChanged: (value) => setState(() => _loginNotifications = value),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildSessionTimeoutCard(),
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            _buildPasswordManagementCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                    fontSize: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 17
                        : isTablet
                        ? 16
                        : isSmallScreen
                        ? 14
                        : 15,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 11
                        : 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6B5FFF),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimeoutCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Timeout',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          DropdownButtonFormField<String>(
            value: _sessionTimeout,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 10
                    : 12,
                vertical: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
              ),
            ),
            items: _timeoutOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _sessionTimeout = newValue;
                });
              }
            },
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'Automatically log out after inactivity.',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordManagementCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                color: const Color(0xFF6B5FFF),
                size: isLargeDesktop
                    ? 26
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                'Password Management',
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 19
                      : isSmallScreen
                      ? 16
                      : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          _buildPasswordForm(),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Column(
      children: [
        _buildPasswordField(
          label: 'Current Password',
          controller: currentPasswordController,
          hintText: 'Enter current password',
        ),
        SizedBox(
          height: isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        _buildPasswordField(
          label: 'New Password',
          controller: newPasswordController,
          hintText: 'Enter new password',
        ),
        SizedBox(
          height: isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        _buildPasswordField(
          label: 'Confirm New Password',
          controller: confirmPasswordController,
          hintText: 'Confirm new password',
        ),
        SizedBox(
          height: isLargeDesktop
              ? 24
              : isDesktop
              ? 22
              : isTablet
              ? 20
              : isSmallScreen
              ? 16
              : 20,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _changePassword(
              currentPasswordController.text,
              newPasswordController.text,
              confirmPasswordController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FFF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 16
                    : 20,
                vertical: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 10
                    : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
              ),
            ),
            icon: Icon(
              Icons.lock,
              size: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 19
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 16
                  : 18,
            ),
            label: Text(
              'Change Password',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 17
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : isSmallScreen
                    ? 13
                    : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: isLargeDesktop
                ? 16
                : isDesktop
                ? 15
                : isTablet
                ? 14
                : isSmallScreen
                ? 12
                : 13,
          ),
        ),
        SizedBox(
          height: isLargeDesktop
              ? 10
              : isDesktop
              ? 9
              : isTablet
              ? 8
              : isSmallScreen
              ? 6
              : 8,
        ),
        TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(
            fontSize: isLargeDesktop
                ? 16
                : isDesktop
                ? 15
                : isTablet
                ? 14
                : isSmallScreen
                ? 12
                : 13,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 12
                  : 13,
            ),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 10
                  : 12,
              vertical: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    try {
      final headers = AuthService().getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.changePassword),
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Password changed successfully');
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Failed to change password',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error changing password: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Email Notifications
  bool _emailCourseUpdates = true;
  bool _emailExamReminders = true;
  bool _emailJobAlerts = true;
  bool _emailPaymentAlerts = true;
  bool _emailSystemUpdates = true;

  // Push Notifications
  bool _pushCourseUpdates = true;
  bool _pushExamReminders = true;
  bool _pushJobAlerts = true;
  bool _pushPaymentAlerts = true;
  bool _pushSystemUpdates = true;

  // SMS Notifications
  bool _smsCourseUpdates = false;
  bool _smsExamReminders = false;
  bool _smsJobAlerts = false;
  bool _smsPaymentAlerts = false;
  bool _smsSystemUpdates = false;

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notification Preferences',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 19
                : isSmallScreen
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 26
                : isTablet
                ? 24
                : isSmallScreen
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationSection(
              title: 'Email Notifications',
              icon: Icons.email_outlined,
              notifications: [
                _NotificationItem(
                  'Course Updates',
                  _emailCourseUpdates,
                  (value) => setState(() => _emailCourseUpdates = value),
                ),
                _NotificationItem(
                  'Exam Reminders',
                  _emailExamReminders,
                  (value) => setState(() => _emailExamReminders = value),
                ),
                _NotificationItem(
                  'Job Alerts',
                  _emailJobAlerts,
                  (value) => setState(() => _emailJobAlerts = value),
                ),
                _NotificationItem(
                  'Payment Alerts',
                  _emailPaymentAlerts,
                  (value) => setState(() => _emailPaymentAlerts = value),
                ),
                _NotificationItem(
                  'System Updates',
                  _emailSystemUpdates,
                  (value) => setState(() => _emailSystemUpdates = value),
                ),
              ],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            _buildNotificationSection(
              title: 'Push Notifications',
              icon: Icons.phone_android_outlined,
              notifications: [
                _NotificationItem(
                  'Course Updates',
                  _pushCourseUpdates,
                  (value) => setState(() => _pushCourseUpdates = value),
                ),
                _NotificationItem(
                  'Exam Reminders',
                  _pushExamReminders,
                  (value) => setState(() => _pushExamReminders = value),
                ),
                _NotificationItem(
                  'Job Alerts',
                  _pushJobAlerts,
                  (value) => setState(() => _pushJobAlerts = value),
                ),
                _NotificationItem(
                  'Payment Alerts',
                  _pushPaymentAlerts,
                  (value) => setState(() => _pushPaymentAlerts = value),
                ),
                _NotificationItem(
                  'System Updates',
                  _pushSystemUpdates,
                  (value) => setState(() => _pushSystemUpdates = value),
                ),
              ],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            _buildNotificationSection(
              title: 'SMS Notifications',
              icon: Icons.sms_outlined,
              notifications: [
                _NotificationItem(
                  'Course Updates',
                  _smsCourseUpdates,
                  (value) => setState(() => _smsCourseUpdates = value),
                ),
                _NotificationItem(
                  'Exam Reminders',
                  _smsExamReminders,
                  (value) => setState(() => _smsExamReminders = value),
                ),
                _NotificationItem(
                  'Job Alerts',
                  _smsJobAlerts,
                  (value) => setState(() => _smsJobAlerts = value),
                ),
                _NotificationItem(
                  'Payment Alerts',
                  _smsPaymentAlerts,
                  (value) => setState(() => _smsPaymentAlerts = value),
                ),
                _NotificationItem(
                  'System Updates',
                  _smsSystemUpdates,
                  (value) => setState(() => _smsSystemUpdates = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required IconData icon,
    required List<_NotificationItem> notifications,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6B5FFF),
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 17
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 14
                      : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          ...notifications.map(
            (notification) => _buildNotificationItem(notification),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(_NotificationItem notification) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 16
            : isDesktop
            ? 14
            : isTablet
            ? 12
            : isSmallScreen
            ? 8
            : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              notification.label,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 12
                    : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: notification.value,
            onChanged: notification.onChanged,
            activeColor: const Color(0xFF6B5FFF),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  _NotificationItem(this.label, this.value, this.onChanged);
}

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  String _profileVisibility = 'Public (Visible to everyone)';
  String _contactVisibility = 'Public';
  String _messagePermissions = 'Allow messages from everyone';
  bool _dataSharing = true;
  bool _analyticsTracking = true;

  final List<String> _profileOptions = [
    'Public (Visible to everyone)',
    'Friends only',
    'Private (Only me)',
  ];

  final List<String> _contactOptions = ['Public', 'Friends only', 'Private'];

  final List<String> _messageOptions = [
    'Allow messages from everyone',
    'Friends only',
    'No messages',
  ];

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Privacy Settings',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 19
                : isSmallScreen
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 26
                : isTablet
                ? 24
                : isSmallScreen
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrivacyCard(
              title: 'Profile Visibility',
              description: 'Control who can see your profile.',
              value: _profileVisibility,
              options: _profileOptions,
              onChanged: (value) => setState(() => _profileVisibility = value!),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildPrivacyCard(
              title: 'Contact Information Visibility',
              description: 'Control who can see your email and phone number.',
              value: _contactVisibility,
              options: _contactOptions,
              onChanged: (value) => setState(() => _contactVisibility = value!),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildPrivacyCard(
              title: 'Message Permissions',
              description: 'Control who can send you messages.',
              value: _messagePermissions,
              options: _messageOptions,
              onChanged: (value) =>
                  setState(() => _messagePermissions = value!),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildToggleCard(
              title: 'Data Sharing',
              description:
                  'Allow sharing of anonymized data with partners for improvements.',
              value: _dataSharing,
              onChanged: (value) => setState(() => _dataSharing = value),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildToggleCard(
              title: 'Analytics Tracking',
              description:
                  'Allow us to collect anonymous usage data to improve the app.',
              value: _analyticsTracking,
              onChanged: (value) => setState(() => _analyticsTracking = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required String title,
    required String description,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 10
                    : 12,
                vertical: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
              ),
            ),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            description,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                    fontSize: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 17
                        : isTablet
                        ? 16
                        : isSmallScreen
                        ? 14
                        : 15,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 11
                        : 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6B5FFF),
          ),
        ],
      ),
    );
  }
}

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  String _currentTheme = 'Light';

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Appearance',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 19
                : isSmallScreen
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 26
                : isTablet
                ? 24
                : isSmallScreen
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildThemeCard()],
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'Current theme: $_currentTheme',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          Center(
            child: ElevatedButton(
              onPressed: _switchTheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 28
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 10
                        : isDesktop
                        ? 9
                        : isTablet
                        ? 8
                        : isSmallScreen
                        ? 6
                        : 8,
                  ),
                ),
              ),
              child: Text(
                'Switch Theme',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 17
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 13
                      : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchTheme() {
    setState(() {
      _currentTheme = _currentTheme == 'Light' ? 'Dark' : 'Light';
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme switched to $_currentTheme'),
        backgroundColor: const Color(0xFF6B5FFF),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class DataStorageSettingsPage extends StatefulWidget {
  const DataStorageSettingsPage({super.key});

  @override
  State<DataStorageSettingsPage> createState() =>
      _DataStorageSettingsPageState();
}

class _DataStorageSettingsPageState extends State<DataStorageSettingsPage> {
  bool _automaticBackup = true;
  String _backupFrequency = 'Weekly';
  String _dataRetention = '1 Year';
  String _exportFormat = 'JSON';

  final List<String> _frequencyOptions = ['Daily', 'Weekly', 'Monthly'];

  final List<String> _retentionOptions = [
    '3 Months',
    '6 Months',
    '1 Year',
    '2 Years',
    'Forever',
  ];

  final List<String> _exportFormats = ['JSON', 'CSV', 'PDF'];

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Data & Storage',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 19
                : isSmallScreen
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 26
                : isTablet
                ? 24
                : isSmallScreen
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackupCard(),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildFrequencyCard(),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildRetentionCard(),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            _buildExportCard(),
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            _buildDeleteAccountCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatic Data Backup',
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                    fontSize: isLargeDesktop
                        ? 18
                        : isDesktop
                        ? 17
                        : isTablet
                        ? 16
                        : isSmallScreen
                        ? 14
                        : 15,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                Text(
                  'Automatically back up your data to the cloud.',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 11
                        : 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _automaticBackup,
            onChanged: (value) => setState(() => _automaticBackup = value),
            activeColor: const Color(0xFF6B5FFF),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup Frequency',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          DropdownButtonFormField<String>(
            value: _backupFrequency,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 10
                    : 12,
                vertical: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
              ),
            ),
            items: _frequencyOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _backupFrequency = newValue);
              }
            },
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'How often your data is automatically backed up.',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Retention',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          DropdownButtonFormField<String>(
            value: _dataRetention,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 10
                    : 12,
                vertical: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
              ),
            ),
            items: _retentionOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _dataRetention = newValue);
              }
            },
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'How long your backed-up data is retained.',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Data',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'Download a copy of your account data.',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 8
                : 12,
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _exportFormat,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 14
                          : isTablet
                          ? 12
                          : isSmallScreen
                          ? 10
                          : 12,
                      vertical: isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 10
                          : isTablet
                          ? 8
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 10
                            : isDesktop
                            ? 9
                            : isTablet
                            ? 8
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 10
                            : isDesktop
                            ? 9
                            : isTablet
                            ? 8
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 10
                            : isDesktop
                            ? 9
                            : isTablet
                            ? 8
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
                    ),
                  ),
                  items: _exportFormats.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 12
                              : 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _exportFormat = newValue);
                    }
                  },
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 8
                    : 12,
              ),
              ElevatedButton.icon(
                onPressed: _exportData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 16
                        : isSmallScreen
                        ? 12
                        : 16,
                    vertical: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 10
                          : isDesktop
                          ? 9
                          : isTablet
                          ? 8
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.download,
                  size: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 19
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 16
                      : 18,
                ),
                label: Text(
                  'Export',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 17
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 15
                        : isSmallScreen
                        ? 13
                        : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountCard() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: Colors.red,
          width: isLargeDesktop || isDesktop
              ? 2.5
              : isTablet
              ? 2
              : isSmallScreen
              ? 1.5
              : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: isLargeDesktop
                    ? 26
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 17
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 14
                      : 15,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDeleteAccountDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 10
                        : isDesktop
                        ? 9
                        : isTablet
                        ? 8
                        : isSmallScreen
                        ? 6
                        : 8,
                  ),
                ),
              ),
              icon: Icon(
                Icons.delete,
                size: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 19
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 16
                    : 18,
              ),
              label: Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 17
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 13
                      : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data in $_exportFormat format...'),
        backgroundColor: const Color(0xFF6B5FFF),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion initiated. This is a demo action.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final SettingsCacheService _cacheService = SettingsCacheService();
  bool _loading = true;
  Map<String, dynamic>? _data;

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getAccountData();
      if (cachedData != null && mounted) {
        setState(() {
          _data = cachedData;
          _loading = false;
        });
        // Still fetch in background to update cache
        _fetchAccountDataInBackground();
        return;
      }
    }

    setState(() => _loading = true);
    await _fetchAccountDataInBackground();
  }

  Future<void> _fetchAccountDataInBackground() async {
    try {
      final headers = await AuthService().getAuthHeaders();
      final resp = await http.get(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final profile = body['data'] as Map<String, dynamic>?;
        final accountData = {
          'username': profile?['username'] ?? profile?['name'] ?? '-',
          'email': profile?['email'] ?? '-',
          'createdAt': profile?['createdAt'],
          'lastLogin': profile?['lastLogin'] ?? 'Never',
        };
        
        // Cache the data
        await _cacheService.setAccountData(accountData);
        
        if (mounted) {
          setState(() {
            _data = accountData;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Account Information',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 19
                : isSmallScreen
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isLargeDesktop
                ? 28
                : isDesktop
                ? 26
                : isTablet
                ? 24
                : isSmallScreen
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF6B5FFF),
                strokeWidth: isLargeDesktop
                    ? 4
                    : isDesktop
                    ? 3.5
                    : isTablet
                    ? 3
                    : isSmallScreen
                    ? 2.5
                    : 3,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusCard(
                    status: 'Active',
                    description: 'Your account is active and in good standing',
                  ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 18
                        : isTablet
                        ? 16
                        : isSmallScreen
                        ? 12
                        : 16,
                  ),
                  isSmallScreen
                      ? Column(
                          children: [
                            _readOnlyField(
                              'Username',
                              _data?['username']?.toString() ?? '-',
                            ),
                            SizedBox(
                              height: isSmallScreen ? 12 : 16,
                            ),
                            _readOnlyField(
                              'Email Address',
                              _data?['email']?.toString() ?? '-',
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _readOnlyField(
                                'Username',
                                _data?['username']?.toString() ?? '-',
                              ),
                            ),
                            SizedBox(
                              width: isLargeDesktop
                                  ? 16
                                  : isDesktop
                                  ? 14
                                  : isTablet
                                  ? 12
                                  : 12,
                            ),
                            Expanded(
                              child: _readOnlyField(
                                'Email Address',
                                _data?['email']?.toString() ?? '-',
                              ),
                            ),
                          ],
                        ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  isSmallScreen
                      ? Column(
                          children: [
                            _iconInfoCard(
                              icon: Icons.calendar_today_outlined,
                              label: 'Member Since',
                              value:
                                  _data?['createdAt']
                                      ?.toString()
                                      .split('T')
                                      .first ??
                                  '-',
                            ),
                            SizedBox(
                              height: isSmallScreen ? 12 : 16,
                            ),
                            _iconInfoCard(
                              icon: Icons.visibility_outlined,
                              label: 'Last Login',
                              value: _data?['lastLogin']?.toString() ?? 'Never',
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _iconInfoCard(
                                icon: Icons.calendar_today_outlined,
                                label: 'Member Since',
                                value:
                                    _data?['createdAt']
                                        ?.toString()
                                        .split('T')
                                        .first ??
                                    '-',
                              ),
                            ),
                            SizedBox(
                              width: isLargeDesktop
                                  ? 16
                                  : isDesktop
                                  ? 14
                                  : isTablet
                                  ? 12
                                  : 12,
                            ),
                            Expanded(
                              child: _iconInfoCard(
                                icon: Icons.visibility_outlined,
                                label: 'Last Login',
                                value: _data?['lastLogin']?.toString() ?? 'Never',
                              ),
                            ),
                          ],
                        ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 32
                        : isDesktop
                        ? 28
                        : isTablet
                        ? 24
                        : isSmallScreen
                        ? 16
                        : 20,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statusCard({required String status, required String description}) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 18
                        : isTablet
                        ? 17
                        : isSmallScreen
                        ? 14
                        : 16,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 8
                      : isDesktop
                      ? 7
                      : isTablet
                      ? 6
                      : isSmallScreen
                      ? 4
                      : 6,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 10,
              vertical: isLargeDesktop
                  ? 8
                  : isDesktop
                  ? 7
                  : isTablet
                  ? 6
                  : isSmallScreen
                  ? 4
                  : 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 16
                    : 18,
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: const Color(0xFF065F46),
                fontWeight: FontWeight.w700,
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 12
                    : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: isLargeDesktop
                ? 16
                : isDesktop
                ? 15
                : isTablet
                ? 14
                : isSmallScreen
                ? 12
                : 13,
          ),
        ),
        SizedBox(
          height: isLargeDesktop
              ? 8
              : isDesktop
              ? 7
              : isTablet
              ? 6
              : isSmallScreen
              ? 4
              : 6,
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
            vertical: isLargeDesktop
                ? 18
                : isDesktop
                ? 16
                : isTablet
                ? 14
                : isSmallScreen
                ? 10
                : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 10
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: isLargeDesktop || isDesktop
                  ? 1.5
                  : isTablet
                  ? 1.2
                  : isSmallScreen
                  ? 0.8
                  : 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 12
                  : 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6B7280),
                size: isLargeDesktop
                    ? 22
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 16
                    : 18,
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 8
                    : isDesktop
                    ? 7
                    : isTablet
                    ? 6
                    : isSmallScreen
                    ? 5
                    : 6,
              ),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 12
                      : 13,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 12
                  : 13,
            ),
          ),
        ],
      ),
    );
  }
}
