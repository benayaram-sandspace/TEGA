import 'package:flutter_test/flutter_test.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/config/env_config.dart';

void main() {
  group('ApiEndpoints', () {
    setUp(() async {
      // Initialize EnvConfig for tests
      await EnvConfig.initialize();
    });

    group('Authentication endpoints', () {
      test('register endpoint should be valid', () {
        final endpoint = ApiEndpoints.register;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/auth/register'));
      });

      test('login endpoint should be valid', () {
        final endpoint = ApiEndpoints.login;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/auth/login'));
      });

      test('logout endpoint should be valid', () {
        final endpoint = ApiEndpoints.logout;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/auth/logout'));
      });

      test('forgotPassword endpoint should be valid', () {
        final endpoint = ApiEndpoints.forgotPassword;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/auth/forgot-password'));
      });
    });

    group('Student endpoints', () {
      test('studentDashboard endpoint should be valid', () {
        final endpoint = ApiEndpoints.studentDashboard;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/student/dashboard'));
      });

      test('studentProfile endpoint should be valid', () {
        final endpoint = ApiEndpoints.studentProfile;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/student/profile'));
      });
    });

    group('Principal endpoints', () {
      test('principalLogin endpoint should be valid', () {
        final endpoint = ApiEndpoints.principalLogin;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/principal/login'));
      });

      test('principalDashboard endpoint should be valid', () {
        final endpoint = ApiEndpoints.principalDashboard;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/principal/dashboard'));
      });
    });

    group('Course endpoints', () {
      test('realTimeCourses endpoint should be valid', () {
        final endpoint = ApiEndpoints.realTimeCourses;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/real-time-courses'));
      });

      test('realTimeCourseById should include course ID', () {
        const courseId = 'test-course-123';
        final endpoint = ApiEndpoints.realTimeCourseById(courseId);
        expect(endpoint, contains(courseId));
        expect(endpoint, contains('/api/real-time-courses'));
      });
    });

    group('Payment endpoints', () {
      test('paymentCreateOrder endpoint should be valid', () {
        final endpoint = ApiEndpoints.paymentCreateOrder;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/payments/create-order'));
      });

      test('paymentHistory endpoint should be valid', () {
        final endpoint = ApiEndpoints.paymentHistory;
        expect(endpoint, isNotEmpty);
        expect(endpoint, contains('/api/payments/history'));
      });
    });

    group('Utility methods', () {
      test('buildUrlWithParams should add query parameters', () {
        const baseUrl = 'https://example.com/api/test';
        final params = {'page': '1', 'limit': '10'};
        final url = ApiEndpoints.buildUrlWithParams(baseUrl, params);
        expect(url, contains('page=1'));
        expect(url, contains('limit=10'));
        expect(url, contains('?'));
      });

      test('buildUrlWithParams should return baseUrl when params empty', () {
        const baseUrl = 'https://example.com/api/test';
        final url = ApiEndpoints.buildUrlWithParams(baseUrl, {});
        expect(url, equals(baseUrl));
      });

      test('buildPaginatedUrl should include page and limit', () {
        const baseUrl = 'https://example.com/api/test';
        final url = ApiEndpoints.buildPaginatedUrl(baseUrl, page: 2, limit: 20);
        expect(url, contains('page=2'));
        expect(url, contains('limit=20'));
      });

      test('buildSearchUrl should include search query', () {
        const baseUrl = 'https://example.com/api/test';
        final url = ApiEndpoints.buildSearchUrl(baseUrl, 'flutter');
        expect(url, contains('search=flutter'));
      });
    });
  });
}

