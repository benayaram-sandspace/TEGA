class AdminUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String status; // active, inactive, pending, suspended
  final String profileImage;
  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime? emailVerifiedAt;
  final List<String> permissions;
  final Map<String, dynamic> preferences;
  final String department;
  final String designation;
  final List<String> managedColleges;
  final Map<String, int> activityStats;
  final bool isSuperAdmin;
  final DateTime? lastPasswordChange;
  final bool requiresPasswordChange;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    required this.role,
    required this.status,
    this.profileImage = '',
    required this.createdAt,
    required this.lastLogin,
    this.emailVerifiedAt,
    required this.permissions,
    this.preferences = const {},
    this.department = '',
    this.designation = '',
    required this.managedColleges,
    this.activityStats = const {},
    this.isSuperAdmin = false,
    this.lastPasswordChange,
    this.requiresPasswordChange = false,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'],
      status: json['status'],
      profileImage: json['profileImage'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.parse(json['emailVerifiedAt'])
          : null,
      permissions: List<String>.from(json['permissions'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      managedColleges: List<String>.from(json['managedColleges'] ?? []),
      activityStats: Map<String, int>.from(json['activityStats'] ?? {}),
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      lastPasswordChange: json['lastPasswordChange'] != null
          ? DateTime.parse(json['lastPasswordChange'])
          : null,
      requiresPasswordChange: json['requiresPasswordChange'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'status': status,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'permissions': permissions,
      'preferences': preferences,
      'department': department,
      'designation': designation,
      'managedColleges': managedColleges,
      'activityStats': activityStats,
      'isSuperAdmin': isSuperAdmin,
      'lastPasswordChange': lastPasswordChange?.toIso8601String(),
      'requiresPasswordChange': requiresPasswordChange,
    };
  }
}

class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String adminName;
  final String adminId;
  final String action;
  final String target;
  final String details;
  final String
  actionType; // user_management, college_management, content_management, etc.
  final String ipAddress;
  final String userAgent;
  final String location;
  final Map<String, dynamic> metadata;
  final String category;
  final int severity; // 1-5 scale
  final bool isSuccess;
  final String? errorMessage;
  final List<String> affectedItems;

  ActivityLog({
    required this.id,
    required this.timestamp,
    required this.adminName,
    required this.adminId,
    required this.action,
    required this.target,
    required this.details,
    required this.actionType,
    this.ipAddress = '',
    this.userAgent = '',
    this.location = '',
    this.metadata = const {},
    this.category = '',
    this.severity = 1,
    this.isSuccess = true,
    this.errorMessage,
    this.affectedItems = const [],
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      adminName: json['adminName'],
      adminId: json['adminId'],
      action: json['action'],
      target: json['target'],
      details: json['details'],
      actionType: json['actionType'],
      ipAddress: json['ipAddress'] ?? '',
      userAgent: json['userAgent'] ?? '',
      location: json['location'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      category: json['category'] ?? '',
      severity: json['severity'] ?? 1,
      isSuccess: json['isSuccess'] ?? true,
      errorMessage: json['errorMessage'],
      affectedItems: List<String>.from(json['affectedItems'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'adminName': adminName,
      'adminId': adminId,
      'action': action,
      'target': target,
      'details': details,
      'actionType': actionType,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'location': location,
      'metadata': metadata,
      'category': category,
      'severity': severity,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'affectedItems': affectedItems,
    };
  }
}

class AdminInvite {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final List<String> permissions;
  final String status; // pending, sent, accepted, expired
  final DateTime createdAt;
  final DateTime expiresAt;
  final String invitedBy;
  final String? invitationToken;
  final String department;
  final String designation;
  final List<String> managedColleges;
  final Map<String, dynamic> inviteMetadata;

  AdminInvite({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    required this.role,
    required this.permissions,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.invitedBy,
    this.invitationToken,
    this.department = '',
    this.designation = '',
    required this.managedColleges,
    this.inviteMetadata = const {},
  });

  factory AdminInvite.fromJson(Map<String, dynamic> json) {
    return AdminInvite(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'],
      permissions: List<String>.from(json['permissions'] ?? []),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      invitedBy: json['invitedBy'],
      invitationToken: json['invitationToken'],
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      managedColleges: List<String>.from(json['managedColleges'] ?? []),
      inviteMetadata: Map<String, dynamic>.from(json['inviteMetadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'permissions': permissions,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'invitedBy': invitedBy,
      'invitationToken': invitationToken,
      'department': department,
      'designation': designation,
      'managedColleges': managedColleges,
      'inviteMetadata': inviteMetadata,
    };
  }
}

class AdminStatistics {
  final int totalAdmins;
  final int activeAdmins;
  final int inactiveAdmins;
  final int suspendedAdmins;
  final int pendingInvites;
  final int expiredInvites;
  final int totalActivities;
  final Map<String, int> activitiesByType;
  final Map<String, int> activitiesByDay;
  final Map<String, int> activitiesByAdmin;
  final List<AdminSession> recentLogins; // last 24 hours
  final double averageSessionsPerAdmin;
  final int failedLoginAttempts;
  final Map<String, dynamic> performanceMetrics;

  AdminStatistics({
    required this.totalAdmins,
    required this.activeAdmins,
    required this.inactiveAdmins,
    required this.suspendedAdmins,
    required this.pendingInvites,
    required this.expiredInvites,
    required this.totalActivities,
    required this.activitiesByType,
    required this.activitiesByDay,
    required this.activitiesByAdmin,
    required this.recentLogins,
    required this.averageSessionsPerAdmin,
    required this.failedLoginAttempts,
    required this.performanceMetrics,
  });

  factory AdminStatistics.fromJson(Map<String, dynamic> json) {
    return AdminStatistics(
      totalAdmins: json['totalAdmins'] ?? 0,
      activeAdmins: json['activeAdmins'] ?? 0,
      inactiveAdmins: json['inactiveAdmins'] ?? 0,
      suspendedAdmins: json['suspendedAdmins'] ?? 0,
      pendingInvites: json['pendingInvites'] ?? 0,
      expiredInvites: json['expiredInvites'] ?? 0,
      totalActivities: json['totalActivities'] ?? 0,
      activitiesByType: Map<String, int>.from(json['activitiesByType'] ?? {}),
      activitiesByDay: Map<String, int>.from(json['activitiesByDay'] ?? {}),
      activitiesByAdmin: Map<String, int>.from(json['activitiesByAdmin'] ?? {}),
      recentLogins: json['recentLogins'] ?? 0,
      averageSessionsPerAdmin: (json['averageSessionsPerAdmin'] ?? 0.0)
          .toDouble(),
      failedLoginAttempts: json['failedLoginAttempts'] ?? 0,
      performanceMetrics: Map<String, double>.from(
        json['performanceMetrics'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAdmins': totalAdmins,
      'activeAdmins': activeAdmins,
      'inactiveAdmins': inactiveAdmins,
      'suspendedAdmins': suspendedAdmins,
      'pendingInvites': pendingInvites,
      'expiredInvites': expiredInvites,
      'totalActivities': totalActivities,
      'activitiesByType': activitiesByType,
      'activitiesByDay': activitiesByDay,
      'activitiesByAdmin': activitiesByAdmin,
      'recentLogins': recentLogins,
      'averageSessionsPerAdmin': averageSessionsPerAdmin,
      'failedLoginAttempts': failedLoginAttempts,
      'performanceMetrics': performanceMetrics,
    };
  }
}

// New models for enhanced functionality
class AdminSession {
  final String id;
  final String adminId;
  final DateTime loginTime;
  final DateTime? logoutTime;
  final String ipAddress;
  final String userAgent;
  final String location;
  final String status; // active, expired, terminated
  final int activityCount;
  final List<String> pagesAccessed;

  AdminSession({
    required this.id,
    required this.adminId,
    required this.loginTime,
    this.logoutTime,
    required this.ipAddress,
    required this.userAgent,
    required this.location,
    required this.status,
    required this.activityCount,
    required this.pagesAccessed,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'],
      adminId: json['adminId'],
      loginTime: DateTime.parse(json['loginTime']),
      logoutTime: json['logoutTime'] != null
          ? DateTime.parse(json['logoutTime'])
          : null,
      ipAddress: json['ipAddress'] ?? '',
      userAgent: json['userAgent'] ?? '',
      location: json['location'] ?? '',
      status: json['status'],
      activityCount: json['activityCount'] ?? 0,
      pagesAccessed: List<String>.from(json['pagesAccessed'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'loginTime': loginTime.toIso8601String(),
      'logoutTime': logoutTime?.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'location': location,
      'status': status,
      'activityCount': activityCount,
      'pagesAccessed': pagesAccessed,
    };
  }
}

class AdminDashboardWidget {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> config;
  final bool isVisible;
  final int position;
  final DateTime lastUpdated;
  final String adminId;

  AdminDashboardWidget({
    required this.id,
    required this.name,
    required this.type,
    required this.config,
    required this.isVisible,
    required this.position,
    required this.lastUpdated,
    required this.adminId,
  });

  factory AdminDashboardWidget.fromJson(Map<String, dynamic> json) {
    return AdminDashboardWidget(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      isVisible: json['isVisible'] ?? true,
      position: json['position'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      adminId: json['adminId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'config': config,
      'isVisible': isVisible,
      'position': position,
      'lastUpdated': lastUpdated.toIso8601String(),
      'adminId': adminId,
    };
  }
}
