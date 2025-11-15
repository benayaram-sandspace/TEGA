import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/transaction_history_service.dart';
import '../../../1_authentication/data/auth_repository.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:tega/core/services/transaction_history_cache_service.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionHistoryService _transactionService =
      TransactionHistoryService();
  final TransactionHistoryCacheService _cacheService = TransactionHistoryCacheService();

  List<Transaction> _transactions = [];
  TransactionStats _stats = TransactionStats.empty();
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _transactionService.clearDummyData(); // Ensure only real data is shown
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadData();
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  Future<String> _getStudentName() async {
    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();

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

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedTransactions = await _cacheService.getTransactionsData();
      final cachedStats = await _cacheService.getStatsData();
      
      if (cachedTransactions != null && cachedStats != null && mounted) {
        setState(() {
          _transactions = cachedTransactions
              .map((json) => Transaction.fromJson(json))
              .toList();
          _stats = TransactionStats(
            totalTransactions: cachedStats['totalTransactions'] ?? 0,
            successRate: (cachedStats['successRate'] ?? 0).toDouble(),
            pendingCount: cachedStats['pendingCount'] ?? 0,
            totalSpent: (cachedStats['totalSpent'] ?? 0).toDouble(),
          );
          _isLoading = false;
          _error = null;
        });
        // Still fetch in background to update cache
        _fetchTransactionsInBackground();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Fetch from API
    await _fetchTransactionsInBackground();
  }

  Future<void> _fetchTransactionsInBackground() async {
    try {
      final transactions = await _transactionService.getTransactionHistory();
      final stats = await _transactionService.getTransactionStats();

      // Cache transactions data
      final transactionsJson = transactions.map((t) => {
        'id': t.id,
        'courseId': t.courseId,
        'courseName': t.courseName,
        'amount': t.amount,
        'currency': t.currency,
        'paymentMethod': t.paymentMethod,
        'status': t.status,
        'transactionId': t.transactionId,
        'createdAt': t.createdAt.toIso8601String(),
        'paymentDate': t.paymentDate?.toIso8601String(),
        'description': t.description,
        'source': t.source,
      }).toList();
      await _cacheService.setTransactionsData(transactionsJson);

      // Cache stats data
      await _cacheService.setStatsData({
        'totalTransactions': stats.totalTransactions,
        'successRate': stats.successRate,
        'pendingCount': stats.pendingCount,
        'totalSpent': stats.totalSpent,
      });

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _stats = stats;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedTransactions = await _cacheService.getTransactionsData();
          final cachedStats = await _cacheService.getStatsData();
          
          if (cachedTransactions != null && cachedStats != null) {
            setState(() {
              _transactions = cachedTransactions
                  .map((json) => Transaction.fromJson(json))
                  .toList();
              _stats = TransactionStats(
                totalTransactions: cachedStats['totalTransactions'] ?? 0,
                successRate: (cachedStats['successRate'] ?? 0).toDouble(),
                pendingCount: cachedStats['pendingCount'] ?? 0,
                totalSpent: (cachedStats['totalSpent'] ?? 0).toDouble(),
              );
              _error = null; // Clear error since we have cached data
              _isLoading = false;
            });
            return;
          }
          // No cache available, show error
          setState(() {
            _error = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Unable to load transactions. Please try again.';
            _isLoading = false;
          });
        }
      }
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

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          color: const Color(0xFF9C88FF),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C88FF)),
                    strokeWidth: isLargeDesktop
                        ? 4
                        : isDesktop
                        ? 3.5
                        : isTablet
                        ? 3
                        : isSmallScreen
                        ? 2.5
                        : 3,
                  ),
                )
              : _error != null
              ? _buildErrorState()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Combined Header and Stats Section
          _buildCombinedHeaderAndStats(),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 18
                : isSmallScreen
                ? 12
                : 16,
          ),
          // Filter Section
          _buildFilters(),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 18
                : isSmallScreen
                ? 12
                : 16,
          ),
          // Transaction List
          _buildTransactionList(),
          SizedBox(
            height: isLargeDesktop
                ? 32
                : isDesktop
                ? 28
                : isTablet
                ? 24
                : isSmallScreen
                ? 16
                : 20,
          ), // Bottom padding for better scrolling
        ],
      ),
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
                      () => _loadData(forceRefresh: true),
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

  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 12
            : 16,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 14,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 16
                : isDesktop
                ? 12
                : isTablet
                ? 10
                : isSmallScreen
                ? 6
                : 8,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 4
                  : isDesktop
                  ? 3
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1
                  : 2,
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTab(
              'All',
              Icons.all_inclusive,
              _transactions.length,
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 8
                  : isSmallScreen
                  ? 6
                  : 7,
            ),
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
            SizedBox(
              width: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 8
                  : isSmallScreen
                  ? 6
                  : 7,
            ),
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
            SizedBox(
              width: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 8
                  : isSmallScreen
                  ? 6
                  : 7,
            ),
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
        height: isLargeDesktop
            ? 44
            : isDesktop
            ? 40
            : isTablet
            ? 38
            : isSmallScreen
            ? 32
            : 36,
        padding: EdgeInsets.symmetric(
          horizontal: isLargeDesktop
              ? 18
              : isDesktop
              ? 16
              : isTablet
              ? 14
              : isSmallScreen
              ? 10
              : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C88FF) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 22
                : isDesktop
                ? 20
                : isTablet
                ? 18
                : isSmallScreen
                ? 16
                : 18,
          ),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C88FF)
                : const Color(0xFFE9ECEF),
            width: isLargeDesktop || isDesktop
                ? 1.5
                : isTablet
                ? 1.2
                : isSmallScreen
                ? 0.8
                : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6C757D),
              size: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 14
                  : 15,
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 8
                  : isDesktop
                  ? 7
                  : isTablet
                  ? 6
                  : isSmallScreen
                  ? 4
                  : 5,
            ),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6C757D),
                fontSize: isLargeDesktop
                    ? 15
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 13
                    : isSmallScreen
                    ? 11
                    : 12,
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
      child: Column(
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C88FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF9C88FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              Text(
                '${filteredTransactions.length} transactions',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transaction Cards
          ...filteredTransactions.map((transaction) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTransactionCard(transaction),
          )),
        ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
    final isNoInternet = _error == 'No internet connection';
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 48
              : isDesktop
              ? 40
              : isTablet
              ? 36
              : isSmallScreen
              ? 24
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isLargeDesktop
                  ? 80
                  : isDesktop
                  ? 72
                  : isTablet
                  ? 64
                  : isSmallScreen
                  ? 48
                  : 56,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            Text(
              isNoInternet
                  ? 'No internet connection'
                  : 'Failed to Load Transactions',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 16
                    : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (isNoInternet) ...[
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
              ),
            ] else ...[
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                _error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
              ),
            ],
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 24,
            ),
            ElevatedButton.icon(
              onPressed: () => _loadData(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
                color: Colors.white,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 13
                      : 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 28
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 16
                      : 20,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 11
                        : isTablet
                        ? 10
                        : isSmallScreen
                        ? 8
                        : 9,
                  ),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
