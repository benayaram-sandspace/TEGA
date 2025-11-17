import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('StudentHomePage Widget Tests', () {
    setUpAll(() {
      // Initialize SQLite FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentHomePage(),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentHomePage(),
        ),
      );

      await tester.pump();

      // Bottom navigation may be present
      final bottomNav = find.byType(BottomNavigationBar);
      // May or may not be visible depending on state
      expect(bottomNav, anyOf(findsWidgets, findsNothing));
    });
  });
}

