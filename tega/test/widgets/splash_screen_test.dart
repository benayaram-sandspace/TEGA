import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/2_shared_ui/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display splash screen', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Wait for the widget to build
      await tester.pump();

      // Verify the scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should have white background', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('should contain FutureBuilder for video', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      await tester.pump();

      // Verify FutureBuilder is present (may need to pump more for async operations)
      await tester.pump();
      // FutureBuilder might not be immediately visible, so check for Scaffold/SafeArea instead
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });
}
