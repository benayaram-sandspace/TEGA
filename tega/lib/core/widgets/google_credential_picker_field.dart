import 'package:flutter/material.dart';
import '../services/simple_google_credential_manager.dart';
import '../constants/app_colors.dart';

/// Google Credential Picker Field Widget
/// This widget shows Google's native credential picker when clicked
class GoogleCredentialPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final InputDecoration decoration;
  final Function(String email, String password)? onCredentialSelected;
  final bool isMobile;

  const GoogleCredentialPickerField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    required this.decoration,
    this.onCredentialSelected,
    this.isMobile = true,
  });

  @override
  State<GoogleCredentialPickerField> createState() =>
      _GoogleCredentialPickerFieldState();
}

class _GoogleCredentialPickerFieldState
    extends State<GoogleCredentialPickerField> {
  final SimpleGoogleCredentialManager _credentialManager =
      SimpleGoogleCredentialManager();
  List<GoogleCredential> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initializeCredentialManager();
    // Don't auto-fill on initialization - let user choose
  }

  Future<void> _initializeCredentialManager() async {
    try {
      await _credentialManager.initialize();
    } catch (e) {}
  }

  Future<void> _loadSuggestions(String partialEmail) async {
    if (partialEmail.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final suggestions = await _credentialManager.getEmailSuggestions(
        partialEmail,
      );
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {}
  }

  void _showCredentialPicker() async {
    try {
      // Check if biometric authentication is available
      final isBiometricAvailable = await _credentialManager
          .isBiometricAvailable();

      if (isBiometricAvailable) {
        // Authenticate with biometrics first
        final isAuthenticated = await _credentialManager
            .authenticateWithBiometrics();
        if (!isAuthenticated) {
          _showSnackBar(
            'Biometric authentication required to access credentials',
          );
          return;
        }
      }

      // Get saved credentials
      final credentials = await _credentialManager.getSavedCredentials();

      if (credentials.isEmpty) {
        _showSnackBar('No saved credentials found');
        return;
      }

      // Show credentials in a bottom sheet
      _showCredentialsBottomSheet(credentials);
    } catch (e) {
      _showSnackBar('Error accessing credentials: $e');
    }
  }

  void _showCredentialsBottomSheet(List<GoogleCredential> credentials) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saved Credentials',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Credentials list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: credentials.length,
                itemBuilder: (context, index) {
                  final credential = credentials[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight, width: 1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectCredential(credential),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Text(
                                    credential.displayName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Credential info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      credential.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      credential.email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete button
                              IconButton(
                                onPressed: () => _deleteCredential(credential),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCredential(GoogleCredential credential) {
    widget.controller.text = credential.email;
    widget.onCredentialSelected?.call(credential.email, credential.password);
    Navigator.of(context).pop();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _deleteCredential(GoogleCredential credential) async {
    try {
      final success = await _credentialManager.deleteCredentials(
        'tega.app',
        credential.email,
      );

      if (success) {
        _showSnackBar('Credential deleted successfully');
        Navigator.of(context).pop();
        _showCredentialPicker(); // Refresh the picker
      } else {
        _showSnackBar('Failed to delete credential');
      }
    } catch (e) {
      _showSnackBar('Error deleting credential');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and remove focus when tapping outside
        FocusScope.of(context).unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Column(
        children: [
          TextFormField(
            controller: widget.controller,
            decoration: widget.decoration.copyWith(
              hintText: widget.hintText,
              suffixIcon: FutureBuilder<bool>(
                future: _credentialManager.hasAnyCredentials(),
                builder: (context, snapshot) {
                  final hasCredentials = snapshot.data ?? false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasCredentials)
                        Tooltip(
                          message: 'Use saved credentials',
                          child: InkWell(
                            onTap: _showCredentialPicker,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C88FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF9C88FF).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF9C88FF),
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Saved',
                                    style: TextStyle(
                                      color: Color(0xFF9C88FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            validator: widget.validator,
            onChanged: (value) {
              _loadSuggestions(value);
            },
            onTap: () {
              // Only show suggestions if user is typing and there are matches
              // Don't auto-trigger credential picker on tap - let user click the button instead
              if (_suggestions.isNotEmpty && widget.controller.text.isNotEmpty) {
                setState(() => _showSuggestions = true);
              }
            },
          ),
          if (_showSuggestions && _suggestions.isNotEmpty)
            _buildSuggestionsList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return GestureDetector(
      onTap: () {
        // Prevent tap from propagating to parent GestureDetector
        // This allows tapping on suggestions without dismissing keyboard
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: Column(
          children: _suggestions.map((credential) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectCredential(credential),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              credential.displayName
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Credential info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                credential.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                credential.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.textDisabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
