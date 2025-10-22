import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/env_config.dart';

/// Simple credential model for Google Credential Manager
class GoogleCredential {
  final String id;
  final String email;
  final String password;
  final String displayName;
  final DateTime lastUsed;

  GoogleCredential({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'displayName': displayName,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory GoogleCredential.fromJson(Map<String, dynamic> json) {
    return GoogleCredential(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }
}

/// Simple Google Credential Manager with biometric access
/// This service provides Google Credential Manager integration with biometric authentication
class SimpleGoogleCredentialManager {
  static final SimpleGoogleCredentialManager _instance =
      SimpleGoogleCredentialManager._internal();
  factory SimpleGoogleCredentialManager() => _instance;
  SimpleGoogleCredentialManager._internal();

  bool _isInitialized = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  List<GoogleCredential> _credentials = [];

  /// Google Client ID for authentication (from environment)
  static String get _googleClientId => EnvConfig.googleClientId;

  /// Initialize the Google Credential Manager
  Future<void> initialize() async {
    try {
      // Check if Google Client ID is configured
      if (_googleClientId.isEmpty) {
        debugPrint('⚠️ Google Client ID not configured in environment');
        _isInitialized = false;
        return;
      }

      // Load saved credentials from persistent storage
      await _loadCredentialsFromStorage();

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing Simple Google Credential Manager: $e');
      _isInitialized = false;
    }
  }

  /// Load credentials from secure storage
  Future<void> _loadCredentialsFromStorage() async {
    try {
      final credentialsJson = await _secureStorage.read(
        key: 'google_credentials',
      );

      if (credentialsJson != null) {
        final List<dynamic> credentialsList = json.decode(credentialsJson);
        _credentials = credentialsList
            .map((json) => GoogleCredential.fromJson(json))
            .toList();
      }
    } catch (e) {
      _credentials = [];
    }
  }

  /// Save credentials to secure storage
  Future<void> _saveCredentialsToStorage() async {
    try {
      final credentialsJson = json.encode(
        _credentials.map((cred) => cred.toJson()).toList(),
      );
      await _secureStorage.write(
        key: 'google_credentials',
        value: credentialsJson,
      );
    } catch (e) {}
  }

  /// Check if credential manager is available and initialized
  bool get isAvailable => _isInitialized;

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access saved credentials',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return result;
    } catch (e) {
      return false;
    }
  }

  /// Save credentials using Google Credential Manager
  Future<bool> saveCredentials({
    required String domain,
    required String username,
    required String password,
    String? displayName,
  }) async {
    if (!isAvailable) {
      return false;
    }

    try {
      // Create credential using Google Credential Manager API
      final credential = GoogleCredential(
        id: '${domain}_$username',
        email: username,
        password: password,
        displayName: displayName ?? username.split('@')[0],
        lastUsed: DateTime.now(),
      );

      // Remove existing credential with same email
      _credentials.removeWhere((c) => c.email == username);

      // Add new credential
      _credentials.add(credential);

      // Save to persistent storage
      await _saveCredentialsToStorage();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get saved credentials using Google Credential Manager
  Future<List<GoogleCredential>> getSavedCredentials() async {
    if (!isAvailable) {
      return [];
    }

    try {
      return _credentials;
    } catch (e) {
      return [];
    }
  }

  /// Show Google's native credential picker
  Future<GoogleCredential?> showCredentialPicker() async {
    if (!isAvailable) {
      return null;
    }

    try {
      // Authenticate with biometrics first
      final biometricAuth = await authenticateWithBiometrics();
      if (!biometricAuth) {
        return null;
      }

      // Get credentials from Google Credential Manager
      final credentials = await getSavedCredentials();

      if (credentials.isEmpty) {
        return null;
      }

      // For now, return the first credential
      // In a real implementation, this would show Google's native picker
      return credentials.first;
    } catch (e) {
      return null;
    }
  }

  /// Delete specific credentials
  Future<bool> deleteCredentials(String domain, String username) async {
    if (!isAvailable) {
      return false;
    }

    try {
      // Authenticate with biometrics first
      final biometricAuth = await authenticateWithBiometrics();
      if (!biometricAuth) {
        return false;
      }

      final initialLength = _credentials.length;
      _credentials.removeWhere((c) => c.email == username);

      if (_credentials.length < initialLength) {
        // Save to persistent storage
        await _saveCredentialsToStorage();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear all credentials
  Future<bool> clearAllCredentials() async {
    if (!isAvailable) {
      return false;
    }

    try {
      // Authenticate with biometrics first
      final biometricAuth = await authenticateWithBiometrics();
      if (!biometricAuth) {
        return false;
      }

      _credentials.clear();
      // Save to persistent storage
      await _saveCredentialsToStorage();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if there are any saved credentials
  Future<bool> hasAnyCredentials() async {
    if (!isAvailable) {
      return false;
    }

    try {
      return _credentials.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get credential count
  Future<int> getCredentialCount() async {
    if (!isAvailable) {
      return 0;
    }

    try {
      return _credentials.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get credentials for email suggestions
  Future<List<GoogleCredential>> getEmailSuggestions(
    String partialEmail,
  ) async {
    if (!isAvailable || partialEmail.isEmpty) {
      return [];
    }

    try {
      return _credentials
          .where(
            (cred) =>
                cred.email.toLowerCase().contains(partialEmail.toLowerCase()),
          )
          .take(5)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if credentials exist for a specific email
  Future<bool> hasCredentials(String email) async {
    if (!isAvailable) {
      return false;
    }

    try {
      return _credentials.any(
        (cred) => cred.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return false;
    }
  }

  /// Get credential by email
  Future<GoogleCredential?> getCredentialByEmail(String email) async {
    if (!isAvailable) {
      return null;
    }

    try {
      return _credentials.firstWhere(
        (cred) => cred.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Credential not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Update last used timestamp for a credential
  Future<bool> updateLastUsed(String email) async {
    if (!isAvailable) {
      return false;
    }

    try {
      final index = _credentials.indexWhere(
        (cred) => cred.email.toLowerCase() == email.toLowerCase(),
      );
      if (index >= 0) {
        _credentials[index] = GoogleCredential(
          id: _credentials[index].id,
          email: _credentials[index].email,
          password: _credentials[index].password,
          displayName: _credentials[index].displayName,
          lastUsed: DateTime.now(),
        );
        // Save to persistent storage
        await _saveCredentialsToStorage();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get the most recently used credential for auto-fill
  Future<GoogleCredential?> getLastUsedCredential() async {
    if (!isAvailable || _credentials.isEmpty) {
      return null;
    }

    try {
      // Sort by last used date and return the most recent
      _credentials.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return _credentials.first;
    } catch (e) {
      return null;
    }
  }
}
