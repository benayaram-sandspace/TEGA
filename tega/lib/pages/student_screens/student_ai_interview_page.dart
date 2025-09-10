import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tega/main.dart'; // for cameras
import 'package:tega/pages/student_screens/student_home_page.dart';

class AiInterviewPage extends StatefulWidget {
  const AiInterviewPage({super.key});

  @override
  State<AiInterviewPage> createState() => _AiInterviewPageState();
}

class _AiInterviewPageState extends State<AiInterviewPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isMicOn = true;

  // Page states
  bool _showInstructions = true;
  bool _isCountdownActive = false;
  int _countdownSeconds = 5; // Starting countdown value
  Timer? _countdownTimer;

  // Interview timer
  static const int _totalTime = 15 * 60; // 15 minutes in seconds
  int _remainingTime = _totalTime;
  Timer? _timer;

  // Track answered and skipped questions
  final Set<int> _answeredQuestions = {};
  final Set<int> _skippedQuestions = {};

  final List<String> _questions = [
    "Tell me about a time when you had to work in a team. How did you contribute to the team's success?",
    "How do you handle stressful situations or tight deadlines?",
    "Describe a time when you had to communicate a difficult idea. How did you make sure others understood?",
    "What do you do when you face conflict with a team member or peer?",
    "How do you prioritize tasks when you have multiple responsibilities?",
  ];

  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  Future<void> _resumeCamera() async {
    if (_controller != null) {
      await _initCamera();
      if (mounted) setState(() {});
    }
  }

  Future<bool> _onWillPop() async {
    if (_showInstructions) {
      return true;
    }

    int totalQuestions = _questions.length;
    int answeredCount = _answeredQuestions.length;
    int unansweredCount = totalQuestions - answeredCount;

    if (unansweredCount > 0) {
      final bool? shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Exit Interview?"),
          content: Text(
            "You still have $unansweredCount question${unansweredCount > 1 ? 's' : ''} left to answer.\n\nAre you sure you want to exit?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Stay"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Exit", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        }
        return true;
      }
      return false;
    } else {
      final bool? shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Skip Analysis?"),
          content: const Text(
            "You've completed all questions!\n\nDo you want to exit without viewing your AI performance analysis?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("View Analysis"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Exit Without Analysis",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        }
        return true;
      }
      return false;
    }
  }

  void _onStartInterview() async {
    await _initCamera();

    if (mounted) {
      setState(() {
        _showInstructions = false;
        _isCountdownActive = true;
      });
      _startCountdown();
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isNotEmpty) {
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      try {
        await _controller!.initialize();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint("Camera initialization error: $e");
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        setState(() {
          _isCountdownActive = false;
        });
        _countdownTimer?.cancel();
        _startInterview();
      }
    });
  }

  void _startInterview() {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;

          int elapsedTime = _totalTime - _remainingTime;
          int expectedQuestionIndex = elapsedTime ~/ 180;

          if (expectedQuestionIndex != _currentQuestionIndex &&
              expectedQuestionIndex < _questions.length &&
              !_answeredQuestions.contains(_currentQuestionIndex)) {
            _answeredQuestions.add(_currentQuestionIndex);
            _currentQuestionIndex = expectedQuestionIndex;
          }
        });
      } else {
        _endInterview();
      }
    });
  }

  void _endInterview() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
    );
  }

  void _onHangUpPressed() {
    if (_remainingTime > 60) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("End Interview?"),
          content: const Text(
            "You still have more than 1 minute left. Are you sure you want to hang up?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _endInterview();
              },
              child: const Text("Yes, End"),
            ),
          ],
        ),
      );
    } else {
      _endInterview();
    }
  }

  void _onNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _answeredQuestions.add(_currentQuestionIndex);
        _skippedQuestions.remove(_currentQuestionIndex);
        _currentQuestionIndex++;
      });
    } else if (_skippedQuestions.isNotEmpty) {
      setState(() {
        _answeredQuestions.add(_currentQuestionIndex);
        _currentQuestionIndex = _skippedQuestions.first;
      });
    } else {
      _answeredQuestions.add(_currentQuestionIndex);
      _endInterview();
    }
  }

  void _onSkipQuestion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Skip Question?"),
        content: const Text(
          "This question needs to be answered, but you can come back to it later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _skippedQuestions.add(_currentQuestionIndex);

                if (_currentQuestionIndex < _questions.length - 1) {
                  _currentQuestionIndex++;
                } else if (_answeredQuestions.length +
                        _skippedQuestions.length <
                    _questions.length) {
                  for (int i = 0; i < _questions.length; i++) {
                    if (!_answeredQuestions.contains(i) &&
                        !_skippedQuestions.contains(i)) {
                      _currentQuestionIndex = i;
                      break;
                    }
                  }
                }
              });
            },
            child: const Text("Skip", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  Widget _buildInstructionsPage() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "AI Interview Instructions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.psychology,
                              size: 48,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Soft Skills Assessment",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Evaluate your communication and interpersonal skills",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Interview Format",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildInfoRow(
                        Icons.timer,
                        "Total Duration",
                        "15 minutes",
                        Colors.blue,
                      ),
                      _buildInfoRow(
                        Icons.question_answer,
                        "Number of Questions",
                        "5 questions",
                        Colors.green,
                      ),
                      _buildInfoRow(
                        Icons.schedule,
                        "Time per Question",
                        "3 minutes each",
                        Colors.orange,
                      ),
                      _buildInfoRow(
                        Icons.rotate_right,
                        "Question Rotation",
                        "Manual or Automatic after 3 minutes",
                        Colors.purple,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Important Instructions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildInstruction(
                        "1",
                        "Ensure you're in a quiet, well-lit environment",
                      ),
                      _buildInstruction(
                        "2",
                        "Position your face clearly in the camera frame",
                      ),
                      _buildInstruction(
                        "3",
                        "Speak clearly and maintain eye contact with the camera",
                      ),
                      _buildInstruction(
                        "4",
                        "You can skip questions and return to them later",
                      ),
                      _buildInstruction(
                        "5",
                        "The AI will analyze your responses in real-time",
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Requirements",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "• Camera and microphone access required\n"
                                    "• Stable internet connection\n"
                                    "• Chrome or Safari browser recommended",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _onStartInterview,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Start Interview",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.camera_alt, size: 60, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Get Ready!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your AI interview will begin in",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        _countdownSeconds.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Tips:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "• Speak clearly and confidently\n"
                    "• Look at the camera\n"
                    "• Take a deep breath",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                      height: 1.5,
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

  @override
  Widget build(BuildContext context) {
    if (_showInstructions) {
      return WillPopScope(
        onWillPop: () async => true,
        child: _buildInstructionsPage(),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller == null || !_controller!.value.isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SizedBox.expand(child: CameraPreview(_controller!)),

                  if (_isCountdownActive)
                    _buildCountdownOverlay()
                  else ...[
                    Positioned(
                      top: 40,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "AI Interview Simulation",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "${_formatTime(_remainingTime)} remaining",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_skippedQuestions.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${_skippedQuestions.length} skipped",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  const Text(
                                    "Soft Skills",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _remainingTime / _totalTime,
                            backgroundColor: Colors.white24,
                            color: Colors.deepPurple,
                            minHeight: 4,
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 260,
                      right: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          "https://cdn-icons-png.flaticon.com/512/4712/4712027.png",
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 100,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Current Question:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_skippedQuestions.contains(
                                  _currentQuestionIndex,
                                ))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "Skipped",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _questions[_currentQuestionIndex],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.mic,
                                  size: 18,
                                  color: _isMicOn
                                      ? Colors.greenAccent
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isMicOn
                                      ? "AI is listening to your response..."
                                      : "Microphone is muted",
                                  style: TextStyle(
                                    color: _isMicOn
                                        ? Colors.greenAccent
                                        : Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.small(
                            heroTag: "skip_btn",
                            onPressed: _onSkipQuestion,
                            backgroundColor: Colors.orange,
                            child: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          FloatingActionButton(
                            heroTag: "call_end_btn",
                            onPressed: _onHangUpPressed,
                            backgroundColor: Colors.red,
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),

                          FloatingActionButton(
                            heroTag: "mic_off_btn",
                            onPressed: () {
                              setState(() {
                                _isMicOn = !_isMicOn;
                              });
                            },
                            backgroundColor: Colors.black54,
                            child: Icon(
                              _isMicOn ? Icons.mic : Icons.mic_off,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),

                          FloatingActionButton.small(
                            heroTag: "next_btn",
                            onPressed: _onNextQuestion,
                            backgroundColor: Colors.green,
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// Dummy Analysis Screen
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Interview Analysis"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Your Interview Analysis",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "This is a dummy analysis page.\nYour performance review will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentHomePage(),
                  ), // ✅ Home
                  (route) => false,
                );
              },
              child: const Text(
                "Back to Home",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
