import 'package:flutter/material.dart';
import 'account_selection_popup.dart';

/// Simple email input field that shows account selection popup on tap
class EmailInputWithPopup extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final InputDecoration decoration;
  final Function(String email, String password)? onAccountSelected;
  final bool isMobile;

  const EmailInputWithPopup({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    required this.decoration,
    this.onAccountSelected,
    this.isMobile = true,
  });

  @override
  State<EmailInputWithPopup> createState() => _EmailInputWithPopupState();
}

class _EmailInputWithPopupState extends State<EmailInputWithPopup> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.controller.text.isEmpty) {
      // Show popup when field gains focus and is empty
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _showAccountSelectionPopup(context);
        }
      });
    }
  }

  void _showAccountSelectionPopup(BuildContext context) {
    debugPrint('🔍 Showing account selection popup');
    showDialog(
      context: context,
      builder: (context) => AccountSelectionPopup(
        translate: (key) => key, // Simple translation function
        isMobile: widget.isMobile,
        onAccountSelected: (email, password) {
          debugPrint('🔍 Account selected from popup: $email');
          widget.controller.text = email;
          widget.onAccountSelected?.call(email, password);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show popup when field is tapped and it's empty
        if (widget.controller.text.isEmpty) {
          debugPrint('🔍 Email field tapped - showing account popup');
          _showAccountSelectionPopup(context);
        } else {
          // Focus the field if it has text
          _focusNode.requestFocus();
        }
      },
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
        decoration: widget.decoration.copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: const Color(0xFF9C88FF),
              size: 20,
            ),
            onPressed: () {
              debugPrint('🔍 Account icon tapped - showing account popup');
              _showAccountSelectionPopup(context);
            },
            tooltip: 'Select saved account',
          ),
        ),
        validator: widget.validator,
        onTap: () {
          debugPrint('🔍 TextFormField onTap - text: "${widget.controller.text}"');
          // Show popup when field is tapped and it's empty
          if (widget.controller.text.isEmpty) {
            _showAccountSelectionPopup(context);
          }
        },
        readOnly: widget.controller.text.isEmpty, // Make read-only when empty to force popup
      ),
    );
  }
}
