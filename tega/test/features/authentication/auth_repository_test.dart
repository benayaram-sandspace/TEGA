import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('User Model', () {
      test('User.fromJson should parse user data correctly', () {
        final json = {
          'id': '123',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com',
          'role': 'student',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final user = User.fromJson(json);
        expect(user.id, equals('123'));
        expect(user.firstName, equals('John'));
        expect(user.lastName, equals('Doe'));
        expect(user.email, equals('john@example.com'));
        expect(user.role, equals(UserRole.student));
      });

      test('User.fromJson should handle name field', () {
        final json = {
          'id': '123',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'role': 'student',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final user = User.fromJson(json);
        expect(user.firstName, equals('Jane'));
        expect(user.lastName, equals('Smith'));
      });

      test('User.fromJson should parse admin role', () {
        final json = {
          'id': '123',
          'username': 'admin',
          'email': 'admin@example.com',
          'role': 'admin',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final user = User.fromJson(json);
        expect(user.role, equals(UserRole.admin));
        expect(user.firstName, equals('admin'));
      });

      test('User.toJson should serialize correctly', () {
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

      test('User.name getter should return full name', () {
        final user = User(
          id: '123',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        expect(user.name, equals('John Doe'));
      });
    });

    group('AuthService State', () {
      test('should start with no logged in user', () {
        expect(authService.isLoggedIn, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.authToken, isNull);
      });

      test('hasRole should return false when not logged in', () {
        expect(authService.hasRole(UserRole.student), isFalse);
        expect(authService.hasRole(UserRole.admin), isFalse);
        expect(authService.hasRole(UserRole.principal), isFalse);
      });

      test('isSessionValid should return false when not logged in', () {
        expect(authService.isSessionValid(), isFalse);
      });
    });

    group('AuthService Role Checks', () {
      test('getRoleDisplayName should return correct names', () {
        expect(authService.getRoleDisplayName(UserRole.admin), equals('Admin'));
        expect(
          authService.getRoleDisplayName(UserRole.principal),
          equals('Principal'),
        );
        expect(
          authService.getRoleDisplayName(UserRole.student),
          equals('Student'),
        );
      });

      test('getRoleColor should return colors for each role', () {
        final adminColor = authService.getRoleColor(UserRole.admin);
        final principalColor = authService.getRoleColor(UserRole.principal);
        final studentColor = authService.getRoleColor(UserRole.student);

        expect(adminColor, isNotNull);
        expect(principalColor, isNotNull);
        expect(studentColor, isNotNull);
      });
    });

    group('AuthService Permissions', () {
      test('hasPermission should return false when no permissions', () {
        expect(authService.hasPermission('test.permission'), isFalse);
      });

      test('hasAnyPermission should return false when no permissions', () {
        expect(authService.hasAnyPermission(['perm1', 'perm2']), isFalse);
      });

      test('hasAllPermissions should return false when no permissions', () {
        expect(authService.hasAllPermissions(['perm1', 'perm2']), isFalse);
      });
    });

    group('AuthService Headers', () {
      test('getAuthHeaders should include Content-Type', () {
        final headers = authService.getAuthHeaders();
        expect(headers['Content-Type'], equals('application/json'));
      });

      test('getAuthHeaders should not include Authorization when no token', () {
        final headers = authService.getAuthHeaders();
        expect(headers.containsKey('Authorization'), isFalse);
      });
    });

    group('AuthException', () {
      test('should create exception with message', () {
        final exception = AuthException('Test error');
        expect(exception.message, equals('Test error'));
        expect(exception.toString(), equals('Test error'));
      });

      test('should create exception with status code', () {
        final exception = AuthException('Error', statusCode: 404);
        expect(exception.statusCode, equals(404));
      });

      test('should create exception with error code', () {
        final exception = AuthException(
          'Error',
          statusCode: 401,
          errorCode: 'UNAUTHORIZED',
        );
        expect(exception.errorCode, equals('UNAUTHORIZED'));
      });
    });

    group('ApiResponse', () {
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

      test('should create failed response', () {
        final response = ApiResponse(
          success: false,
          message: 'Error',
          statusCode: 400,
        );

        expect(response.success, isFalse);
        expect(response.statusCode, equals(400));
      });

      test('fromJson should parse response correctly', () {
        final json = {
          'success': true,
          'message': 'Success',
          'data': {'test': 'value'},
        };

        final response = ApiResponse.fromJson(json, json['data']);
        expect(response.success, isTrue);
        expect(response.message, equals('Success'));
      });
    });
  });
}
