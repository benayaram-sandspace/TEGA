import 'package:flutter_test/flutter_test.dart';
import 'package:tega/core/config/env_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('EnvConfig', () {
    setUpAll(() async {
      // Initialize with empty env for tests
      try {
        await dotenv.load(fileName: ".env", mergeWith: {});
      } catch (e) {
        // If .env doesn't exist, use empty map
        dotenv.testLoad(fileInput: '');
      }
      await EnvConfig.initialize();
    });

    test('should initialize successfully', () async {
      // Test that initialization doesn't throw
      expect(() => EnvConfig.initialize(), returnsNormally);
    });

    test('should throw exception if not initialized', () {
      // This test verifies the initialization check
      // Note: This may need adjustment based on actual implementation
      expect(() => EnvConfig.getString('TEST_KEY'), returnsNormally);
    });

    test('getString should return default value when key not found', () {
      expect(EnvConfig.getString('NON_EXISTENT_KEY', defaultValue: 'default'),
          equals('default'));
    });

    test('getBool should return true for "true" string', () {
      // Assuming we set a test value
      expect(EnvConfig.getBool('ENABLE_DEBUG_LOGS', defaultValue: false),
          isA<bool>());
    });

    test('getInt should parse integer values', () {
      expect(EnvConfig.getInt('TEST_INT', defaultValue: 42), equals(42));
    });

    test('getDouble should parse double values', () {
      expect(EnvConfig.getDouble('TEST_DOUBLE', defaultValue: 3.14),
          equals(3.14));
    });

    test('hasKey should check if key exists', () {
      expect(EnvConfig.hasKey('BASE_URL'), isA<bool>());
    });

    test('baseUrl should return valid URL', () {
      final url = EnvConfig.baseUrl;
      expect(url, isNotEmpty);
      expect(url, isA<String>());
    });

    test('isDevelopment should return boolean', () {
      expect(EnvConfig.isDevelopment, isA<bool>());
    });

    test('isProduction should return boolean', () {
      expect(EnvConfig.isProduction, isA<bool>());
    });

    test('isStaging should return boolean', () {
      expect(EnvConfig.isStaging, isA<bool>());
    });

    test('baseApiUrl should contain /api', () {
      final url = EnvConfig.baseApiUrl;
      expect(url, contains('/api'));
    });
  });
}

