import 'package:flutter/material.dart';
import 'on_boarding_page_3.dart';
import 'on_boarding_page_5.dart';

class OnboardingScreen4 extends StatefulWidget {
  const OnboardingScreen4({Key? key}) : super(key: key);

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
                          builder: (context) => const OnboardingScreen3(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Let's get to know your skills",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔥 Progress Bar (Step 4 of 6)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Step 4 of 6',
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
                          widthFactor: 4 / 6,
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
                    '67% Complete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

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
                  "💡 This isn't a test. Just a quick challenge to help you better.",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),

              const SizedBox(height: 20),

              // Question number + progress bar
              Row(
                children: [
                  Text(
                    "Q${currentQuestion + 1} of ${questions.length}",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentQuestion + 1) / questions.length,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFFA726),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔥 Animated Question + Options
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Column(
                    key: ValueKey<int>(currentQuestion),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question text
                      Text(
                        questions[currentQuestion]["question"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Options
                      Expanded(
                        child: ListView.builder(
                          itemCount:
                              questions[currentQuestion]["options"].length,
                          itemBuilder: (context, index) {
                            bool isSelected = answers[currentQuestion] == index;

                            return GestureDetector(
                              onTap: () => selectOption(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFA726)
                                        : Colors.grey.shade300,
                                  ),
                                  color: isSelected
                                      ? const Color(
                                          0xFFFFA726,
                                        ).withOpacity(0.15)
                                      : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isSelected
                                          ? const Color(0xFFFFA726)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        questions[currentQuestion]["options"][index],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
