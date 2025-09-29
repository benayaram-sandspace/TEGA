import 'package:flutter/material.dart';
import 'package:tega/features/5_student_dashboard/presentation/0_onboarding/on_boarding_page_2.dart';
import 'package:tega/features/5_student_dashboard/presentation/0_onboarding/on_boarding_page_4.dart';

class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({super.key});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  // Skills with their rating values
  final Map<String, int> skills = {
    "Communication": 0,
    "Teamwork": 0,
    "Logical Reasoning": 0,
    "Technical Knowledge": 0,
    "Public Speaking": 0,
    "English Writing": 0,
    "Problem Solving": 0,
    "Time Management": 0,
    "Leadership": 0,
  };

  // Icons for each skill
  final Map<String, IconData> skillIcons = {
    "Communication": Icons.psychology,
    "Teamwork": Icons.group,
    "Logical Reasoning": Icons.auto_stories,
    "Technical Knowledge": Icons.laptop_mac,
    "Public Speaking": Icons.record_voice_over,
    "English Writing": Icons.edit_note,
    "Problem Solving": Icons.extension,
    "Time Management": Icons.access_time,
    "Leadership": Icons.workspace_premium,
  };

  void setRating(String skill, int rating) {
    setState(() {
      skills[skill] = rating;
    });
  }

  bool allSkillsRated() {
    return skills.values.every((rating) => rating > 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed = allSkillsRated();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back Arrow + Heading
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen2(),
                        ),
                      );
                    },
                  ),
                  const Text(
                    "💪 What are your current\nstrengths?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔵 Progress Tracker (Bar style - Step 3 of 6)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Step 3 of 6',
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
                          widthFactor: 0.50, // ✅ 3/6 steps = 50%
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
                    '50% Complete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Text(
                "Rate each skill from 1 to 5",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "💡 Your answers help us tailor your Skill Graph.\nBe honest — there are no wrong answers!",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),

              const SizedBox(height: 20),

              // Skills list
              Expanded(
                child: ListView(
                  children: skills.keys.map((skill) {
                    int rating = skills[skill]!;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Skill name + rating number
                          Row(
                            children: [
                              Icon(
                                skillIcons[skill],
                                color: Colors.black87,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                "($rating)",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Rating circles
                          Row(
                            children: List.generate(5, (index) {
                              int circleValue = index + 1;
                              bool isSelected = circleValue <= rating;

                              return GestureDetector(
                                onTap: () => setRating(skill, circleValue),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFFFFA726)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // Bottom buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Skip → Go to OnboardingScreen4
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen4(),
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
                    onPressed: canProceed
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen4(),
                              ),
                            );
                          }
                        : null, // disabled when not all rated
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed
                          ? const Color(0xFFFFA726)
                          : Colors.grey.shade400,
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
}
