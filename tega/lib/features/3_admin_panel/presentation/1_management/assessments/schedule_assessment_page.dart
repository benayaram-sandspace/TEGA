import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/assessments/create_assessment_form_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/assessments/question_papers_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/assessments/manage_exams_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/assessments/registrations_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/assessments/exam_results_page.dart';

class ScheduleAssessmentPage extends StatefulWidget {
  const ScheduleAssessmentPage({super.key});

  @override
  State<ScheduleAssessmentPage> createState() => _ScheduleAssessmentPageState();
}

class _ScheduleAssessmentPageState extends State<ScheduleAssessmentPage> {
  int _selectedNavIndex = 0;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Schedule Assessment',
      isActive: true,
    ),
    NavItem(
      icon: Icons.folder_rounded,
      label: 'Question Papers',
      isActive: false,
    ),
    NavItem(
      icon: Icons.description_rounded,
      label: 'Manage Exams',
      isActive: false,
    ),
    NavItem(
      icon: Icons.people_rounded,
      label: 'Registrations',
      isActive: false,
    ),
    NavItem(
      icon: Icons.assignment_turned_in_rounded,
      label: 'Exam Results',
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: AppColors.whiteShade2,
      body: Column(
        children: [
          _buildNavigationMenu(isMobile, isTablet, isDesktop),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : isTablet ? 16 : 20),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : isTablet ? 14 : 16,
        vertical: isMobile ? 10 : isTablet ? 11 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedNavIndex == index;
            
            return Padding(
              padding: EdgeInsets.only(right: isMobile ? 6 : isTablet ? 7 : 8),
              child: _buildNavButton(item, isSelected, index, isMobile, isTablet, isDesktop),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    NavItem item,
    bool isSelected,
    int index,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    if (isSelected) {
      return ElevatedButton.icon(
        onPressed: () {
          setState(() => _selectedNavIndex = index);
        },
        icon: Icon(
          item.icon,
          size: isMobile ? 16 : isTablet ? 17 : 18,
          color: Colors.white,
        ),
        label: Text(
          item.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 12 : isTablet ? 13 : 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminDashboardStyles.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : isTablet ? 14 : 16,
            vertical: isMobile ? 10 : isTablet ? 11 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
          ),
          elevation: 0,
        ),
      );
    } else {
      return TextButton.icon(
        onPressed: () {
          setState(() => _selectedNavIndex = index);
        },
        icon: Icon(
          item.icon,
          size: isMobile ? 16 : isTablet ? 17 : 18,
          color: AdminDashboardStyles.primary.withOpacity(0.6),
        ),
        label: Text(
          item.label,
          style: TextStyle(
            color: AdminDashboardStyles.primary.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : isTablet ? 13 : 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : isTablet ? 14 : 16,
            vertical: isMobile ? 10 : isTablet ? 11 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
          ),
        ),
      );
    }
  }

  Widget _buildContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildScheduleAssessmentContent();
      case 1:
        return _buildQuestionPapersContent();
      case 2:
        return _buildManageExamsContent();
      case 3:
        return _buildRegistrationsContent();
      case 4:
        return _buildExamResultsContent();
      default:
        return _buildScheduleAssessmentContent();
    }
  }

  Widget _buildScheduleAssessmentContent() {
    return const CreateAssessmentFormPage();
  }

  Widget _buildQuestionPapersContent() {
    return const QuestionPapersPage();
  }

  Widget _buildManageExamsContent() {
    return const ManageExamsPage();
  }

  Widget _buildRegistrationsContent() {
    return const RegistrationsPage();
  }

  Widget _buildExamResultsContent() {
    return const ExamResultsPage();
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final bool isActive;

  NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });
}

