import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/credential_manager.dart';

/// Popup dialog for selecting saved accounts
class AccountSelectionPopup extends StatefulWidget {
  final String Function(String) translate;
  final bool isMobile;
  final Function(String email, String password)? onAccountSelected;

  const AccountSelectionPopup({
    super.key,
    required this.translate,
    this.isMobile = true,
    this.onAccountSelected,
  });

  @override
  State<AccountSelectionPopup> createState() => _AccountSelectionPopupState();
}

class _AccountSelectionPopupState extends State<AccountSelectionPopup> {
  final CredentialManager _credentialManager = CredentialManager();
  List<SavedAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    
    await _credentialManager.initialize();
    setState(() {
      _accounts = _credentialManager.savedAccounts;
      _isLoading = false;
    });
  }

  void _selectAccount(SavedAccount account) {
    debugPrint('🔍 Account selected: ${account.email}');
    // Update last used timestamp
    _credentialManager.updateLastUsed(account.email);
    
    // Notify parent about account selection
    widget.onAccountSelected?.call(account.email, account.password);
    
    // Close dialog
    Navigator.of(context).pop();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF9C88FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.person,
            color: const Color(0xFF9C88FF),
            size: 20,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.email,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Last used: ${_formatLastUsed(account.lastUsed)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
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
        onTap: () => _selectAccount(account),
      ),
    );
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        width: widget.isMobile ? double.infinity : 400,
        height: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C88FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFF9C88FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a saved account to login',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C88FF)),
                      ),
                    )
                  : _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_circle_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No saved accounts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Save accounts to use this feature',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) {
                            return _buildAccountItem(_accounts[index]);
                          },
                        ),
            ),

            // Footer
            if (_accounts.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.cancel,
                    size: 18,
                    color: Color(0xFF5D6D7E),
                  ),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF5D6D7E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
