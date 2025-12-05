import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/settings_cache_service.dart';
import 'package:provider/provider.dart';
import 'package:tega/core/providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Responsive breakpoints
  static double get mobileBreakpoint => 600;
  static double get tabletBreakpoint => 1024;
  static double get desktopBreakpoint => 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    final isLargeDesktop = SettingsPage.isLargeDesktop(context);
    final isDesktop = SettingsPage.isDesktop(context);
    final isTablet = SettingsPage.isTablet(context);
    final isSmallScreen = SettingsPage.isSmallScreen(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              icon: Icons.security,
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
        color: selected
            ? primary.withOpacity(0.08)
            : Theme.of(context).cardColor,
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
            color: selected
                ? primary
                : Theme.of(context).textTheme.bodyLarge?.color,
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
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _loadCurrentPassword();
  }

  Future<void> _loadCurrentPassword() async {
    print('DEBUG: UI - Loading current password...');
    final password = await AuthService().getSavedPassword();
    print('DEBUG: UI - Password loaded from service: ${password != null}');
    if (password != null && mounted) {
      setState(() {
        _currentPasswordController.text = password;
      });
      print('DEBUG: UI - Password set to controller');
    } else {
      print('DEBUG: UI - Password was null or widget not mounted');
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiEndpoints.studentChangePassword),
        headers: headers,
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Color(0xFF6B5FFF),
          ),
        );
        // Don't clear current password as it's still valid until next login (or update it if we want)
        // But usually change password requires re-login or updating the stored password.
        // For now, let's just clear new/confirm fields.
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        final error =
            json.decode(response.body)['message'] ??
            'Failed to change password';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiEndpoints.studentDeleteAccount),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Clear auth data and navigate to login
        await AuthService().logout();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Color(0xFF6B5FFF),
          ),
        );

        // Navigate to login page and remove all previous routes
        // Using MaterialPageRoute since named route might not be defined
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        final error =
            json.decode(response.body)['message'] ?? 'Failed to delete account';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          'Security',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
            color: Theme.of(context).iconTheme.color,
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
            _buildPasswordManagementCard(),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            _buildDeleteAccountCard(),
          ],
        ),
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
        color: Theme.of(context).cardColor,
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
      child: Form(
        key: _formKey,
        child: AutofillGroup(
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                hint: '••••••••••',
                obscure: true,
                onToggle: () {},
                readOnly: true,
                showToggle: false,
                autofillHints: const [AutofillHints.password],
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
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter new password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                autofillHints: const [AutofillHints.newPassword],
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
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Confirm new password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                autofillHints: const [AutofillHints.newPassword],
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5FFF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
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
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Change Password',
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,

    bool readOnly = false,
    bool showToggle = true,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
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
        TextFormField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          autofillHints: autofillHints,
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: hint,
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
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF9CA3AF),
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
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
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
        color: const Color(0xFFFEF2F2),
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
          color: const Color(0xFFFECACA),
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
                Icons.warning_amber_rounded,
                color: const Color(0xFFDC2626),
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
                'Danger Zone',
                style: TextStyle(
                  color: const Color(0xFF991B1B),
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
              color: const Color(0xFF7F1D1D),
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
            'Permanently delete your account and all associated data. This action cannot be undone. All your courses, exam results, and progress will be lost.',
            style: TextStyle(
              color: const Color(0xFF991B1B),
              fontSize: isLargeDesktop
                  ? 15
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 11
                  : 12,
              height: 1.5,
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
            child: ElevatedButton(
              onPressed: _showDeleteAccountDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
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
                'Delete Account',
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;

  bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Appearance',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.w700,
            fontSize: isLargeDesktop(context)
                ? 22
                : isDesktop(context)
                ? 20
                : isTablet(context)
                ? 19
                : isSmallScreen(context)
                ? 16
                : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
            size: isLargeDesktop(context)
                ? 28
                : isDesktop(context)
                ? 26
                : isTablet(context)
                ? 24
                : isSmallScreen(context)
                ? 20
                : 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop(context)
              ? 24
              : isDesktop(context)
              ? 20
              : isTablet(context)
              ? 18
              : isSmallScreen(context)
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildThemeCard(context, themeProvider)],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.grey[400] : const Color(0xFF6B7280);
    final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB);

    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop(context)
            ? 20
            : isDesktop(context)
            ? 18
            : isTablet(context)
            ? 16
            : isSmallScreen(context)
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(
          isLargeDesktop(context)
              ? 16
              : isDesktop(context)
              ? 14
              : isTablet(context)
              ? 12
              : isSmallScreen(context)
              ? 10
              : 12,
        ),
        border: Border.all(
          color: borderColor,
          width: isLargeDesktop(context) || isDesktop(context)
              ? 1.5
              : isTablet(context)
              ? 1.2
              : isSmallScreen(context)
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
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: isLargeDesktop(context)
                  ? 18
                  : isDesktop(context)
                  ? 17
                  : isTablet(context)
                  ? 16
                  : isSmallScreen(context)
                  ? 14
                  : 15,
            ),
          ),
          SizedBox(
            height: isLargeDesktop(context)
                ? 12
                : isDesktop(context)
                ? 10
                : isTablet(context)
                ? 8
                : isSmallScreen(context)
                ? 6
                : 8,
          ),
          Text(
            'Current theme: ${isDark ? 'Dark' : 'Light'}',
            style: TextStyle(
              color: subTextColor,
              fontSize: isLargeDesktop(context)
                  ? 15
                  : isDesktop(context)
                  ? 14
                  : isTablet(context)
                  ? 13
                  : isSmallScreen(context)
                  ? 11
                  : 12,
            ),
          ),
          SizedBox(
            height: isLargeDesktop(context)
                ? 20
                : isDesktop(context)
                ? 18
                : isTablet(context)
                ? 16
                : isSmallScreen(context)
                ? 12
                : 16,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                themeProvider.toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Theme switched to ${!isDark ? 'Dark' : 'Light'}',
                    ),
                    backgroundColor: const Color(0xFF6B5FFF),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop(context)
                      ? 32
                      : isDesktop(context)
                      ? 28
                      : isTablet(context)
                      ? 24
                      : isSmallScreen(context)
                      ? 20
                      : 24,
                  vertical: isLargeDesktop(context)
                      ? 16
                      : isDesktop(context)
                      ? 14
                      : isTablet(context)
                      ? 12
                      : isSmallScreen(context)
                      ? 10
                      : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop(context)
                        ? 10
                        : isDesktop(context)
                        ? 9
                        : isTablet(context)
                        ? 8
                        : isSmallScreen(context)
                        ? 6
                        : 8,
                  ),
                ),
              ),
              child: Text(
                'Switch Theme',
                style: TextStyle(
                  fontSize: isLargeDesktop(context)
                      ? 17
                      : isDesktop(context)
                      ? 16
                      : isTablet(context)
                      ? 15
                      : isSmallScreen(context)
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
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          'Account Information',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
            color: Theme.of(context).iconTheme.color,
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
                            SizedBox(height: isSmallScreen ? 12 : 16),
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
                            SizedBox(height: isSmallScreen ? 12 : 16),
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
                                value:
                                    _data?['lastLogin']?.toString() ?? 'Never',
                              ),
                            ),
                          ],
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
        color: const Color(0xFFECFDF5),
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
          color: const Color(0xFFD1FAE5),
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
          Container(
            padding: EdgeInsets.all(
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
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: isLargeDesktop
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
          SizedBox(
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: const Color(0xFF065F46),
                    fontWeight: FontWeight.w700,
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
                      ? 4
                      : isDesktop
                      ? 3
                      : isTablet
                      ? 2
                      : isSmallScreen
                      ? 2
                      : 2,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF047857),
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
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: isLargeDesktop
                ? 15
                : isDesktop
                ? 14
                : isTablet
                ? 13
                : isSmallScreen
                ? 11
                : 12,
            fontWeight: FontWeight.w500,
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
          width: double.infinity,
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
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 10
                : isSmallScreen
                ? 8
                : 10,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
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
            ? 16
            : isDesktop
            ? 14
            : isTablet
            ? 12
            : isSmallScreen
            ? 10
            : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 12
              : isDesktop
              ? 10
              : isTablet
              ? 8
              : isSmallScreen
              ? 6
              : 8,
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
          Icon(
            icon,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
            size: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 18,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: isLargeDesktop
                      ? 13
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 10
                      : 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
