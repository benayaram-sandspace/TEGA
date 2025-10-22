import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrowseByCategory(),
            const SizedBox(height: 24),
            _buildPopularArticles(),
            const SizedBox(height: 24),
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseByCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by Category',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildCategoryCard(
              icon: Icons.play_circle_outline,
              iconColor: const Color(0xFF3B82F6),
              title: 'Getting Started',
              description:
                  'Learn how to create an account, enroll in courses, and navigate the platform.',
            ),
            _buildCategoryCard(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF10B981),
              title: 'Account & Profile',
              description:
                  'Manage your account settings, update profile information, and change passwords.',
            ),
            _buildCategoryCard(
              icon: Icons.school_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Courses & Learning',
              description:
                  'Access course materials, submit assignments, and track your progress.',
            ),
            _buildCategoryCard(
              icon: Icons.payment_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'Payments & Refunds',
              description:
                  'Information about payment methods, refunds, and billing issues.',
            ),
            _buildCategoryCard(
              icon: Icons.support_agent,
              iconColor: const Color(0xFFEF4444),
              title: 'Technical Support',
              description:
                  'Troubleshoot technical issues with the platform and system requirements.',
            ),
            _buildCategoryCard(
              icon: Icons.verified_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: 'Certificates & Credentials',
              description:
                  'Access and verify your course completion certificates.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Articles',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildArticleItem('How to reset your password'),
              _buildDivider(),
              _buildArticleItem('System requirements for online learning'),
              _buildDivider(),
              _buildArticleItem('How to download course materials'),
              _buildDivider(),
              _buildArticleItem(
                'Understanding the course completion certificate',
              ),
              _buildDivider(),
              _buildArticleItem('Troubleshooting video playback issues'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArticleItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            'Read →',
            style: TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Text(
            'Still need help?',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our support team is available to help you with any questions or issues you might have.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSupportButton(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  isPrimary: false,
                  onTap: () => _launchEmail(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSupportButton(
                  icon: Icons.phone_outlined,
                  title: 'Call Support',
                  isPrimary: true,
                  onTap: () => _launchPhone(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Available Monday to Friday, 9:00 AM to 6:00 PM IST',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF3B82F6) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF3B82F6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF3B82F6), width: 1),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 18),
        label: Text(title),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@tega.com',
      query: 'subject=Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+91-9876543210');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}
