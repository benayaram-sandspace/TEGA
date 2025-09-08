import 'package:flutter/material.dart';
import 'package:tega/pages/admin_dashboard.dart';
import 'package:tega/pages/college_report_page.dart';
import 'package:tega/pages/custom_report_builder.dart';
import 'package:tega/pages/student_report_builder.dart';

// Reports & Export Center Page
class ReportsExportCenterPage extends StatelessWidget {
  const ReportsExportCenterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reports & Export Center',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (route) => false,
            );
          },
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // College-Wise Report Card
          ReportCard(
            imageWidget: const CollegeIllustration(),
            title: 'College-Wise Report',
            titleColor: const Color(0xFFFFC107),
            description: 'Generate a comprehensive report for all colleges.',
            subtitleText: 'College-Wise Report',
            buttonText: 'Generate',
            buttonColor: const Color(0xFFFFC107),
            onPressed: () {
              _generateCollegeReport(context);
            },
          ),
          const SizedBox(height: 16),

          // Student-Wise Report Card
          ReportCard(
            imageWidget: const StudentIllustration(),
            title: 'Student-Wise Report',
            titleColor: const Color(0xFFFFC107),
            description: 'Generate a detailed report for individual students.',
            subtitleText: 'Student-Wise Report',
            buttonText: 'Generate',
            buttonColor: const Color(0xFFFFC107),
            onPressed: () {
              _generateStudentReport(context);
            },
          ),
          const SizedBox(height: 16),

          // Custom Report Builder Card
          ReportCard(
            imageWidget: const ChartIllustration(),
            title: 'Custom Report Builder',
            titleColor: const Color(0xFFFFC107),
            description: 'Create tailored reports with specific data points.',
            subtitleText: 'Custom Report Builder',
            buttonText: 'Create Report',
            buttonColor: const Color(0xFFFFC107),
            onPressed: () {
              _openCustomReportBuilder(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening report settings...')));
  }

  void _generateCollegeReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigureCollegeReportPage(),
      ),
    );
  }

  void _generateStudentReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigureStudentReportPage(),
      ),
    );
  }

  void _openCustomReportBuilder(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => const CustomReportBuilderPage(),
        fullscreenDialog: false, // Ensure it's not treated as a dialog
      ),
    );
  }
}

// Reusable Report Card Widget
class ReportCard extends StatelessWidget {
  final Widget imageWidget;
  final String title;
  final Color titleColor;
  final String description;
  final String subtitleText;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  const ReportCard({
    Key? key,
    required this.imageWidget,
    required this.title,
    required this.titleColor,
    required this.description,
    required this.subtitleText,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF21209C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subtitleText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// College Building Illustration
class CollegeIllustration extends StatelessWidget {
  const CollegeIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF87CEEB), // Sky blue
            Color(0xFFB8E6B8), // Light green
          ],
        ),
      ),
      child: Stack(
        children: [
          // Clouds
          Positioned(top: 20, left: 30, child: _buildCloud()),
          Positioned(top: 30, right: 40, child: _buildCloud()),

          // Building
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main building
                Container(
                  width: 180,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A574),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // Windows
                      for (int i = 0; i < 3; i++)
                        for (int j = 0; j < 3; j++)
                          Positioned(
                            left: 20.0 + (i * 55),
                            top: 15.0 + (j * 30),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B7355),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      // Entrance
                      Positioned(
                        bottom: 0,
                        left: 75,
                        child: Container(
                          width: 30,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B5D54),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Ground
                Container(
                  width: 200,
                  height: 10,
                  color: const Color(0xFF90C890),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 40,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// Student with Laptop Illustration
class StudentIllustration extends StatelessWidget {
  const StudentIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5E6D8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Person icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4A574), width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 35),
            ),
            const SizedBox(height: 10),

            // Laptop
            Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF34495E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Container(
                  width: 65,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F8C8D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Plant decoration
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                width: 30,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF27AE60),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chart/Graph Illustration
class ChartIllustration extends StatelessWidget {
  const ChartIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
        ),
      ),
      child: Center(
        child: Container(
          width: 140,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Bar chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar(30),
                  _buildBar(50),
                  _buildBar(40),
                  _buildBar(70),
                  _buildBar(45),
                  _buildBar(60),
                  _buildBar(80),
                ],
              ),
              const SizedBox(height: 8),
              // X-axis line
              Container(height: 2, color: const Color(0xFF2E7D32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(2),
        ),
      ),
    );
  }
}

// Example of how to navigate to this page:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => const ReportsExportCenterPage(),
//   ),
// );
