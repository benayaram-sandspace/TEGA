import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  // final AuthService _authService = AuthService(); // Unused for now
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackupEnabled = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Enhanced animations for settings tiles
  late List<AnimationController> _tileAnimations;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideTileAnimations;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    // Initialize tile animations (for ~15 settings items)
    _tileAnimations = List.generate(
      15,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );
    
    _scaleAnimations = _tileAnimations
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutBack,
            ))
        .toList();
    
    _slideTileAnimations = _tileAnimations
        .map((controller) => Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutCubic,
            )))
        .toList();
    
    _animationController.forward();
    _startTileAnimations();
  }
  
  void _startTileAnimations() {
    for (int i = 0; i < _tileAnimations.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _tileAnimations[i].forward();
        }
      });
    }
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _tileAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboardStyles.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //General Settings
                    _buildAnimatedSettingsSection(
                      title: 'General Settings',
                      children: [
                        _buildAnimatedSettingsTile(
                          icon: Icons.notifications,
                          title: 'Push Notifications',
                          subtitle:
                              'Receive notifications for important updates',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              _saveSettings();
                            },
                            activeThumbColor: AdminDashboardStyles.primary,
                          ),
                          index: 0,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.dark_mode,
                          title: 'Dark Mode',
                          subtitle: 'Switch to dark theme',
                          trailing: Switch(
                            value: _darkModeEnabled,
                            onChanged: (value) {
                              setState(() {
                                _darkModeEnabled = value;
                              });
                              _saveSettings();
                              _showThemeChangeDialog();
                            },
                            activeThumbColor: AdminDashboardStyles.primary,
                          ),
                          index: 1,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: 'English (US)',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showLanguageDialog(),
                          index: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    //Security Settings
                    _buildAnimatedSettingsSection(
                      title: 'Security',
                      children: [
                        _buildAnimatedSettingsTile(
                          icon: Icons.lock,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showChangePasswordDialog(),
                          index: 3,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.security,
                          title: 'Two-Factor Authentication',
                          subtitle: 'Add an extra layer of security',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _show2FADialog(),
                          index: 4,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.login,
                          title: 'Login Sessions',
                          subtitle: 'Manage active login sessions',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showSessionsDialog(),
                          index: 5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    //Data & Privacy
                    _buildAnimatedSettingsSection(
                      title: 'Data & Privacy',
                      children: [
                        _buildAnimatedSettingsTile(
                          icon: Icons.backup,
                          title: 'Auto Backup',
                          subtitle: 'Automatically backup your data',
                          trailing: Switch(
                            value: _autoBackupEnabled,
                            onChanged: (value) {
                              setState(() {
                                _autoBackupEnabled = value;
                              });
                              _saveSettings();
                            },
                            activeThumbColor: AdminDashboardStyles.primary,
                          ),
                          index: 6,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.download,
                          title: 'Export Data',
                          subtitle: 'Download your account data',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _exportData(),
                          index: 7,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          subtitle: 'Permanently delete your account',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showDeleteAccountDialog(),
                          index: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    //System Information
                    _buildAnimatedSettingsSection(
                      title: 'System Information',
                      children: [
                        _buildAnimatedSettingsTile(
                          icon: Icons.info,
                          title: 'App Version',
                          subtitle: '1.0.0 (Build 1)',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showVersionInfo(),
                          index: 9,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.help,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact support',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showHelpDialog(),
                          index: 10,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showPrivacyPolicy(),
                          index: 11,
                        ),
                        _buildAnimatedSettingsTile(
                          icon: Icons.description,
                          title: 'Terms of Service',
                          subtitle: 'Read our terms of service',
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showTermsOfService(),
                          index: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AdminDashboardStyles.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminDashboardStyles.textDark,
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnimatedSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    required int index,
  }) {
    if (index >= _tileAnimations.length) {
      return _buildSettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }
    
    return AnimatedBuilder(
      animation: _scaleAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[index].value,
          child: SlideTransition(
            position: _slideTileAnimations[index],
            child: _buildSettingsTile(
              icon: icon,
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AdminDashboardStyles.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AdminDashboardStyles.textLight, fontSize: 14),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
  
  void _showThemeChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Changed'),
        content: const Text(
          'Dark mode preference has been saved. The theme change will take effect after app restart.',
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: const Text(
          'Language selection will be implemented with real backend integration.',
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

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'Password change functionality will be implemented with real backend integration.',
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

  void _show2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
          '2FA setup will be implemented with real backend integration.',
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

  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Sessions'),
        content: const Text(
          'Session management will be implemented with real backend integration.',
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

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Data export functionality will be implemented with real backend integration.',
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Version: 1.0.0'),
            Text('Build Number: 1'),
            Text('Flutter Version: 3.9.0'),
            Text('Dart Version: 3.0.0'),
          ],
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Help and support features will be implemented with real backend integration.',
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'Privacy policy will be implemented with real backend integration.',
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text(
          'Terms of service will be implemented with real backend integration.',
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
}
