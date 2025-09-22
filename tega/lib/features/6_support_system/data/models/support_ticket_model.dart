class SupportTicket {
  final String id;
  final String title;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String category; // 'bug', 'feature_request', 'general', 'technical'
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SupportMessage> messages;
  final List<String> tags;

  SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.createdAt,
    this.updatedAt,
    required this.messages,
    required this.tags,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      category: json['category'],
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((message) => SupportMessage.fromJson(message))
              .toList() ??
          [],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'tags': tags,
    };
  }
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderType; // 'user', 'support', 'system'
  final String content;
  final DateTime timestamp;
  final List<String> attachments;
  final bool isInternal; // for internal notes

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.timestamp,
    required this.attachments,
    required this.isInternal,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      ticketId: json['ticketId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderType: json['senderType'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      attachments: List<String>.from(json['attachments'] ?? []),
      isInternal: json['isInternal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'attachments': attachments,
      'isInternal': isInternal,
    };
  }
}

class Feedback {
  final String id;
  final String title;
  final String description;
  final String
  type; // 'bug_report', 'feature_request', 'improvement', 'positive'
  final String status; // 'new', 'in_progress', 'completed', 'rejected'
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int priority;

  Feedback({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.updatedAt,
    required this.tags,
    required this.priority,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      status: json['status'],
      userId: json['userId'],
      userName: json['userName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      priority: json['priority'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'priority': priority,
    };
  }
}

class SupportStatistics {
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final int totalFeedback;
  final int newFeedback;
  final int inProgressFeedback;
  final int completedFeedback;
  final double averageResponseTime; // in hours
  final double customerSatisfaction; // percentage

  SupportStatistics({
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.totalFeedback,
    required this.newFeedback,
    required this.inProgressFeedback,
    required this.completedFeedback,
    required this.averageResponseTime,
    required this.customerSatisfaction,
  });

  factory SupportStatistics.fromJson(Map<String, dynamic> json) {
    return SupportStatistics(
      totalTickets: json['totalTickets'],
      openTickets: json['openTickets'],
      inProgressTickets: json['inProgressTickets'],
      resolvedTickets: json['resolvedTickets'],
      totalFeedback: json['totalFeedback'],
      newFeedback: json['newFeedback'],
      inProgressFeedback: json['inProgressFeedback'],
      completedFeedback: json['completedFeedback'],
      averageResponseTime: json['averageResponseTime']?.toDouble() ?? 0.0,
      customerSatisfaction: json['customerSatisfaction']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTickets': totalTickets,
      'openTickets': openTickets,
      'inProgressTickets': inProgressTickets,
      'resolvedTickets': resolvedTickets,
      'totalFeedback': totalFeedback,
      'newFeedback': newFeedback,
      'inProgressFeedback': inProgressFeedback,
      'completedFeedback': completedFeedback,
      'averageResponseTime': averageResponseTime,
      'customerSatisfaction': customerSatisfaction,
    };
  }
}
