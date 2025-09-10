import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tega/pages/student_screens/student_home_page.dart';
import 'package:tega/pages/student_screens/student_quiz_leaderboard_page.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int _currentQuestion = 0;
  int _selectedIndex = -1;
  int _score = 0;
  int _timeLeft = 90;
  Timer? _timer;

  final List<Map<String, dynamic>> _questions = [
    {
      "title": "Logical Reasoning Puzzle",
      "question":
          "If all Zorks are Flurbs, and some Flurbs are Blurps, which of the following statements must be true?",
      "options": [
        "All Zorks are Blurps",
        "Some Zorks are Blurps",
        "No Zorks are Blurps",
        "None of the above",
      ],
      "answer": 1,
      "explanation":
          "Since all Zorks are Flurbs, and some Flurbs are Blurps, it follows that some Zorks might be Blurps, but we cannot say for certain that all Zorks are Blurps or that no Zorks are Blurps.",
    },
    {
      "title": "Math Puzzle",
      "question": "What is 12 × 8?",
      "options": ["96", "108", "112", "128"],
      "answer": 0,
      "explanation": "12 × 8 = 96.",
    },
    {
      "title": "General Knowledge",
      "question": "Which planet is known as the Red Planet?",
      "options": ["Earth", "Venus", "Mars", "Jupiter"],
      "answer": 2,
      "explanation":
          "Mars is often called the Red Planet because of its reddish appearance.",
    },
    {
      "title": "Science",
      "question": "What is H2O commonly known as?",
      "options": ["Hydrogen", "Oxygen", "Salt", "Water"],
      "answer": 3,
      "explanation": "H2O is the chemical formula for water.",
    },
    {
      "title": "History",
      "question": "Who was the first President of the United States?",
      "options": [
        "Abraham Lincoln",
        "George Washington",
        "Thomas Jefferson",
        "John Adams",
      ],
      "answer": 1,
      "explanation":
          "George Washington was the first President of the USA (1789–1797).",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timeLeft = 90;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _goToExplanation(-1);
      }
    });
  }

  void _goToExplanation(int selected) {
    _timer?.cancel();
    final question = _questions[_currentQuestion];
    final int correctAnswer = question["answer"] as int; // ✅ explicit cast
    final bool isCorrect = selected == correctAnswer;
    if (isCorrect) _score++;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExplanationPage(
          questionNumber: _currentQuestion + 1,
          total: _questions.length,
          isCorrect: isCorrect,
          explanation: question["explanation"] as String, // ✅ cast too
          onNext: () {
            if (_currentQuestion < _questions.length - 1) {
              setState(() {
                _currentQuestion++;
                _selectedIndex = -1;
                _startTimer();
              });
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => QuizCompletedPage(
                    score: _score,
                    total: _questions.length,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final options = List<String>.from(question["options"]);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  "Question ${_currentQuestion + 1} of ${_questions.length}",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Color(0xFF6F6F7A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeLeft),
                    style: const TextStyle(
                      color: Color(0xFF6F6F7A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              width: double.infinity,
              height: 3,
              color: const Color(0xFFEAEAEA),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor:
                      (_currentQuestion + 1) / _questions.length.toDouble(),
                  child: Container(height: 3, color: const Color(0xFF5E4FDB)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question["title"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question["question"],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF444444),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  Column(
                    children: List.generate(options.length, (index) {
                      final isSelected = _selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF5E4FDB)
                                  : const Color(0xFFDADCE0),
                              width: isSelected ? 2 : 1,
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF5E4FDB)
                                        : const Color(0xFFDADCE0),
                                    width: 1.5,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFEDEBFE)
                                      : Colors.white,
                                ),
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isSelected
                                        ? const Color(0xFF5E4FDB)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _selectedIndex == -1
                          ? null
                          : () => _goToExplanation(_selectedIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E4FDB),
                        disabledBackgroundColor: const Color(0xFFBFB8E6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Submit Answer",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExplanationPage extends StatelessWidget {
  final int questionNumber;
  final int total;
  final bool isCorrect;
  final String explanation;
  final VoidCallback onNext;

  const ExplanationPage({
    super.key,
    required this.questionNumber,
    required this.total,
    required this.isCorrect,
    required this.explanation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Question $questionNumber of $total",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? "Correct!" : "Wrong!",
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isCorrect
                    ? "Great job! You selected the right answer."
                    : "That’s not correct. Review the explanation below.",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                "Explanation:",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                explanation,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4FDB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    questionNumber == total ? "Finish" : "Next Question",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizCompletedPage extends StatelessWidget {
  final int score;
  final int total;

  const QuizCompletedPage({
    super.key,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Results",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.emoji_events, size: 64, color: Color(0xFF5E4FDB)),
            const SizedBox(height: 12),
            const Text(
              "Drill Complete!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "You Scored",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$score/$total",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _resultRow(Icons.flash_on, "XP Gained", "+50 XP"),
                  const SizedBox(height: 12),
                  _resultRow(
                    Icons.local_fire_department,
                    "Current Streak",
                    "6 Days",
                  ),
                  const SizedBox(height: 12),
                  _resultRow(
                    Icons.emoji_events,
                    "Badge Earned",
                    "Logical Thinker",
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Need to Review:\n\nQuestion #3: Review the concept of \"Conditional Reasoning\" in the Logic chapter of your course materials.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LeaderboardPage(),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF5E4FDB)),
                            foregroundColor: const Color(0xFF5E4FDB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "View Leaderboard",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const StudentHomePage(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E4FDB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(fontWeight: FontWeight.w600),
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
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF5E4FDB),
          ),
        ),
      ],
    );
  }
}
