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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMenuTap();
                },
                borderRadius: BorderRadius.circular(12),
                splashColor: const Color(0xFF6B5FFF).withOpacity(0.2),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.menu_rounded,
                    size: 26,
                    color: Color(0xFF6B5FFF),
                  ),
                ),
              ),
            ),
          ),
          // Page title (Center) with icon and black text
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForTitle(title),
                    size: 24,
                    color: const Color(0xFF6B5FFF),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Notification icon with animation
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 24,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
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
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Profile Avatar with elegant design
          Hero(
            tag: 'avatarHero',
            child: ProfilePictureWidget(
              profilePhotoUrl: profileData?['profilePhoto'],
              username: profileData?['username'] ?? profileData?['email'],
              firstName: profileData?['firstName'],
              lastName: profileData?['lastName'],
              radius: 17,
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
