import 'package:flutter/material.dart';
import '../services/simple_google_credential_manager.dart';

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
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modern handle bar
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Modern header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Credentials',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${credentials.length} account${credentials.length == 1 ? '' : 's'} saved',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Modern credentials list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: credentials.length,
                itemBuilder: (context, index) {
                  final credential = credentials[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _selectCredential(credential),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Top row with avatar and info
                              Row(
                                children: [
                                  // Larger avatar
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue[400]!,
                                          Colors.blue[600]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        credential.displayName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Credential info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          credential.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          credential.email,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Security badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.green[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified,
                                                size: 14,
                                                color: Colors.green[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Secured with Biometrics',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Action buttons row
                              Row(
                                children: [
                                  // Select button
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green[500]!,
                                            Colors.green[600]!,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              _selectCredential(credential),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Select Account',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Delete button
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () =>
                                            _deleteCredential(credential),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Center(
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[600],
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
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
                      if (widget.controller.text.isNotEmpty && hasCredentials)
                        IconButton(
                          onPressed: () =>
                              _loadSuggestions(widget.controller.text),
                          icon: const Icon(Icons.search),
                          tooltip: 'Search saved credentials',
                        ),
                      if (hasCredentials)
                        IconButton(
                          onPressed: _showCredentialPicker,
                          icon: const Icon(Icons.account_circle),
                          tooltip: 'Show saved credentials',
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
            onTap: () async {
              // If field is empty, check if there are saved credentials first
              if (widget.controller.text.isEmpty) {
                final hasCredentials = await _credentialManager
                    .hasAnyCredentials();
                if (hasCredentials) {
                  _showCredentialPicker();
                }
                // If no credentials, allow normal typing (don't show picker)
              } else if (_suggestions.isNotEmpty) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: _suggestions.map((credential) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectCredential(credential),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Modern avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              credential.displayName
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
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
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                credential.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Selection indicator
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.blue[600],
                          ),
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
