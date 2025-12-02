import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration Service
///
/// This service manages all environment variables and provides
/// a centralized way to access configuration values throughout the app.
class EnvConfig {
  static bool _isInitialized = false;

  /// Initialize the environment configuration
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
    }
  }

  /// Get a string value from environment variables
  static String getString(String key, {String defaultValue = ''}) {
    _ensureInitialized();
    return dotenv.env[key] ?? defaultValue;
  }

  /// Get a boolean value from environment variables
  static bool getBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();
    final value = dotenv.env[key]?.toLowerCase();
    return value == 'true' || value == '1';
  }

  /// Get an integer value from environment variables
  static int getInt(String key, {int defaultValue = 0}) {
    _ensureInitialized();
    return int.tryParse(dotenv.env[key] ?? '') ?? defaultValue;
  }

  /// Get a double value from environment variables
  static double getDouble(String key, {double defaultValue = 0.0}) {
    _ensureInitialized();
    return double.tryParse(dotenv.env[key] ?? '') ?? defaultValue;
  }

  /// Check if a key exists in environment variables
  static bool hasKey(String key) {
    _ensureInitialized();
    return dotenv.env.containsKey(key);
  }

  /// Get all environment variables
  static Map<String, String> getAll() {
    _ensureInitialized();
    return Map.from(dotenv.env);
  }

  /// Ensure the environment is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'EnvConfig not initialized. Call EnvConfig.initialize() in main() first.',
      );
    }
  }

  // ==================== CONVENIENCE GETTERS ====================

  /// Base URL for API calls
  static String get baseUrl =>
      getString('BASE_URL', defaultValue: 'http://localhost:5001');

  /// API version
  static String get apiVersion => getString('API_VERSION', defaultValue: 'v1');

  /// Current environment (development, staging, production)
  static String get environment =>
      getString('ENVIRONMENT', defaultValue: 'development');

  /// Whether debug logs are enabled
  static bool get enableDebugLogs =>
      getBool('ENABLE_DEBUG_LOGS', defaultValue: false);

  /// Whether analytics are enabled
  static bool get enableAnalytics =>
      getBool('ENABLE_ANALYTICS', defaultValue: false);

  /// App name
  static String get appName => getString('APP_NAME', defaultValue: 'TEGA');

  /// App version
  static String get appVersion =>
      getString('APP_VERSION', defaultValue: '1.0.0');

  /// Google Maps API Key (if needed)
  static String get googleMapsApiKey => getString('GOOGLE_MAPS_API_KEY');

  /// Firebase Project ID (if needed)
  static String get firebaseProjectId => getString('FIREBASE_PROJECT_ID');

  /// Encryption Key (if needed)
  static String get encryptionKey => getString('ENCRYPTION_KEY');

  /// JWT Secret (if needed)
  static String get jwtSecret => getString('JWT_SECRET');

  /// Google Client ID for Credential Manager
  /// Add GOOGLE_CLIENT_ID=your_google_client_id_here to your .env file
  static String get googleClientId => getString('GOOGLE_CLIENT_ID');

  /// Razorpay Key ID for client checkout
  static String get razorpayKeyId => getString('RAZORPAY_KEY_ID');

  // ==================== UTILITY METHODS ====================

  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if running in production mode
  static bool get isProduction => environment == 'production';

  /// Check if running in staging mode
  static bool get isStaging => environment == 'staging';

  /// Get full API URL with version
  static String get fullApiUrl => '$baseUrl/api/$apiVersion';

  /// Get base API URL without version
  static String get baseApiUrl => '$baseUrl/api';

  /// Print all environment variables (for debugging)
  static void printAll() {
    if (enableDebugLogs) {
      // Debug logging disabled for production
    }
  }
}
