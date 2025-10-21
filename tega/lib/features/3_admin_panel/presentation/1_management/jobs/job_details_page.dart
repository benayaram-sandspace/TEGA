import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_job_page.dart';

class JobDetailsPage extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Job Details'),
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
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit Job'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 16),
                    SizedBox(width: 8),
                    Text('Share Job'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 16),
            // Job Information Card
            _buildJobInfoCard(),
            const SizedBox(height: 16),
            // Description Card
            if (job['description'] != null) ...[
              _buildDescriptionCard(),
              const SizedBox(height: 16),
            ],
            // Requirements Card
            if (job['requirements'] != null &&
                (job['requirements'] as List).isNotEmpty) ...[
              _buildRequirementsCard(),
              const SizedBox(height: 16),
            ],
            // Benefits Card
            if (job['benefits'] != null &&
                (job['benefits'] as List).isNotEmpty) ...[
              _buildBenefitsCard(),
              const SizedBox(height: 16),
            ],
            // Application Info Card
            _buildApplicationCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Untitled Job',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job['company'] ?? 'Unknown Company',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (job['location'] != null) ...[
                _buildInfoChip(
                  Icons.location_on,
                  job['location'],
                  const Color(0xFF4299E1),
                ),
                const SizedBox(width: 12),
              ],
              _buildInfoChip(
                Icons.work,
                job['jobType'] ?? 'full-time',
                const Color(0xFF48BB78),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.category,
                job['postingType'] ?? 'job',
                const Color(0xFFED8936),
              ),
            ],
          ),
          if (job['salary'] != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '₹${NumberFormat('#,##,###').format(job['salary'])}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Job Type', job['jobType'] ?? 'Not specified'),
          _buildInfoRow('Posting Type', job['postingType'] ?? 'Not specified'),
          _buildInfoRow('Status', job['status'] ?? 'Not specified'),
          _buildInfoRow('Active', job['isActive'] == true ? 'Yes' : 'No'),
          if (job['experience'] != null)
            _buildInfoRow('Experience Required', job['experience']),
          if (job['deadline'] != null)
            _buildInfoRow(
              'Application Deadline',
              DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(job['deadline'])),
            ),
          _buildInfoRow(
            'Created',
            DateFormat('MMM dd, yyyy').format(DateTime.parse(job['createdAt'])),
          ),
          if (job['updatedAt'] != null)
            _buildInfoRow(
              'Last Updated',
              DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(job['updatedAt'])),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            job['description'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    final requirements = job['requirements'] as List;
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requirements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...requirements.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF48BB78),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
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

  Widget _buildBenefitsCard() {
    final benefits = job['benefits'] as List;
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Benefits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.star_outline,
                    size: 16,
                    color: Color(0xFFED8936),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
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

  Widget _buildApplicationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Application Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          if (job['applicationLink'] != null) ...[
            _buildInfoRow('Application Link', job['applicationLink']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle application link
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apply Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'No application link provided',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = job['status'] ?? 'open';
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF718096),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
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

  void _shareJob(BuildContext context) {
    // Implement job sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job sharing functionality will be implemented'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
