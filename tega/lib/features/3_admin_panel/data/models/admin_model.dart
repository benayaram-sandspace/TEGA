class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status; // active, inactive, pending
  final String profileImage;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<String> permissions;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.profileImage,
    required this.createdAt,
    required this.lastLogin,
    required this.permissions,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      profileImage: json['profileImage'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'permissions': permissions,
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

  ActivityLog({
    required this.id,
    required this.timestamp,
    required this.adminName,
    required this.adminId,
    required this.action,
    required this.target,
    required this.details,
    required this.actionType,
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
    };
  }
}

class AdminInvite {
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  AdminInvite({
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });
}

class AdminStatistics {
  final int totalAdmins;
  final int activeAdmins;
  final int pendingInvites;
  final int totalActivities;
  final Map<String, int> activitiesByType;

  AdminStatistics({
    required this.totalAdmins,
    required this.activeAdmins,
    required this.pendingInvites,
    required this.totalActivities,
    required this.activitiesByType,
  });
}
