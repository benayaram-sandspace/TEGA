import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for transaction history data
/// Provides caching with TTL (Time To Live) for transaction listings and stats
class TransactionHistoryCacheService {
  static final TransactionHistoryCacheService _instance =
      TransactionHistoryCacheService._internal();
  factory TransactionHistoryCacheService() => _instance;
  TransactionHistoryCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _transactionsDataKey = 'transaction_history_data';
  static const String _statsDataKey = 'transaction_stats_data';
  static const String _cacheTimestampKey =
      'transaction_history_cache_timestamp';

  // Cache TTL - 5 minutes
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if the cache is valid (not expired)
  Future<bool> _isCacheValid() async {
    await _ensurePrefs();
    final timestamp = _prefs?.getString(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime) <= _cacheTTL;
  }

  /// Get cached transactions data if valid
  Future<List<Map<String, dynamic>>?> getTransactionsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearTransactions();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_transactionsDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) {
        final map = e as Map<String, dynamic>;
        // Convert createdAt and paymentDate from string to DateTime
        if (map['createdAt'] is String) {
          map['createdAt'] = DateTime.parse(
            map['createdAt'] as String,
          ).toIso8601String();
        }
        if (map['paymentDate'] is String && map['paymentDate'] != null) {
          map['paymentDate'] = DateTime.parse(
            map['paymentDate'] as String,
          ).toIso8601String();
        }
        return map;
      }).toList();
    } catch (e) {
      await clearTransactions();
      return null;
    }
  }

  /// Set transactions data in cache
  Future<void> setTransactionsData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    // Convert DateTime to string for JSON encoding
    final serializedData = data.map((transaction) {
      final transactionCopy = Map<String, dynamic>.from(transaction);
      if (transactionCopy['createdAt'] is DateTime) {
        transactionCopy['createdAt'] =
            (transactionCopy['createdAt'] as DateTime).toIso8601String();
      }
      if (transactionCopy['paymentDate'] is DateTime) {
        transactionCopy['paymentDate'] =
            (transactionCopy['paymentDate'] as DateTime).toIso8601String();
      }
      return transactionCopy;
    }).toList();
    await _prefs?.setString(_transactionsDataKey, json.encode(serializedData));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached stats data if valid
  Future<Map<String, dynamic>?> getStatsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearStats();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_statsDataKey);
      return dataJson != null ? json.decode(dataJson) : null;
    } catch (e) {
      await clearStats();
      return null;
    }
  }

  /// Set stats data in cache
  Future<void> setStatsData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_statsDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Clear transactions cache
  Future<void> clearTransactions() async {
    await _ensurePrefs();
    await _prefs?.remove(_transactionsDataKey);
  }

  /// Clear stats cache
  Future<void> clearStats() async {
    await _ensurePrefs();
    await _prefs?.remove(_statsDataKey);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_transactionsDataKey);
    await _prefs?.remove(_statsDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}
