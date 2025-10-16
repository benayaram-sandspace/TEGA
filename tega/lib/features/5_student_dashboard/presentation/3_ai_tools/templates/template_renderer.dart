import 'package:flutter/material.dart';
import '../models/resume_template.dart';
import 'template_placeholders.dart';
import 'contemporary_template.dart';
import 'creative_template.dart';
import 'elegant_template.dart';
import 'executive_template.dart';
import 'functional_template.dart';
import 'it_fresher_template.dart';
import 'minimal_template.dart';
import 'modern_template.dart';
import 'professional_template.dart';
import 'simple_template.dart';
import 'technical_fresher_template.dart';
import 'technical_template.dart';
import 'traditional_template.dart';

class TemplateRenderer extends StatelessWidget {
  final ResumeData resumeData;
  final TemplateMetadata template;
  final bool isPreview;
  final double? width;
  final double? height;

  const TemplateRenderer({
    super.key,
    required this.resumeData,
    required this.template,
    this.isPreview = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isPreview
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildTemplateContent(),
      ),
    );
  }

  Widget _buildTemplateContent() {
    switch (template.id) {
      case 'professional_1':
        return ATSClassicTemplate(resumeData: resumeData);
      case 'professional_2':
        return ATSEngineeringTemplate(resumeData: resumeData);
      case 'professional_3':
        return ATSITTemplate(resumeData: resumeData);
      case 'creative_1':
        return ATSModernTemplate(resumeData: resumeData);
      case 'creative_2':
        return ATSProfessionalTemplate(resumeData: resumeData);
      case 'modern_1':
        return ATSSimpleTemplate(resumeData: resumeData);
      case 'modern_2':
        return ATSTechnicalTemplate(resumeData: resumeData);
      case 'classic_1':
        return BoldTemplate(resumeData: resumeData);
      case 'classic_2':
        return CSFresherTemplate(resumeData: resumeData);
      case 'minimalist_1':
        return ChronologicalTemplate(resumeData: resumeData);
      case 'minimalist_2':
        return ClassicTemplate(resumeData: resumeData);
      case 'executive_1':
        return CleanTemplate(resumeData: resumeData);
      case 'executive_2':
        return CompactTemplate(resumeData: resumeData);
      case 'executive_3':
        return ContemporaryTemplate(resumeData: resumeData);
      case 'creative_3':
        return CreativeTemplate(resumeData: resumeData);
      case 'creative_4':
        return ElegantTemplate(resumeData: resumeData);
      case 'executive_4':
        return ExecutiveTemplate(resumeData: resumeData);
      case 'functional_1':
        return FunctionalTemplate(resumeData: resumeData);
      case 'it_fresher_1':
        return ITFresherTemplate(resumeData: resumeData);
      case 'minimalist_3':
        return MinimalTemplate(resumeData: resumeData);
      case 'modern_3':
        return ModernTemplate(resumeData: resumeData);
      case 'professional_4':
        return ProfessionalTemplate(resumeData: resumeData);
      case 'simple_1':
        return SimpleTemplate(resumeData: resumeData);
      case 'technical_fresher_1':
        return TechnicalFresherTemplate(resumeData: resumeData);
      case 'technical_2':
        return TechnicalTemplate(resumeData: resumeData);
      case 'traditional_1':
        return TraditionalTemplate(resumeData: resumeData);
      default:
        return DefaultTemplate(resumeData: resumeData);
    }
  }
}

// Base template widget
abstract class BaseTemplate extends StatelessWidget {
  final ResumeData resumeData;

  const BaseTemplate({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 24), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resumeData.fullName.isNotEmpty)
                Text(
                  resumeData.fullName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              const SizedBox(height: 8),
              if (resumeData.email.isNotEmpty || resumeData.phone.isNotEmpty)
                Row(
                  children: [
                    if (resumeData.email.isNotEmpty) ...[
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(resumeData.email),
                      const SizedBox(width: 16),
                    ],
                    if (resumeData.phone.isNotEmpty) ...[
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(resumeData.phone),
                    ],
                  ],
                ),
              if (resumeData.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(resumeData.location),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeData.summary.isNotEmpty) ...[
          _buildSectionTitle('Professional Summary'),
          const SizedBox(height: 8),
          Text(
            resumeData.summary,
            style: const TextStyle(fontSize: 14, height: 1.5),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: resumeData.skills
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(skill, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildSectionTitle('Projects'),
          const SizedBox(height: 12),
          ...resumeData.projects.map((project) => _buildProjectItem(project)),
          const SizedBox(height: 24),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildExperienceItem(WorkExperience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exp.position,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Text(
            exp.company,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exp.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(Education edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.degree,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            edu.institution,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (edu.gpa.isNotEmpty)
            Text(
              'GPA: ${edu.gpa}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Technologies: ${project.technologies}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification cert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              cert.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            cert.date,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Default template implementation
class DefaultTemplate extends BaseTemplate {
  const DefaultTemplate({super.key, required super.resumeData});
}
