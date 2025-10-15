import 'package:flutter/material.dart';
import '../models/resume_template.dart';

// Technical Template - Technical-focused design with monospace font, skill tags, and clean section borders
class TechnicalTemplate extends StatelessWidget {
  final ResumeData resumeData;

  const TechnicalTemplate({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resumeData.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937), // gray-800
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          resumeData.title,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF2563EB), // blue-600
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (resumeData.email.isNotEmpty)
              Text(
                resumeData.email,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280), // gray-500
                  fontFamily: 'monospace',
                ),
              ),
            if (resumeData.phone.isNotEmpty)
              Text(
                resumeData.phone,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280), // gray-500
                  fontFamily: 'monospace',
                ),
              ),
            if (resumeData.linkedin.isNotEmpty)
              Text(
                resumeData.linkedin,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280), // gray-500
                  fontFamily: 'monospace',
                ),
              ),
            if (resumeData.website.isNotEmpty)
              Text(
                resumeData.website,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280), // gray-500
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSummarySection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSkillsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildExperienceSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildEducationSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.languages.isNotEmpty) ...[
          _buildLanguagesSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildCertificationsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.interests.isNotEmpty) ...[
          _buildHobbiesSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.achievements.isNotEmpty) ...[
          _buildAchievementsSection(),
        ],
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Summary'),
        const SizedBox(height: 8),
        Text(
          resumeData.summary,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280), // gray-500
            height: 1.6,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Technical Skills'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resumeData.skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB), // gray-200
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937), // gray-800
                  fontFamily: 'monospace',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Experience'),
        const SizedBox(height: 8),
        ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Education'),
        const SizedBox(height: 8),
        ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Languages'),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.languages.map((language) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280), // gray-500
                  fontFamily: 'monospace',
                ),
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
        _buildSectionTitle('Certifications'),
        const SizedBox(height: 8),
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
        _buildSectionTitle('Hobbies'),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.interests.map((interest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280), // gray-500
                  fontFamily: 'monospace',
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
        _buildSectionTitle('Achievements'),
        const SizedBox(height: 8),
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
                      color: Color(0xFF6B7280), // gray-500
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      achievement,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280), // gray-500
                        fontFamily: 'monospace',
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

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 2), // gray-200
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151), // gray-700
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.position,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937), // gray-800
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${exp.company} | ${_formatDateRange(exp.startDate, exp.endDate, exp.isCurrent)}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280), // gray-500
              fontFamily: 'monospace',
            ),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280), // gray-500
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.institution,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937), // gray-800
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            edu.degree,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280), // gray-500
              fontFamily: 'monospace',
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937), // gray-800
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${cert.issuer} - ${cert.date}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280), // gray-500
              fontFamily: 'monospace',
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
