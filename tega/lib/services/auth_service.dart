import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { admin, user, moderator }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    required this.createdAt,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isLoggedIn = false;
  DateTime? _loginTime;
  SharedPreferences? _prefs;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  UserRole? get currentUserRole => _currentUser?.role;
  DateTime? get loginTime => _loginTime;

  // Ensure SharedPreferences is always initialized
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Fake login method - replace with real API call later
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    final fakeUsers = {
      'admin@tega.com': {
        'password': 'admin123',
        'user': User(
          id: '1',
          name: 'Administrator',
          email: 'admin@tega.com',
          role: UserRole.admin,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      },
      'college@tega.com': {
        'password': 'college123',
        'user': User(
          id: '2',
          name: 'College Principal',
          email: 'college@tega.com',
          role: UserRole.moderator,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      },
      'user@tega.com': {
        'password': 'user123',
        'user': User(
          id: '3',
          name: 'Regular User',
          email: 'user@tega.com',
          role: UserRole.user,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      },
    };

    if (fakeUsers.containsKey(email)) {
      final userData = fakeUsers[email]!;
      if (userData['password'] == password) {
        _currentUser = userData['user'] as User;
        _isLoggedIn = true;
        _loginTime = DateTime.now();
        await _saveSession(); // ✅ Now always saves
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

  // Fake signup method - replace with real API call later
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'admin@tega.com' ||
        email == 'moderator@tega.com' ||
        email == 'user@tega.com') {
      return {'success': false, 'message': 'User already exists'};
    }

    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: UserRole.user, // default role
      createdAt: DateTime.now(),
    );
    _isLoggedIn = true;
    _loginTime = DateTime.now();
    await _saveSession();

    return {
      'success': true,
      'message': 'Account created successfully',
      'user': _currentUser,
    };
  }

  // Logout method
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isLoggedIn = false;
    _loginTime = null;
    await _clearSession();
  }

  // Role helpers
  bool hasRole(UserRole role) => _currentUser?.role == role;
  bool get isAdmin => hasRole(UserRole.admin);
  bool get isModeratorOrAdmin =>
      hasRole(UserRole.moderator) || hasRole(UserRole.admin);

  String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'College Principal';
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

  bool isSessionValid() => _isLoggedIn && _currentUser != null;

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

  // Restore session when app restarts
  Future<void> initializeSession() async {
    await _ensurePrefs();

    final isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    final userEmail = _prefs?.getString('userEmail');
    final userName = _prefs?.getString('userName');
    final userRole = _prefs?.getString('userRole');
    final loginTimeString = _prefs?.getString('loginTime');

    if (isLoggedIn &&
        userEmail != null &&
        userName != null &&
        userRole != null) {
      _isLoggedIn = true;
      _currentUser = User(
        id: _prefs?.getString('userId') ?? '',
        name: userName,
        email: userEmail,
        role: UserRole.values.firstWhere(
          (role) => role.toString() == 'UserRole.$userRole',
          orElse: () => UserRole.user,
        ),
        createdAt:
            DateTime.tryParse(_prefs?.getString('createdAt') ?? '') ??
            DateTime.now(),
      );

      if (loginTimeString != null) {
        _loginTime = DateTime.tryParse(loginTimeString);
      }

      debugPrint(
        '✅ Session restored for ${_currentUser!.name} as ${_currentUser!.role}',
      );
    }
  }

  // Save session
  Future<void> _saveSession() async {
    await _ensurePrefs();

    await _prefs!.setBool('isLoggedIn', _isLoggedIn);
    if (_currentUser != null) {
      await _prefs!.setString('userId', _currentUser!.id);
      await _prefs!.setString('userName', _currentUser!.name);
      await _prefs!.setString('userEmail', _currentUser!.email);
      await _prefs!.setString(
        'userRole',
        _currentUser!.role.toString().split('.').last,
      );
      await _prefs!.setString(
        'createdAt',
        _currentUser!.createdAt.toIso8601String(),
      );
    }
    if (_loginTime != null) {
      await _prefs!.setString('loginTime', _loginTime!.toIso8601String());
    }
  }

  // Clear session
  Future<void> _clearSession() async {
    await _ensurePrefs();

    await _prefs!.remove('isLoggedIn');
    await _prefs!.remove('userId');
    await _prefs!.remove('userName');
    await _prefs!.remove('userEmail');
    await _prefs!.remove('userRole');
    await _prefs!.remove('createdAt');
    await _prefs!.remove('loginTime');
  }
}
