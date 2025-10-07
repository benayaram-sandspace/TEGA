import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For the line chart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';

class OnboardingScreen6 extends StatelessWidget {
  const OnboardingScreen6({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // 🔹 Top Icon (Brain)
              const FaIcon(
                FontAwesomeIcons.brain,
                size: 60,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 15),

              // 🔹 Title
              const Text(
                "Your Career Engine is Ready!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We’ve built your personalized Skill Graph based on your answers. Here’s what we found:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 20),

              // 🔹 Line Chart
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final skills = [
                              "Comm.",
                              "Problem Solv.",
                              "Domain",
                              "Reasoning",
                              "Eng. Writing",
                              "Teamwork",
                            ];
                            if (value.toInt() >= 0 &&
                                value.toInt() < skills.length) {
                              return Transform.rotate(
                                angle: -0.6, // 🔹 Rotate text ~ -34 degrees
                                child: Text(
                                  skills[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text("");
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        spots: const [
                          FlSpot(0, 5),
                          FlSpot(1, 4),
                          FlSpot(2, 2),
                          FlSpot(3, 3.5),
                          FlSpot(4, 2.5),
                          FlSpot(5, 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Skills List
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Skills Mapped:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildSkillTile(
                "Communication",
                Colors.green,
                "4.5/5",
                Icons.check_circle,
              ),
              _buildSkillTile(
                "Problem Solving",
                Colors.blue,
                "4/5",
                Icons.check_circle,
              ),
              _buildSkillTile(
                "Domain Knowledge",
                Colors.orange,
                "2/5",
                Icons.error,
              ),
              _buildSkillTile(
                "Reasoning",
                Colors.purple,
                "3.5/5",
                Icons.check_circle,
              ),
              _buildSkillTile(
                "English Writing",
                Colors.red,
                "2.5/5",
                Icons.error,
              ),

              const SizedBox(height: 20),

              // 🔹 Ready Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.deepPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🎉 You’re Ready!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "You’re now ready to explore your career paths, close skill gaps, and grow daily. Your personalized journey starts here!",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Final CTA Button (with 🚀 rocket)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentHomePage(),
                    ),
                    (route) => false, // 🔹 Removes all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.rocket,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Enter Skill Explorer Home",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable Skill Tile
  Widget _buildSkillTile(
    String skill,
    Color color,
    String rating,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                skill,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            rating,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
