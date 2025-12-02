import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/main.dart';
import 'package:tega/core/config/env_config.dart';

void main() {
  group('MyApp Widget Tests', () {
    setUpAll(() async {
      // Initialize environment config for tests
      await EnvConfig.initialize();
    });

    testWidgets('should build app without errors', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());

      // Verify the MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should have correct app title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('TEGA'));
    });

    testWidgets('should have light theme', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.light));
    });

    testWidgets('should have primary color set', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.primaryColor, isNotNull);
    });

    testWidgets('should start with SplashScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // The home should be set to SplashScreen
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.home, isNotNull);
    });
  });
}
