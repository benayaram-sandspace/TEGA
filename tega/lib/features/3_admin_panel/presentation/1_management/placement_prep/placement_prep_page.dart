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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Container(
      color: AdminDashboardStyles.background,
      child: Column(
        children: [
          _buildTabNavigation(isMobile, isTablet, isDesktop),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 12
            : isTablet
            ? 16
            : 20,
        vertical: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              label: 'Questions',
              icon: Icons.description_outlined,
              isActive: _selectedTabIndex == 0,
              isFirst: true,
              isLast: false,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          ),
          SizedBox(
            width: isMobile
                ? 8
                : isTablet
                ? 10
                : 12,
          ),
          Expanded(
            child: _buildTabButton(
              index: 1,
              label: 'Modules',
              icon: Icons.book_outlined,
              isActive: _selectedTabIndex == 1,
              isFirst: false,
              isLast: false,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          ),
          SizedBox(
            width: isMobile
                ? 8
                : isTablet
                ? 10
                : 12,
          ),
          Expanded(
            child: _buildTabButton(
              index: 2,
              label: 'Analytics',
              icon: Icons.bar_chart_outlined,
              isActive: _selectedTabIndex == 2,
              isFirst: false,
              isLast: true,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
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
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            isFirst
                ? (isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12)
                : 0,
          ),
          topRight: Radius.circular(
            isLast
                ? (isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12)
                : 0,
          ),
          bottomLeft: Radius.circular(
            isFirst
                ? (isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12)
                : 0,
          ),
          bottomRight: Radius.circular(
            isLast
                ? (isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12)
                : 0,
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 10
                : isTablet
                ? 13
                : 16,
            vertical: isMobile
                ? 10
                : isTablet
                ? 12
                : 14,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AdminDashboardStyles.primary
                : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                isFirst
                    ? (isMobile
                          ? 10
                          : isTablet
                          ? 11
                          : 12)
                    : 0,
              ),
              topRight: Radius.circular(
                isLast
                    ? (isMobile
                          ? 10
                          : isTablet
                          ? 11
                          : 12)
                    : 0,
              ),
              bottomLeft: Radius.circular(
                isFirst
                    ? (isMobile
                          ? 10
                          : isTablet
                          ? 11
                          : 12)
                    : 0,
              ),
              bottomRight: Radius.circular(
                isLast
                    ? (isMobile
                          ? 10
                          : isTablet
                          ? 11
                          : 12)
                    : 0,
              ),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AdminDashboardStyles.primary.withOpacity(0.3),
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
                size: isMobile
                    ? 18
                    : isTablet
                    ? 19
                    : 20,
              ),
              SizedBox(
                width: isMobile
                    ? 5
                    : isTablet
                    ? 5.5
                    : 6,
              ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile
                        ? 12
                        : isTablet
                        ? 13
                        : 14,
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
