import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize session from empty state', () async {
      await authService.initializeSession();
      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('should handle logout when not logged in', () async {
      await authService.logout();
      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('should maintain session state consistency', () {
      // Test that session state is consistent
      expect(authService.isLoggedIn, equals(authService.currentUser != null));
    });

    test('should handle token expiration check', () {
      // When not logged in, token expiry time is null, so isTokenExpired returns false
      // (null check returns false, not true)
      expect(authService.isTokenExpired, isFalse);
    });

    test('should handle token expiring soon check', () {
      // When not logged in, token should not be expiring soon
      expect(authService.isTokenExpiringSoon, isFalse);
    });

    test('should return null session duration when not logged in', () {
      expect(authService.getSessionDuration(), isNull);
    });

    test('should return correct formatted session duration when not logged in', () {
      expect(authService.getFormattedSessionDuration(), equals('Not logged in'));
    });

    test('should handle role checks when not logged in', () {
      expect(authService.isAdmin, isFalse);
      expect(authService.isPrincipal, isFalse);
      expect(authService.isStudent, isFalse);
      expect(authService.isPrincipalOrAbove, isFalse);
    });
  });
}

