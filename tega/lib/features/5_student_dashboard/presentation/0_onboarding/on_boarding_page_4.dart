import 'package:flutter/material.dart';
import 'on_boarding_page_3.dart';
import 'on_boarding_page_5.dart';

class OnboardingScreen4 extends StatefulWidget {
  const OnboardingScreen4({super.key});

  @override
  State<OnboardingScreen4> createState() => _OnboardingScreen4State();
}

class _OnboardingScreen4State extends State<OnboardingScreen4> {
  int currentQuestion = 0;
  final Map<int, int> answers = {}; // Stores questionIndex -> optionIndex

  final List<Map<String, dynamic>> questions = [
    {
      "question":
          "Which of the following best describes effective communication in a team setting?",
      "options": [
        "Speaking loudly to ensure everyone hears",
        "Active listening and clear expression of ideas",
        "Using technical jargon to show expertise",
        "Avoiding disagreements at all costs",
      ],
    },
    {
      "question": "What’s the best way to resolve a conflict in a project?",
      "options": [
        "Ignore it and keep working",
        "Discuss openly and find common ground",
        "Let the manager handle everything",
        "Prove your point strongly until accepted",
      ],
    },
    {
      "question":
          "When working under a deadline, what’s the most effective approach?",
      "options": [
        "Work non-stop without breaks",
        "Prioritize tasks and manage time effectively",
        "Rush through everything quickly",
        "Wait until the last moment for motivation",
      ],
    },
  ];

  void selectOption(int optionIndex) {
    setState(() {
      answers[currentQuestion] = optionIndex;

      // Auto-move to next question if not last
      if (currentQuestion < questions.length - 1) {
        Future.delayed(const Duration(milliseconds: 400), () {
          setState(() {
            currentQuestion++;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool allAnswered = answers.length == questions.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen3(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Let's get to know your skills",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔥 Progress Bar (Step 4 of 6)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Step 4 of 6',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color,
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
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Bottom "Next" button (disabled until all questions answered)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: allAnswered
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen5(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allAnswered
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
