// Basic app smoke test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/main.dart';
import 'package:tega/core/config/env_config.dart';

void main() {
  setUpAll(() async {
    // Initialize environment config for tests
    try {
      await EnvConfig.initialize();
    } catch (e) {
      // Handle initialization errors gracefully
    }
  });

  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
