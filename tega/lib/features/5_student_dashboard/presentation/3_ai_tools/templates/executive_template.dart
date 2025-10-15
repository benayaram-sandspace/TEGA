import 'package:flutter/material.dart';
import '../models/resume_template.dart';

// Executive Template - Executive-level design with bold typography and strong borders
class ExecutiveTemplate extends StatelessWidget {
  final ResumeData resumeData;

  const ExecutiveTemplate({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(40),
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
          const SizedBox(height: 40),
          _buildGridLayout(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF374151), width: 4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  resumeData.fullName,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: 1.5,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resumeData.title,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF6B7280),
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content - 3/4 width
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 80),
            child: _buildMainContent(),
          ),
        ),
        const SizedBox(width: 40),
        // Sidebar - 1/4 width
        Expanded(flex: 1, child: _buildSidebar()),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSummarySection(),
          const SizedBox(height: 32),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildExperienceSection(),
          const SizedBox(height: 32),
        ],
        if (resumeData.educations.isNotEmpty) ...[_buildEducationSection()],
      ],
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.email.isNotEmpty ||
            resumeData.phone.isNotEmpty ||
            resumeData.location.isNotEmpty) ...[
          _buildContactSection(),
          const SizedBox(height: 32),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSkillsSection(),
          const SizedBox(height: 32),
        ],
        if (resumeData.languages.isNotEmpty) ...[
          _buildLanguagesSection(),
          const SizedBox(height: 32),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildCertificationsSection(),
          const SizedBox(height: 32),
        ],
        if (resumeData.interests.isNotEmpty) ...[_buildHobbiesSection()],
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Executive Summary'),
        const SizedBox(height: 16),
        Text(
          resumeData.summary,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF6B7280),
            height: 1.6,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Professional Experience'),
        const SizedBox(height: 16),
        ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Education'),
        const SizedBox(height: 16),
        ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contact'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumeData.email.isNotEmpty)
              Text(
                resumeData.email,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
                ),
              ),
            if (resumeData.phone.isNotEmpty)
              Text(
                resumeData.phone,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
                ),
              ),
            if (resumeData.location.isNotEmpty)
              Text(
                resumeData.location,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
                ),
              ),
            if (resumeData.linkedin.isNotEmpty)
              Text(
                resumeData.linkedin,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Core Competencies'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.skills.map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Languages'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.languages.map((language) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
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
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.certifications.map((cert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'serif',
                    ),
                  ),
                  Text(
                    '${cert.issuer}, ${cert.date}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontFamily: 'serif',
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

  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hobbies'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.interests.map((interest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                  fontFamily: 'serif',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 2)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151),
          fontFamily: 'serif',
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
          Text(
            exp.position,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${exp.company} | ${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontFamily: 'serif',
            ),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF9CA3AF),
                height: 1.5,
                fontFamily: 'serif',
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            edu.degree,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
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
