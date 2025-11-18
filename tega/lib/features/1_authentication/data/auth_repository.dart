import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:tega/core/constants/api_constants.dart';

enum UserRole { admin, principal, student }

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  AuthException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: data,
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<String>? permissions;
  final String? status;

  // Student-specific fields
  final String? studentId;
  final String? course;
  final String? year;
  final String? college;
  final String? phone;

  // Principal-specific fields
  final String? university;
  final String? gender;

  String get name => '$firstName $lastName';

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
    this.permissions,
    this.status,
    this.studentId,
    this.course,
    this.year,
    this.college,
    this.phone,
    this.university,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String fName = json['firstName'] ?? '';
    String lName = json['lastName'] ?? '';

    // Handle different name formats from backend
    if (fName.isEmpty && lName.isEmpty && json['name'] != null) {
      final nameValue = json['name'];
      if (nameValue is String) {
        final parts = nameValue.split(' ');
        fName = parts.first;
        lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    // Handle username field for admin (backend uses username instead of firstName)
    if (fName.isEmpty && json['username'] != null) {
      final usernameValue = json['username'];
      if (usernameValue is String) {
        fName = usernameValue;
      }
    }

    // Handle profilePicture - can be a string or an object with 'url' property
    String? profileImage;
    if (json['profileImage'] != null) {
      if (json['profileImage'] is String) {
        profileImage = json['profileImage'] as String;
      } else if (json['profileImage'] is Map) {
        profileImage = json['profileImage']?['url'] as String?;
      }
    } else if (json['profilePicture'] != null) {
      if (json['profilePicture'] is String) {
        profileImage = json['profilePicture'] as String;
      } else if (json['profilePicture'] is Map) {
        profileImage = json['profilePicture']?['url'] as String?;
      }
    }

    // Handle course - can be a string or an object
    String? course;
    if (json['course'] != null) {
      if (json['course'] is String) {
        course = json['course'] as String;
      } else if (json['course'] is Map) {
        course =
            json['course']?['name'] as String? ??
            json['course']?['courseName'] as String?;
      }
    }

    // Handle college/institute - can be a string or an object
    String? college;
    if (json['college'] != null) {
      if (json['college'] is String) {
        college = json['college'] as String;
      } else if (json['college'] is Map) {
        college =
            json['college']?['name'] as String? ??
            json['college']?['collegeName'] as String?;
      }
    } else if (json['institute'] != null) {
      if (json['institute'] is String) {
        college = json['institute'] as String;
      } else if (json['institute'] is Map) {
        college =
            json['institute']?['name'] as String? ??
            json['institute']?['instituteName'] as String?;
      }
    }

    // Handle year - convert number to string if needed
    String? year;
    if (json['year'] != null) {
      if (json['year'] is String) {
        year = json['year'] as String;
      } else if (json['year'] is num) {
        year = json['year'].toString();
      }
    } else if (json['yearOfStudy'] != null) {
      if (json['yearOfStudy'] is String) {
        year = json['yearOfStudy'] as String;
      } else if (json['yearOfStudy'] is num) {
        year = json['yearOfStudy'].toString();
      }
    }

    // Handle permissions - ensure it's a list of strings
    List<String>? permissions;
    if (json['permissions'] != null) {
      if (json['permissions'] is List) {
        permissions = (json['permissions'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: fName,
      lastName: lName,
      email: json['email']?.toString() ?? '',
      role: _parseRole(json['role']?.toString()),
      profileImage: profileImage,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'].toString())
          : null,
      permissions: permissions,
      status: json['status']?.toString(),
      studentId: json['studentId']?.toString(),
      course: course,
      year: year,
      college: college,
      phone: json['phone']?.toString(),
      university: json['university']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'principal':
        return UserRole.principal;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'permissions': permissions,
      'status': status,
      'studentId': studentId,
      'course': course,
      'year': year,
      'college': college,
      'phone': phone,
      'university': university,
      'gender': gender,
    };
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Configuration
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _tokenRefreshBuffer = Duration(minutes: 5);

  // State
  User? _currentUser;
  bool _isLoggedIn = false;
  DateTime? _loginTime;
  DateTime? _tokenExpiryTime;
  SharedPreferences? _prefs;
  String? _authToken;
  String? _refreshToken;
  List<String> _userPermissions = [];
  Timer? _tokenRefreshTimer;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  UserRole? get currentUserRole => _currentUser?.role;
  DateTime? get loginTime => _loginTime;
  String? get authToken => _authToken;
  String? get refreshToken => _refreshToken;
  List<String> get userPermissions => _userPermissions;
  bool get isTokenExpired =>
      _tokenExpiryTime?.isBefore(DateTime.now()) ?? false;
  bool get isTokenExpiringSoon {
    if (_tokenExpiryTime == null) return false;
    final timeUntilExpiry = _tokenExpiryTime!.difference(DateTime.now());
    return timeUntilExpiry < _tokenRefreshBuffer;
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Make HTTP POST request with retry logic and proper error handling
  Future<http.Response> _makePostRequest(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    int retryCount = 0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_requestTimeout);
      return response;
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makePostRequest(
          url,
          body,
          headers: headers,
          retryCount: retryCount + 1,
        );
      }
      throw AuthException(
        'Request timeout. Please check your internet connection.',
      );
    } on http.ClientException {
      throw AuthException(
        'Network error. Please check your internet connection.',
      );
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Make HTTP GET request with retry logic
  Future<http.Response> _makeGetRequest(
    String url, {
    Map<String, String>? headers,
    int retryCount = 0,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers ?? getAuthHeaders())
          .timeout(_requestTimeout);
      return response;
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeGetRequest(
          url,
          headers: headers,
          retryCount: retryCount + 1,
        );
      }
      throw AuthException(
        'Request timeout. Please check your internet connection.',
      );
    } on http.ClientException {
      throw AuthException(
        'Network error. Please check your internet connection.',
      );
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Handle API response errors
  void _handleResponseErrors(http.Response response, String operation) {
    String? serverMessage;
    try {
      final dynamic parsed = json.decode(response.body);
      if (parsed is Map<String, dynamic>) {
        serverMessage = parsed['message']?.toString();
      }
    } catch (_) {}

    String messageOr(String fallback) => serverMessage ?? fallback;

    if (response.statusCode == 401) {
      throw AuthException(
        messageOr('Unauthorized. Please login again.'),
        statusCode: 401,
      );
    } else if (response.statusCode == 403) {
      throw AuthException(messageOr('Access forbidden.'), statusCode: 403);
    } else if (response.statusCode == 404) {
      throw AuthException(messageOr('Resource not found.'), statusCode: 404);
    } else if (response.statusCode == 422) {
      throw AuthException(messageOr('Invalid data provided.'), statusCode: 422);
    } else if (response.statusCode == 429) {
      throw AuthException(
        messageOr('Too many requests. Please try again later.'),
        statusCode: 429,
      );
    } else if (response.statusCode >= 500) {
      throw AuthException(
        messageOr('Server error. Please try again later.'),
        statusCode: response.statusCode,
      );
    } else if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(
        messageOr('$operation failed (${response.statusCode}).'),
        statusCode: response.statusCode,
      );
    }
  }

  /// Start token refresh timer
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    if (_tokenExpiryTime != null) {
      final timeUntilRefresh =
          _tokenExpiryTime!.difference(DateTime.now()) - _tokenRefreshBuffer;
      if (timeUntilRefresh.isNegative) return;

      _tokenRefreshTimer = Timer(timeUntilRefresh, () {
        refreshAuthToken().catchError((error) {
          return false;
        });
      });
    }
  }

  /// Register a new user account
  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? course,
    String? year,
    String? college,
  }) async {
    try {
      final signupData = {
        'firstName': firstName,
        'lastName': lastName,
        'username': email, // Use email as username
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (course != null) 'course': course,
        if (year != null) 'year': year,
        if (college != null) 'college': college,
      };

      final response = await _makePostRequest(
        ApiEndpoints.register,
        signupData,
      );

      _handleResponseErrors(response, 'Signup');
      final responseData = json.decode(response.body);

      if (responseData['token'] != null && responseData['user'] != null) {
        _authToken = responseData['token'];
        _refreshToken = responseData['refreshToken'];

        _currentUser = User.fromJson(responseData['user']);

        _isLoggedIn = true;
        _loginTime = DateTime.now();
        _tokenExpiryTime = DateTime.now().add(
          const Duration(days: 7),
        ); // Adjust based on backend
        _userPermissions = _currentUser?.permissions ?? [];

        await _saveSession();
        _startTokenRefreshTimer();

        return {
          'success': true,
          'message': responseData['message'] ?? 'Account created successfully!',
          'user': _currentUser,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Signup failed',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Login user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final loginData = {'email': email, 'password': password};

      final response = await _makePostRequest(ApiEndpoints.login, loginData);

      // Try to parse response body first
      Map<String, dynamic>? responseData;
      try {
        if (response.body.isNotEmpty) {
          responseData = json.decode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // If we can't parse JSON, check if it's a server error
        if (response.statusCode >= 500) {
          return {
            'success': false,
            'message': 'Server error. Please try again later.',
          };
        }
        return {
          'success': false,
          'message': 'Invalid server response. Please try again.',
        };
      }

      // Handle specific error status codes for login (don't throw, return error message)
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404) {
        final errorMessage =
            responseData?['message'] ??
            (response.statusCode == 401
                ? 'Incorrect email or password. Please try again.'
                : response.statusCode == 404
                ? 'No account found with this email address.'
                : 'Invalid request. Please check your input.');
        return {'success': false, 'message': errorMessage};
      }

      // For other non-success status codes, use the standard error handler
      if (response.statusCode != 200 && response.statusCode != 201) {
        _handleResponseErrors(response, 'Login');
      }

      // If responseData is null, something went wrong
      if (responseData == null) {
        return {
          'success': false,
          'message': 'Invalid server response. Please try again.',
        };
      }

      // Check if login was successful - backend returns success: true and user object
      // In production, tokens may be in cookies only, not in response body
      final isSuccess =
          response.statusCode == 200 &&
          responseData['success'] == true &&
          responseData['user'] != null;

      if (isSuccess) {
        // Extract token from response body (available in development mode)
        String? token = responseData['token'];
        String? refreshToken = responseData['refreshToken'];

        // Parse user data
        if (responseData['user'] != null) {
          try {
            _currentUser = User.fromJson(responseData['user']);

            // Set tokens if available in response (development mode)
            // In production, tokens are in httpOnly cookies which can't be accessed
            // but subsequent requests will work if using a cookie-aware HTTP client
            if (token != null) {
              _authToken = token;
            }
            if (refreshToken != null) {
              _refreshToken = refreshToken;
            }

            _isLoggedIn = true;
            _loginTime = DateTime.now();
            _tokenExpiryTime = DateTime.now().add(const Duration(days: 7));
            _userPermissions = _currentUser?.permissions ?? [];

            await _saveSession();

            // Only start token refresh timer if we have a token
            if (_authToken != null) {
              _startTokenRefreshTimer();
            }

            return {
              'success': true,
              'message': responseData['message'] ?? 'Login successful',
              'user': _currentUser,
            };
          } catch (e) {
            return {
              'success': false,
              'message': 'Failed to parse user data. Please try again.',
            };
          }
        }
      }

      // If we reach here, login failed
      final errorMessage =
          responseData['message'] ??
          (responseData['success'] == false
              ? 'Login failed. Please check your credentials.'
              : 'Login failed. Please try again.');

      return {'success': false, 'message': errorMessage};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message':
            'Could not connect to server. Please check your internet connection and try again.',
      };
    }
  }

  /// Fetch and update user profile
  Future<void> fetchUserProfile() async {
    if (_authToken == null) {
      throw AuthException('Not authenticated');
    }

    try {
      final response = await _makeGetRequest(
        ApiEndpoints.studentProfile,
        headers: getAuthHeaders(),
      );

      _handleResponseErrors(response, 'Fetch profile');
      final profileData = json.decode(response.body);

      _currentUser = User.fromJson(profileData);

      await _saveSession();
    } catch (e) {
      throw AuthException('Failed to load profile: ${e.toString()}');
    }
  }

  /// Logout user and clear session
  Future<void> logout() async {
    _tokenRefreshTimer?.cancel();
    await _clearSession();

    // Clear login form fields
    try {
      // Import the LoginPage to access the static method
      // This will be handled by the navigation logic
    } catch (e) {
      // Ignore if login page is not available
    }
  }

  /// Check if email is available for registration
  Future<Map<String, dynamic>> checkEmailAvailability(String email) async {
    try {
      final response = await _makePostRequest(ApiEndpoints.checkEmail, {
        'email': email,
      });

      _handleResponseErrors(response, 'Email check');
      final responseData = json.decode(response.body);

      return {
        'success': true,
        'available': responseData['available'] ?? false,
        'message': responseData['message'] ?? '',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message, 'available': false};
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not verify email availability',
        'available': false,
      };
    }
  }

  /// Send OTP for registration
  Future<Map<String, dynamic>> sendRegistrationOTP(
    String email, {
    String? firstName,
    String? lastName,
    String? password,
    String? college,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'email': email,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        if (password != null && password.isNotEmpty) 'password': password,
        if (college != null && college.isNotEmpty) 'institute': college,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final response = await _makePostRequest(
        ApiEndpoints.sendRegistrationOTP,
        payload,
      );

      _handleResponseErrors(response, 'Send OTP');
      final responseData = json.decode(response.body);
      if (responseData is Map && responseData['success'] == false) {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Send OTP failed.',
        };
      }

      return {
        'success': true,
        'message': responseData['message'] ?? 'OTP sent successfully',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    }
  }

  /// Verify OTP for registration
  Future<Map<String, dynamic>> verifyRegistrationOTP(
    String email,
    String otp,
  ) async {
    try {
      final response = await _makePostRequest(
        ApiEndpoints.verifyRegistrationOTP,
        {'email': email, 'otp': otp},
      );

      _handleResponseErrors(response, 'Verify OTP');
      final responseData = json.decode(response.body);

      return {
        'success': true,
        'message': responseData['message'] ?? 'OTP verified successfully',
        'verified': responseData['verified'] ?? true,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message, 'verified': false};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP. Please try again.',
        'verified': false,
      };
    }
  }

  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _makePostRequest(ApiEndpoints.forgotPassword, {
        'email': email,
      });

      _handleResponseErrors(response, 'Forgot password');
      final responseData = json.decode(response.body);

      // Respect backend success flag when present (backend may return 200 with success:false)
      if (responseData is Map && responseData.containsKey('success')) {
        final bool ok = responseData['success'] == true;
        final result = {
          'success': ok,
          'message':
              responseData['message'] ??
              (ok
                  ? 'Password reset instructions sent to your email'
                  : 'Failed to send reset email.'),
        };
        if (!ok) {
          if (responseData.containsKey('emailError')) {
            result['emailError'] = responseData['emailError'];
          }
          if (responseData.containsKey('otp')) {
            result['otp'] = responseData['otp'];
          }
        }
        return result;
      }

      return {
        'success': true,
        'message':
            responseData['message'] ??
            'Password reset instructions sent to your email',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send reset email. Please try again.',
      };
    }
  }

  /// Verify OTP for password reset
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await _makePostRequest(ApiEndpoints.verifyOTP, {
        'email': email,
        'otp': otp,
      });

      _handleResponseErrors(response, 'Verify OTP');
      final responseData = json.decode(response.body);

      return {
        'success': true,
        'message': responseData['message'] ?? 'OTP verified successfully',
        'verified': responseData['verified'] ?? true,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message, 'verified': false};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP. Please try again.',
        'verified': false,
      };
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await _makePostRequest(ApiEndpoints.resetPassword, {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });

      _handleResponseErrors(response, 'Reset password');
      final responseData = json.decode(response.body);

      return {
        'success': true,
        'message': responseData['message'] ?? 'Password reset successful',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reset password. Please try again.',
      };
    }
  }

  /// Refresh authentication token
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      final response = await _makePostRequest(ApiEndpoints.refreshToken, {
        'refreshToken': _refreshToken,
      });

      _handleResponseErrors(response, 'Refresh token');
      final responseData = json.decode(response.body);

      if (responseData['token'] != null) {
        _authToken = responseData['token'];
        if (responseData['refreshToken'] != null) {
          _refreshToken = responseData['refreshToken'];
        }
        _tokenExpiryTime = DateTime.now().add(const Duration(days: 7));

        await _saveSession();
        _startTokenRefreshTimer();

        return true;
      }

      return false;
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        // Refresh token expired, logout user
        await logout();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool hasRole(UserRole role) => _currentUser?.role == role;
  bool get isAdmin => hasRole(UserRole.admin);
  bool get isPrincipal => hasRole(UserRole.principal);
  bool get isStudent => hasRole(UserRole.student);
  bool get isPrincipalOrAbove =>
      hasRole(UserRole.principal) || hasRole(UserRole.admin);
  bool isSessionValid() =>
      _isLoggedIn && _currentUser != null && _authToken != null;

  bool hasPermission(String permission) {
    return _userPermissions.contains(permission);
  }

  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((p) => hasPermission(p));
  }

  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((p) => hasPermission(p));
  }

  String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.principal:
        return 'Principal';
      case UserRole.student:
        return 'Student';
    }
  }

  Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.principal:
        return Colors.orange;
      case UserRole.student:
        return Colors.blue;
    }
  }

  Duration? getSessionDuration() {
    if (_loginTime == null) return null;
    return DateTime.now().difference(_loginTime!);
  }

  String getFormattedSessionDuration() {
    final duration = getSessionDuration();
    if (duration == null) return 'Not logged in';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// Initialize session from stored preferences
  Future<void> initializeSession() async {
    await _ensurePrefs();
    try {
      final isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
      final token = _prefs?.getString('authToken');
      final refreshToken = _prefs?.getString('refreshToken');
      final userJson = _prefs?.getString('user');
      final loginTimeString = _prefs?.getString('loginTime');
      final tokenExpiryString = _prefs?.getString('tokenExpiry');

      if (isLoggedIn && token != null && userJson != null) {
        _isLoggedIn = true;
        _authToken = token;
        _refreshToken = refreshToken;
        _currentUser = User.fromJson(json.decode(userJson));
        _userPermissions = _currentUser?.permissions ?? [];

        if (loginTimeString != null) {
          _loginTime = DateTime.tryParse(loginTimeString);
        }

        if (tokenExpiryString != null) {
          _tokenExpiryTime = DateTime.tryParse(tokenExpiryString);
        }

        // Check if token is expired
        if (isTokenExpired) {
          final refreshed = await refreshAuthToken();
          if (!refreshed) {
            await _clearSession();
            return;
          }
        } else if (isTokenExpiringSoon) {
          refreshAuthToken().catchError((error) {
            return false;
          });
        }

        _startTokenRefreshTimer();
      }
    } catch (e) {
      await _clearSession();
    }
  }

  /// Save session to preferences
  Future<void> _saveSession() async {
    await _ensurePrefs();
    try {
      await _prefs!.setBool('isLoggedIn', _isLoggedIn);

      if (_currentUser != null) {
        final userJson = json.encode(_currentUser!.toJson());
        await _prefs!.setString('user', userJson);
      }

      if (_authToken != null) {
        await _prefs!.setString('authToken', _authToken!);
      }

      if (_refreshToken != null) {
        await _prefs!.setString('refreshToken', _refreshToken!);
      }

      if (_loginTime != null) {
        await _prefs!.setString('loginTime', _loginTime!.toIso8601String());
      }

      if (_tokenExpiryTime != null) {
        await _prefs!.setString(
          'tokenExpiry',
          _tokenExpiryTime!.toIso8601String(),
        );
      }
    } catch (e) {}
  }

  /// Clear all session data
  Future<void> _clearSession() async {
    _currentUser = null;
    _isLoggedIn = false;
    _loginTime = null;
    _tokenExpiryTime = null;
    _authToken = null;
    _refreshToken = null;
    _userPermissions = [];

    await _ensurePrefs();
    await _prefs!.remove('isLoggedIn');
    await _prefs!.remove('user');
    await _prefs!.remove('authToken');
    await _prefs!.remove('refreshToken');
    await _prefs!.remove('loginTime');
    await _prefs!.remove('tokenExpiry');
  }

  /// Cleanup resources (call when app is disposing)
  void dispose() {
    _tokenRefreshTimer?.cancel();
  }
}
