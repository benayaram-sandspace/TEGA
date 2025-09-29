import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tega/features/3_admin_panel/data/models/admin_model.dart';

class AdminRepository {
  static AdminRepository? _instance;
  static AdminRepository get instance => _instance ??= AdminRepository._();
  AdminRepository._();

  List<AdminUser> _adminUsers = [];
  List<ActivityLog> _activityLogs = [];
  List<AdminSession> _activeSessions = [];
  List<AdminInvite> _pendingInvites = [];
  List<AdminDashboardWidget> _dashboardWidgets = [];
  AdminStatistics? _statistics;
  bool _isLoaded = false;
  String? _currentAdminId;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/admin_data.json',
      );
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
        activitiesByType: Map<String, int>.from(
          jsonData['statistics']['activitiesByType'],
        ),
        inactiveAdmins: jsonData['statistics']['inactiveAdmins'] ?? 0,
        suspendedAdmins: jsonData['statistics']['suspendedAdmins'] ?? 0,
        expiredInvites: jsonData['statistics']['expiredInvites'] ?? 0,
        activitiesByDay: Map<String, int>.from(
          jsonData['statistics']['activitiesByDay'] ?? {},
        ),
        activitiesByAdmin: Map<String, int>.from(
          jsonData['statistics']['activitiesByAdmin'] ?? {},
        ),
        recentLogins: (jsonData['statistics']['recentLogins'] as List?)
                ?.map((json) => AdminSession.fromJson(json))
                .toList() ??
            [],
        averageSessionsPerAdmin: jsonData['statistics']['averageSessionsPerAdmin'] ?? 0.0,
        failedLoginAttempts: jsonData['statistics']['failedLoginAttempts'] ?? 0,
        performanceMetrics: Map<String, dynamic>.from(
          jsonData['statistics']['performanceMetrics'] ?? {},
        ),
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

    return _adminUsers
        .where(
          (admin) =>
              admin.name.toLowerCase().contains(query.toLowerCase()) ||
              admin.email.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
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
      final index = _adminUsers.indexWhere(
        (admin) => admin.id == updatedAdmin.id,
      );
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

  List<ActivityLog> getActivityLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _activityLogs
        .where(
          (log) =>
              log.timestamp.isAfter(startDate) &&
              log.timestamp.isBefore(endDate),
        )
        .toList();
  }

  List<ActivityLog> getActivityLogsByAdmin(String adminId) {
    return _activityLogs.where((log) => log.adminId == adminId).toList();
  }

  List<ActivityLog> getActivityLogsByActionType(String actionType) {
    return _activityLogs.where((log) => log.actionType == actionType).toList();
  }

  List<ActivityLog> searchActivityLogs(String query) {
    if (query.isEmpty) return getAllActivityLogs();

    return _activityLogs
        .where(
          (log) =>
              log.adminName.toLowerCase().contains(query.toLowerCase()) ||
              log.action.toLowerCase().contains(query.toLowerCase()) ||
              log.target.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
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
        inactiveAdmins: _statistics!.inactiveAdmins,
        suspendedAdmins: _statistics!.suspendedAdmins,
        expiredInvites: _statistics!.expiredInvites,
        activitiesByDay: _statistics!.activitiesByDay,
        activitiesByAdmin: _statistics!.activitiesByAdmin,
        recentLogins: _statistics!.recentLogins,
        averageSessionsPerAdmin: _statistics!.averageSessionsPerAdmin,
        failedLoginAttempts: _statistics!.failedLoginAttempts,
        performanceMetrics: _statistics!.performanceMetrics,
      );
    }
  }

  // Statistics
  AdminStatistics? getStatistics() {
    return _statistics;
  }

  // Utility methods
  List<String> getAvailableRoles() {
    return [
      'Super Admin',
      'Content Manager',
      'User Manager',
      'College Manager',
      'Analytics Manager',
    ];
  }

  List<String> getAvailableStatuses() {
    return ['active', 'inactive', 'pending'];
  }

  List<String> getAvailableActionTypes() {
    return [
      'user_management',
      'college_management',
      'content_management',
      'analytics',
      'admin_management',
    ];
  }

  List<String> getAvailablePermissions() {
    return [
      'manage_users',
      'edit_content',
      'view_analytics',
      'manage_colleges',
      'manage_admins',
    ];
  }

  // Invite management
  Future<bool> sendAdminInvite(AdminInvite invite) async {
    try {
      _pendingInvites.add(invite);
      await _logActivity(
        adminId: _currentAdminId ?? 'current_admin',
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

  // Session Management
  Future<AdminSession> startSession({
    required String adminId,
    required String ipAddress,
    required String userAgent,
    required String location,
  }) async {
    final session = AdminSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      adminId: adminId,
      loginTime: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      status: 'active',
      activityCount: 0,
      pagesAccessed: [],
    );

    _activeSessions.add(session);
    _currentAdminId = adminId;

    await _logActivity(
      adminId: adminId,
      adminName: _getAdminNameById(adminId) ?? 'Unknown Admin',
      action: 'Login',
      target: 'System',
      details: 'Admin logged in successfully',
      actionType: 'authentication',
    );

    return session;
  }

  Future<void> endSession(String sessionId) async {
    final sessionIndex = _activeSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _activeSessions[sessionIndex];
      _activeSessions[sessionIndex] = AdminSession(
        id: session.id,
        adminId: session.adminId,
        loginTime: session.loginTime,
        logoutTime: DateTime.now(),
        ipAddress: session.ipAddress,
        userAgent: session.userAgent,
        location: session.location,
        status: 'terminated',
        activityCount: session.activityCount,
        pagesAccessed: session.pagesAccessed,
      );

      await _logActivity(
        adminId: session.adminId,
        adminName: _getAdminNameById(session.adminId) ?? 'Unknown Admin',
        action: 'Logout',
        target: 'System',
        details: 'Admin logged out',
        actionType: 'authentication',
      );
    }
  }

  List<AdminSession> getActiveSessions() {
    return List.from(_activeSessions.where((s) => s.status == 'active'));
  }

  // Page Access Tracking
  Future<void> trackPageAccess(String adminId, String pageName) async {
    final sessionIndex = _activeSessions.indexWhere(
      (s) => s.adminId == adminId && s.status == 'active',
    );
    
    if (sessionIndex != -1) {
      final session = _activeSessions[sessionIndex];
      if (!session.pagesAccessed.contains(pageName)) {
        final updatedPages = List<String>.from(session.pagesAccessed)..add(pageName);
        _activeSessions[sessionIndex] = AdminSession(
          id: session.id,
          adminId: session.adminId,
          loginTime: session.loginTime,
          logoutTime: session.logoutTime,
          ipAddress: session.ipAddress,
          userAgent: session.userAgent,
          location: session.location,
          status: session.status,
          activityCount: session.activityCount + 1,
          pagesAccessed: updatedPages,
        );

        await _logActivity(
          adminId: adminId,
          adminName: _getAdminNameById(adminId) ?? 'Unknown Admin',
          action: 'Page Access',
          target: pageName,
          details: 'Accessed $pageName page',
          actionType: 'navigation',
        );
      }
    }
  }

  // Advanced Admin Operations
  Future<bool> bulkUpdateAdminStatus(List<String> adminIds, String newStatus) async {
    try {
      bool success = true;
      for (final adminId in adminIds) {
        final admin = getAdminById(adminId);
        if (admin != null) {
          final updatedAdmin = AdminUser(
            id: admin.id,
            name: admin.name,
            email: admin.email,
            phoneNumber: admin.phoneNumber,
            role: admin.role,
            status: newStatus,
            profileImage: admin.profileImage,
            createdAt: admin.createdAt,
            lastLogin: admin.lastLogin,
            emailVerifiedAt: admin.emailVerifiedAt,
            permissions: admin.permissions,
            preferences: admin.preferences,
            department: admin.department,
            designation: admin.designation,
            managedColleges: admin.managedColleges,
            activityStats: admin.activityStats,
            isSuperAdmin: admin.isSuperAdmin,
            lastPasswordChange: admin.lastPasswordChange,
            requiresPasswordChange: admin.requiresPasswordChange,
          );

          final index = _adminUsers.indexWhere((a) => a.id == adminId);
          if (index != -1) {
            _adminUsers[index] = updatedAdmin;
            
            await _logActivity(
              adminId: _currentAdminId ?? 'current_admin',
              adminName: 'Current Admin',
              action: 'Bulk Status Update',
              target: admin.name,
              details: 'Updated status to $newStatus',
              actionType: 'admin_management',
            );
          }
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Dashboard Widgets Management
  Future<List<AdminDashboardWidget>> getDashboardWidgets(String adminId) async {
    return _dashboardWidgets.where((w) => w.adminId == adminId).toList();
  }

  Future<bool> updateDashboardWidgets(
    String adminId,
    List<AdminDashboardWidget> widgets,
  ) async {
    try {
      // Remove old widgets for this admin
      _dashboardWidgets.removeWhere((w) => w.adminId == adminId);
      
      // Add new widgets
      _dashboardWidgets.addAll(widgets);
      
      await _logActivity(
        adminId: adminId,
        adminName: _getAdminNameById(adminId) ?? 'Unknown Admin',
        action: 'Dashboard Update',
        target: 'Dashboard',
        details: 'Updated dashboard layout',
        actionType: 'preferences',
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Enhanced Analytics
  Map<String, dynamic> getDetailedAnalytics(DateTime startDate, DateTime endDate) {
    final filteredLogs = _activityLogs
        .where((log) => log.timestamp.isAfter(startDate) && log.timestamp.isBefore(endDate))
        .toList();

    return {
      'totalActivities': filteredLogs.length,
      'successfulActivities': filteredLogs.where((l) => l.isSuccess).length,
      'failedActivities': filteredLogs.where((l) => !l.isSuccess).length,
      'activitiesByType': _groupActivitiesBy(filteredLogs, (log) => log.actionType),
      'activitiesByAdmin': _groupActivitiesBy(filteredLogs, (log) => log.adminName),
      'activitiesByCategory': _groupActivitiesBy(filteredLogs, (log) => log.category),
      'topPerformingAdmins': _getTopPerformingAdmins(filteredLogs),
      'securityIncidents': filteredLogs.where((l) => l.category == 'security' && !l.isSuccess).length,
      'avgResponseTime': _calculateAvgResponseTime(filteredLogs),
    };
  }

  List<ActivityLog> getSecurityAuditLogs() {
    return _activityLogs
        .where((log) => log.category == 'security' || log.severity >= 4)
        .toList();
  }

  // Enhanced Statistics Calculation
  AdminStatistics calculateAdvancedStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentActivities = _activityLogs
        .where((log) => log.timestamp.isAfter(last24Hours))
        .toList();

    final recentLogins = recentActivities
        .where((log) => log.action == 'Login' && log.isSuccess)
        .length;

    return AdminStatistics(
      totalAdmins: _adminUsers.length,
      activeAdmins: _adminUsers.where((a) => a.status == 'active').length,
      inactiveAdmins: _adminUsers.where((a) => a.status == 'inactive').length,
      suspendedAdmins: _adminUsers.where((a) => a.status == 'suspended').length,
      pendingInvites: _pendingInvites.where((i) => i.status == 'pending').length,
      expiredInvites: _pendingInvites.where((i) => i.status == 'expired').length,
      totalActivities: _activityLogs.length,
      activitiesByType: _groupActivitiesBy(_activityLogs, (log) => log.actionType),
      activitiesByDay: _groupActivitiesByDays(_activityLogs, 30),
      activitiesByAdmin: _groupActivitiesBy(_activityLogs, (log) => log.adminName),
      recentLogins: _activeSessions,
      averageSessionsPerAdmin: _adminUsers.isNotEmpty ? _activeSessions.length / _adminUsers.length : 0.0,
      failedLoginAttempts: recentActivities
          .where((log) => log.action == 'Login' && !log.isSuccess)
          .length,
      performanceMetrics: _calculatePerformanceMetrics(),
    );
  }

  // Utility helper methods
  String? _getAdminNameById(String adminId) {
    try {
      return _adminUsers.firstWhere((a) => a.id == adminId).name;
    } catch (e) {
      return null;
    }
  }

  Map<String, int> _groupActivitiesBy(List<ActivityLog> logs, String Function(ActivityLog) getter) {
    final Map<String, int> result = {};
    for (final log in logs) {
      final key = getter(log);
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  Map<String, int> _groupActivitiesByDays(List<ActivityLog> logs, int days) {
    final now = DateTime.now();
    final Map<String, int> result = {};
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayLogs = logs.where((log) => 
        log.timestamp.year == date.year &&
        log.timestamp.month == date.month &&
        log.timestamp.day == date.day
      ).length;
      result[dateKey] = dayLogs;
    }
    
    return result;
  }

  List<Map<String, dynamic>> _getTopPerformingAdmins(List<ActivityLog> logs) {
    final adminStats = <String, Map<String, int>>{};
    
    for (final log in logs) {
      if (!adminStats.keys.contains(log.adminName)) {
        adminStats[log.adminName] = {'total': 0, 'successful': 0};
      }
      
      adminStats[log.adminName]!['total'] = (adminStats[log.adminName]!['total'] ?? 0) + 1;
      if (log.isSuccess) {
        adminStats[log.adminName]!['successful'] = (adminStats[log.adminName]!['successful'] ?? 0) + 1;
      }
    }
    
    return adminStats.entries
        .map((entry) => {
              'adminName': entry.key,
              'totalActivities': entry.value['total'],
              'successRate': entry.value['successful']! / entry.value['total']!,
            })
        .toList()
        ..sort((a, b) => (b['totalActivities'] as int).compareTo(a['totalActivities'] as int));
  }

  double _calculateAvgResponseTime(List<ActivityLog> logs) {
    final responseTimes = logs
        .where((log) => log.metadata.containsKey('responseTime'))
        .map((log) => log.metadata['responseTime'] as double)
        .toList();
    
    if (responseTimes.isEmpty) return 0.0;
    return responseTimes.reduce((a, b) => a + b) / responseTimes.length;
  }

  double _calculateAverageSessionDuration() {
    final completedSessions = _activeSessions
        .where((s) => s.logoutTime != null)
        .map((s) => s.logoutTime!.difference(s.loginTime).inMinutes)
        .toList();
    
    if (completedSessions.isEmpty) return 0.0;
    return completedSessions.reduce((a, b) => a + b) / completedSessions.length;
  }

  Map<String, double> _calculatePerformanceMetrics() {
    final totalActivities = _activityLogs.length;
    final successfulActivities = _activityLogs.where((l) => l.isSuccess).length;
    final avgActionsPerSession = _activeSessions.isEmpty ? 0.0 : 
        _activeSessions.map((s) => s.activityCount).reduce((a, b) => a + b) / _activeSessions.length;
    
    return {
      'successRate': totalActivities > 0 ? successfulActivities / totalActivities : 0.0,
      'averageActivitiesPerSession': avgActionsPerSession,
      'securityIncidentRate': avgActionsPerSession,
      'adminEfficiency': successfulActivities / (_adminUsers.isNotEmpty ? _adminUsers.length : 1),
    };
  }

  // Enhanced activity logging (duplicate method - removing)
  // Future<void> _logActivity({
  //   required String adminId,
  //   required String adminName,
  //   required String action,
  //   required String target,
  //   required String details,
  //   required String actionType,
  //   String ipAddress = '',
  //   String userAgent = '',
  //   String location = '',
  //   Map<String, dynamic> metadata = const {},
  //   String category = '',
  //   int severity = 1,
  //   bool isSuccess = true,
  //   String? errorMessage,
  //   List<String> affectedItems = const [],
  // }) async {
  //   final log = ActivityLog(
  //     id: 'log_${DateTime.now().millisecondsSinceEpoch}',
  //     timestamp: DateTime.now(),
  //     adminName: adminName,
  //     adminId: adminId,
  //     action: action,
  //     target: target,
  //     details: details,
  //     actionType: actionType,
  //     ipAddress: ipAddress,
  //     userAgent: userAgent,
  //     location: location,
  //     metadata: metadata,
  //     category: category,
  //     severity: severity,
  //     isSuccess: isSuccess,
  //     errorMessage: errorMessage,
  //     affectedItems: affectedItems,
  //   );

  //   _activityLogs.insert(0, log);
  //   _updateStatistics();
  // }

  void _updateStatistics() {
    // Update statistics when activities are logged
    _statistics = calculateAdvancedStatistics();
  }
}
