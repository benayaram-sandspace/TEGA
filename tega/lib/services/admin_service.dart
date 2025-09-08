import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/admin_models.dart';

class AdminService {
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();
  AdminService._();

  List<AdminUser> _adminUsers = [];
  List<ActivityLog> _activityLogs = [];
  AdminStatistics? _statistics;
  bool _isLoaded = false;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('lib/data/admin_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _adminUsers = (jsonData['adminUsers'] as List)
          .map((json) => AdminUser.fromJson(json))
          .toList();

      _activityLogs = (jsonData['activityLogs'] as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();

      _statistics = AdminStatistics(
        totalAdmins: jsonData['statistics']['totalAdmins'],
        activeAdmins: jsonData['statistics']['activeAdmins'],
        pendingInvites: jsonData['statistics']['pendingInvites'],
        totalActivities: jsonData['statistics']['totalActivities'],
        activitiesByType: Map<String, int>.from(jsonData['statistics']['activitiesByType']),
      );

      _isLoaded = true;
    } catch (e) {
      print('Error loading admin data: $e');
    }
  }

  // Admin Users Management
  List<AdminUser> getAllAdmins() {
    return List.from(_adminUsers);
  }

  List<AdminUser> searchAdmins(String query) {
    if (query.isEmpty) return getAllAdmins();
    
    return _adminUsers.where((admin) =>
        admin.name.toLowerCase().contains(query.toLowerCase()) ||
        admin.email.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<AdminUser> filterAdminsByRole(String role) {
    if (role.isEmpty) return getAllAdmins();
    return _adminUsers.where((admin) => admin.role == role).toList();
  }

  List<AdminUser> filterAdminsByStatus(String status) {
    if (status.isEmpty) return getAllAdmins();
    return _adminUsers.where((admin) => admin.status == status).toList();
  }

  AdminUser? getAdminById(String id) {
    try {
      return _adminUsers.firstWhere((admin) => admin.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addAdmin(AdminUser admin) async {
    try {
      _adminUsers.add(admin);
      await _logActivity(
        adminId: 'current_admin', // In real app, get from auth service
        adminName: 'Current Admin',
        action: 'Admin Creation',
        target: admin.name,
        details: 'Created new admin user',
        actionType: 'admin_management',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAdmin(AdminUser updatedAdmin) async {
    try {
      final index = _adminUsers.indexWhere((admin) => admin.id == updatedAdmin.id);
      if (index != -1) {
        _adminUsers[index] = updatedAdmin;
        await _logActivity(
          adminId: 'current_admin',
          adminName: 'Current Admin',
          action: 'Admin Update',
          target: updatedAdmin.name,
          details: 'Updated admin user information',
          actionType: 'admin_management',
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAdmin(String adminId) async {
    try {
      final admin = getAdminById(adminId);
      if (admin != null) {
        _adminUsers.removeWhere((a) => a.id == adminId);
        await _logActivity(
          adminId: 'current_admin',
          adminName: 'Current Admin',
          action: 'Admin Deletion',
          target: admin.name,
          details: 'Deleted admin user',
          actionType: 'admin_management',
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Activity Logs Management
  List<ActivityLog> getAllActivityLogs() {
    return List.from(_activityLogs);
  }

  List<ActivityLog> getActivityLogsByDateRange(DateTime startDate, DateTime endDate) {
    return _activityLogs.where((log) =>
        log.timestamp.isAfter(startDate) && log.timestamp.isBefore(endDate)
    ).toList();
  }

  List<ActivityLog> getActivityLogsByAdmin(String adminId) {
    return _activityLogs.where((log) => log.adminId == adminId).toList();
  }

  List<ActivityLog> getActivityLogsByActionType(String actionType) {
    return _activityLogs.where((log) => log.actionType == actionType).toList();
  }

  List<ActivityLog> searchActivityLogs(String query) {
    if (query.isEmpty) return getAllActivityLogs();
    
    return _activityLogs.where((log) =>
        log.adminName.toLowerCase().contains(query.toLowerCase()) ||
        log.action.toLowerCase().contains(query.toLowerCase()) ||
        log.target.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<void> _logActivity({
    required String adminId,
    required String adminName,
    required String action,
    required String target,
    required String details,
    required String actionType,
  }) async {
    final log = ActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      adminName: adminName,
      adminId: adminId,
      action: action,
      target: target,
      details: details,
      actionType: actionType,
    );
    
    _activityLogs.insert(0, log); // Add to beginning for chronological order
    
    // Update statistics
    if (_statistics != null) {
      _statistics = AdminStatistics(
        totalAdmins: _statistics!.totalAdmins,
        activeAdmins: _statistics!.activeAdmins,
        pendingInvites: _statistics!.pendingInvites,
        totalActivities: _statistics!.totalActivities + 1,
        activitiesByType: Map.from(_statistics!.activitiesByType)
          ..update(actionType, (value) => value + 1, ifAbsent: () => 1),
      );
    }
  }

  // Statistics
  AdminStatistics? getStatistics() {
    return _statistics;
  }

  // Utility methods
  List<String> getAvailableRoles() {
    return ['Super Admin', 'Content Manager', 'User Manager', 'College Manager', 'Analytics Manager'];
  }

  List<String> getAvailableStatuses() {
    return ['active', 'inactive', 'pending'];
  }

  List<String> getAvailableActionTypes() {
    return ['user_management', 'college_management', 'content_management', 'analytics', 'admin_management'];
  }

  List<String> getAvailablePermissions() {
    return ['manage_users', 'edit_content', 'view_analytics', 'manage_colleges', 'manage_admins'];
  }

  // Invite management
  Future<bool> sendAdminInvite(AdminInvite invite) async {
    try {
      // In a real app, this would send an email invitation
      await _logActivity(
        adminId: 'current_admin',
        adminName: 'Current Admin',
        action: 'Admin Invitation',
        target: invite.name,
        details: 'Sent invitation to new admin user',
        actionType: 'admin_management',
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
