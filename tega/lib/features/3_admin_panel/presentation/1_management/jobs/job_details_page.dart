import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'edit_job_page.dart';

class JobDetailsPage extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsPage({super.key, required this.job});

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(
          'Job Details',
          style: TextStyle(fontSize: isMobile ? 18 : isTablet ? 19 : 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditJobPage(job: job),
                    ),
                  );
                  break;
                case 'share':
                  _shareJob(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: isMobile ? 16 : isTablet ? 17 : 18,
                    ),
                    SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                    Text(
                      'Edit Job',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(
                      Icons.share,
                      size: isMobile ? 16 : isTablet ? 17 : 18,
                    ),
                    SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                    Text(
                      'Share Job',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            iconSize: isMobile ? 20 : isTablet ? 22 : 24,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              _buildJobInfoCard(isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              if (job['description'] != null) ...[
                _buildDescriptionCard(isMobile, isTablet, isDesktop),
                SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              ],
              if (job['requirements'] != null &&
                  (job['requirements'] as List).isNotEmpty) ...[
                _buildRequirementsCard(isMobile, isTablet, isDesktop),
                SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              ],
              if (job['benefits'] != null &&
                  (job['benefits'] as List).isNotEmpty) ...[
                _buildBenefitsCard(isMobile, isTablet, isDesktop),
                SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              ],
              _buildApplicationCard(context, isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Untitled Job',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : isTablet ? 22 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : isTablet ? 7 : 8),
                    Text(
                      job['company'] ?? 'Unknown Company',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(isMobile, isTablet, isDesktop),
            ],
          ),
          if (job['salary'] != null) ...[
            SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: isMobile ? 18 : isTablet ? 19 : 20,
                  color: Colors.grey[600],
                ),
                SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                Text(
                  '₹${NumberFormat('#,##,###').format(job['salary'])}',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobInfoCard(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Information',
            style: TextStyle(
              fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          Wrap(
            spacing: isMobile ? 6.0 : isTablet ? 7.0 : 8.0,
            runSpacing: isMobile ? 6.0 : isTablet ? 7.0 : 8.0,
            children: [
              if (job['location'] != null)
                _buildInfoChip(
                  Icons.location_on,
                  job['location'],
                  const Color(0xFF4299E1),
                  isMobile,
                  isTablet,
                  isDesktop,
                ),
              _buildInfoChip(
                Icons.work,
                job['jobType'] ?? 'full-time',
                const Color(0xFF48BB78),
                isMobile,
                isTablet,
                isDesktop,
              ),
              _buildInfoChip(
                Icons.category,
                job['postingType'] ?? 'job',
                const Color(0xFFED8936),
                isMobile,
                isTablet,
                isDesktop,
              ),
            ],
          ),
          Divider(height: isMobile ? 24 : isTablet ? 28 : 32),
          _buildInfoRow('Status', job['status'] ?? 'Not specified', isMobile, isTablet, isDesktop),
          _buildInfoRow('Active', job['isActive'] == true ? 'Yes' : 'No', isMobile, isTablet, isDesktop),
          if (job['experience'] != null)
            _buildInfoRow('Experience Required', job['experience'], isMobile, isTablet, isDesktop),
          if (job['deadline'] != null)
            _buildInfoRow(
              'Application Deadline',
              DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(job['deadline'])),
              isMobile,
              isTablet,
              isDesktop,
            ),
          _buildInfoRow(
            'Created',
            DateFormat('MMM dd, yyyy').format(DateTime.parse(job['createdAt'])),
            isMobile,
            isTablet,
            isDesktop,
          ),
          if (job['updatedAt'] != null)
            _buildInfoRow(
              'Last Updated',
              DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(job['updatedAt'])),
              isMobile,
              isTablet,
              isDesktop,
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Description',
            style: TextStyle(
              fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          Text(
            job['description'],
            style: TextStyle(
              fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
              color: const Color(0xFF4A5568),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(bool isMobile, bool isTablet, bool isDesktop) {
    final requirements = job['requirements'] as List;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requirements',
            style: TextStyle(
              fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          ...requirements.map(
            (req) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 6 : isTablet ? 7 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: isMobile ? 14 : isTablet ? 15 : 16,
                    color: const Color(0xFF48BB78),
                  ),
                  SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                  Expanded(
                    child: Text(
                      req,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(bool isMobile, bool isTablet, bool isDesktop) {
    final benefits = job['benefits'] as List;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits',
            style: TextStyle(
              fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          ...benefits.map(
            (benefit) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 6 : isTablet ? 7 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: isMobile ? 14 : isTablet ? 15 : 16,
                    color: const Color(0xFFED8936),
                  ),
                  SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Information',
            style: TextStyle(
              fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          if (job['applicationLink'] != null) ...[
            _buildInfoRow('Application Link', job['applicationLink'], isMobile, isTablet, isDesktop),
            SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _launchURL(context, job['applicationLink']);
                },
                icon: Icon(
                  Icons.open_in_new,
                  size: isMobile ? 18 : isTablet ? 19 : 20,
                ),
                label: Text(
                  'Open Application Link',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminDashboardStyles.primary,
                  side: BorderSide(color: AdminDashboardStyles.primary),
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : isTablet ? 11 : 12,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'No application link provided',
              style: TextStyle(
                fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                color: const Color(0xFF718096),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isMobile, bool isTablet, bool isDesktop) {
    final status = job['status'] ?? 'open';
    final color = _getStatusColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : isTablet ? 11 : 12,
        vertical: isMobile ? 5 : isTablet ? 5.5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: isMobile ? 10 : isTablet ? 11 : 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : isTablet ? 11 : 12,
        vertical: isMobile ? 5 : isTablet ? 5.5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 12 : isTablet ? 13 : 14,
            color: color,
          ),
          SizedBox(width: isMobile ? 5 : isTablet ? 5.5 : 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 11 : isTablet ? 11.5 : 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile, bool isTablet, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : isTablet ? 11 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : isTablet ? 14 : 16),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
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

  void _shareJob(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job sharing functionality will be implemented'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
