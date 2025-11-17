import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/presentation/screens/forgot_password_page.dart';

void main() {
  group('ForgetPasswordPage Widget Tests', () {
    testWidgets('should display forgot password form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgetPasswordPage(),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have email input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgetPasswordPage(),
        ),
      );

      await tester.pump();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });
  });
}

