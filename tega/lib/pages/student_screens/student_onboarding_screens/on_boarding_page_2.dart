import 'package:flutter/material.dart';
import 'package:tega/pages/student_screens/student_onboarding_screens/on_boarding_page_1.dart';
import 'package:tega/pages/student_screens/student_onboarding_screens/on_boarding_page_3.dart';

class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  // List of interests
  final List<String> interests = [
    "IT / Software Development",
    "Government Services",
    "Startups & Innovation",
    "Business / Finance",
    "Core Engineering",
    "Data Analytics",
    "Design / UI-UX",
    "Healthcare / Life Sciences",
    "Teaching / Education",
    "Banking & Insurance",
    "Entrepreneurship",
  ];

  // Track selected items
  final Set<String> selectedInterests = {};

  void toggleInterest(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        if (selectedInterests.length < 5) {
          selectedInterests.add(interest);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back Arrow + Title Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CareerDiscoveryWelcome(),
                        ),
                      );
                    },
                  ),
                  const Text(
                    "What are you interested in\nafter college?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔵 Progress Bar (Step 2 of 6 → 33%)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Step 2 of 6',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.33, // 2/6 = 33%
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA726),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    '33% Complete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                "(Choose up to 5)",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Interests list
              Expanded(
                child: ListView.builder(
                  itemCount: interests.length,
                  itemBuilder: (context, index) {
                    final interest = interests[index];
                    final isSelected = selectedInterests.contains(interest);

                    return GestureDetector(
                      onTap: () => toggleInterest(interest),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFA726)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFA726)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForInterest(interest),
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                interest,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Bottom buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Skip action → directly go to next onboarding
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen3(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Next → goes to next onboarding
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen3(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA726),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Next →",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to assign icons
  IconData _getIconForInterest(String interest) {
    switch (interest) {
      case "IT / Software Development":
        return Icons.computer;
      case "Government Services":
        return Icons.account_balance;
      case "Startups & Innovation":
        return Icons.lightbulb_outline;
      case "Business / Finance":
        return Icons.show_chart;
      case "Core Engineering":
        return Icons.settings;
      case "Data Analytics":
        return Icons.bar_chart;
      case "Design / UI-UX":
        return Icons.brush;
      case "Healthcare / Life Sciences":
        return Icons.healing;
      case "Teaching / Education":
        return Icons.school;
      case "Banking & Insurance":
        return Icons.account_balance_wallet;
      case "Entrepreneurship":
        return Icons.rocket_launch;
      default:
        return Icons.circle;
    }
  }
}
