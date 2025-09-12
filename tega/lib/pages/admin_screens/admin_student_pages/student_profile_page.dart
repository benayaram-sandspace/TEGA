import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/student.dart';
import 'package:tega/pages/admin_screens/reports/progress_report_generator_page.dart';

class StudentProfilePage extends StatelessWidget {
  final Student student;

  const StudentProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent, // Modern touch for AppBar
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Header Section - Enhanced for visual appeal
            _buildProfileHeader(),

            // Rest of the content with consistent padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobReadinessSection(context),
                  const SizedBox(height: 24),
                  _buildCareerPathsSection(),
                  const SizedBox(height: 24),
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 24),
                  _buildAcademicDetailsSection(),
                  const SizedBox(height: 24),
                  _buildInterestsSection(),
                  const SizedBox(height: 24),
                  _buildResumeSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main profile header with avatar and name.
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Using CircleAvatar for a more standard profile picture look.
          CircleAvatar(
            radius: 55,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.person_outline,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            student.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Grouping email and ID with icons for clarity.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'priya.sharma@example.com',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.badge_outlined,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Student ID: 123456',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A helper to build the container for each section, ensuring a consistent look.
  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// A helper to build section headers with an optional icon.
  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// A more visual Job Readiness section with a progress circle.
  Widget _buildJobReadinessSection(BuildContext context) {
    return _buildSectionContainer(
      child: Row(
        children: [
          // A CircularProgressIndicator is a great way to visualize percentages.
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.75, // Score (75%)
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
                Center(
                  child: const Text(
                    '75%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Button with an icon for better affordance.
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Generate Report'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProgressReportGeneratorPage(student: student),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerPathsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Recommended Career Paths',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 20),
          _buildCareerPathItem('Software Development', 75),
          const SizedBox(height: 18),
          _buildCareerPathItem('Data Science', 60),
          const SizedBox(height: 18),
          _buildCareerPathItem('Machine Learning Engineering', 50),
        ],
      ),
    );
  }

  /// Career path item with a LinearProgressIndicator for better data visualization.
  Widget _buildCareerPathItem(String title, int readiness) {
    double progress = readiness / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$readiness% Match',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Personal Information',
            icon: Icons.person_pin_outlined,
          ),
          const SizedBox(height: 16),
          // Using SizedBox instead of Dividers for a cleaner, more spacious look.
          _buildInfoRow('Full Name', student.name),
          const SizedBox(height: 16),
          _buildInfoRow('Email', 'priya.sharma@example.com'),
          const SizedBox(height: 16),
          _buildInfoRow('College', 'IIT Delhi'),
          const SizedBox(height: 16),
          _buildInfoRow('Branch', 'Computer Science'),
          const SizedBox(height: 16),
          _buildInfoRow('Year of Study', '3rd Year'),
        ],
      ),
    );
  }

  Widget _buildAcademicDetailsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Academic Details', icon: Icons.school_outlined),
          const SizedBox(height: 16),
          _buildInfoRow('CGPA / % Marks', '8.5 / 85%'),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Interests', icon: Icons.interests_outlined),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInterestTag('Coding'),
              _buildInterestTag('Machine Learning'),
              _buildInterestTag('Web Development'),
              _buildInterestTag('Data Analysis'),
              _buildInterestTag('Problem Solving'),
            ],
          ),
        ],
      ),
    );
  }

  /// A more modern "pill" style for interest tags.
  Widget _buildInterestTag(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        interest,
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Using a ListTile for the resume section, a standard for tappable list items.
  Widget _buildResumeSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Uploaded Resume',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'View Priya_Sharma_Resume.pdf',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
            onTap: () {
              // TODO: Add logic to open/view the resume PDF.
            },
          ),
        ],
      ),
    );
  }

  /// A generic row for displaying a label and a value.
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
