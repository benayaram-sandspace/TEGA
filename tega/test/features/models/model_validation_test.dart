import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

void main() {
  group('Model Validation Tests', () {
    group('User Model', () {
      test('should create user with all required fields', () {
        final user = User(
          id: '123',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        expect(user.id, equals('123'));
        expect(user.firstName, equals('John'));
        expect(user.lastName, equals('Doe'));
        expect(user.email, equals('john@example.com'));
        expect(user.role, equals(UserRole.student));
      });

      test('should generate full name correctly', () {
        final user = User(
          id: '123',
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane@example.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        expect(user.name, equals('Jane Smith'));
      });

      test('should parse user from JSON with all fields', () {
        final json = {
          'id': '123',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com',
          'role': 'student',
          'createdAt': '2024-01-01T00:00:00Z',
          'studentId': 'STU001',
          'course': 'Computer Science',
          'year': '3',
          'college': 'Test College',
        };

        final user = User.fromJson(json);
        expect(user.id, equals('123'));
        expect(user.studentId, equals('STU001'));
        expect(user.course, equals('Computer Science'));
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': '123',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com',
          'role': 'student',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final user = User.fromJson(json);
        expect(user.studentId, isNull);
        expect(user.course, isNull);
      });

      test('should serialize user to JSON', () {
        final user = User(
          id: '123',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          role: UserRole.student,
          createdAt: DateTime(2024, 1, 1),
        );

        final json = user.toJson();
        expect(json['id'], equals('123'));
        expect(json['firstName'], equals('John'));
        expect(json['email'], equals('john@example.com'));
        expect(json['role'], equals('student'));
      });
    });

    group('ApiResponse Model', () {
      test('should create successful response', () {
        final response = ApiResponse(
          success: true,
          message: 'Success',
          data: {'key': 'value'},
        );

        expect(response.success, isTrue);
        expect(response.message, equals('Success'));
        expect(response.data, isNotNull);
      });

      test('should create error response', () {
        final response = ApiResponse(
          success: false,
          message: 'Error occurred',
          statusCode: 400,
        );

        expect(response.success, isFalse);
        expect(response.statusCode, equals(400));
      });

      test('should parse from JSON', () {
        final json = {
          'success': true,
          'message': 'Operation successful',
          'data': {'result': 'ok'},
        };

        final response = ApiResponse.fromJson(json, json['data']);
        expect(response.success, isTrue);
        expect(response.message, equals('Operation successful'));
      });
    });

    group('AuthException Model', () {
      test('should create exception with message', () {
        final exception = AuthException('Test error');
        expect(exception.message, equals('Test error'));
      });

      test('should include status code', () {
        final exception = AuthException('Error', statusCode: 404);
        expect(exception.statusCode, equals(404));
      });

      test('should include error code', () {
        final exception = AuthException(
          'Error',
          statusCode: 401,
          errorCode: 'UNAUTHORIZED',
        );
        expect(exception.errorCode, equals('UNAUTHORIZED'));
      });
    });
  });
}

