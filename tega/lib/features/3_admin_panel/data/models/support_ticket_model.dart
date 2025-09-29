enum TicketStatus {
  open,
  inProgress,
  pendingCustomer,
  resolved,
  closed,
  cancelled,
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent,
  critical,
}

enum TicketCategory {
  bug,
  featureRequest,
  generalQuestion,
  technicalSupport,
  billing,
  account,
  security,
}

class TicketEvent {
  final String id;
  final DateTime timestamp;
  final String action;
  final String performedBy;
  final String performedByName;
  final String description;
  final Map<String, dynamic> metadata;
  final String eventType; // status_change, assignment, message, escalation, etc.

  TicketEvent({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    required this.description,
    this.metadata = const {},
    required this.eventType,
  });

  factory TicketEvent.fromJson(Map<String, dynamic> json) {
    return TicketEvent(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'],
      performedBy: json['performedBy'],
      performedByName: json['performedByName'],
      description: json['description'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      eventType: json['eventType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'description': description,
      'metadata': metadata,
      'eventType': eventType,
    };
  }
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String detailedDescription;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory category;
  final String subCategory;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? firstResponseAt;
  final DateTime? lastCustomerResponseAt;
  final List<SupportMessage> messages;
  final List<String> tags;
  final List<String> attachments;
  final String assignedTo;
  final String assignedByName;
  final String department;
  final List<TicketEvent> history;
  final Map<String, dynamic> metadata;
  final int satisfactionRating;
  final String satisfactionComments;
  final List<String> relatedTickets;
  final String escalationLevel; // level1, level2, level3
  final DateTime? slaDeadline;
  final bool isEscalated;
  final String source; // web, mobile, email, phone
  final Map<String, dynamic> customFields;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    this.detailedDescription = '',
    required this.status,
    required this.priority,
    required this.category,
    this.subCategory = '',
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
    required this.createdAt,
    this.updatedAt,
    this.firstResponseAt,
    this.lastCustomerResponseAt,
    required this.messages,
    required this.tags,
    this.attachments = const [],
    this.assignedTo = '',
    this.assignedByName = '',
    this.department = '',
    required this.history,
    this.metadata = const {},
    this.satisfactionRating = 0,
    this.satisfactionComments = '',
    this.relatedTickets = const [],
    this.escalationLevel = 'level1',
    this.slaDeadline,
    this.isEscalated = false,
    this.source = 'web',
    this.customFields = const {},
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      ticketNumber: json['ticketNumber'] ?? '',
      title: json['title'],
      description: json['description'],
      detailedDescription: json['detailedDescription'] ?? '',
      status: TicketStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      category: TicketCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TicketCategory.generalQuestion,
      ),
      subCategory: json['subCategory'] ?? '',
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userPhone: json['userPhone'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      firstResponseAt: json['firstResponseAt'] != null ? DateTime.parse(json['firstResponseAt']) : null,
      lastCustomerResponseAt: json['lastCustomerResponseAt'] != null ? DateTime.parse(json['lastCustomerResponseAt']) : null,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((message) => SupportMessage.fromJson(message))
          .toList() ?? [],
      tags: List<String>.from(json['tags'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
      assignedTo: json['assignedTo'] ?? '',
      assignedByName: json['assignedByName'] ?? '',
      department: json['department'] ?? '',
      history: (json['history'] as List<dynamic>?)
          ?.map((event) => TicketEvent.fromJson(event))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      satisfactionRating: json['satisfactionRating'] ?? 0,
      satisfactionComments: json['satisfactionComments'] ?? '',
      relatedTickets: List<String>.from(json['relatedTickets'] ?? []),
      escalationLevel: json['escalationLevel'] ?? 'level1',
      slaDeadline: json['slaDeadline'] != null ? DateTime.parse(json['slaDeadline']) : null,
      isEscalated: json['isEscalated'] ?? false,
      source: json['source'] ?? 'web',
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'title': title,
      'description': description,
      'detailedDescription': detailedDescription,
      'status': status.name,
      'priority': priority.name,
      'category': category.name,
      'subCategory': subCategory,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'firstResponseAt': firstResponseAt?.toIso8601String(),
      'lastCustomerResponseAt': lastCustomerResponseAt?.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'tags': tags,
      'attachments': attachments,
      'assignedTo': assignedTo,
      'assignedByName': assignedByName,
      'department': department,
      'history': history.map((event) => event.toJson()).toList(),
      'metadata': metadata,
      'satisfactionRating': satisfactionRating,
      'satisfactionComments': satisfactionComments,
      'relatedTickets': relatedTickets,
      'escalationLevel': escalationLevel,
      'slaDeadline': slaDeadline?.toIso8601String(),
      'isEscalated': isEscalated,
      'source': source,
      'customFields': customFields,
    };
  }
}

enum MessageType {
  user,
  support,
  system,
  automated,
}

class MessageAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String mimeType;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String description;
  final bool isPublic;

  MessageAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploadedBy,
    this.description = '',
    this.isPublic = false,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      uploadedBy: json['uploadedBy'],
      description: json['description'] ?? '',
      isPublic: json['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
      'description': description,
      'isPublic': isPublic,
    };
  }
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final MessageType senderType;
  final String content;
  final String contentType; // text, html, markdown
  final DateTime timestamp;
  final DateTime? readAt;
  final List<String> attachments;
  final List<MessageAttachment> attachmentDetails;
  final bool isInternal;
  final bool isRead;
  final String replyToMessageId;
  final Map<String, dynamic> metadata;
  final String ipAddress;
  final String userAgent;
  final List<String> ccRecipients;
  final List<String> bccRecipients;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    this.senderEmail = '',
    required this.senderType,
    required this.content,
    this.contentType = 'text',
    required this.timestamp,
    this.readAt,
    required this.attachments,
    this.attachmentDetails = const [],
    required this.isInternal,
    this.isRead = false,
    this.replyToMessageId = '',
    this.metadata = const {},
    this.ipAddress = '',
    this.userAgent = '',
    this.ccRecipients = const [],
    this.bccRecipients = const [],
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      ticketId: json['ticketId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderEmail: json['senderEmail'] ?? '',
      senderType: MessageType.values.firstWhere(
        (t) => t.name == json['senderType'],
        orElse: () => MessageType.user,
      ),
      content: json['content'],
      contentType: json['contentType'] ?? 'text',
      timestamp: DateTime.parse(json['timestamp']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      attachments: List<String>.from(json['attachments'] ?? []),
      attachmentDetails: (json['attachmentDetails'] as List<dynamic>?)
          ?.map((att) => MessageAttachment.fromJson(att))
          .toList() ?? [],
      isInternal: json['isInternal'] ?? false,
      isRead: json['isRead'] ?? false,
      replyToMessageId: json['replyToMessageId'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      ipAddress: json['ipAddress'] ?? '',
      userAgent: json['userAgent'] ?? '',
      ccRecipients: List<String>.from(json['ccRecipients'] ?? []),
      bccRecipients: List<String>.from(json['bccRecipients'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderType': senderType.name,
      'content': content,
      'contentType': contentType,
      'timestamp': timestamp.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'attachments': attachments,
      'attachmentDetails': attachmentDetails.map((att) => att.toJson()).toList(),
      'isInternal': isInternal,
      'isRead': isRead,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'ccRecipients': ccRecipients,
      'bccRecipients': bccRecipients,
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
