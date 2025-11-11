import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/company_questions/upload_pdf_tab.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/company_questions/manage_questions_tab.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/company_questions/add_question_tab.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/company_questions/companies_tab.dart';

class CompanyQuestionsPage extends StatefulWidget {
  const CompanyQuestionsPage({super.key});

  @override
  State<CompanyQuestionsPage> createState() => _CompanyQuestionsPageState();
}

class _CompanyQuestionsPageState extends State<CompanyQuestionsPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabNavigation(),
          const SizedBox(height: 20),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabButton(
            icon: Icons.upload_rounded,
            label: 'Upload PDF',
            index: 0,
          ),
          const SizedBox(width: 12),
          _buildTabButton(
            icon: Icons.description_rounded,
            label: 'Manage Questions',
            index: 1,
          ),
          const SizedBox(width: 12),
          _buildTabButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add Question',
            index: 2,
          ),
          const SizedBox(width: 12),
          _buildTabButton(
            icon: Icons.business_rounded,
            label: 'Companies',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedTabIndex == index;
    
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AdminDashboardStyles.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AdminDashboardStyles.primary : AdminDashboardStyles.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AdminDashboardStyles.textDark,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AdminDashboardStyles.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const UploadPdfTab();
      case 1:
        return const ManageQuestionsTab();
      case 2:
        return const AddQuestionTab();
      case 3:
        return const CompaniesTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

