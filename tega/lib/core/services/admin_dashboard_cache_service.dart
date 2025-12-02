import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Cache service for admin dashboard data using SQLite
/// Provides caching with TTL (Time To Live) for dashboard data
class AdminDashboardCacheService {
  static final AdminDashboardCacheService _instance =
      AdminDashboardCacheService._internal();
  factory AdminDashboardCacheService() => _instance;
  AdminDashboardCacheService._internal();

  Database? _database;
  static const String _databaseName = 'admin_dashboard_cache.db';
  static const String _tableName = 'dashboard_cache';
  static const int _databaseVersion = 1;

  // Cache TTL - 5 minutes
  static const Duration _cacheTTL = Duration(minutes: 5);

  // Global flag to track if "no internet" toast has been shown
  bool _hasShownNoInternetToast = false;

  // Connectivity state tracking
  bool _isCurrentlyOffline = false;
  bool _hasShownOfflineToast = false;
  bool _hasShownOnlineToast = false;

  /// Initialize the database
  Future<void> initialize() async {
    if (_database != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Ensure database is initialized
  Future<void> _ensureDatabase() async {
    if (_database == null) {
      await initialize();
    }
  }

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getDashboardData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['dashboard_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await clearCache();
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached payment stats
  Future<Map<String, dynamic>?> getPaymentStats() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['payment_stats'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['payment_stats'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached courses data
  Future<Map<String, dynamic>?> getCoursesData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['courses_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['courses_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cache dashboard data
  Future<void> setDashboardData(Map<String, dynamic> data) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'dashboard_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache payment stats
  Future<void> setPaymentStats(Map<String, dynamic> stats) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(stats);
      await _database!.insert(_tableName, {
        'key': 'payment_stats',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache courses data
  Future<void> setCoursesData(Map<String, dynamic> coursesData) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(coursesData);
      await _database!.insert(_tableName, {
        'key': 'courses_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached offers data
  Future<Map<String, dynamic>?> getOffersData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['offers_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['offers_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached package offers data
  Future<List<dynamic>?> getPackageOffersData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['package_offers_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['package_offers_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached offer stats
  Future<Map<String, dynamic>?> getOfferStats() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['offer_stats'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['offer_stats'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cache offers data
  Future<void> setOffersData(Map<String, dynamic> offersData) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(offersData);
      await _database!.insert(_tableName, {
        'key': 'offers_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache package offers data
  Future<void> setPackageOffersData(List<dynamic> packageOffersData) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(packageOffersData);
      await _database!.insert(_tableName, {
        'key': 'package_offers_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache offer stats
  Future<void> setOfferStats(Map<String, dynamic> stats) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(stats);
      await _database!.insert(_tableName, {
        'key': 'offer_stats',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensureDatabase();
    try {
      await _database!.delete(_tableName);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear specific cache entry
  Future<void> clearCacheEntry(String key) async {
    await _ensureDatabase();
    try {
      await _database!.delete(_tableName, where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Check if cache is valid (not expired)
  Future<bool> isCacheValid() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['dashboard_data'],
      );

      if (results.isEmpty) return false;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      return now.difference(timestamp) <= _cacheTTL;
    } catch (e) {
      return false;
    }
  }

  /// Get cache age (time since last cache update)
  Future<Duration?> getCacheAge() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['dashboard_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      return now.difference(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Get cached available courses for forms
  Future<List<dynamic>?> getAvailableCourses() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['available_courses'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['available_courses'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached available TEGA exams for forms
  Future<List<dynamic>?> getAvailableTegaExams() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['available_tega_exams'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['available_tega_exams'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached available institutes for forms
  Future<List<String>?> getAvailableInstitutes() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['available_institutes'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['available_institutes'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return List<String>.from(json.decode(dataJson) as List<dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Cache available courses for forms
  Future<void> setAvailableCourses(List<dynamic> courses) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(courses);
      await _database!.insert(_tableName, {
        'key': 'available_courses',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache available TEGA exams for forms
  Future<void> setAvailableTegaExams(List<dynamic> exams) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(exams);
      await _database!.insert(_tableName, {
        'key': 'available_tega_exams',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache available institutes for forms
  Future<void> setAvailableInstitutes(List<String> institutes) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(institutes);
      await _database!.insert(_tableName, {
        'key': 'available_institutes',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached students data (all students)
  Future<Map<String, dynamic>?> getStudentsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['students_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['students_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cache students data (all students)
  Future<void> setStudentsData(Map<String, dynamic> data) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'students_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached students data by college
  Future<Map<String, dynamic>?> getStudentsDataByCollege(
    String collegeName,
  ) async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['students_data_$collegeName'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['students_data_$collegeName'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cache students data by college
  Future<void> setStudentsDataByCollege(
    String collegeName,
    Map<String, dynamic> data,
  ) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'students_data_$collegeName',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached principals data
  Future<Map<String, dynamic>?> getPrincipalsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['principals_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['principals_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cache principals data
  Future<void> setPrincipalsData(Map<String, dynamic> data) async {
    await _ensureDatabase();
    try {
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'principals_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached notifications data
  Future<List<Map<String, dynamic>>?> getNotificationsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['notifications_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['notifications_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache notifications data
  Future<void> setNotificationsData(
    List<Map<String, dynamic>> notifications,
  ) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'notifications': notifications};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'notifications_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached exams data
  Future<List<Map<String, dynamic>>?> getExamsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['exams_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['exams_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['exams'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache exams data
  Future<void> setExamsData(List<Map<String, dynamic>> exams) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'exams': exams, 'data': exams};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'exams_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached question papers data
  Future<List<Map<String, dynamic>>?> getQuestionPapersData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['question_papers_data'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['question_papers_data'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['questionPapers'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache question papers data
  Future<void> setQuestionPapersData(
    List<Map<String, dynamic>> questionPapers,
  ) async {
    await _ensureDatabase();
    try {
      final data = {
        'success': true,
        'questionPapers': questionPapers,
        'data': questionPapers,
      };
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'question_papers_data',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached exam registrations data
  Future<List<Map<String, dynamic>>?> getExamRegistrationsData(
    String examId,
  ) async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['exam_registrations_$examId'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['exam_registrations_$examId'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['registrations'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache exam registrations data
  Future<void> setExamRegistrationsData(
    String examId,
    List<Map<String, dynamic>> registrations,
  ) async {
    await _ensureDatabase();
    try {
      final data = {
        'success': true,
        'registrations': registrations,
        'data': registrations,
      };
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'exam_registrations_$examId',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached exam results data
  Future<List<Map<String, dynamic>>?> getExamResultsData(String examId) async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['exam_results_$examId'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['exam_results_$examId'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['results'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache exam results data
  Future<void> setExamResultsData(
    String examId,
    List<Map<String, dynamic>> results,
  ) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'results': results, 'data': results};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'exam_results_$examId',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached jobs data
  Future<Map<String, dynamic>?> getJobsData({
    String? searchQuery,
    String? status,
    String? type,
    int page = 1,
  }) async {
    await _ensureDatabase();
    try {
      // Create a cache key based on filters
      final cacheKey =
          'jobs_data_${searchQuery ?? ''}_${status ?? 'all'}_${type ?? 'all'}_$page';

      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: [cacheKey],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: [cacheKey],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache jobs data
  Future<void> setJobsData({
    required List<Map<String, dynamic>> jobs,
    required Map<String, dynamic> pagination,
    String? searchQuery,
    String? status,
    String? type,
    int page = 1,
  }) async {
    await _ensureDatabase();
    try {
      // Create a cache key based on filters
      final cacheKey =
          'jobs_data_${searchQuery ?? ''}_${status ?? 'all'}_${type ?? 'all'}_$page';

      final data = {'success': true, 'data': jobs, 'pagination': pagination};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': cacheKey,
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached jobs stats
  Future<Map<String, int>?> getJobsStats() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['jobs_stats'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['jobs_stats'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return Map<String, int>.from(data['stats'] ?? {});
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache jobs stats
  Future<void> setJobsStats(Map<String, int> stats) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'stats': stats};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'jobs_stats',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached placement prep questions data
  Future<List<Map<String, dynamic>>?> getPlacementPrepQuestionsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['placement_prep_questions'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['placement_prep_questions'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['questions'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache placement prep questions data
  Future<void> setPlacementPrepQuestionsData(
    List<Map<String, dynamic>> questions,
  ) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'questions': questions, 'data': questions};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'placement_prep_questions',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached placement prep modules data
  Future<List<Map<String, dynamic>>?> getPlacementPrepModulesData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['placement_prep_modules'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['placement_prep_modules'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['modules'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache placement prep modules data
  Future<void> setPlacementPrepModulesData(
    List<Map<String, dynamic>> modules,
  ) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'modules': modules, 'data': modules};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'placement_prep_modules',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached placement prep stats data
  Future<Map<String, dynamic>?> getPlacementPrepStatsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['placement_prep_stats'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['placement_prep_stats'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['stats'] ?? {});
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache placement prep stats data
  Future<void> setPlacementPrepStatsData(Map<String, dynamic> stats) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'stats': stats};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'placement_prep_stats',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached company questions data
  Future<List<Map<String, dynamic>>?> getCompanyQuestionsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['company_questions'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['company_questions'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['questions'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache company questions data
  Future<void> setCompanyQuestionsData(
    List<Map<String, dynamic>> questions,
  ) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'questions': questions, 'data': questions};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'company_questions',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached company list data
  Future<List<String>?> getCompanyListData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['company_list'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['company_list'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<String>.from(data['companies'] ?? data['data'] ?? []);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache company list data
  Future<void> setCompanyListData(List<String> companies) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'companies': companies, 'data': companies};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'company_list',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached company list with details (for companies tab)
  Future<List<Map<String, dynamic>>?> getCompanyListWithDetailsData() async {
    await _ensureDatabase();
    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: ['company_list_details'],
      );

      if (results.isEmpty) return null;

      final timestampStr = results.first['timestamp'] as String;
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(timestamp) > _cacheTTL) {
        await _database!.delete(
          _tableName,
          where: 'key = ?',
          whereArgs: ['company_list_details'],
        );
        return null;
      }

      final dataJson = results.first['data'] as String;
      final data = json.decode(dataJson) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          data['companies'] ?? data['data'] ?? [],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache company list with details (for companies tab)
  Future<void> setCompanyListWithDetailsData(
    List<Map<String, dynamic>> companies,
  ) async {
    await _ensureDatabase();
    try {
      final data = {'success': true, 'companies': companies, 'data': companies};
      final dataJson = json.encode(data);
      await _database!.insert(_tableName, {
        'key': 'company_list_details',
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Check if "no internet" toast has been shown
  bool get hasShownNoInternetToast => _hasShownNoInternetToast;

  /// Mark that "no internet" toast has been shown
  void markNoInternetToastShown() {
    _hasShownNoInternetToast = true;
  }

  /// Reset the "no internet" toast flag (call when internet is restored)
  void resetNoInternetToastFlag() {
    _hasShownNoInternetToast = false;
  }

  /// Handle offline state - shows toast if going offline for the first time
  void handleOfflineState(BuildContext? context) {
    if (!_isCurrentlyOffline && !_hasShownOfflineToast) {
      _isCurrentlyOffline = true;
      _hasShownOfflineToast = true;
      _hasShownOnlineToast = false; // Reset online toast flag

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Offline'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Handle online state - shows toast if coming back online
  void handleOnlineState(BuildContext? context) {
    if (_isCurrentlyOffline && !_hasShownOnlineToast) {
      _isCurrentlyOffline = false;
      _hasShownOnlineToast = true;
      _hasShownOfflineToast = false; // Reset offline toast flag

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Back online'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
