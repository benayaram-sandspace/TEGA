import 'package:flutter/material.dart';

/// Ultra simple test widget to debug tap detection
class UltraSimpleTest extends StatelessWidget {
  const UltraSimpleTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.yellow, // Bright yellow background
        border: Border.all(color: Colors.red, width: 3),
      ),
      child: GestureDetector(
        onTap: () {
          debugPrint('🔍 ULTRA SIMPLE: TAP DETECTED!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('TAP DETECTED!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Center(
          child: Text(
            'TAP ME TO TEST',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
