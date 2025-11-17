import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LoginPage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pump();

      // Verify the scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pump();

      // Look for text fields (email and password)
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });

    testWidgets('should display login button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pump();

      // Look for any button type (ElevatedButton, TextButton, etc.)
      final elevatedButtons = find.byType(ElevatedButton);
      final textButtons = find.byType(TextButton);
      final iconButtons = find.byType(IconButton);
      
      // At least one type of button should be present
      final hasElevatedButton = elevatedButtons.evaluate().isNotEmpty;
      final hasTextButton = textButtons.evaluate().isNotEmpty;
      final hasIconButton = iconButtons.evaluate().isNotEmpty;
      
      expect(hasElevatedButton || hasTextButton || hasIconButton, isTrue);
    });
  });
}

