import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Model representing a saved account credential
class SavedAccount {
  final String id;
  final String email;
  final String password;
  final String? accountName;
  final DateTime savedAt;
  final DateTime lastUsed;

  SavedAccount({
    required this.id,
    required this.email,
    required this.password,
    this.accountName,
    required this.savedAt,
    required this.lastUsed,
  });

  /// Create a SavedAccount from JSON
  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      accountName: json['accountName'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  /// Convert SavedAccount to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'accountName': accountName,
      'savedAt': savedAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SavedAccount copyWith({
    String? id,
    String? email,
    String? password,
    String? accountName,
    DateTime? savedAt,
    DateTime? lastUsed,
  }) {
    return SavedAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      accountName: accountName ?? this.accountName,
      savedAt: savedAt ?? this.savedAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Get display name for the account
  String get displayName {
    if (accountName != null && accountName!.isNotEmpty) {
      return accountName!;
    }
    return email.split('@')[0]; // Use email prefix as display name
  }

  @override
  String toString() {
    return 'SavedAccount(id: $id, email: $email, accountName: $accountName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedAccount && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Service to manage saved credentials similar to Google's account suggestions
class CredentialManager {
  static final CredentialManager _instance = CredentialManager._internal();
  factory CredentialManager() => _instance;
  CredentialManager._internal();

  static const String _savedAccountsKey = 'saved_accounts';
  static const int _maxSavedAccounts = 5; // Limit to prevent storage bloat

  SharedPreferences? _prefs;
  List<SavedAccount> _savedAccounts = [];

  /// Initialize the credential manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedAccounts();
  }

  /// Load saved accounts from SharedPreferences
  Future<void> _loadSavedAccounts() async {
    try {
      final accountsJson = _prefs?.getString(_savedAccountsKey);
      if (accountsJson != null) {
        final List<dynamic> accountsList = json.decode(accountsJson);
        _savedAccounts = accountsList
            .map((json) => SavedAccount.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by last used date (most recent first)
        _savedAccounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        
        debugPrint('✅ Loaded ${_savedAccounts.length} saved accounts');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading saved accounts: $e');
      _savedAccounts = [];
    }
  }

  /// Save accounts to SharedPreferences
  Future<void> _saveAccounts() async {
    try {
      final accountsJson = json.encode(
        _savedAccounts.map((account) => account.toJson()).toList(),
      );
      await _prefs?.setString(_savedAccountsKey, accountsJson);
      debugPrint('💾 Saved ${_savedAccounts.length} accounts to storage');
    } catch (e) {
      debugPrint('⚠️ Error saving accounts: $e');
    }
  }

  /// Get all saved accounts
  List<SavedAccount> get savedAccounts => List.unmodifiable(_savedAccounts);

  /// Get accounts matching a partial email
  List<SavedAccount> getAccountsForEmail(String partialEmail) {
    if (partialEmail.isEmpty) return [];
    
    return _savedAccounts
        .where((account) => 
            account.email.toLowerCase().contains(partialEmail.toLowerCase()))
        .take(3) // Limit suggestions to 3
        .toList();
  }

  /// Save a new account credential
  Future<bool> saveAccount({
    required String email,
    required String password,
    String? accountName,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      
      // Check if account already exists
      final existingIndex = _savedAccounts.indexWhere(
        (account) => account.email.toLowerCase() == normalizedEmail,
      );

      final now = DateTime.now();
      final accountId = existingIndex >= 0 
          ? _savedAccounts[existingIndex].id 
          : DateTime.now().millisecondsSinceEpoch.toString();

      final savedAccount = SavedAccount(
        id: accountId,
        email: normalizedEmail,
        password: password,
        accountName: accountName?.trim(),
        savedAt: existingIndex >= 0 
            ? _savedAccounts[existingIndex].savedAt 
            : now,
        lastUsed: now,
      );

      if (existingIndex >= 0) {
        // Update existing account
        _savedAccounts[existingIndex] = savedAccount;
        debugPrint('🔄 Updated existing account: ${savedAccount.displayName} (${savedAccount.email})');
      } else {
        // Add new account
        _savedAccounts.insert(0, savedAccount);
        
        // Remove oldest account if we exceed the limit
        if (_savedAccounts.length > _maxSavedAccounts) {
          final removedAccount = _savedAccounts.removeLast();
          debugPrint('🗑️ Removed oldest account: ${removedAccount.email}');
        }
        
        debugPrint('➕ Added new account: ${savedAccount.displayName} (${savedAccount.email})');
      }

      // Sort by last used date
      _savedAccounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      
      await _saveAccounts();
      return true;
    } catch (e) {
      debugPrint('⚠️ Error saving account: $e');
      return false;
    }
  }

  /// Update last used timestamp for an account
  Future<void> updateLastUsed(String email) async {
    try {
      final accountIndex = _savedAccounts.indexWhere(
        (account) => account.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (accountIndex >= 0) {
        _savedAccounts[accountIndex] = _savedAccounts[accountIndex].copyWith(
          lastUsed: DateTime.now(),
        );
        
        // Sort by last used date
        _savedAccounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        await _saveAccounts();
        
        debugPrint('🕒 Updated last used for: ${email}');
      }
    } catch (e) {
      debugPrint('⚠️ Error updating last used: $e');
    }
  }

  /// Delete an account
  Future<bool> deleteAccount(String email) async {
    try {
      final initialLength = _savedAccounts.length;
      _savedAccounts.removeWhere(
        (account) => account.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (_savedAccounts.length < initialLength) {
        await _saveAccounts();
        debugPrint('🗑️ Deleted account: $email');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error deleting account: $e');
      return false;
    }
  }

  /// Update account password
  Future<bool> updateAccountPassword(String email, String newPassword) async {
    try {
      final accountIndex = _savedAccounts.indexWhere(
        (account) => account.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (accountIndex >= 0) {
        _savedAccounts[accountIndex] = _savedAccounts[accountIndex].copyWith(
          password: newPassword,
          lastUsed: DateTime.now(),
        );
        
        // Sort by last used date
        _savedAccounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        await _saveAccounts();
        
        debugPrint('🔑 Updated password for: $email');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error updating password: $e');
      return false;
    }
  }

  /// Update account name
  Future<bool> updateAccountName(String email, String newName) async {
    try {
      final accountIndex = _savedAccounts.indexWhere(
        (account) => account.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (accountIndex >= 0) {
        _savedAccounts[accountIndex] = _savedAccounts[accountIndex].copyWith(
          accountName: newName.trim(),
        );
        
        await _saveAccounts();
        debugPrint('✏️ Updated account name for $email: $newName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error updating account name: $e');
      return false;
    }
  }

  /// Clear all saved accounts
  Future<void> clearAllAccounts() async {
    try {
      _savedAccounts.clear();
      await _prefs?.remove(_savedAccountsKey);
      debugPrint('🗑️ Cleared all saved accounts');
    } catch (e) {
      debugPrint('⚠️ Error clearing accounts: $e');
    }
  }

  /// Check if an account exists
  bool hasAccount(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    return _savedAccounts.any(
      (account) => account.email.toLowerCase() == normalizedEmail,
    );
  }

  /// Get account by email
  SavedAccount? getAccount(String email) {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      return _savedAccounts.firstWhere(
        (account) => account.email.toLowerCase() == normalizedEmail,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get account count
  int get accountCount => _savedAccounts.length;

  /// Check if there are any saved accounts
  bool get hasAccounts => _savedAccounts.isNotEmpty;
}
