import 'package:flutter/material.dart';
import 'on_boarding_page_2.dart';
import 'on_boarding_page_4.dart';
import 'on_boarding_page_6.dart'; // <-- Create this screen

class OnboardingScreen5 extends StatelessWidget {
  const OnboardingScreen5({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Top section with back + progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen4(),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    "STEP 5 OF 6",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: 5 / 6,
                backgroundColor: Theme.of(
                  context,
                ).dividerColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🔽 Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎉 Celebration Icon
                    const Center(
                      child: Text("🎉", style: TextStyle(fontSize: 36)),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      "Ramesh, here's your Career Snapshot",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Based on your responses, we've identified your strengths and growth areas",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Top Career Domains
                    _buildCard(
                      context: context,
                      icon: Icons.work,
                      title: "Top Career Domains",
                      children: [
                        _buildTag("IT / Software Development"),
                        _buildTag("Government Services"),
                        _buildTag("Data Analytics"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Skill Strengths
                    _buildCard(
                      context: context,
                      icon: Icons.trending_up,
                      title: "Skill Strengths",
                      children: [
                        _buildTag(
                          "Communication",
                          suffix: "Strong",
                          color: Colors.green,
                        ),
                        _buildTag(
                          "Logical Reasoning",
                          suffix: "Medium",
                          color: Colors.orange,
                        ),
                        _buildTag(
                          "Teamwork",
                          suffix: "Strong",
                          color: Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Areas for Growth
                    _buildCard(
                      context: context,
                      icon: Icons.warning,
                      title: "Areas for Growth",
                      children: [
                        _buildTag("English Writing", color: Colors.red),
                        _buildTag("Domain Knowledge", color: Colors.red),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 🔹 Bottom Action Buttons
                    ElevatedButton(
                      onPressed: () {
                        // ✅ Go to last onboarding page (Screen 6)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen6(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "✅ Yes, I'm ready to start!",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () {
                        // 🔙 Go back to tweak skills (Screen 2)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen2(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      label: Text(
                        "Edit Responses",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTag(String text, {String? suffix, Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (color ?? Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.green),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: color ?? Colors.green),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: color ?? Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (suffix != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    color?.withOpacity(0.15) ?? Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                suffix,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
