import 'package:flutter/material.dart';
import '../models/resume_template.dart';

// Creative Template - Creative design with purple theme and card-based sections
class CreativeTemplate extends StatelessWidget {
  final ResumeData resumeData;

  const CreativeTemplate({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210 * 2.834645669, // A4 width in points
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(9999),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              resumeData.fullName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            resumeData.title,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF374151),
              fontStyle: FontStyle.italic,
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
        // Sidebar - 3/12 width
        Expanded(flex: 3, child: _buildSidebar()),
        const SizedBox(width: 24),
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
        if (resumeData.email.isNotEmpty ||
            resumeData.phone.isNotEmpty ||
            resumeData.location.isNotEmpty) ...[
          _buildContactCard(),
          const SizedBox(height: 24),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSkillsCard(),
          const SizedBox(height: 24),
        ],
        if (resumeData.languages.isNotEmpty) ...[
          _buildLanguagesCard(),
          const SizedBox(height: 24),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildCertificationsCard(),
          const SizedBox(height: 24),
        ],
        if (resumeData.achievements.isNotEmpty) ...[
          _buildAchievementsCard(),
          const SizedBox(height: 24),
        ],
        if (resumeData.interests.isNotEmpty) ...[_buildHobbiesCard()],
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
        if (resumeData.experiences.isNotEmpty) ...[
          _buildExperienceSection(),
          const SizedBox(height: 24),
        ],
        if (resumeData.educations.isNotEmpty) ...[_buildEducationSection()],
      ],
    );
  }

  Widget _buildContactCard() {
    return _buildCard(
      title: 'Contact',
      child: Column(
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
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return _buildCard(
      title: 'Skills',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: resumeData.skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7C3AED),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguagesCard() {
    return _buildCard(
      title: 'Languages',
      child: Column(
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
    );
  }

  Widget _buildCertificationsCard() {
    return _buildCard(
      title: 'Certifications',
      child: Column(
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
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return _buildCard(
      title: 'Achievements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: resumeData.achievements.map((achievement) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              achievement,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHobbiesCard() {
    return _buildCard(
      title: 'Hobbies',
      child: Column(
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
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About Me'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            resumeData.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.6,
            ),
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
        const SizedBox(height: 12),
        Column(
          children: resumeData.experiences
              .map((exp) => _buildExperienceCard(exp))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Education'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: resumeData.educations
                .map((edu) => _buildEducationItem(edu))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(WorkExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.position,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${exp.company} | ${_formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : _formatDate(exp.endDate)}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          edu.institution,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          edu.degree,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
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
