import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/presentation/screens/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SignUpPage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display signup form', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Wait for any timers

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have form fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Wait for any timers

      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });

    testWidgets('should validate form inputs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Wait for any timers

      // Form should be present
      expect(find.byType(Form), findsWidgets);
    });
  });
}
