import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class TransactionHistoryService {
  static final TransactionHistoryService _instance =
      TransactionHistoryService._internal();
  factory TransactionHistoryService() => _instance;
  TransactionHistoryService._internal();

  final AuthService _authService = AuthService();

  /// Get user's payment history from all sources
  Future<List<Transaction>> getTransactionHistory() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final List<Transaction> allTransactions = [];

      // Fetch from payment history endpoint
      final futures = [_fetchPaymentHistory(headers)];

      final results = await Future.wait(futures);

      for (final transactions in results) {
        allTransactions.addAll(transactions);
      }

      // Sort by date (newest first)
      allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allTransactions;
    } catch (e) {
      debugPrint('Error fetching transaction history: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> _fetchPaymentHistory(
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.paymentHistory),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> transactionsJson = data['data'];
          return transactionsJson
              .map((json) => Transaction.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  /// Get transaction statistics
  Future<TransactionStats> getTransactionStats() async {
    try {
      final transactions = await getTransactionHistory();
      return TransactionStats.fromTransactions(transactions);
    } catch (e) {
      debugPrint('Error calculating transaction stats: $e');
      return TransactionStats.empty();
    }
  }

  /// Clear any dummy/test data (for development purposes)
  Future<void> clearDummyData() async {
    try {
      // Note: This would require backend endpoints to clear dummy data
      // For now, we'll just ensure only real data is shown
    } catch (e) {
      debugPrint('Error clearing dummy data: $e');
    }
  }
}

/// Transaction data model
class Transaction {
  final String id;
  final String courseId;
  final String courseName;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? paymentDate;
  final String? description;
  final String source; // 'payment', 'razorpay', 'tega_exam'

  Transaction({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.paymentDate,
    this.description,
    required this.source,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? 'Unknown Course',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      paymentMethod: json['paymentMethod'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      transactionId: json['transactionId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      description: json['description'],
      source: json['source'] ?? 'payment',
    );
  }

  /// Get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'failed':
      case 'error':
        return const Color(0xFFF44336);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Get status icon
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'paid':
        return Icons.check_circle;
      case 'failed':
      case 'error':
        return Icons.error;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  /// Get formatted amount
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get formatted date
  String get formattedDate {
    final date = paymentDate ?? createdAt;
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get relative time
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Transaction statistics model
class TransactionStats {
  final int totalTransactions;
  final double successRate;
  final int pendingCount;
  final double totalSpent;

  TransactionStats({
    required this.totalTransactions,
    required this.successRate,
    required this.pendingCount,
    required this.totalSpent,
  });

  factory TransactionStats.fromTransactions(List<Transaction> transactions) {
    final total = transactions.length;
    final completed = transactions
        .where(
          (t) =>
              t.status.toLowerCase() == 'completed' ||
              t.status.toLowerCase() == 'success' ||
              t.status.toLowerCase() == 'paid',
        )
        .length;
    final pending = transactions
        .where((t) => t.status.toLowerCase() == 'pending')
        .length;
    final totalSpent = transactions
        .where(
          (t) =>
              t.status.toLowerCase() == 'completed' ||
              t.status.toLowerCase() == 'success' ||
              t.status.toLowerCase() == 'paid',
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    return TransactionStats(
      totalTransactions: total,
      successRate: total > 0 ? (completed / total) * 100 : 0.0,
      pendingCount: pending,
      totalSpent: totalSpent,
    );
  }

  factory TransactionStats.empty() {
    return TransactionStats(
      totalTransactions: 0,
      successRate: 0.0,
      pendingCount: 0,
      totalSpent: 0.0,
    );
  }

  String get formattedTotalSpent => '₹${totalSpent.toStringAsFixed(2)}';
  String get formattedSuccessRate => '${successRate.toStringAsFixed(1)}%';
}
