import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for test utilities
class TestHelpers {
  /// Create a mock user for testing
  static User createMockUser({
    String id = 'test-id',
    String firstName = 'Test',
    String lastName = 'User',
    String email = 'test@example.com',
    UserRole role = UserRole.student,
  }) {
    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
  }

  /// Create a mock admin user
  static User createMockAdmin() {
    return createMockUser(email: 'admin@example.com', role: UserRole.admin);
  }

  /// Create a mock principal user
  static User createMockPrincipal() {
    return createMockUser(
      email: 'principal@example.com',
      role: UserRole.principal,
    );
  }

  /// Clear all SharedPreferences
  static Future<void> clearPreferences() async {
    SharedPreferences.setMockInitialValues({});
  }

  /// Wait for async operations
  static Future<void> waitForAsync() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for valid email format
  static Matcher isValidEmail = predicate<String>((email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }, 'is a valid email');

  /// Matcher for valid password (at least 6 characters)
  static Matcher isValidPassword = predicate<String>((password) {
    return password.length >= 6;
  }, 'is a valid password');
}
