import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onStatusUpdate;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const JobCard({
    super.key,
    required this.job,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.onStatusUpdate,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
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
              margin: EdgeInsets.only(
                bottom: isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                    padding: EdgeInsets.all(
                      isMobile
                          ? 12
                          : isTablet
                          ? 14
                          : 16,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          isMobile
                              ? 9
                              : isTablet
                              ? 10
                              : 11,
                        ), // Account for 1px border
                        topRight: Radius.circular(
                          isMobile
                              ? 9
                              : isTablet
                              ? 10
                              : 11,
                        ),
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
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 16
                                      : isTablet
                                      ? 17
                                      : 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                                maxLines: 1, // Prevent title overflow
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isMobile ? 3 : 4),
                              Text(
                                job['company'] ?? 'Unknown Company',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 13
                                      : isTablet
                                      ? 13.5
                                      : 14,
                                  color: const Color(0xFF718096),
                                ),
                                maxLines: 1, // Prevent company overflow
                                overflow: TextOverflow.ellipsis,
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
                    padding: EdgeInsets.all(
                      isMobile
                          ? 12
                          : isTablet
                          ? 14
                          : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Details (Using Wrap for responsiveness)
                        Wrap(
                          spacing: isMobile
                              ? 6.0
                              : isTablet
                              ? 7.0
                              : 8.0,
                          runSpacing: isMobile
                              ? 6.0
                              : isTablet
                              ? 7.0
                              : 8.0,
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
                          SizedBox(
                            height: isMobile
                                ? 10
                                : isTablet
                                ? 11
                                : 12,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: isMobile
                                    ? 14
                                    : isTablet
                                    ? 15
                                    : 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: isMobile ? 3 : 4),
                              Text(
                                '₹${NumberFormat('#,##,###').format(job['salary'])}',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 13
                                      : isTablet
                                      ? 13.5
                                      : 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (job['description'] != null) ...[
                          SizedBox(
                            height: isMobile
                                ? 10
                                : isTablet
                                ? 11
                                : 12,
                          ),
                          Text(
                            job['description'],
                            style: TextStyle(
                              fontSize: isMobile
                                  ? 13
                                  : isTablet
                                  ? 13.5
                                  : 14,
                              color: const Color(0xFF4A5568),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (job['deadline'] != null) ...[
                          SizedBox(
                            height: isMobile
                                ? 10
                                : isTablet
                                ? 11
                                : 12,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: isMobile
                                    ? 14
                                    : isTablet
                                    ? 15
                                    : 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: isMobile ? 3 : 4),
                              Text(
                                'Deadline: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(job['deadline']))}',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 11
                                      : isTablet
                                      ? 11.5
                                      : 12,
                                  color: const Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(
                          height: isMobile
                              ? 12
                              : isTablet
                              ? 14
                              : 16,
                        ),
                        // Action Buttons (Using Row + Expanded for better spacing)
                        Row(
                          children: [
                            Expanded(
                              // Makes View button take available space
                              child: OutlinedButton.icon(
                                onPressed: onView,
                                icon: Icon(
                                  Icons.visibility,
                                  size: isMobile
                                      ? 14
                                      : isTablet
                                      ? 15
                                      : 16,
                                ),
                                label: Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: isMobile
                                        ? 12
                                        : isTablet
                                        ? 12.5
                                        : 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminDashboardStyles.primary,
                                  side: BorderSide(
                                    color: AdminDashboardStyles.primary,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile
                                        ? 10
                                        : isTablet
                                        ? 11
                                        : 12,
                                    vertical: isMobile
                                        ? 6
                                        : isTablet
                                        ? 7
                                        : 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? 6
                                  : isTablet
                                  ? 7
                                  : 8,
                            ),
                            Expanded(
                              // Makes Edit button take available space
                              child: OutlinedButton.icon(
                                onPressed: onEdit,
                                icon: Icon(
                                  Icons.edit,
                                  size: isMobile
                                      ? 14
                                      : isTablet
                                      ? 15
                                      : 16,
                                ),
                                label: Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: isMobile
                                        ? 12
                                        : isTablet
                                        ? 12.5
                                        : 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4299E1),
                                  side: const BorderSide(
                                    color: Color(0xFF4299E1),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile
                                        ? 10
                                        : isTablet
                                        ? 11
                                        : 12,
                                    vertical: isMobile
                                        ? 6
                                        : isTablet
                                        ? 7
                                        : 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? 6
                                  : isTablet
                                  ? 7
                                  : 8,
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
                                PopupMenuItem(
                                  value: 'status',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.update,
                                        size: isMobile
                                            ? 14
                                            : isTablet
                                            ? 15
                                            : 16,
                                      ),
                                      SizedBox(
                                        width: isMobile
                                            ? 6
                                            : isTablet
                                            ? 7
                                            : 8,
                                      ),
                                      Text(
                                        'Update Status',
                                        style: TextStyle(
                                          fontSize: isMobile
                                              ? 13
                                              : isTablet
                                              ? 13.5
                                              : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: isMobile
                                            ? 14
                                            : isTablet
                                            ? 15
                                            : 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(
                                        width: isMobile
                                            ? 6
                                            : isTablet
                                            ? 7
                                            : 8,
                                      ),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: isMobile
                                              ? 13
                                              : isTablet
                                              ? 13.5
                                              : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              icon: Icon(
                                Icons.more_vert,
                                size: isMobile
                                    ? 18
                                    : isTablet
                                    ? 19
                                    : 20,
                                color: const Color(0xFF718096),
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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 6
            : isTablet
            ? 7
            : 8,
        vertical: isMobile
            ? 3
            : isTablet
            ? 3.5
            : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: isMobile
              ? 9
              : isTablet
              ? 9.5
              : 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 6
            : isTablet
            ? 7
            : 8,
        vertical: isMobile
            ? 3
            : isTablet
            ? 3.5
            : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 6
              : isTablet
              ? 7
              : 8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile
                ? 11
                : isTablet
                ? 11.5
                : 12,
            color: color,
          ),
          SizedBox(
            width: isMobile
                ? 3
                : isTablet
                ? 3.5
                : 4,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile
                  ? 11
                  : isTablet
                  ? 11.5
                  : 12,
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
      case 'expired':
        return const Color(0xFFF56565);
      case 'paused':
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF718096);
    }
  }
}
