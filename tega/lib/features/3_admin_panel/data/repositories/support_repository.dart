import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tega/features/3_admin_panel/data/models/support_ticket_model.dart';

class SupportService {
  static SupportService? _instance;
  static SupportService get instance => _instance ??= SupportService._();

  SupportService._();

  List<SupportTicket> _tickets = [];
  List<Feedback> _feedback = [];
  SupportStatistics? _statistics;
  bool _isLoaded = false;

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

  Future<List<SupportTicket>> getTicketsByStatus(String status) async {
    await loadData();
    return _tickets.where((ticket) => ticket.status == status).toList();
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

  Future<bool> updateTicketStatus(String ticketId, String status) async {
    await loadData();
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index != -1) {
      final updatedTicket = SupportTicket(
        id: _tickets[index].id,
        title: _tickets[index].title,
        description: _tickets[index].description,
        status: status,
        priority: _tickets[index].priority,
        category: _tickets[index].category,
        userId: _tickets[index].userId,
        userName: _tickets[index].userName,
        userEmail: _tickets[index].userEmail,
        createdAt: _tickets[index].createdAt,
        updatedAt: DateTime.now(),
        messages: _tickets[index].messages,
        tags: _tickets[index].tags,
      );
      _tickets[index] = updatedTicket;
      return true;
    }
    return false;
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
}
