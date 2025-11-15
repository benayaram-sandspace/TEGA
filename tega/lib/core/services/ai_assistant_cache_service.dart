import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for AI assistant conversation history
/// Provides caching with TTL (Time To Live) for conversations
class AIAssistantCacheService {
  static final AIAssistantCacheService _instance = AIAssistantCacheService._internal();
  factory AIAssistantCacheService() => _instance;
  AIAssistantCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _conversationsKey = 'ai_assistant_conversations';
  static const String _activeConversationIdKey = 'ai_assistant_active_id';
  static const String _sessionIdKey = 'ai_assistant_session_id';
  static const String _cacheTimestampKey = 'ai_assistant_cache_timestamp';

  // Cache TTL - 30 days (conversations should persist longer)
  static const Duration _cacheTTL = Duration(days: 30);

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

  /// Get cached conversations
  Future<List<Map<String, dynamic>>?> getConversations() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_conversationsKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Set conversations in cache
  Future<void> setConversations(List<Map<String, dynamic>> conversations) async {
    await _ensurePrefs();
    await _prefs?.setString(_conversationsKey, json.encode(conversations));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Get active conversation ID
  Future<String?> getActiveConversationId() async {
    await _ensurePrefs();
    return _prefs?.getString(_activeConversationIdKey);
  }

  /// Set active conversation ID
  Future<void> setActiveConversationId(String? id) async {
    await _ensurePrefs();
    if (id == null) {
      await _prefs?.remove(_activeConversationIdKey);
    } else {
      await _prefs?.setString(_activeConversationIdKey, id);
    }
  }

  /// Get session ID
  Future<String?> getSessionId() async {
    await _ensurePrefs();
    return _prefs?.getString(_sessionIdKey);
  }

  /// Set session ID
  Future<void> setSessionId(String? sessionId) async {
    await _ensurePrefs();
    if (sessionId == null) {
      await _prefs?.remove(_sessionIdKey);
    } else {
      await _prefs?.setString(_sessionIdKey, sessionId);
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_conversationsKey);
    await _prefs?.remove(_activeConversationIdKey);
    await _prefs?.remove(_sessionIdKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

