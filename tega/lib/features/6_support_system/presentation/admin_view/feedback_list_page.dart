import 'package:flutter/material.dart';

import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/6_support_system/data/models/support_ticket_model.dart'
    as support_models;
import 'package:tega/features/6_support_system/data/repositories/support_repository.dart';

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({super.key});

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage>
    with SingleTickerProviderStateMixin {
  final SupportService _supportService = SupportService.instance;
  late TabController _tabController;

  List<support_models.Feedback> _allFeedback = [];
  List<support_models.Feedback> _filteredFeedback = [];
  bool _isLoading = true;

  final List<String> _tabs = ['All', 'To Do', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final feedback = await _supportService.getAllFeedback();
      setState(() {
        _allFeedback = feedback;
        _filteredFeedback = feedback;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load feedback: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _filterFeedbackByTab(int index) {
    setState(() {
      switch (index) {
        case 0: // All
          _filteredFeedback = _allFeedback;
          break;
        case 1: // To Do
          _filteredFeedback = _allFeedback
              .where((f) => f.status == 'new')
              .toList();
          break;
        case 2: // In Progress
          _filteredFeedback = _allFeedback
              .where((f) => f.status == 'in_progress')
              .toList();
          break;
        case 3: // Done
          _filteredFeedback = _allFeedback
              .where((f) => f.status == 'completed')
              .toList();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text(
          'Feedback',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          onTap: _filterFeedbackByTab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _filteredFeedback.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No feedback found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No feedback items match the current filter',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFeedback.length,
              itemBuilder: (context, index) {
                return _buildFeedbackItem(_filteredFeedback[index]);
              },
            ),
    );
  }

  Widget _buildFeedbackItem(support_models.Feedback feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFeedbackIconColor(feedback.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFeedbackIcon(feedback.type),
            color: _getFeedbackIconColor(feedback.type),
            size: 24,
          ),
        ),
        title: Text(
          feedback.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'User: ${feedback.userName}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(feedback.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _supportService.getStatusDisplayName(feedback.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(feedback.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getFeedbackIconColor(
                      feedback.type,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _supportService.getTypeDisplayName(feedback.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getFeedbackIconColor(feedback.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: () {
          _showFeedbackDetails(feedback);
        },
      ),
    );
  }

  IconData _getFeedbackIcon(String type) {
    switch (type) {
      case 'bug_report':
        return Icons.bug_report;
      case 'feature_request':
        return Icons.lightbulb;
      case 'improvement':
        return Icons.trending_up;
      case 'positive':
        return Icons.thumb_up;
      default:
        return Icons.feedback;
    }
  }

  Color _getFeedbackIconColor(String type) {
    switch (type) {
      case 'bug_report':
        return AppColors.error;
      case 'feature_request':
        return AppColors.info;
      case 'improvement':
        return AppColors.warning;
      case 'positive':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showFeedbackDetails(support_models.Feedback feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feedback.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.description,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'User: ${feedback.userName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_supportService.getStatusDisplayName(feedback.status)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${_supportService.getTypeDisplayName(feedback.type)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(feedback.createdAt)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (feedback.status == 'new')
            ElevatedButton(
              onPressed: () async {
                await _supportService.updateFeedbackStatus(
                  feedback.id,
                  'in_progress',
                );
                Navigator.of(context).pop();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback status updated to In Progress'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.pureWhite,
              ),
              child: const Text('Start Working'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
