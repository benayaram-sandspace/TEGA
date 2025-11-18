import 'package:flutter/material.dart';

/// A widget that dismisses the keyboard when tapping outside of text fields
class KeyboardDismisser extends StatelessWidget {
  final Widget child;

  const KeyboardDismisser({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus any currently focused widget (closes keyboard)
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

/// Extension to make it easier to wrap widgets with KeyboardDismisser
extension KeyboardDismisserExtension on Widget {
  Widget dismissKeyboardOnTap() {
    return KeyboardDismisser(child: this);
  }
}
