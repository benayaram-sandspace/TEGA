import 'package:local_auth/local_auth.dart';
import 'simple_google_credential_manager.dart';

/// Fingerprint Login Service
/// Provides fingerprint authentication for login
class FingerprintLoginService {
  static final FingerprintLoginService _instance =
      FingerprintLoginService._internal();
  factory FingerprintLoginService() => _instance;
  FingerprintLoginService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SimpleGoogleCredentialManager _credentialManager =
      SimpleGoogleCredentialManager();

  /// Check if fingerprint authentication is available
  Future<bool> isFingerprintAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with fingerprint
  Future<bool> authenticateWithFingerprint({
    String reason = 'Authenticate with your fingerprint to login',
  }) async {
    try {
      final isAvailable = await isFingerprintAvailable();
      if (!isAvailable) {
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: reason,
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

  /// Login with fingerprint - gets the last used credential
  Future<GoogleCredential?> loginWithFingerprint() async {
    try {
      // Check if fingerprint is available
      final isAvailable = await isFingerprintAvailable();
      if (!isAvailable) {
        return null;
      }

      // Initialize credential manager
      await _credentialManager.initialize();

      // Get saved credentials
      final credentials = await _credentialManager.getSavedCredentials();
      if (credentials.isEmpty) {
        return null;
      }

      // Authenticate with fingerprint
      final isAuthenticated = await authenticateWithFingerprint(
        reason: 'Use your fingerprint to login with saved credentials',
      );

      if (!isAuthenticated) {
        return null;
      }

      // Get the most recently used credential
      final lastUsedCredential = await _credentialManager
          .getLastUsedCredential();
      if (lastUsedCredential != null) {
        // Update last used timestamp
        await _credentialManager.updateLastUsed(lastUsedCredential.email);
        return lastUsedCredential;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if there are any saved credentials for fingerprint login
  Future<bool> hasSavedCredentials() async {
    try {
      await _credentialManager.initialize();
      return await _credentialManager.hasAnyCredentials();
    } catch (e) {
      return false;
    }
  }
}
