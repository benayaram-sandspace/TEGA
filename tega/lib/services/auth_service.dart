import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  admin,
  user,
  moderator,
}

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

  // Fake login method - replace with real API call later
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Fake user data - replace with real API response
    final fakeUsers = {
      'admin@tega.com': {
        'password': 'admin123',
        'user': User(
          id: '1',
          name: 'Benayaram',
          email: 'admin@tega.com',
          role: UserRole.admin,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      },
      'moderator@tega.com': {
        'password': 'mod123',
        'user': User(
          id: '2',
          name: 'Moderator User',
          email: 'moderator@tega.com',
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
        _loginTime = DateTime.now(); // Record login time
        await _saveSession(); // Save session to storage
        return {
          'success': true,
          'message': 'Login successful',
          'user': _currentUser,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid password',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'User not found',
      };
    }
  }

  // Fake signup method - replace with real API call later
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Check if user already exists
    if (email == 'admin@tega.com' || email == 'moderator@tega.com' || email == 'user@tega.com') {
      return {
        'success': false,
        'message': 'User already exists',
      };
    }

    // Create new user with default role
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: UserRole.user, // Default role for new users
      createdAt: DateTime.now(),
    );
    _isLoggedIn = true;
    _loginTime = DateTime.now(); // Record login time
    await _saveSession(); // Save session to storage

    return {
      'success': true,
      'message': 'Account created successfully',
      'user': _currentUser,
    };
  }

  // Fake logout method
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isLoggedIn = false;
    _loginTime = null; // Clear login time
    await _clearSession(); // Clear session from storage
  }

  // Check if user has specific role
  bool hasRole(UserRole role) {
    return _currentUser?.role == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole(UserRole.admin);

  // Check if user is moderator or admin
  bool get isModeratorOrAdmin => hasRole(UserRole.moderator) || hasRole(UserRole.admin);

  // Get role display name
  String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.user:
        return 'User';
    }
  }

  // Get role color
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

  // Check if session is still valid (no expiration for now)
  bool isSessionValid() {
    return _isLoggedIn && _currentUser != null;
  }

  // Get session duration
  Duration? getSessionDuration() {
    if (_loginTime == null) return null;
    return DateTime.now().difference(_loginTime!);
  }

  // Get formatted session duration
  String getFormattedSessionDuration() {
    final duration = getSessionDuration();
    if (duration == null) return 'Not logged in';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Initialize session (for app startup)
  Future<void> initializeSession() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check if user was previously logged in
    final isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    final userEmail = _prefs?.getString('userEmail');
    final userName = _prefs?.getString('userName');
    final userRole = _prefs?.getString('userRole');
    final loginTimeString = _prefs?.getString('loginTime');
    
    if (isLoggedIn && userEmail != null && userName != null && userRole != null) {
      // Restore session
      _isLoggedIn = true;
      _currentUser = User(
        id: _prefs?.getString('userId') ?? '',
        name: userName,
        email: userEmail,
        role: UserRole.values.firstWhere(
          (role) => role.toString() == 'UserRole.$userRole',
          orElse: () => UserRole.user,
        ),
        createdAt: DateTime.tryParse(_prefs?.getString('createdAt') ?? '') ?? DateTime.now(),
      );
      
      if (loginTimeString != null) {
        _loginTime = DateTime.tryParse(loginTimeString);
      }
      
      print('Session restored for user: ${_currentUser!.name}');
    }
  }

  // Save session data to SharedPreferences
  Future<void> _saveSession() async {
    if (_prefs == null) return;
    
    await _prefs!.setBool('isLoggedIn', _isLoggedIn);
    if (_currentUser != null) {
      await _prefs!.setString('userId', _currentUser!.id);
      await _prefs!.setString('userName', _currentUser!.name);
      await _prefs!.setString('userEmail', _currentUser!.email);
      await _prefs!.setString('userRole', _currentUser!.role.toString().split('.').last);
      await _prefs!.setString('createdAt', _currentUser!.createdAt.toIso8601String());
    }
    if (_loginTime != null) {
      await _prefs!.setString('loginTime', _loginTime!.toIso8601String());
    }
  }

  // Clear session data from SharedPreferences
  Future<void> _clearSession() async {
    if (_prefs == null) return;
    
    await _prefs!.remove('isLoggedIn');
    await _prefs!.remove('userId');
    await _prefs!.remove('userName');
    await _prefs!.remove('userEmail');
    await _prefs!.remove('userRole');
    await _prefs!.remove('createdAt');
    await _prefs!.remove('loginTime');
  }
}
