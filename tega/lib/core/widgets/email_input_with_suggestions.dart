import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/credential_manager.dart';

/// Custom email input field with account suggestions dropdown
class EmailInputWithSuggestions extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final InputDecoration decoration;
  final VoidCallback? onAccountSelected;
  final bool isMobile;

  const EmailInputWithSuggestions({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    required this.decoration,
    this.onAccountSelected,
    this.isMobile = true,
  });

  @override
  State<EmailInputWithSuggestions> createState() => _EmailInputWithSuggestionsState();
}

class _EmailInputWithSuggestionsState extends State<EmailInputWithSuggestions> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<SavedAccount> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
    } else {
      // Delay hiding suggestions to allow for tap selection
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _hideSuggestions();
        }
      });
    }
  }

  void _updateSuggestions() {
    final text = widget.controller.text;
    final credentialManager = CredentialManager();
    
    setState(() {
      _suggestions = credentialManager.getAccountsForEmail(text);
      _showSuggestions = text.isNotEmpty && _suggestions.isNotEmpty;
    });

    if (_showSuggestions) {
      _showOverlay();
    } else {
      _hideSuggestions();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.isMobile ? 50 : 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildSuggestionItems(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _showSuggestions = false;
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  List<Widget> _buildSuggestionItems() {
    return _suggestions.map((account) => _buildSuggestionItem(account)).toList();
  }

  Widget _buildSuggestionItem(SavedAccount account) {
    return InkWell(
      onTap: () => _selectAccount(account),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Account avatar/icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF9C88FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: const Color(0xFF9C88FF),
              ),
            ),
            const SizedBox(width: 12),
            // Account details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Last used indicator
            if (account.lastUsed.difference(DateTime.now()).inDays.abs() < 7)
              Container(
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
              ),
          ],
        ),
      ),
    );
  }

  void _selectAccount(SavedAccount account) {
    widget.controller.text = account.email;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: account.email.length),
    );
    
    // Update last used timestamp
    CredentialManager().updateLastUsed(account.email);
    
    _hideSuggestions();
    _focusNode.unfocus();
    
    // Notify parent about account selection
    widget.onAccountSelected?.call();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          fontSize: widget.isMobile ? 14 : 15,
          color: const Color(0xFF2C3E50),
        ),
        decoration: widget.decoration,
        validator: widget.validator,
        onTap: () {
          if (widget.controller.text.isNotEmpty) {
            _updateSuggestions();
          }
        },
      ),
    );
  }
}
