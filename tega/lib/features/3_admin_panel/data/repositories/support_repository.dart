import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tega/features/3_admin_panel/data/models/support_ticket_model.dart';

class SupportRepository {
  static SupportRepository? _instance;
  static SupportRepository get instance => _instance ??= SupportRepository._();

  SupportRepository._();

  List<SupportTicket> _tickets = [];
  List<Feedback> _feedback = [];
  List<TicketEvent> _ticketEvents = [];
  SupportStatistics? _statistics;
  bool _isLoaded = false;
  String? _currentUserId;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/support_data.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _statistics = SupportStatistics.fromJson(jsonData['statistics']);

      _tickets = (jsonData['tickets'] as List<dynamic>)
          .map((ticket) => SupportTicket.fromJson(ticket))
          .toList();

      _feedback = (jsonData['feedback'] as List<dynamic>)
          .map((feedback) => Feedback.fromJson(feedback))
          .toList();

      _isLoaded = true;
    } catch (e) {
      throw Exception('Failed to load support data: $e');
    }
  }

  // Statistics
  Future<SupportStatistics> getStatistics() async {
    await loadData();
    return _statistics!;
  }

  // Tickets
  Future<List<SupportTicket>> getAllTickets() async {
    await loadData();
    return List.from(_tickets);
  }

  Future<List<SupportTicket>> getTicketsByStatus(TicketStatus status) async {
    await loadData();
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  Future<List<SupportTicket>> getTicketsByPriority(TicketPriority priority) async {
    await loadData();
    return _tickets.where((ticket) => ticket.priority == priority).toList();
  }

  Future<List<SupportTicket>> getTicketsByCategory(TicketCategory category) async {
    await loadData();
    return _tickets.where((ticket) => ticket.category == category).toList();
  }

  Future<List<SupportTicket>> getTicketsByAssignee(String assigneeId) async {
    await loadData();
    return _tickets.where((ticket) => ticket.assignedTo == assigneeId).toList();
  }

  Future<List<SupportTicket>> getTicketsByUser(String userId) async {
    await loadData();
    return _tickets.where((ticket) => ticket.userId == userId).toList();
  }

  Future<List<SupportTicket>> getEscalatedTickets() async {
    await loadData();
    return _tickets.where((ticket) => ticket.isEscalated).toList();
  }

  Future<List<SupportTicket>> getOverdueTickets() async {
    await loadData();
    final now = DateTime.now();
    return _tickets.where((ticket) => 
      ticket.slaDeadline != null && 
      ticket.slaDeadline!.isBefore(now) && 
      ticket.status != TicketStatus.closed && 
      ticket.status != TicketStatus.resolved
    ).toList();
  }

  Future<SupportTicket?> getTicketById(String id) async {
    await loadData();
    try {
      return _tickets.firstWhere((ticket) => ticket.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<SupportTicket>> searchTickets(String query) async {
    await loadData();
    final lowercaseQuery = query.toLowerCase();
    return _tickets.where((ticket) {
      return ticket.title.toLowerCase().contains(lowercaseQuery) ||
          ticket.description.toLowerCase().contains(lowercaseQuery) ||
          ticket.userName.toLowerCase().contains(lowercaseQuery) ||
          ticket.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Enhanced CRUD operations
  Future<bool> createTicket(SupportTicket ticket) async {
    try {
      await loadData();
      _tickets.add(ticket);
      await _logTicketEvent(
        ticketId: ticket.id,
        action: 'Ticket Created',
        description: 'New support ticket created',
        eventType: 'creation',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTicketStatus(String ticketId, TicketStatus status, {String? performedBy, String? performedByName}) async {
    try {
      await loadData();
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        final oldTicket = _tickets[index];
        final updatedTicket = SupportTicket(
          id: oldTicket.id,
          ticketNumber: oldTicket.ticketNumber,
          title: oldTicket.title,
          description: oldTicket.description,
          detailedDescription: oldTicket.detailedDescription,
          status: status,
          priority: oldTicket.priority,
          category: oldTicket.category,
          subCategory: oldTicket.subCategory,
          userId: oldTicket.userId,
          userName: oldTicket.userName,
          userEmail: oldTicket.userEmail,
          userPhone: oldTicket.userPhone,
          createdAt: oldTicket.createdAt,
          updatedAt: DateTime.now(),
          firstResponseAt: oldTicket.firstResponseAt,
          lastCustomerResponseAt: oldTicket.lastCustomerResponseAt,
          messages: oldTicket.messages,
          tags: oldTicket.tags,
          attachments: oldTicket.attachments,
          assignedTo: oldTicket.assignedTo,
          assignedByName: oldTicket.assignedByName,
          department: oldTicket.department,
          history: oldTicket.history,
          metadata: oldTicket.metadata,
          satisfactionRating: oldTicket.satisfactionRating,
          satisfactionComments: oldTicket.satisfactionComments,
          relatedTickets: oldTicket.relatedTickets,
          escalationLevel: oldTicket.escalationLevel,
          slaDeadline: oldTicket.slaDeadline,
          isEscalated: oldTicket.isEscalated,
          source: oldTicket.source,
          customFields: oldTicket.customFields,
        );
        _tickets[index] = updatedTicket;
        
        await _logTicketEvent(
          ticketId: ticketId,
          action: 'Status Changed',
          description: 'Status changed from ${oldTicket.status.name} to ${status.name}',
          eventType: 'status_change',
          performedBy: performedBy ?? _currentUserId ?? '',
          performedByName: performedByName ?? 'System',
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignTicket(String ticketId, String assigneeId, String assigneeName) async {
    try {
      await loadData();
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        final oldTicket = _tickets[index];
        final updatedTicket = SupportTicket(
          id: oldTicket.id,
          ticketNumber: oldTicket.ticketNumber,
          title: oldTicket.title,
          description: oldTicket.description,
          detailedDescription: oldTicket.detailedDescription,
          status: oldTicket.status,
          priority: oldTicket.priority,
          category: oldTicket.category,
          subCategory: oldTicket.subCategory,
          userId: oldTicket.userId,
          userName: oldTicket.userName,
          userEmail: oldTicket.userEmail,
          userPhone: oldTicket.userPhone,
          createdAt: oldTicket.createdAt,
          updatedAt: DateTime.now(),
          firstResponseAt: oldTicket.firstResponseAt,
          lastCustomerResponseAt: oldTicket.lastCustomerResponseAt,
          messages: oldTicket.messages,
          tags: oldTicket.tags,
          attachments: oldTicket.attachments,
          assignedTo: assigneeId,
          assignedByName: assigneeName,
          department: oldTicket.department,
          history: oldTicket.history,
          metadata: oldTicket.metadata,
          satisfactionRating: oldTicket.satisfactionRating,
          satisfactionComments: oldTicket.satisfactionComments,
          relatedTickets: oldTicket.relatedTickets,
          escalationLevel: oldTicket.escalationLevel,
          slaDeadline: oldTicket.slaDeadline,
          isEscalated: oldTicket.isEscalated,
          source: oldTicket.source,
          customFields: oldTicket.customFields,
        );
        _tickets[index] = updatedTicket;
        
        await _logTicketEvent(
          ticketId: ticketId,
          action: 'Ticket Assigned',
          description: 'Ticket assigned to $assigneeName',
          eventType: 'assignment',
          performedBy: _currentUserId ?? '',
          performedByName: 'System',
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> escalateTicket(String ticketId, String newLevel) async {
    try {
      await loadData();
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        final oldTicket = _tickets[index];
        final updatedTicket = SupportTicket(
          id: oldTicket.id,
          ticketNumber: oldTicket.ticketNumber,
          title: oldTicket.title,
          description: oldTicket.description,
          detailedDescription: oldTicket.detailedDescription,
          status: oldTicket.status,
          priority: oldTicket.priority,
          category: oldTicket.category,
          subCategory: oldTicket.subCategory,
          userId: oldTicket.userId,
          userName: oldTicket.userName,
          userEmail: oldTicket.userEmail,
          userPhone: oldTicket.userPhone,
          createdAt: oldTicket.createdAt,
          updatedAt: DateTime.now(),
          firstResponseAt: oldTicket.firstResponseAt,
          lastCustomerResponseAt: oldTicket.lastCustomerResponseAt,
          messages: oldTicket.messages,
          tags: oldTicket.tags,
          attachments: oldTicket.attachments,
          assignedTo: oldTicket.assignedTo,
          assignedByName: oldTicket.assignedByName,
          department: oldTicket.department,
          history: oldTicket.history,
          metadata: oldTicket.metadata,
          satisfactionRating: oldTicket.satisfactionRating,
          satisfactionComments: oldTicket.satisfactionComments,
          relatedTickets: oldTicket.relatedTickets,
          escalationLevel: newLevel,
          slaDeadline: oldTicket.slaDeadline,
          isEscalated: true,
          source: oldTicket.source,
          customFields: oldTicket.customFields,
        );
        _tickets[index] = updatedTicket;
        
        await _logTicketEvent(
          ticketId: ticketId,
          action: 'Ticket Escalated',
          description: 'Ticket escalated to $newLevel',
          eventType: 'escalation',
          performedBy: _currentUserId ?? '',
          performedByName: 'System',
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMessageToTicket(
    String ticketId,
    SupportMessage message,
  ) async {
    await loadData();
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index != -1) {
      final updatedMessages = List<SupportMessage>.from(
        _tickets[index].messages,
      );
      updatedMessages.add(message);

      final updatedTicket = SupportTicket(
        id: _tickets[index].id,
        title: _tickets[index].title,
        description: _tickets[index].description,
        status: _tickets[index].status,
        priority: _tickets[index].priority,
        category: _tickets[index].category,
        userId: _tickets[index].userId,
        ticketNumber: _tickets[index].ticketNumber,
        history: _tickets[index].history,
        userName: _tickets[index].userName,
        userEmail: _tickets[index].userEmail,
        createdAt: _tickets[index].createdAt,
        updatedAt: DateTime.now(),
        messages: updatedMessages,
        tags: _tickets[index].tags,
      );
      _tickets[index] = updatedTicket;
      return true;
    }
    return false;
  }

  // Feedback
  Future<List<Feedback>> getAllFeedback() async {
    await loadData();
    return List.from(_feedback);
  }

  Future<List<Feedback>> getFeedbackByStatus(String status) async {
    await loadData();
    return _feedback.where((feedback) => feedback.status == status).toList();
  }

  Future<List<Feedback>> getFeedbackByType(String type) async {
    await loadData();
    return _feedback.where((feedback) => feedback.type == type).toList();
  }

  Future<Feedback?> getFeedbackById(String id) async {
    await loadData();
    try {
      return _feedback.firstWhere((feedback) => feedback.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Feedback>> searchFeedback(String query) async {
    await loadData();
    final lowercaseQuery = query.toLowerCase();
    return _feedback.where((feedback) {
      return feedback.title.toLowerCase().contains(lowercaseQuery) ||
          feedback.description.toLowerCase().contains(lowercaseQuery) ||
          feedback.userName.toLowerCase().contains(lowercaseQuery) ||
          feedback.tags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  Future<bool> updateFeedbackStatus(String feedbackId, String status) async {
    await loadData();
    final index = _feedback.indexWhere((feedback) => feedback.id == feedbackId);
    if (index != -1) {
      final updatedFeedback = Feedback(
        id: _feedback[index].id,
        title: _feedback[index].title,
        description: _feedback[index].description,
        type: _feedback[index].type,
        status: status,
        userId: _feedback[index].userId,
        userName: _feedback[index].userName,
        createdAt: _feedback[index].createdAt,
        updatedAt: DateTime.now(),
        tags: _feedback[index].tags,
        priority: _feedback[index].priority,
      );
      _feedback[index] = updatedFeedback;
      return true;
    }
    return false;
  }

  // Recent feedback for overview
  Future<List<Feedback>> getRecentFeedback({int limit = 3}) async {
    await loadData();
    final sortedFeedback = List<Feedback>.from(_feedback);
    sortedFeedback.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedFeedback.take(limit).toList();
  }

  // Helper methods
  String getStatusDisplayName(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'new':
        return 'New';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String getPriorityDisplayName(String priority) {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'bug':
        return 'Bug Report';
      case 'feature_request':
        return 'Feature Request';
      case 'general':
        return 'General';
      case 'technical':
        return 'Technical';
      default:
        return category;
    }
  }

  String getTypeDisplayName(String type) {
    switch (type) {
      case 'bug_report':
        return 'Bug Report';
      case 'feature_request':
        return 'Feature Request';
      case 'improvement':
        return 'Improvement';
      case 'positive':
        return 'Positive Feedback';
      default:
        return type;
    }
  }

  // Analytics and Reporting
  Future<Map<String, dynamic>> getTicketAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? assigneeId,
    TicketCategory? category,
  }) async {
    await loadData();
    
    var filteredTickets = _tickets;
    
    if (startDate != null) {
      filteredTickets = filteredTickets.where((t) => t.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filteredTickets = filteredTickets.where((t) => t.createdAt.isBefore(endDate)).toList();
    }
    if (assigneeId != null) {
      filteredTickets = filteredTickets.where((t) => t.assignedTo == assigneeId).toList();
    }
    if (category != null) {
      filteredTickets = filteredTickets.where((t) => t.category == category).toList();
    }

    final totalTickets = filteredTickets.length;
    final openTickets = filteredTickets.where((t) => t.status == TicketStatus.open).length;
    final inProgressTickets = filteredTickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolvedTickets = filteredTickets.where((t) => t.status == TicketStatus.resolved).length;
    final closedTickets = filteredTickets.where((t) => t.status == TicketStatus.closed).length;
    final escalatedTickets = filteredTickets.where((t) => t.isEscalated).length;
    final overdueTickets = filteredTickets.where((t) => 
      t.slaDeadline != null && 
      t.slaDeadline!.isBefore(DateTime.now()) && 
      t.status != TicketStatus.closed && 
      t.status != TicketStatus.resolved
    ).length;

    final avgSatisfaction = filteredTickets
        .where((t) => t.satisfactionRating > 0)
        .map((t) => t.satisfactionRating)
        .fold(0, (sum, rating) => sum + rating) / 
        filteredTickets.where((t) => t.satisfactionRating > 0).length;

    return {
      'totalTickets': totalTickets,
      'openTickets': openTickets,
      'inProgressTickets': inProgressTickets,
      'resolvedTickets': resolvedTickets,
      'closedTickets': closedTickets,
      'escalatedTickets': escalatedTickets,
      'overdueTickets': overdueTickets,
      'resolutionRate': totalTickets > 0 ? ((resolvedTickets + closedTickets) / totalTickets) * 100 : 0,
      'escalationRate': totalTickets > 0 ? (escalatedTickets / totalTickets) * 100 : 0,
      'averageSatisfaction': avgSatisfaction.isNaN ? 0 : avgSatisfaction,
      'slaCompliance': totalTickets > 0 ? ((totalTickets - overdueTickets) / totalTickets) * 100 : 0,
    };
  }

  Future<Map<String, dynamic>> getAgentPerformance(String agentId) async {
    await loadData();
    
    final agentTickets = _tickets.where((t) => t.assignedTo == agentId).toList();
    final completedTickets = agentTickets.where((t) => 
      t.status == TicketStatus.resolved || t.status == TicketStatus.closed
    ).toList();

    final totalTickets = agentTickets.length;
    final avgResolutionTime = completedTickets.isNotEmpty 
        ? completedTickets.map((t) => t.updatedAt?.difference(t.createdAt)?.inHours ?? 0)
            .fold(0, (sum, hours) => sum + hours) / completedTickets.length
        : 0;

    final avgSatisfaction = completedTickets
        .where((t) => t.satisfactionRating > 0)
        .map((t) => t.satisfactionRating)
        .fold(0, (sum, rating) => sum + rating) / 
        completedTickets.where((t) => t.satisfactionRating > 0).length;

    return {
      'totalTickets': totalTickets,
      'completedTickets': completedTickets.length,
      'completionRate': totalTickets > 0 ? (completedTickets.length / totalTickets) * 100 : 0,
      'averageResolutionTime': avgResolutionTime,
      'averageSatisfaction': avgSatisfaction.isNaN ? 0 : avgSatisfaction,
      'escalatedTickets': agentTickets.where((t) => t.isEscalated).length,
    };
  }

  // Bulk Operations
  Future<bool> bulkUpdateTicketStatus(List<String> ticketIds, TicketStatus status) async {
    try {
      await loadData();
      bool allUpdated = true;
      
      for (final ticketId in ticketIds) {
        final success = await updateTicketStatus(ticketId, status);
        if (!success) allUpdated = false;
      }
      
      return allUpdated;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bulkAssignTickets(List<String> ticketIds, String assigneeId, String assigneeName) async {
    try {
      await loadData();
      bool allAssigned = true;
      
      for (final ticketId in ticketIds) {
        final success = await assignTicket(ticketId, assigneeId, assigneeName);
        if (!success) allAssigned = false;
      }
      
      return allAssigned;
    } catch (e) {
      return false;
    }
  }

  // Event Logging
  Future<void> _logTicketEvent({
    required String ticketId,
    required String action,
    required String description,
    required String eventType,
    String? performedBy,
    String? performedByName,
  }) async {
    final event = TicketEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      action: action,
      performedBy: performedBy ?? _currentUserId ?? 'system',
      performedByName: performedByName ?? 'System',
      description: description,
      eventType: eventType,
    );

    _ticketEvents.add(event);

    // Update ticket history
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      final ticket = _tickets[ticketIndex];
      final updatedHistory = List<TicketEvent>.from(ticket.history)..add(event);
      
      _tickets[ticketIndex] = SupportTicket(
        id: ticket.id,
        ticketNumber: ticket.ticketNumber,
        title: ticket.title,
        description: ticket.description,
        detailedDescription: ticket.detailedDescription,
        status: ticket.status,
        priority: ticket.priority,
        category: ticket.category,
        subCategory: ticket.subCategory,
        userId: ticket.userId,
        userName: ticket.userName,
        userEmail: ticket.userEmail,
        userPhone: ticket.userPhone,
        createdAt: ticket.createdAt,
        updatedAt: DateTime.now(),
        firstResponseAt: ticket.firstResponseAt,
        lastCustomerResponseAt: ticket.lastCustomerResponseAt,
        messages: ticket.messages,
        tags: ticket.tags,
        attachments: ticket.attachments,
        assignedTo: ticket.assignedTo,
        assignedByName: ticket.assignedByName,
        department: ticket.department,
        history: updatedHistory,
        metadata: ticket.metadata,
        satisfactionRating: ticket.satisfactionRating,
        satisfactionComments: ticket.satisfactionComments,
        relatedTickets: ticket.relatedTickets,
        escalationLevel: ticket.escalationLevel,
        slaDeadline: ticket.slaDeadline,
        isEscalated: ticket.isEscalated,
        source: ticket.source,
        customFields: ticket.customFields,
      );
    }
  }

  Future<List<TicketEvent>> getTicketHistory(String ticketId) async {
    await loadData();
    return _ticketEvents.where((event) => event.description.contains(ticketId)).toList();
  }

  // SLA Management
  Future<List<SupportTicket>> getTicketsNearSLA({int hoursThreshold = 24}) async {
    await loadData();
    final threshold = DateTime.now().add(Duration(hours: hoursThreshold));
    
    return _tickets.where((ticket) => 
      ticket.slaDeadline != null && 
      ticket.slaDeadline!.isBefore(threshold) &&
      ticket.status != TicketStatus.closed && 
      ticket.status != TicketStatus.resolved
    ).toList();
  }

  // Satisfaction Management
  Future<bool> updateSatisfactionRating(String ticketId, int rating, String comments) async {
    try {
      await loadData();
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        final oldTicket = _tickets[index];
        final updatedTicket = SupportTicket(
          id: oldTicket.id,
          ticketNumber: oldTicket.ticketNumber,
          title: oldTicket.title,
          description: oldTicket.description,
          detailedDescription: oldTicket.detailedDescription,
          status: oldTicket.status,
          priority: oldTicket.priority,
          category: oldTicket.category,
          subCategory: oldTicket.subCategory,
          userId: oldTicket.userId,
          userName: oldTicket.userName,
          userEmail: oldTicket.userEmail,
          userPhone: oldTicket.userPhone,
          createdAt: oldTicket.createdAt,
          updatedAt: DateTime.now(),
          firstResponseAt: oldTicket.firstResponseAt,
          lastCustomerResponseAt: oldTicket.lastCustomerResponseAt,
          messages: oldTicket.messages,
          tags: oldTicket.tags,
          attachments: oldTicket.attachments,
          assignedTo: oldTicket.assignedTo,
          assignedByName: oldTicket.assignedByName,
          department: oldTicket.department,
          history: oldTicket.history,
          metadata: oldTicket.metadata,
          satisfactionRating: rating,
          satisfactionComments: comments,
          relatedTickets: oldTicket.relatedTickets,
          escalationLevel: oldTicket.escalationLevel,
          slaDeadline: oldTicket.slaDeadline,
          isEscalated: oldTicket.isEscalated,
          source: oldTicket.source,
          customFields: oldTicket.customFields,
        );
        _tickets[index] = updatedTicket;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
