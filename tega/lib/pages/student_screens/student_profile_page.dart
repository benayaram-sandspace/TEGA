import 'package:flutter/material.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/pages/student_screens/student_ai_job_search_page.dart';
import 'package:tega/pages/student_screens/student_home_page.dart';
import 'package:tega/pages/student_screens/student_profile_pages/student_edit_profile_page.dart';
import 'package:tega/pages/student_screens/student_profile_pages/student_help_page.dart';
import 'package:tega/pages/student_screens/student_profile_pages/student_setting_page.dart';
import 'package:tega/services/auth_service.dart';

class StudentProfilePage extends StatelessWidget {
  // ... (constructor and _handleLogout method are unchanged)
  final String studentName;
  final String course;
  final String year;
  final String college;
  final AuthService _authService = AuthService();

  StudentProfilePage({
    Key? key,
    this.studentName = 'Ramesh',
    this.course = 'CSE',
    this.year = '3rd Year',
    this.college = 'AI College',
  }) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _authService.logout();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await Future.delayed(const Duration(milliseconds: 100));

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) => const LoginPage(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => StudentHomePage()),
            );
          },
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(
              context,
            ), // This method has the borderRadius removed now
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 20),
            _buildSettingsMenu(context), // This method now handles navigation
            const SizedBox(height: 40),
            Image.asset(
              'assets/logo.png',
              height: 80,
              opacity: const AlwaysStoppedAnimation(.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // UPDATED: This widget has the borderRadius removed
  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5FFF), Color(0xFF4A47A3)],
        ),
        // borderRadius property was here, now it is removed.
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/32.jpg',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // UPDATED: Navigate to the actual Edit Profile page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6B5FFF),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFF6B5FFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            studentName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'B.Tech | $course | $year | $college',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ... (_buildStatsSection and _buildStatCard are unchanged)
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(Icons.check_circle, '75%', 'Job Readiness'),
          _buildStatCard(Icons.star, '1,250', 'XP Earned'),
          _buildStatCard(Icons.psychology, '15', 'Skills Mastered'),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6B5FFF), size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: This widget now navigates to the new pages
  Widget _buildSettingsMenu(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuOption(
            icon: Icons.person_outline,
            title: 'Edit Profile', // Changed title for clarity
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
          _buildMenuOption(
            icon: Icons.settings_outlined,
            title: 'App Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          _buildMenuOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              );
            },
          ),
          const Divider(indent: 20, endIndent: 20),
          _buildMenuOption(
            icon: Icons.logout,
            title: 'Logout',
            isLogout: true,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  // ... (_buildMenuOption is unchanged)
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout ? Colors.redAccent : Colors.black87;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
