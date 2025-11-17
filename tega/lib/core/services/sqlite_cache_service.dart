import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// A unified SQLite-based cache service with TTL support
/// Replaces SharedPreferences for better performance and data handling
class SQLiteCacheService {
  static SQLiteCacheService? _instance;
  static Database? _database;
  static final _initLock = Completer<void>();

  SQLiteCacheService._();

  /// Get singleton instance
  static SQLiteCacheService get instance {
    if (_instance == null) {
      _instance = SQLiteCacheService._();
      if (!_initLock.isCompleted) {
        _instance!._initDatabase();
      }
    }
    return _instance!;
  }

  /// Initialize the database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'tega_cache.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cache (
              key TEXT PRIMARY KEY,
              category TEXT NOT NULL,
              value TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              ttl INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_category ON cache(category)',
          );
          await db.execute(
            'CREATE INDEX idx_timestamp ON cache(timestamp)',
          );
        },
      );

      _initLock.complete();
    } catch (e) {
      if (!_initLock.isCompleted) {
        _initLock.completeError(e);
      }
      rethrow;
    }
  }

  /// Ensure database is initialized
  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initLock.future;
    return _database!;
  }

  /// Store a value in cache with TTL
  Future<void> set({
    required String key,
    required String category,
    required dynamic value,
    required Duration ttl,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'cache',
      {
        'key': key,
        'category': category,
        'value': jsonEncode(value),
        'timestamp': now,
        'ttl': ttl.inMilliseconds,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a value from cache if not expired
  Future<dynamic> get({
    required String key,
    required String category,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final results = await db.query(
      'cache',
      where: 'key = ? AND category = ?',
      whereArgs: [key, category],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final record = results.first;
    final timestamp = record['timestamp'] as int;
    final ttl = record['ttl'] as int;

    // Check if expired
    if (now - timestamp > ttl) {
      await delete(key: key, category: category);
      return null;
    }

    final value = record['value'] as String;
    return jsonDecode(value);
  }

  /// Delete a specific cache entry
  Future<void> delete({
    required String key,
    required String category,
  }) async {
    final db = await database;
    await db.delete(
      'cache',
      where: 'key = ? AND category = ?',
      whereArgs: [key, category],
    );
  }

  /// Delete all cache entries in a category
  Future<void> deleteCategory(String category) async {
    final db = await database;
    await db.delete(
      'cache',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  /// Clear all expired entries
  Future<void> clearExpired() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.delete(
      'cache',
      where: 'timestamp + ttl < ?',
      whereArgs: [now],
    );
  }

  /// Clear all cache
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cache');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;

    // Total entries
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache');
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    // Entries by category
    final categoryResult = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM cache GROUP BY category',
    );

    final byCategory = <String, int>{};
    for (final row in categoryResult) {
      byCategory[row['category'] as String] = row['count'] as int;
    }

    // Expired entries
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache WHERE timestamp + ttl < ?',
      [now],
    );
    final expired = Sqflite.firstIntValue(expiredResult) ?? 0;

    // Database size (approximate)
    final sizeResult = await db.rawQuery(
      'SELECT SUM(LENGTH(value)) as size FROM cache',
    );
    final size = Sqflite.firstIntValue(sizeResult) ?? 0;

    return {
      'total': total,
      'expired': expired,
      'active': total - expired,
      'byCategory': byCategory,
      'sizeBytes': size,
      'sizeMB': (size / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Check if a key exists and is not expired
  Future<bool> has({
    required String key,
    required String category,
  }) async {
    final value = await get(key: key, category: category);
    return value != null;
  }

  /// Close the database (call on app termination)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _instance = null;
    }
  }
}

