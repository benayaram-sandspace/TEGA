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
      final parts = (json['name'] as String).split(' ');
      fName = parts.first;
      lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    // Handle username field for admin (backend uses username instead of firstName)
    if (fName.isEmpty && json['username'] != null) {
      fName = json['username'];
    }

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      firstName: fName,
      lastName: lName,
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      profileImage: json['profileImage'] ?? json['profilePicture'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      status: json['status'],
      studentId: json['studentId'],
      course: json['course'],
      year: json['year'] ?? json['yearOfStudy']?.toString(),
      college: json['college'],
      phone: json['phone'],
      university: json['university'],
      gender: json['gender'],
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
  static const bool _useDemoMode = false; // Set to false in production

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
        debugPrint(
          'Request timeout, retrying... (${retryCount + 1}/$_maxRetries)',
        );
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
        debugPrint(
          'Request timeout, retrying... (${retryCount + 1}/$_maxRetries)',
        );
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
          debugPrint('Token refresh failed: $error');
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

      debugPrint('🔍 [AUTH] Signup request data: $signupData');
      debugPrint('🔍 [AUTH] Signup URL: ${ApiEndpoints.register}');

      final response = await _makePostRequest(
        ApiEndpoints.register,
        signupData,
      );

      _handleResponseErrors(response, 'Signup');
      final responseData = json.decode(response.body);

      if (responseData['token'] != null && responseData['user'] != null) {
        _authToken = responseData['token'];
        _refreshToken = responseData['refreshToken'];

        // Debug: Print the raw user data from backend
        debugPrint(
          '🔍 [AUTH] Raw user data from signup: ${responseData['user']}',
        );

        _currentUser = User.fromJson(responseData['user']);

        // Debug: Print the parsed user object
        debugPrint('🔍 [AUTH] Parsed user object: ${_currentUser?.toJson()}');

        _isLoggedIn = true;
        _loginTime = DateTime.now();
        _tokenExpiryTime = DateTime.now().add(
          const Duration(days: 7),
        ); // Adjust based on backend
        _userPermissions = _currentUser?.permissions ?? [];

        await _saveSession();
        _startTokenRefreshTimer();

        debugPrint('✅ Signup successful for: $email');

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
      debugPrint('❌ Signup error: ${e.message}');
      if (_useDemoMode) {
        debugPrint('⚠️ Falling back to demo mode');
        return _fakeSignup(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          phone: phone,
        );
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Unexpected signup error: $e');
      if (_useDemoMode) {
        return _fakeSignup(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          phone: phone,
        );
      }
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Login user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Check for demo mode
    if (_useDemoMode) {
      const demoEmails = [
        'admin@tega.com',
        'college@tega.com',
        'user@tega.com',
      ];
      if (demoEmails.contains(email.toLowerCase().trim())) {
        debugPrint("⚠️ Demo mode: Using fake login for $email");
        return _fakeLogin(email, password);
      }
    }

    try {
      final loginData = {'email': email, 'password': password};

      debugPrint('🔍 [AUTH] Login request data: $loginData');
      debugPrint('🔍 [AUTH] Login URL: ${ApiEndpoints.login}');

      final response = await _makePostRequest(ApiEndpoints.login, loginData);

      _handleResponseErrors(response, 'Login');
      final responseData = json.decode(response.body);

      if (responseData['token'] != null && responseData['user'] != null) {
        _authToken = responseData['token'];
        _refreshToken = responseData['refreshToken'];

        // Debug: Print the raw user data from backend
        debugPrint(
          '🔍 [AUTH] Raw user data from login: ${responseData['user']}',
        );

        _currentUser = User.fromJson(responseData['user']);

        // Debug: Print the parsed user object
        debugPrint('🔍 [AUTH] Parsed user object: ${_currentUser?.toJson()}');

        _isLoggedIn = true;
        _loginTime = DateTime.now();
        _tokenExpiryTime = DateTime.now().add(const Duration(days: 7));
        _userPermissions = _currentUser?.permissions ?? [];

        await _saveSession();
        _startTokenRefreshTimer();

        debugPrint('✅ Login successful for: $email');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'user': _currentUser,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Login failed',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Login error: ${e.message}');
      if (_useDemoMode && e.statusCode == null) {
        debugPrint('⚠️ Network error, falling back to demo mode');
        return _fakeLogin(email, password);
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      return {
        'success': false,
        'message': 'Could not connect to server. Please try again.',
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

      // Debug: Print the raw profile data from backend
      debugPrint('🔍 [AUTH] Raw profile data from fetch: $profileData');

      _currentUser = User.fromJson(profileData);

      // Debug: Print the updated user object
      debugPrint('🔍 [AUTH] Updated user object: ${_currentUser?.toJson()}');

      await _saveSession();

      debugPrint('✅ User profile updated');
    } on AuthException catch (e) {
      debugPrint('❌ Fetch profile error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected profile error: $e');
      throw AuthException('Failed to load profile: ${e.toString()}');
    }
  }

  /// Logout user and clear session
  Future<void> logout() async {
    _tokenRefreshTimer?.cancel();
    await _clearSession();
    debugPrint('✅ User logged out successfully');
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

      debugPrint('✅ OTP sent to: $email');

      return {
        'success': true,
        'message': responseData['message'] ?? 'OTP sent successfully',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Send OTP error: ${e.message}');
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

      debugPrint('✅ OTP verified for: $email');

      return {
        'success': true,
        'message': responseData['message'] ?? 'OTP verified successfully',
        'verified': responseData['verified'] ?? true,
      };
    } on AuthException catch (e) {
      debugPrint('❌ Verify OTP error: ${e.message}');
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
        if (ok) debugPrint('✅ Password reset email sent to: $email');
        return result;
      }

      debugPrint('✅ Password reset email sent to: $email');

      return {
        'success': true,
        'message':
            responseData['message'] ??
            'Password reset instructions sent to your email',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Forgot password error: ${e.message}');
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

      debugPrint('✅ Password reset OTP verified for: $email');

      return {
        'success': true,
        'message': responseData['message'] ?? 'OTP verified successfully',
        'verified': responseData['verified'] ?? true,
      };
    } on AuthException catch (e) {
      debugPrint('❌ Verify OTP error: ${e.message}');
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

      debugPrint('✅ Password reset successful for: $email');

      return {
        'success': true,
        'message': responseData['message'] ?? 'Password reset successful',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Reset password error: ${e.message}');
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
      debugPrint('⚠️ No refresh token available');
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

        debugPrint('✅ Token refreshed successfully');
        return true;
      }

      debugPrint('❌ Token refresh failed - no token in response');
      return false;
    } on AuthException catch (e) {
      debugPrint('❌ Token refresh error: ${e.message}');
      if (e.statusCode == 401) {
        // Refresh token expired, logout user
        await logout();
      }
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected token refresh error: $e');
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
          debugPrint('⚠️ Token expired, attempting refresh...');
          final refreshed = await refreshAuthToken();
          if (!refreshed) {
            debugPrint('❌ Token refresh failed, clearing session');
            await _clearSession();
            return;
          }
        } else if (isTokenExpiringSoon) {
          debugPrint('⚠️ Token expiring soon, refreshing...');
          refreshAuthToken().catchError((error) {
            debugPrint('⚠️ Background token refresh failed: $error');
            return false;
          });
        }

        _startTokenRefreshTimer();
        debugPrint('✅ Session initialized for: ${_currentUser?.email}');
      }
    } catch (e) {
      debugPrint('❌ Error initializing session: $e');
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

      debugPrint('💾 Session saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
    }
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

    debugPrint('🗑️ Session cleared');
  }

  /// Cleanup resources (call when app is disposing)
  void dispose() {
    _tokenRefreshTimer?.cancel();
    debugPrint('🧹 AuthService disposed');
  }

  /// Demo/Fake login for testing
  Future<Map<String, dynamic>> _fakeLogin(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final fakeUsers = {
      'admin@tega.com': {
        'password': 'admin123',
        'user': User(
          id: '1',
          firstName: 'Admin',
          lastName: 'User',
          email: 'admin@tega.com',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          gender: 'Male',
        ),
      },
      'college@tega.com': {
        'password': 'college123',
        'user': User(
          id: '2',
          firstName: 'College',
          lastName: 'Principal',
          email: 'college@tega.com',
          role: UserRole.principal,
          createdAt: DateTime.now(),
          university: 'Aditya University',
          gender: 'Male',
        ),
      },
      'user@tega.com': {
        'password': 'user123',
        'user': User(
          id: '3',
          firstName: 'Test',
          lastName: 'Student',
          email: 'user@tega.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
          studentId: 'TEGA2024001',
          college: 'Aditya Engineering College',
          course: 'B.Tech CSE',
          year: '3',
          phone: '+91 9876543210',
        ),
      },
    };

    final cleanEmail = email.toLowerCase().trim();
    if (fakeUsers.containsKey(cleanEmail)) {
      final userData = fakeUsers[cleanEmail]!;
      if (userData['password'] == password) {
        _currentUser = userData['user'] as User;
        _isLoggedIn = true;
        _loginTime = DateTime.now();
        _tokenExpiryTime = DateTime.now().add(const Duration(days: 30));
        _authToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
        _refreshToken = 'demo_refresh_${DateTime.now().millisecondsSinceEpoch}';
        _userPermissions = _currentUser?.permissions ?? [];

        await _saveSession();
        _startTokenRefreshTimer();

        debugPrint('✅ Demo login successful for: $email');

        return {
          'success': true,
          'message': 'Login successful (Demo Mode)',
          'user': _currentUser,
        };
      } else {
        return {'success': false, 'message': 'Invalid password'};
      }
    } else {
      return {'success': false, 'message': 'User not found'};
    }
  }

  /// Demo/Fake signup for testing
  Future<Map<String, dynamic>> _fakeSignup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'admin@tega.com' ||
        email == 'college@tega.com' ||
        email == 'user@tega.com') {
      return {'success': false, 'message': 'Email already exists'};
    }

    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: UserRole.student,
      createdAt: DateTime.now(),
      phone: phone,
    );
    _isLoggedIn = true;
    _loginTime = DateTime.now();
    _tokenExpiryTime = DateTime.now().add(const Duration(days: 30));
    _authToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    _refreshToken = 'demo_refresh_${DateTime.now().millisecondsSinceEpoch}';

    await _saveSession();
    _startTokenRefreshTimer();

    debugPrint('✅ Demo signup successful for: $email');

    return {
      'success': true,
      'message': 'Account created successfully (Demo Mode)',
      'user': _currentUser,
    };
  }
}
