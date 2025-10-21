import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/credential_manager.dart';

/// Simple test email input to debug the issue
class TestEmailInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final InputDecoration decoration;
  final Function(String email, String password)? onAccountSelected;
  final bool isMobile;

  const TestEmailInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    required this.decoration,
    this.onAccountSelected,
    this.isMobile = true,
  });

  @override
  State<TestEmailInput> createState() => _TestEmailInputState();
}

class _TestEmailInputState extends State<TestEmailInput> {
  final CredentialManager _credentialManager = CredentialManager();

  @override
  void initState() {
    super.initState();
    _testCredentialManager();
  }

  Future<void> _testCredentialManager() async {
    await _credentialManager.initialize();
    final accounts = _credentialManager.savedAccounts;
    debugPrint('🔍 TEST: Found ${accounts.length} saved accounts');
    for (var account in accounts) {
      debugPrint('🔍 TEST: Account - ${account.email} (${account.displayName})');
    }
  }

  void _showTestBottomSheet() {
    debugPrint('🔍 TEST: Showing bottom sheet');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  const Icon(Icons.account_circle, color: Color(0xFF9C88FF)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('🔍 TEST: Close button pressed');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Test content
              Expanded(
                child: FutureBuilder<List<SavedAccount>>(
                  future: _getSavedAccounts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final accounts = snapshot.data ?? [];
                    debugPrint('🔍 TEST: Building list with ${accounts.length} accounts');
                    
                    if (accounts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_circle_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No saved accounts'),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return ListTile(
                          leading: const Icon(Icons.person, color: Color(0xFF9C88FF)),
                          title: Text(account.displayName),
                          subtitle: Text(account.email),
                          onTap: () {
                            debugPrint('🔍 TEST: Account tapped: ${account.email}');
                            widget.controller.text = account.email;
                            widget.onAccountSelected?.call(account.email, account.password);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('🔍 TEST: Cancel button pressed');
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<SavedAccount>> _getSavedAccounts() async {
    await _credentialManager.initialize();
    return _credentialManager.savedAccounts;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2), // Debug border
      ),
      child: GestureDetector(
        onTap: () {
          debugPrint('🔍 TEST: Email field tapped!');
          _showTestBottomSheet();
        },
        child: TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontSize: widget.isMobile ? 14 : 15,
            color: const Color(0xFF2C3E50),
          ),
          decoration: widget.decoration.copyWith(
            hintText: 'Tap here to select account (TEST)',
            suffixIcon: IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF9C88FF)),
              onPressed: () {
                debugPrint('🔍 TEST: Account icon tapped!');
                _showTestBottomSheet();
              },
            ),
          ),
          validator: widget.validator,
          readOnly: true, // Make read-only to force popup
        ),
      ),
    );
  }
}
