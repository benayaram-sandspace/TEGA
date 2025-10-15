import 'package:flutter/material.dart';
import '../models/resume_template.dart';

// Technical Fresher Template - Designed for technical fresh graduates with focus on education, projects, and technical skills
class TechnicalFresherTemplate extends StatelessWidget {
  final ResumeData resumeData;

  const TechnicalFresherTemplate({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32), // 8mm padding
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
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 80),
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(bottom: 24),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF2563EB), width: 2), // blue-600
          ),
        ),
        child: Column(
          children: [
            Text(
              resumeData.fullName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // gray-900
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resumeData.title,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF2563EB), // blue-600
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 4,
              children: [
                if (resumeData.email.isNotEmpty)
                  Text(
                    resumeData.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280), // gray-500
                    ),
                  ),
                if (resumeData.phone.isNotEmpty)
                  Text(
                    resumeData.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280), // gray-500
                    ),
                  ),
                if (resumeData.location.isNotEmpty)
                  Text(
                    resumeData.location,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280), // gray-500
                    ),
                  ),
                if (resumeData.linkedin.isNotEmpty)
                  Text(
                    resumeData.linkedin,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280), // gray-500
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildObjectiveSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildEducationSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildProjectsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildExperienceSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildTechnicalSkillsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildCertificationsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.achievements.isNotEmpty) ...[
          _buildAchievementsSection(),
        ],
      ],
    );
  }

  Widget _buildObjectiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('OBJECTIVE'),
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

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('EDUCATION'),
        const SizedBox(height: 16),
        ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PROJECTS'),
        const SizedBox(height: 16),
        ...resumeData.projects.map((project) => _buildProjectItem(project)),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('EXPERIENCE'),
        const SizedBox(height: 16),
        ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
      ],
    );
  }

  Widget _buildTechnicalSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TECHNICAL SKILLS'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
          children: resumeData.skills.map((skill) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827), // gray-900
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
        _buildSectionTitle('CERTIFICATIONS'),
        const SizedBox(height: 16),
        ...resumeData.certifications.map(
          (cert) => _buildCertificationItem(cert),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACHIEVEMENTS'),
        const SizedBox(height: 16),
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

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 4), // blue-600
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827), // gray-900
        ),
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827), // gray-900
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151), // gray-700
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDateRange(edu.startDate, edu.endDate),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280), // gray-500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827), // gray-900
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151), // gray-700
                height: 1.5,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280), // gray-500
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151), // gray-700
                        fontWeight: FontWeight.w500,
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
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151), // gray-700
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827), // gray-900
          ),
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (cert.issuer.isNotEmpty) ...[
              const TextSpan(text: ' - '),
              TextSpan(
                text: cert.issuer,
                style: const TextStyle(color: Color(0xFF374151)), // gray-700
              ),
            ],
            if (cert.date.isNotEmpty) ...[
              const TextSpan(text: ' '),
              TextSpan(
                text: '(${cert.date})',
                style: const TextStyle(
                  color: Color(0xFF6B7280), // gray-500
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
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
