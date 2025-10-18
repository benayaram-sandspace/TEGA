import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/credential_manager.dart';

/// Email input field with saved account selection popup
class EmailInputWithAccountSelection extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final InputDecoration decoration;
  final Function(String email, String password)? onAccountSelected;
  final bool isMobile;

  const EmailInputWithAccountSelection({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    required this.decoration,
    this.onAccountSelected,
    this.isMobile = true,
  });

  @override
  State<EmailInputWithAccountSelection> createState() => _EmailInputWithAccountSelectionState();
}

class _EmailInputWithAccountSelectionState extends State<EmailInputWithAccountSelection> {
  final CredentialManager _credentialManager = CredentialManager();
  List<SavedAccount> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      await _credentialManager.initialize();
      setState(() {
        _savedAccounts = _credentialManager.savedAccounts;
      });
      debugPrint('✅ Loaded ${_savedAccounts.length} saved accounts');
    } catch (e) {
      debugPrint('⚠️ Error loading accounts: $e');
    }
  }

  void _showAccountBottomSheet() {
    
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C88FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_circle_rounded,
                      color: Color(0xFF9C88FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Account list
              Expanded(
                child: _savedAccounts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No saved accounts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Save accounts to use this feature',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _savedAccounts.length,
                        itemBuilder: (context, index) {
                          final account = _savedAccounts[index];
                          return _buildAccountItem(account);
                        },
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildAccountItem(SavedAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF9C88FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.person,
            color: const Color(0xFF9C88FF),
            size: 18,
          ),
        ),
        title: Text(
          account.displayName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Text(
          account.email,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: account.lastUsed.difference(DateTime.now()).inDays.abs() < 7
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        onTap: () {
          debugPrint('✅ Account selected: ${account.email}');
          // Update last used timestamp
          _credentialManager.updateLastUsed(account.email);
          
          // Fill the fields
          widget.controller.text = account.email;
          widget.onAccountSelected?.call(account.email, account.password);
          
          // Close bottom sheet
          Navigator.of(context).pop();
          
          // Haptic feedback
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            hintText: widget.hintText,
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF9C88FF),
                size: 20,
              ),
              onPressed: _showAccountBottomSheet,
              tooltip: 'Select saved account',
            ),
          ),
        validator: widget.validator,
        onTap: () {
          // Only show popup if field is empty
          if (widget.controller.text.isEmpty) {
            _showAccountBottomSheet();
          }
        },
      ),
    );
  }
}
