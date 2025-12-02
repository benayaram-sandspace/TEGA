import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_notification_page.dart';
import 'package:tega/features/5_student_dashboard/presentation/4_profile_and_settings/student_avatar_screen.dart';
import 'package:tega/features/5_student_dashboard/presentation/shared/widgets/profile_picture_widget.dart';

class StudentDashboardHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final int notificationCount;
  final String title;
  final Map<String, dynamic>? profileData;

  const StudentDashboardHeader({
    super.key,
    required this.onMenuTap,
    this.notificationCount = 0,
    this.title = 'Dashboard',
    this.profileData,
  });

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Dashboard':
        return Icons.home_rounded;
      case 'Explore Courses':
        return Icons.school_rounded;
      case 'Placement Prep':
        return Icons.business_center_rounded;
      case 'Exams':
        return Icons.assignment_rounded;
      case 'My Results':
        return Icons.assessment_rounded;
      case 'Jobs':
        return Icons.work_rounded;
      case 'Internships':
        return Icons.work_outline_rounded;
      case 'Resume Builder':
        return Icons.description_rounded;
      case 'AI Assistant':
        return Icons.psychology_rounded;
      case 'Notifications':
        return Icons.notifications_rounded;
      case 'Learning History':
        return Icons.history_rounded;
      case 'Transaction History':
        return Icons.receipt_long_rounded;
      case 'Start Payment':
        return Icons.payment_rounded;
      case 'Help & Support':
        return Icons.help_rounded;
      case 'Settings':
        return Icons.settings_rounded;
      case 'Profile':
        return Icons.person_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final isLargeDesktop = screenWidth >= 1440;
    final isSmallScreen = screenWidth < 400;

    // Responsive padding
    final horizontalPadding = isLargeDesktop
        ? 24.0
        : isDesktop
        ? 20.0
        : isTablet
        ? 18.0
        : isSmallScreen
        ? 12.0
        : 16.0;

    final verticalPadding = isLargeDesktop
        ? 16.0
        : isDesktop
        ? 14.0
        : isTablet
        ? 12.0
        : isSmallScreen
        ? 10.0
        : 12.0;

    // Responsive icon sizes
    final menuIconSize = isLargeDesktop
        ? 28.0
        : isDesktop
        ? 26.0
        : isTablet
        ? 24.0
        : 22.0;

    final titleIconSize = isLargeDesktop
        ? 26.0
        : isDesktop
        ? 24.0
        : isTablet
        ? 22.0
        : 20.0;

    final notificationIconSize = isLargeDesktop
        ? 26.0
        : isDesktop
        ? 24.0
        : isTablet
        ? 22.0
        : 20.0;

    final titleFontSize = isLargeDesktop
        ? 20.0
        : isDesktop
        ? 18.0
        : isTablet
        ? 17.0
        : isSmallScreen
        ? 15.0
        : 16.0;

    final avatarRadius = isLargeDesktop
        ? 20.0
        : isDesktop
        ? 18.0
        : isTablet
        ? 17.0
        : 16.0;

    final buttonPadding = isLargeDesktop
        ? 10.0
        : isDesktop
        ? 9.0
        : isTablet
        ? 8.0
        : 7.0;

    final borderRadius = isLargeDesktop
        ? 14.0
        : isDesktop
        ? 12.0
        : isTablet
        ? 11.0
        : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button (Left) with glass effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B5FFF).withOpacity(0.1),
                  const Color(0xFF6B5FFF).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMenuTap();
                },
                borderRadius: BorderRadius.circular(borderRadius),
                splashColor: const Color(0xFF6B5FFF).withOpacity(0.2),
                child: Container(
                  padding: EdgeInsets.all(buttonPadding),
                  child: Icon(
                    Icons.menu_rounded,
                    size: menuIconSize,
                    color: const Color(0xFF6B5FFF),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          // Page title (Center) with icon and black text
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForTitle(title),
                    size: titleIconSize,
                    color: const Color(0xFF6B5FFF),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          // Notification icon with animation
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Container(
                      padding: EdgeInsets.all(buttonPadding),
                      child: Icon(
                        Icons.notifications_outlined,
                        size: notificationIconSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: isSmallScreen ? 3 : 4,
                  top: isSmallScreen ? 3 : 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 5,
                      vertical: isSmallScreen ? 1 : 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: isSmallScreen ? 16 : 18,
                      minHeight: isSmallScreen ? 16 : 18,
                    ),
                    child: Center(
                      child: Text(
                        '$notificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 9 : 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          // Profile Avatar with elegant design
          Hero(
            tag: 'avatarHero',
            child: ProfilePictureWidget(
              profilePhotoUrl: profileData?['profilePhoto'],
              username: profileData?['username'] ?? profileData?['email'],
              firstName: profileData?['firstName'],
              lastName: profileData?['lastName'],
              radius: avatarRadius,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AvatarScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
