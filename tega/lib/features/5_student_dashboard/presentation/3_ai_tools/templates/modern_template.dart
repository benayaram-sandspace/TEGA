import 'package:flutter/material.dart';
import '../models/resume_template.dart';

// Modern Template - Modern sidebar layout with dark gradient sidebar and blue accents
class ModernTemplate extends StatelessWidget {
  final ResumeData resumeData;

  const ModernTemplate({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar - 25% width
          _buildSidebar(),
          // Main Content - 75% width
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: (210 * 2.834645669) * 0.25, // 25% of total width
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1F2937), // gray-800
            Color(0xFF111827), // gray-900
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 24),
          _buildContactSection(),
          const SizedBox(height: 24),
          if (resumeData.skills.isNotEmpty) ...[
            _buildSkillsSection(),
            const SizedBox(height: 24),
          ],
          if (resumeData.educations.isNotEmpty) ...[_buildEducationSection()],
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resumeData.title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF93C5FD), // blue-300
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF60A5FA), // blue-400
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarSectionTitle('Contact'),
        const SizedBox(height: 12),
        Column(
          children: [
            if (resumeData.email.isNotEmpty)
              _buildContactItem(Icons.email, resumeData.email),
            if (resumeData.phone.isNotEmpty)
              _buildContactItem(Icons.phone, resumeData.phone),
            if (resumeData.location.isNotEmpty)
              _buildContactItem(Icons.location_on, resumeData.location),
            if (resumeData.linkedin.isNotEmpty)
              _buildContactItem(Icons.link, resumeData.linkedin),
          ],
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarSectionTitle('Skills'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: resumeData.skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF374151), // gray-700
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                skill,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarSectionTitle('Education'),
        const SizedBox(height: 12),
        ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
      ],
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.degree,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            edu.institution,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFD1D5DB), // gray-300
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDateRange(edu.startDate, edu.endDate),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF), // gray-400
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF4B5563), width: 1), // gray-600
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: (210 * 2.834645669) * 0.75, // 75% of total width
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB), // gray-50
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resumeData.summary.isNotEmpty) ...[
            _buildSummarySection(),
            const SizedBox(height: 16),
          ],
          if (resumeData.experiences.isNotEmpty) ...[
            _buildExperienceSection(),
            const SizedBox(height: 16),
          ],
          if (resumeData.projects.isNotEmpty) ...[
            _buildProjectsSection(),
            const SizedBox(height: 16),
          ],
          if (resumeData.languages.isNotEmpty) ...[
            _buildLanguagesSection(),
            const SizedBox(height: 16),
          ],
          if (resumeData.certifications.isNotEmpty) ...[
            _buildCertificationsSection(),
            const SizedBox(height: 16),
          ],
          if (resumeData.interests.isNotEmpty) ...[
            _buildHobbiesSection(),
            const SizedBox(height: 16),
          ],
          if (resumeData.achievements.isNotEmpty) ...[
            _buildAchievementsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Summary'),
        const SizedBox(height: 12),
        Text(
          resumeData.summary,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151), // gray-700
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Experience'),
        const SizedBox(height: 12),
        ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Projects'),
        const SizedBox(height: 12),
        ...resumeData.projects.map((project) => _buildProjectItem(project)),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Languages'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: resumeData.languages.map((language) {
            return Text(
              language,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151), // gray-700
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Certificates'),
        const SizedBox(height: 12),
        ...resumeData.certifications.map(
          (cert) => _buildCertificationItem(cert),
        ),
      ],
    );
  }

  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Hobbies & Interests'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resumeData.interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // gray-100
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF374151), // gray-700
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainSectionTitle('Achievements'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF374151), // gray-700
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      achievement,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151), // gray-700
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMainSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF3B82F6), width: 2), // blue-500
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937), // gray-800
        ),
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
                      exp.position,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937), // gray-800
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280), // gray-500
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDateRange(exp.startDate, exp.endDate, exp.isCurrent),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280), // gray-500
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (exp.description.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: exp.description.split('\n').map((line) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF374151), // gray-700
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF374151), // gray-700
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937), // gray-800
            ),
          ),
          const SizedBox(height: 4),
          if (project.technologies.isNotEmpty)
            Text(
              project.technologies,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151), // gray-700
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            project.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151), // gray-700
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cert.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937), // gray-800
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${cert.issuer} - ${cert.date}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280), // gray-500
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(
    String startDate,
    String endDate, [
    bool isCurrent = false,
  ]) {
    final start = _formatDate(startDate);
    final end = isCurrent ? 'Present' : _formatDate(endDate);
    return '$start - $end';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      return '${_getMonthName(parsed.month)} ${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
