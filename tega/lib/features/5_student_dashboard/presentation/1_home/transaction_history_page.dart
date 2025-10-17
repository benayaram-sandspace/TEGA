import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/transaction_history_service.dart';
import '../../../1_authentication/data/auth_repository.dart';
import '../../../../core/constants/api_constants.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionHistoryService _transactionService =
      TransactionHistoryService();

  List<Transaction> _transactions = [];
  TransactionStats _stats = TransactionStats.empty();
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _transactionService.clearDummyData(); // Ensure only real data is shown
  }

  Future<String> _getStudentName() async {
    try {
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final userData = data['data'];
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          return '$firstName $lastName'.trim();
        }
      }
      return 'Student';
    } catch (e) {
      return 'Student';
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final transactions = await _transactionService.getTransactionHistory();
      final stats = await _transactionService.getTransactionStats();

      setState(() {
        _transactions = transactions;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Transaction> get _filteredTransactions {
    var filtered = _transactions;

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((transaction) {
        switch (_selectedFilter) {
          case 'Completed':
            return transaction.status.toLowerCase() == 'completed' ||
                transaction.status.toLowerCase() == 'success' ||
                transaction.status.toLowerCase() == 'paid';
          case 'Failed':
            return transaction.status.toLowerCase() == 'failed' ||
                transaction.status.toLowerCase() == 'error';
          case 'Pending':
            return transaction.status.toLowerCase() == 'pending';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.courseName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (transaction.transactionId?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            transaction.paymentMethod.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Combined Header and Stats Section
        _buildCombinedHeaderAndStats(),
        const SizedBox(height: 16),
        // Search and Filter Section
        _buildSearchAndFilters(),
        const SizedBox(height: 16),
        // Transaction List
        Expanded(child: _buildTransactionList()),
      ],
    );
  }

  Widget _buildCombinedHeaderAndStats() {
    final total = _stats.totalTransactions;
    final completed = _transactions
        .where(
          (t) =>
              t.status.toLowerCase() == 'completed' ||
              t.status.toLowerCase() == 'success' ||
              t.status.toLowerCase() == 'paid',
        )
        .length;
    final completionRate = total > 0 ? (completed / total) : 0.0;
    final totalSpent = _stats.totalSpent;
    final avgTransaction = total > 0 ? totalSpent / total : 0.0;
    final latestTransaction = _transactions.isNotEmpty
        ? _transactions.first
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info and Actions
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF3498DB),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<String>(
                      future: _getStudentName(),
                      builder: (context, snapshot) {
                        final studentName = snapshot.data ?? 'Loading...';
                        return Text(
                          studentName,
                          style: const TextStyle(
                            color: Color(0xFF3498DB),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Refresh Button
                    _buildActionButton(
                      'Refresh',
                      Icons.refresh,
                      () => _loadData(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Bottom Row with timestamp and live updates
                Row(
                  children: [
                    Text(
                      'Updated: ${DateTime.now().toString().substring(11, 19)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // Live Updates Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.wifi, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Live Updates',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Transaction Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Stats Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Progress Ring Section
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: completionRate,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(completionRate * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Success',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$total\nTransactions',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),

                    // Stats Details - Moved more to the right
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Total Spent
                          _buildStatRow(
                            Icons.account_balance_wallet,
                            '₹${totalSpent.toStringAsFixed(0)}',
                            'Total Spent',
                          ),
                          const SizedBox(height: 16),

                          // Average Transaction
                          _buildStatRow(
                            Icons.trending_up,
                            '₹${avgTransaction.toStringAsFixed(0)}',
                            'Average Transaction',
                          ),
                          const SizedBox(height: 16),

                          // Pending Count
                          _buildStatRow(
                            Icons.access_time,
                            '${_stats.pendingCount}',
                            'Pending Transactions',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Recent Activity Section
                if (latestTransaction != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Latest Transaction',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latestTransaction.courseName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    latestTransaction.formattedAmount,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${latestTransaction.timeAgo}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3498DB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF9C88FF),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab(
                  'All',
                  Icons.all_inclusive,
                  _transactions.length,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  'Completed',
                  Icons.check_circle,
                  _transactions
                      .where(
                        (t) =>
                            t.status.toLowerCase() == 'completed' ||
                            t.status.toLowerCase() == 'success' ||
                            t.status.toLowerCase() == 'paid',
                      )
                      .length,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  'Failed',
                  Icons.error,
                  _transactions
                      .where(
                        (t) =>
                            t.status.toLowerCase() == 'failed' ||
                            t.status.toLowerCase() == 'error',
                      )
                      .length,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  'Pending',
                  Icons.access_time,
                  _transactions
                      .where((t) => t.status.toLowerCase() == 'pending')
                      .length,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C88FF) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C88FF)
                : const Color(0xFFE9ECEF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6C757D),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6C757D),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String value, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final filteredTransactions = _filteredTransactions;

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        itemCount: filteredTransactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transaction.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  transaction.statusIcon,
                  color: transaction.statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      transaction.paymentMethod,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    transaction.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status and Details Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: TextStyle(
                    color: transaction.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (transaction.transactionId != null)
                Text(
                  'ID: ${transaction.transactionId!.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6C757D),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 40,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You haven\'t made any transactions yet. Complete a payment to see your transaction history here.\n\nOnly real transactions from the database are displayed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
              ),
              const SizedBox(height: 20),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C88FF), Color(0xFF7A6BFF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C88FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      // Navigate to courses or payment page
                    },
                    child: const Center(
                      child: Text(
                        'Make Your First Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE74C3C)),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
