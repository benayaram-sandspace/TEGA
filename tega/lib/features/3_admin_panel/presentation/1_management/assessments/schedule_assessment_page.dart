import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.whiteShade2,
      body: Column(
        children: [
          _buildNavigationMenu(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedNavIndex == index;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildNavButton(item, isSelected, index),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavButton(NavItem item, bool isSelected, int index) {
    if (isSelected) {
      return ElevatedButton.icon(
        onPressed: () {
          setState(() => _selectedNavIndex = index);
        },
        icon: Icon(
          item.icon,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          item.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Blue color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
          size: 18,
          color: Colors.grey[700],
        ),
        label: Text(
          item.label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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

