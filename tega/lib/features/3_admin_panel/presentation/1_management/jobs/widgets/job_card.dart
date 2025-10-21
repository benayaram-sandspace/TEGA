import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onStatusUpdate;

  const JobCard({
    super.key,
    required this.job,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(
                          11,
                        ), // 11 to account for 1px border
                        topRight: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['title'] ?? 'Untitled Job',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job['company'] ?? 'Unknown Company',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Details (Using Wrap for responsiveness)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _buildInfoChip(
                              Icons.location_on,
                              job['location'] ?? 'Not specified',
                              const Color(0xFF4299E1),
                            ),
                            _buildInfoChip(
                              Icons.work,
                              job['jobType'] ?? 'full-time',
                              const Color(0xFF48BB78),
                            ),
                            _buildInfoChip(
                              Icons.category,
                              job['postingType'] ?? 'job',
                              const Color(0xFFED8936),
                            ),
                          ],
                        ),
                        if (job['salary'] != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₹${NumberFormat('#,##,###').format(job['salary'])}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (job['description'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            job['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (job['deadline'] != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Deadline: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(job['deadline']))}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Action Buttons (Using Wrap for responsiveness)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            OutlinedButton.icon(
                              onPressed: onView,
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('View'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B5FFF),
                                side: const BorderSide(
                                  color: Color(0xFF6B5FFF),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4299E1),
                                side: const BorderSide(
                                  color: Color(0xFF4299E1),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'status':
                                    onStatusUpdate();
                                    break;
                                  case 'delete':
                                    onDelete();
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'status',
                                  child: Row(
                                    children: [
                                      Icon(Icons.update, size: 16),
                                      SizedBox(width: 8),
                                      Text('Update Status'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Icon(Icons.more_vert, size: 16),
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
          ),
        );
      },
    );
  }

  Widget _buildStatusChip() {
    final status = job['status'] ?? 'open';
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    final status = job['status'] ?? 'open';
    switch (status) {
      case 'open':
        return const Color(0xFF48BB78);
      case 'active':
        return const Color(0xFF4299E1);
      case 'closed':
        return const Color(0xFFF56565);
      case 'paused':
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF718096);
    }
  }
}
