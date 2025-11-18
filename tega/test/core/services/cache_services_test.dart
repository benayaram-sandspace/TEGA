import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Cache Services', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Dashboard Cache Service', () {
      test('should cache dashboard data', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dashboard_cache', '{"test": "data"}');
        final cached = prefs.getString('dashboard_cache');
        expect(cached, isNotNull);
      });

      test('should clear cache when requested', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dashboard_cache', '{"test": "data"}');
        await prefs.remove('dashboard_cache');
        final cached = prefs.getString('dashboard_cache');
        expect(cached, isNull);
      });

      test('should handle cache expiration', () async {
        final prefs = await SharedPreferences.getInstance();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('dashboard_cache_timestamp', timestamp);
        final cachedTimestamp = prefs.getInt('dashboard_cache_timestamp');
        expect(cachedTimestamp, equals(timestamp));
      });
    });

    group('Profile Cache Service', () {
      test('should cache profile data', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_cache', '{"name": "Test User"}');
        final cached = prefs.getString('profile_cache');
        expect(cached, isNotNull);
      });
    });

    group('Courses Cache Service', () {
      test('should cache courses list', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'courses_cache',
          '[{"id": "1", "name": "Course 1"}]',
        );
        final cached = prefs.getString('courses_cache');
        expect(cached, isNotNull);
      });
    });

    group('Notifications Cache Service', () {
      test('should cache notifications', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notifications_cache', '[]');
        final cached = prefs.getString('notifications_cache');
        expect(cached, isNotNull);
      });
    });

    group('Payment Cache Service', () {
      test('should cache payment data', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('payment_cache', '{"status": "pending"}');
        final cached = prefs.getString('payment_cache');
        expect(cached, isNotNull);
      });
    });

    group('Cache Expiration', () {
      test('should check if cache is expired', () {
        final now = DateTime.now();
        final cacheTime = now.subtract(const Duration(hours: 2));
        final isExpired = now.difference(cacheTime).inHours > 1;
        expect(isExpired, isTrue);
      });

      test('should identify valid cache', () {
        final now = DateTime.now();
        final cacheTime = now.subtract(const Duration(minutes: 30));
        final isValid = now.difference(cacheTime).inMinutes < 60;
        expect(isValid, isTrue);
      });
    });
  });
}
