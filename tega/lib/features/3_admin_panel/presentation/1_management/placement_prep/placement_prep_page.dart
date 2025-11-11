import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/placement_prep/questions_tab.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/placement_prep/modules_tab.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/placement_prep/analytics_tab.dart';

class PlacementPrepPage extends StatefulWidget {
  const PlacementPrepPage({super.key});

  @override
  State<PlacementPrepPage> createState() => _PlacementPrepPageState();
}

class _PlacementPrepPageState extends State<PlacementPrepPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboardStyles.background,
      child: Column(
        children: [
          _buildTabNavigation(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            label: 'Questions',
            icon: Icons.description_outlined,
            isActive: _selectedTabIndex == 0,
            isFirst: true,
          ),
          _buildTabButton(
            index: 1,
            label: 'Modules',
            icon: Icons.book_outlined,
            isActive: _selectedTabIndex == 1,
            isFirst: false,
            isLast: false,
          ),
          _buildTabButton(
            index: 2,
            label: 'Analytics',
            icon: Icons.bar_chart_outlined,
            isActive: _selectedTabIndex == 2,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isActive,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 12 : 0),
            topRight: Radius.circular(isLast ? 12 : 0),
            bottomLeft: Radius.circular(isFirst ? 12 : 0),
            bottomRight: Radius.circular(isLast ? 12 : 0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1E9E5F) : const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isFirst ? 12 : 0),
                topRight: Radius.circular(isLast ? 12 : 0),
                bottomLeft: Radius.circular(isFirst ? 12 : 0),
                bottomRight: Radius.circular(isLast ? 12 : 0),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1E9E5F).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : const Color(0xFF343A40),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF343A40),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const QuestionsTab();
      case 1:
        return const ModulesTab();
      case 2:
        return const AnalyticsTab();
      default:
        return const QuestionsTab();
    }
  }
}

