import 'package:flutter/material.dart';
import '../models/resume_template.dart';
import 'template_renderer.dart';

// ATS Classic Template - Clean and ATS-friendly
class ATSClassicTemplate extends BaseTemplate {
  const ATSClassicTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 2)),
      ),
      child: Column(
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 18, color: Color(0xFF374151)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            children: [
              if (resumeData.email.isNotEmpty)
                Text(
                  resumeData.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
              if (resumeData.phone.isNotEmpty)
                Text(
                  resumeData.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
              if (resumeData.location.isNotEmpty)
                Text(
                  resumeData.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
              if (resumeData.linkedin.isNotEmpty)
                Text(
                  resumeData.linkedin,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL SUMMARY'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL EXPERIENCE'),
          const SizedBox(height: 16),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('EDUCATION'),
          const SizedBox(height: 16),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('TECHNICAL SKILLS'),
          const SizedBox(height: 16),
          _buildSkillsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('PROJECTS'),
          const SizedBox(height: 16),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('CERTIFICATIONS'),
          const SizedBox(height: 16),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
          letterSpacing: 0.5,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (cert.issuer.isNotEmpty)
              TextSpan(
                text: ' - ${cert.issuer}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            if (cert.date.isNotEmpty)
              TextSpan(
                text: ' (${cert.date})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
          ],
        ),
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

// ATS Engineering Template - Engineering-focused layout
class ATSEngineeringTemplate extends BaseTemplate {
  const ATSEngineeringTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resumeData.email.isNotEmpty)
                      Text(
                        resumeData.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    if (resumeData.phone.isNotEmpty)
                      Text(
                        resumeData.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (resumeData.location.isNotEmpty)
                      Text(
                        resumeData.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    if (resumeData.linkedin.isNotEmpty)
                      Text(
                        resumeData.linkedin,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL SUMMARY'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL EXPERIENCE'),
          const SizedBox(height: 16),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('EDUCATION'),
          const SizedBox(height: 16),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('TECHNICAL SKILLS'),
          const SizedBox(height: 16),
          _buildSkillsSection(),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
        letterSpacing: 0.5,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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

// ATS IT Template - IT-focused layout with labeled contact info
class ATSITTemplate extends BaseTemplate {
  const ATSITTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resumeData.email.isNotEmpty)
                      _buildContactItem('Email:', resumeData.email),
                    if (resumeData.phone.isNotEmpty)
                      _buildContactItem('Phone:', resumeData.phone),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resumeData.location.isNotEmpty)
                      _buildContactItem('Location:', resumeData.location),
                    if (resumeData.linkedin.isNotEmpty)
                      _buildContactItem('LinkedIn:', resumeData.linkedin),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            TextSpan(
              text: ' $value',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL SUMMARY'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL EXPERIENCE'),
          const SizedBox(height: 16),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('EDUCATION'),
          const SizedBox(height: 16),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('TECHNICAL SKILLS'),
          const SizedBox(height: 16),
          _buildSkillsSection(),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
        letterSpacing: 0.5,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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

// ATS Modern Template - Modern layout with blue accent and two-column header
class ATSModernTemplate extends BaseTemplate {
  const ATSModernTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF3B82F6), width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resumeData.fullName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resumeData.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (resumeData.email.isNotEmpty)
                Text(
                  resumeData.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.phone.isNotEmpty)
                Text(
                  resumeData.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.location.isNotEmpty)
                Text(
                  resumeData.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.linkedin.isNotEmpty)
                Text(
                  resumeData.linkedin,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL SUMMARY'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('WORK EXPERIENCE'),
          const SizedBox(height: 16),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('EDUCATION'),
          const SizedBox(height: 16),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('CORE COMPETENCIES'),
          const SizedBox(height: 16),
          _buildSkillsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('KEY PROJECTS'),
          const SizedBox(height: 16),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('CERTIFICATIONS'),
          const SizedBox(height: 16),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
        letterSpacing: 1.0,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (cert.issuer.isNotEmpty)
              TextSpan(
                text: ' - ${cert.issuer}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            if (cert.date.isNotEmpty)
              TextSpan(
                text: ' (${cert.date})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
          ],
        ),
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

// ATS Professional Template - Clean professional layout with centered header and bordered sections
class ATSProfessionalTemplate extends BaseTemplate {
  const ATSProfessionalTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF9CA3AF), width: 1)),
      ),
      child: Column(
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 18, color: Color(0xFF374151)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 32,
            children: [
              if (resumeData.email.isNotEmpty)
                Text(
                  resumeData.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.phone.isNotEmpty)
                Text(
                  resumeData.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.location.isNotEmpty)
                Text(
                  resumeData.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.linkedin.isNotEmpty)
                Text(
                  resumeData.linkedin,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL SUMMARY'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL EXPERIENCE'),
          const SizedBox(height: 16),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('EDUCATION'),
          const SizedBox(height: 16),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('TECHNICAL SKILLS'),
          const SizedBox(height: 16),
          _buildSkillsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('PROJECTS'),
          const SizedBox(height: 16),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('CERTIFICATIONS'),
          const SizedBox(height: 16),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 2)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (cert.issuer.isNotEmpty)
              TextSpan(
                text: ' - ${cert.issuer}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            if (cert.date.isNotEmpty)
              TextSpan(
                text: ' (${cert.date})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
          ],
        ),
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

// ATS Simple Template - Clean minimal design with simple inline styling
class ATSSimpleTemplate extends BaseTemplate {
  const ATSSimpleTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 24), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (resumeData.email.isNotEmpty)
                Text(
                  resumeData.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.phone.isNotEmpty)
                Text(
                  resumeData.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.location.isNotEmpty)
                Text(
                  resumeData.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (resumeData.linkedin.isNotEmpty)
                Text(
                  resumeData.linkedin,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('Summary'),
          const SizedBox(height: 8),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('Experience'),
          const SizedBox(height: 12),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 20),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('Education'),
          const SizedBox(height: 12),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 20),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('Skills'),
          const SizedBox(height: 12),
          _buildSkillsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('Projects'),
          const SizedBox(height: 12),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 20),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('Certifications'),
          const SizedBox(height: 12),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (cert.issuer.isNotEmpty)
              TextSpan(
                text: ' - ${cert.issuer}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            if (cert.date.isNotEmpty)
              TextSpan(
                text: ' (${cert.date})',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
          ],
        ),
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

// ATS Technical Template - Technical style with left borders and larger typography
class ATSTechnicalTemplate extends BaseTemplate {
  const ATSTechnicalTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 24), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 80, bottom: 24),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF1F2937), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 20, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resumeData.email.isNotEmpty)
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'EMAIL: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextSpan(
                        text: resumeData.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              if (resumeData.phone.isNotEmpty)
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'PHONE: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextSpan(
                        text: resumeData.phone,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              if (resumeData.location.isNotEmpty)
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'LOCATION: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextSpan(
                        text: resumeData.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              if (resumeData.linkedin.isNotEmpty)
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'LINKEDIN: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextSpan(
                        text: resumeData.linkedin,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('PROFESSIONAL SUMMARY'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('TECHNICAL EXPERIENCE'),
          const SizedBox(height: 12),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 20),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('EDUCATION'),
          const SizedBox(height: 12),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 20),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('TECHNICAL SKILLS'),
          const SizedBox(height: 12),
          _buildSkillsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('PROJECTS'),
          const SizedBox(height: 12),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 20),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('CERTIFICATIONS'),
          const SizedBox(height: 12),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          '• $skill',
          style: const TextStyle(fontSize: 18, color: Color(0xFF374151)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 80),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: const BoxDecoration(color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(left: 16, right: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 16, right: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(left: 16, right: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 16, right: 80),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (cert.issuer.isNotEmpty)
              TextSpan(
                text: ' - ${cert.issuer}',
                style: const TextStyle(fontSize: 18, color: Color(0xFF374151)),
              ),
            if (cert.date.isNotEmpty)
              TextSpan(
                text: ' (${cert.date})',
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
          ],
        ),
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

// Bold Template - Dark theme with yellow accents and two-column layout
class BoldTemplate extends BaseTemplate {
  const BoldTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark gray background
        border: Border.all(
          color: const Color(0xFFFCD34D),
          width: 4,
        ), // Yellow border
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFCD34D), width: 2)),
      ),
      child: Column(
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFCD34D), // Yellow accent
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: 96,
            height: 4,
            color: const Color(0xFFFCD34D), // Yellow accent line
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Content - 3/4 width
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resumeData.summary.isNotEmpty) ...[
                  _buildSectionTitle('SUMMARY'),
                  const SizedBox(height: 12),
                  Text(
                    resumeData.summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD1D5DB), // Light gray text
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (resumeData.experiences.isNotEmpty) ...[
                  _buildSectionTitle('EXPERIENCE'),
                  const SizedBox(height: 12),
                  ...resumeData.experiences.map(
                    (exp) => _buildExperienceItem(exp),
                  ),
                  const SizedBox(height: 24),
                ],
                if (resumeData.educations.isNotEmpty) ...[
                  _buildSectionTitle('EDUCATION'),
                  const SizedBox(height: 12),
                  ...resumeData.educations.map(
                    (edu) => _buildEducationItem(edu),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Sidebar - 1/4 width
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactSection(),
              const SizedBox(height: 24),
              if (resumeData.skills.isNotEmpty) _buildSkillsSection(),
              if (resumeData.skills.isNotEmpty) const SizedBox(height: 24),
              if (resumeData.languages.isNotEmpty) _buildLanguagesSection(),
              if (resumeData.languages.isNotEmpty) const SizedBox(height: 24),
              if (resumeData.interests.isNotEmpty) _buildInterestsSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFCD34D), // Yellow accent
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CONTACT'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumeData.email.isNotEmpty)
              Text(
                resumeData.email,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
              ),
            if (resumeData.phone.isNotEmpty)
              Text(
                resumeData.phone,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
              ),
            if (resumeData.location.isNotEmpty)
              Text(
                resumeData.location,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
              ),
            if (resumeData.linkedin.isNotEmpty)
              Text(
                resumeData.linkedin,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
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
        _buildSectionTitle('SKILLS'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resumeData.skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFCD34D), // Yellow background
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937), // Dark text on yellow
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
        _buildSectionTitle('LANGUAGES'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.languages.map((language) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('INTERESTS'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.interests.map((interest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                interest,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.position,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${exp.company} | ${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF9CA3AF), // Medium gray
            ),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFD1D5DB), // Light gray
                height: 1.4,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            edu.degree,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF9CA3AF), // Medium gray
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

// CS Fresher Template - Clean design with green accents for computer science graduates
class CSFresherTemplate extends BaseTemplate {
  const CSFresherTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 32), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF16A34A), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resumeData.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A), // Green accent
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resumeData.email.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Email: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            TextSpan(
                              text: resumeData.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (resumeData.phone.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Phone: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            TextSpan(
                              text: resumeData.phone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resumeData.location.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Location: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            TextSpan(
                              text: resumeData.location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (resumeData.linkedin.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'LinkedIn: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            TextSpan(
                              text: resumeData.linkedin,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resumeData.summary.isNotEmpty) ...[
            _buildSectionTitle('PROFESSIONAL SUMMARY'),
            const SizedBox(height: 12),
            Text(
              resumeData.summary,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (resumeData.educations.isNotEmpty) ...[
            _buildSectionTitle('EDUCATION'),
            const SizedBox(height: 16),
            ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
            const SizedBox(height: 24),
          ],
          if (resumeData.projects.isNotEmpty) ...[
            _buildSectionTitle('PROJECTS'),
            const SizedBox(height: 16),
            ...resumeData.projects.map((project) => _buildProjectItem(project)),
            const SizedBox(height: 24),
          ],
          if (resumeData.experiences.isNotEmpty) ...[
            _buildSectionTitle('EXPERIENCE'),
            const SizedBox(height: 16),
            ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
            const SizedBox(height: 24),
          ],
          if (resumeData.skills.isNotEmpty) ...[
            _buildSectionTitle('TECHNICAL SKILLS'),
            const SizedBox(height: 16),
            _buildSkillsSection(),
            const SizedBox(height: 24),
          ],
          if (resumeData.certifications.isNotEmpty) ...[
            _buildSectionTitle('CERTIFICATIONS'),
            const SizedBox(height: 16),
            ...resumeData.certifications.map(
              (cert) => _buildCertificationItem(cert),
            ),
            const SizedBox(height: 24),
          ],
          if (resumeData.achievements.isNotEmpty) ...[
            _buildSectionTitle('ACHIEVEMENTS'),
            const SizedBox(height: 16),
            _buildAchievementsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A), // Green accent
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Text(
          skill,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: resumeData.achievements.map((achievement) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A), // Green accent
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  achievement,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.4,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                if (edu.gpa.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GPA: ${edu.gpa}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
              color: Color(0xFF111827),
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
          children: [
            TextSpan(
              text: cert.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (cert.issuer.isNotEmpty)
              TextSpan(
                text: ' - ${cert.issuer}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            if (cert.date.isNotEmpty)
              TextSpan(
                text: ' (${cert.date})',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
          ],
        ),
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

// Chronological Template - Traditional chronological layout with centered header
class ChronologicalTemplate extends BaseTemplate {
  const ChronologicalTemplate({super.key, required super.resumeData});

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
        children: [_buildHeader(), const SizedBox(height: 24), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 2)),
      ),
      child: Column(
        children: [
          Text(
            resumeData.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            resumeData.title,
            style: const TextStyle(fontSize: 20, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (resumeData.email.isNotEmpty) ...[
                Text(
                  resumeData.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '|',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 8),
              ],
              if (resumeData.phone.isNotEmpty) ...[
                Text(
                  resumeData.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '|',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 8),
              ],
              if (resumeData.linkedin.isNotEmpty)
                Text(
                  resumeData.linkedin,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('Summary'),
          const SizedBox(height: 8),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('Work Experience'),
          const SizedBox(height: 12),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('Education'),
          const SizedBox(height: 12),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('Skills'),
          const SizedBox(height: 12),
          _buildSkillsSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('Certifications'),
          const SizedBox(height: 12),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.achievements.isNotEmpty) ...[
          _buildSectionTitle('Achievements'),
          const SizedBox(height: 12),
          ...resumeData.achievements.map(
            (achievement) => _buildAchievementItem(achievement),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.languages.isNotEmpty) ...[
          _buildSectionTitle('Languages'),
          const SizedBox(height: 12),
          ...resumeData.languages.map(
            (language) => _buildLanguageItem(language),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.interests.isNotEmpty) ...[
          _buildSectionTitle('Hobbies'),
          const SizedBox(height: 12),
          ...resumeData.interests.map(
            (interest) => _buildInterestItem(interest),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resumeData.skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            skill,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementItem(String achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        achievement,
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildLanguageItem(String language) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        language,
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildInterestItem(String interest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        interest,
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  exp.position,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${exp.company}, ${exp.location}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
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
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cert.issuer}, ${cert.date}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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

// Classic Template - Professional design with centered header and comprehensive sections
class ClassicTemplate extends BaseTemplate {
  const ClassicTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 8), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Profile image placeholder (if available)
          if (resumeData.fullName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  resumeData.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  resumeData.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // Contact information
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              if (resumeData.email.isNotEmpty)
                Text(
                  resumeData.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              if (resumeData.phone.isNotEmpty)
                Text(
                  resumeData.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              if (resumeData.location.isNotEmpty)
                Text(
                  resumeData.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              if (resumeData.linkedin.isNotEmpty)
                Text(
                  resumeData.linkedin,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('Professional Summary'),
          const SizedBox(height: 4),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('Professional Experience'),
          const SizedBox(height: 8),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 20),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('Education'),
          const SizedBox(height: 8),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
          const SizedBox(height: 20),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSectionTitle('Skills'),
          const SizedBox(height: 8),
          _buildSkillsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('Projects'),
          const SizedBox(height: 8),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 20),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildSectionTitle('Certifications'),
          const SizedBox(height: 12),
          ...resumeData.certifications.map(
            (cert) => _buildCertificationItem(cert),
          ),
          const SizedBox(height: 20),
        ],
        if (resumeData.languages.isNotEmpty) ...[
          _buildSectionTitle('Languages'),
          const SizedBox(height: 8),
          ...resumeData.languages.map(
            (language) => _buildLanguageItem(language),
          ),
          const SizedBox(height: 20),
        ],
        if (resumeData.interests.isNotEmpty) ...[
          _buildSectionTitle('Hobbies'),
          const SizedBox(height: 8),
          ...resumeData.interests.map(
            (interest) => _buildInterestItem(interest),
          ),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle('Achievements'),
        const SizedBox(height: 8),
        _buildAchievementsSection(),
        const SizedBox(height: 20),
        if (resumeData.achievements.isNotEmpty) ...[
          _buildSectionTitle('Extracurricular Activities'),
          const SizedBox(height: 8),
          ...resumeData.achievements.map(
            (achievement) => _buildAchievementItem(achievement),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: resumeData.skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            skill,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            project.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ],
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cert.issuer} - ${cert.date}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(String language) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        language,
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildInterestItem(String interest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        interest,
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.achievements.isNotEmpty) ...[
          ...resumeData.achievements.map(
            (achievement) => _buildAchievementItem(achievement),
          ),
        ] else ...[
          _buildAchievementItem(
            'Led cross-functional team of 8 developers to deliver critical system migration 2 weeks ahead of schedule',
          ),
          _buildAchievementItem(
            'Received "Innovation Award" for developing automated deployment pipeline that reduced release time by 70%',
          ),
          _buildAchievementItem(
            'Contributed to open-source project with 10K+ GitHub stars and 500+ contributors',
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementItem(String achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF374151),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              achievement,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.position,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.company,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
                style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...exp.description
                .split('\n')
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF374151),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                if (edu.gpa.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'GPA: ${edu.gpa}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate)}',
            style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
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

// Clean Template - Two-column layout with sidebar and main content
class CleanTemplate extends BaseTemplate {
  const CleanTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(20),
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
          _buildTwoColumnLayout(),
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
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1F2937),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          resumeData.title,
          style: const TextStyle(fontSize: 20, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar - 3/12 width
        Expanded(flex: 3, child: _buildSidebar()),
        const SizedBox(width: 32),
        // Main content - 9/12 width
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 80),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactSection(),
        const SizedBox(height: 24),
        if (resumeData.skills.isNotEmpty) ...[
          _buildSkillsSection(),
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
        if (resumeData.interests.isNotEmpty) ...[_buildHobbiesSection()],
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('Summary'),
          const SizedBox(height: 12),
          Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.experiences.isNotEmpty) ...[
          _buildSectionTitle('Experience'),
          const SizedBox(height: 12),
          ...resumeData.experiences.map((exp) => _buildExperienceItem(exp)),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[
          _buildSectionTitle('Education'),
          const SizedBox(height: 12),
          ...resumeData.educations.map((edu) => _buildEducationItem(edu)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('Contact'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumeData.email.isNotEmpty)
              Text(
                resumeData.email,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            if (resumeData.phone.isNotEmpty)
              Text(
                resumeData.phone,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            if (resumeData.location.isNotEmpty)
              Text(
                resumeData.location,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            if (resumeData.linkedin.isNotEmpty)
              Text(
                resumeData.linkedin,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            // GitHub field not available in ResumeData model
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('Skills'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.skills.map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                skill,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
        _buildSidebarTitle('Languages'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.languages.map((language) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
        _buildSidebarTitle('Certifications'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.certifications.map((cert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${cert.issuer}, ${cert.date}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
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
        _buildSidebarTitle('Hobbies'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.interests.map((interest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                interest,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSidebarTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.position,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${exp.company} | ${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                height: 1.4,
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
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            edu.degree,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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

// Compact Template - Compact design with header and grid layout
class CompactTemplate extends BaseTemplate {
  const CompactTemplate({super.key, required super.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 16),
          if (resumeData.summary.isNotEmpty) ...[
            _buildSummarySection(),
            const SizedBox(height: 16),
          ],
          _buildGridLayout(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resumeData.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resumeData.title,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (resumeData.email.isNotEmpty)
              Text(
                resumeData.email,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            if (resumeData.phone.isNotEmpty)
              Text(
                resumeData.phone,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            if (resumeData.location.isNotEmpty)
              Text(
                resumeData.location,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            if (resumeData.linkedin.isNotEmpty)
              Text(
                resumeData.linkedin,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Text(
      resumeData.summary,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF374151),
        height: 1.5,
      ),
    );
  }

  Widget _buildGridLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content - 2/3 width
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resumeData.experiences.isNotEmpty) ...[
                _buildExperienceSection(),
                const SizedBox(height: 16),
              ],
              if (resumeData.educations.isNotEmpty) ...[
                _buildEducationSection(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Sidebar - 1/3 width
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resumeData.skills.isNotEmpty) ...[
                _buildSkillsSection(),
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
              if (resumeData.interests.isNotEmpty) ...[_buildHobbiesSection()],
            ],
          ),
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

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skills'),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.skills.map((skill) {
            return Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF374151),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
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
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.certifications.map((cert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${cert.issuer}, ${cert.date}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
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
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resumeData.interests.map((interest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                interest,
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
        border: Border(bottom: BorderSide(color: Color(0xFF1F2937), width: 1)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${exp.position} at ${exp.company}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.institution,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            edu.degree,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
