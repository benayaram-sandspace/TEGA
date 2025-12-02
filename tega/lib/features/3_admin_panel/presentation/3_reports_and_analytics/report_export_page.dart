import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/3_reports_and_analytics/college_report_page.dart';
import 'package:tega/features/3_admin_panel/presentation/3_reports_and_analytics/custom_report_builder.dart';
import 'package:tega/features/3_admin_panel/presentation/3_reports_and_analytics/student_report_builder.dart';

// A simple data model for our report cards for cleaner code
class ReportInfo {
  final IconData iconData;
  final Color iconColor;
  final Color
  backgroundColor; // This will be the accent color for the icon section
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  ReportInfo({
    required this.iconData,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });
}

// Reports & Export Center Page - Now a StatefulWidget for animations
class ReportsExportCenterPage extends StatefulWidget {
  const ReportsExportCenterPage({super.key});

  @override
  State<ReportsExportCenterPage> createState() =>
      _ReportsExportCenterPageState();
}

class _ReportsExportCenterPageState extends State<ReportsExportCenterPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<ReportInfo> _reports;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to build the list of reports
  void _buildReports(BuildContext context) {
    _reports = [
      ReportInfo(
        iconData: Icons.school_outlined,
        iconColor: const Color(0xFFD4A574), // More vibrant icon color
        backgroundColor: const Color(
          0xFFF5E6D8,
        ), // Lighter background for the icon section
        title: 'College-Wise Report',
        description: 'Generate a comprehensive report for all colleges.',
        buttonText: 'Generate Report',
        onPressed: () =>
            _navigateTo(context, const ConfigureCollegeReportPage()),
      ),
      ReportInfo(
        iconData: Icons.person_search_outlined,
        iconColor: const Color(0xFF506A6B), // Darker icon for contrast
        backgroundColor: const Color(0xFFB8CDCE), // Lighter background
        title: 'Student-Wise Report',
        description: 'Generate a detailed report for individual students.',
        buttonText: 'Generate Report',
        onPressed: () =>
            _navigateTo(context, const ConfigureStudentReportPage()),
      ),
      ReportInfo(
        iconData: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF5A8D6F), // Muted green for icon
        backgroundColor: const Color(0xFFC7E0D3), // Lighter background
        title: 'Custom Report Builder',
        description: 'Create tailored reports with specific data points.',
        buttonText: 'Create Custom Report',
        onPressed: () => _navigateTo(context, const CustomReportBuilderPage()),
      ),
    ];
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    _buildReports(context); // Build the list
    return Container(
      color: AdminDashboardStyles.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Analytics',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AdminDashboardStyles.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate comprehensive reports and export data',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AdminDashboardStyles.textLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    // Quick Stats - Made responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 600;
                        return isSmallScreen
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          'Total Reports',
                                          '24',
                                          Icons.assessment,
                                          AdminDashboardStyles.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          'This Month',
                                          '8',
                                          Icons.calendar_month,
                                          AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          'Exports',
                                          '156',
                                          Icons.download,
                                          AppColors.info,
                                        ),
                                      ),
                                      const Expanded(
                                        child: SizedBox(),
                                      ), // Empty space
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickStatCard(
                                      'Total Reports',
                                      '24',
                                      Icons.assessment,
                                      AdminDashboardStyles.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickStatCard(
                                      'This Month',
                                      '8',
                                      Icons.calendar_month,
                                      AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickStatCard(
                                      'Exports',
                                      '156',
                                      Icons.download,
                                      AppColors.info,
                                    ),
                                  ),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),

              // Reports Grid - Made responsive
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                    final childAspectRatio = constraints.maxWidth > 600
                        ? 0.8
                        : 1.2;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return AnimatedCard(
                          animationController: _animationController,
                          index: index,
                          child: ModernReportCard(
                            iconData: report.iconData,
                            iconColor: report.iconColor,
                            backgroundColor: report.backgroundColor,
                            title: report.title,
                            description: report.description,
                            buttonText: report.buttonText,
                            onPressed: report.onPressed,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AdminDashboardStyles.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Report Card with enhanced design
class ModernReportCard extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  const ModernReportCard({
    super.key,
    required this.iconData,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminDashboardStyles.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, color: iconColor, size: 32),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdminDashboardStyles.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminDashboardStyles.textLight,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminDashboardStyles.primary,
                    foregroundColor: AdminDashboardStyles.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Legacy Report Card (keeping for compatibility)
class ReportCard extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  const ReportCard({
    super.key,
    required this.iconData,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Deep Teal gradient for the main card background
    const Color primaryDarkTeal = Color(0xFF004D40); // Darker teal
    const Color primaryMidTeal = Color(0xFF00695C); // Mid-range teal

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [primaryDarkTeal, primaryMidTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDarkTeal.withValues(
              alpha: 0.4,
            ), // Shadow reflecting new color
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with Icon - uses the accent background color
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    backgroundColor.withValues(alpha: 0.9),
                    backgroundColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.2,
                  ), // Slightly more opaque white accent
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(iconData, size: 48, color: iconColor),
              ),
            ),

            // Bottom section with Text and Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFC107), // Gold accent
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.9,
                      ), // Slightly more prominent white text
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.3),
                    ), // Divider for visual break
                  ),
                  // Button with gradient
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFC107),
                        ], // Gold gradient
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFC107,
                          ).withValues(alpha: 0.4), // Gold shadow
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent, // Transparent to show gradient
                        shadowColor: Colors
                            .transparent, // No shadow from ElevatedButton itself
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonText,
                            style: const TextStyle(color: Colors.black87),
                          ), // Dark text for contrast
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black87,
                          ), // Dark icon
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A new widget to handle the animation for each card
class AnimatedCard extends StatelessWidget {
  final AnimationController animationController;
  final int index;
  final Widget child;

  const AnimatedCard({
    super.key,
    required this.animationController,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Stagger the animation of each card
    final interval = Interval(
      (0.1 * index), // Start time for this card's animation
      0.8, // End time for all cards (adjust as needed)
      curve: Curves.easeOut,
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        // Only animate if the animation is actually running
        if (!animationController.isAnimating &&
            animationController.value == 0) {
          return const SizedBox.shrink(); // Or return the child directly without animation
        }

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animationController, curve: interval),
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.3), // Slide up from slightly below
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animationController, curve: interval),
                ),
            child: child,
          ),
        );
      },
    );
  }
}
