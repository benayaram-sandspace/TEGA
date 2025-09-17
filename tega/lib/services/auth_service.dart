import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/constants/api_constants.dart';

enum UserRole { admin, moderator, user }

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
  final String? course;
  final String? year;
  final String? college;

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
    this.course,
    this.year,
    this.college,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String fName = json['firstName'] ?? '';
    String lName = json['lastName'] ?? '';

    if (fName.isEmpty && lName.isEmpty && json['name'] != null) {
      final parts = (json['name'] as String).split(' ');
      fName = parts.first;
      lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      firstName: fName,
      lastName: lName,
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      profileImage: json['profileImage'],
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
      course: json['course'],
      year: json['yearOfStudy']?.toString(), // Corrected mapping
      college: json['college'],
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      case 'user':
      default:
        return UserRole.user;
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
      'course': course,
      'year': year,
      'college': college,
    };
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isLoggedIn = false;
  DateTime? _loginTime;
  SharedPreferences? _prefs;
  String? _authToken;
  List<String> _userPermissions = [];

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  UserRole? get currentUserRole => _currentUser?.role;
  DateTime? get loginTime => _loginTime;
  String? get authToken => _authToken;
  List<String> get userPermissions => _userPermissions;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

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
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phone': phone,
          'course': course,
          'year': year,
          'college': college,
        }),
      );
      final responseData = json.decode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          responseData['token'] != null) {
        _authToken = responseData['token'];
        _currentUser = User.fromJson(responseData['user']);
        _isLoggedIn = true;
        _loginTime = DateTime.now();
        _userPermissions = _currentUser?.permissions ?? [];
        await _saveSession();
        return {
          'success': true,
          'message': 'Account created and logged in successfully!',
          'user': _currentUser,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      debugPrint('API signup failed, falling back to fake signup: $e');
      return _fakeSignup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
    }
  }

  // MODIFIED: This version prioritizes checking demo credentials
  Future<Map<String, dynamic>> login(String email, String password) async {
    // First, check if the email matches one of the demo accounts.
    const demoEmails = ['admin@tega.com', 'college@tega.com', 'user@tega.com'];
    if (demoEmails.contains(email.toLowerCase().trim())) {
      debugPrint("Attempting login with demo credentials for: $email");
      return _fakeLogin(email, password);
    }

    // If it's not a demo account, proceed with the real API call.
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['token'] != null) {
        _authToken = responseData['token'];
        _currentUser = User.fromJson(responseData['user']);
        _isLoggedIn = true;
        _loginTime = DateTime.now();
        _userPermissions = _currentUser?.permissions ?? [];
        await _saveSession();
        return {
          'success': true,
          'message': 'Login successful',
          'user': _currentUser,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Login failed due to an unknown server error.',
        };
      }
    } catch (e) {
      debugPrint('API login failed: $e');
      return {
        'success': false,
        'message': 'Could not connect to the server. Please try again later.',
      };
    }
  }

  Future<void> fetchUserProfile() async {
    if (_authToken == null) throw Exception('Not authenticated.');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final profileData = json.decode(response.body);
        _currentUser = User.fromJson(profileData);
        await _saveSession();
      } else {
        throw Exception(
          'Failed to load user profile. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await http.post(
          Uri.parse(ApiEndpoints.logout),
          headers: getAuthHeaders(),
        );
      }
    } catch (e) {
      // Fail silently
    }
    await _clearSession();
  }

  bool hasRole(UserRole role) => _currentUser?.role == role;
  bool get isAdmin => hasRole(UserRole.admin);
  bool get isModerator => hasRole(UserRole.moderator);
  bool get isRegularUser => hasRole(UserRole.user);
  bool get isModeratorOrAbove =>
      hasRole(UserRole.moderator) || hasRole(UserRole.admin);
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
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.user:
        return 'User';
    }
  }

  Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.user:
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

  Future<void> initializeSession() async {
    await _ensurePrefs();
    final isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    final token = _prefs?.getString('authToken');
    final userJson = _prefs?.getString('user');
    final loginTimeString = _prefs?.getString('loginTime');
    if (isLoggedIn && token != null && userJson != null) {
      _isLoggedIn = true;
      _authToken = token;
      _currentUser = User.fromJson(json.decode(userJson));
      _userPermissions = _currentUser?.permissions ?? [];
      if (loginTimeString != null) {
        _loginTime = DateTime.tryParse(loginTimeString);
      }
    }
  }

  Future<void> _saveSession() async {
    await _ensurePrefs();
    await _prefs!.setBool('isLoggedIn', _isLoggedIn);
    if (_currentUser != null) {
      String userJson = json.encode(_currentUser!.toJson());
      await _prefs!.setString('user', userJson);
    }
    if (_authToken != null) {
      await _prefs!.setString('authToken', _authToken!);
    }
    if (_loginTime != null) {
      await _prefs!.setString('loginTime', _loginTime!.toIso8601String());
    }
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _isLoggedIn = false;
    _loginTime = null;
    _authToken = null;
    _userPermissions = [];
    await _ensurePrefs();
    await _prefs!.remove('isLoggedIn');
    await _prefs!.remove('user');
    await _prefs!.remove('authToken');
    await _prefs!.remove('loginTime');
  }

  Future<Map<String, dynamic>> _fakeLogin(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final fakeUsers = {
      'admin@tega.com': {
        'password': 'admin123',
        'user': User(
          id: '1',
          firstName: 'Admin',
          lastName: '',
          email: 'admin@tega.com',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        ),
      },
      'college@tega.com': {
        'password': 'college123',
        'user': User(
          id: '2',
          firstName: 'College',
          lastName: 'Principal',
          email: 'college@tega.com',
          role: UserRole.moderator,
          createdAt: DateTime.now(),
        ),
      },
      'user@tega.com': {
        'password': 'user123',
        'user': User(
          id: '3',
          firstName: 'Test',
          lastName: 'User',
          email: 'user@tega.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
          college: 'Aditya Engineering College',
          course: 'B.Tech | CSE',
          year: '3rd Year',
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
        _authToken = 'fake_token_${DateTime.now().millisecondsSinceEpoch}';
        _userPermissions = _currentUser?.permissions ?? [];
        await _saveSession();
        return {
          'success': true,
          'message': 'Login successful',
          'user': _currentUser,
        };
      } else {
        return {'success': false, 'message': 'Invalid password'};
      }
    } else {
      return {'success': false, 'message': 'User not found'};
    }
  }

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
      return {'success': false, 'message': 'User already exists'};
    }
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: UserRole.user,
      createdAt: DateTime.now(),
    );
    _isLoggedIn = true;
    _loginTime = DateTime.now();
    _authToken = 'fake_token_${DateTime.now().millisecondsSinceEpoch}';
    await _saveSession();
    return {
      'success': true,
      'message': 'Account created successfully',
      'user': _currentUser,
    };
  }
}
