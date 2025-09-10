import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tega/main.dart'; // for cameras
import 'package:tega/pages/student_screens/studen_home_page.dart';

class AiInterviewPage extends StatefulWidget {
  const AiInterviewPage({super.key});

  @override
  State<AiInterviewPage> createState() => _AiInterviewPageState();
}

class _AiInterviewPageState extends State<AiInterviewPage> {
  CameraController? _controller;
  bool _isMicOn = true;

  static const int _totalTime = 15 * 60; // 15 minutes in seconds
  int _remainingTime = _totalTime;
  Timer? _timer;

  final List<String> _questions = [
    "Tell me about a time when you had to work in a team. How did you contribute to the team’s success?",
    "How do you handle stressful situations or tight deadlines?",
    "Describe a time when you had to communicate a difficult idea. How did you make sure others understood?",
    "What do you do when you face conflict with a team member or peer?",
    "How do you prioritize tasks when you have multiple responsibilities?",
  ];

  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startTimer();
  }

  Future<void> _initCamera() async {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;

          // Switch questions every 3 minutes (180 seconds)
          int elapsedTime = _totalTime - _remainingTime;
          int newQuestionIndex = elapsedTime ~/ 180;
          if (newQuestionIndex != _currentQuestionIndex &&
              newQuestionIndex < _questions.length) {
            _currentQuestionIndex = newQuestionIndex;
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

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Fullscreen camera
                SizedBox.expand(child: CameraPreview(_controller!)),

                // Top Overlay: Interview Info
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
                          const Text(
                            "Soft Skills",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
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

                // AI interviewer chatbot thumbnail
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://cdn-icons-png.flaticon.com/512/4712/4712027.png", // AI bot image
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Bottom overlay: Question & Status
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Question:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _questions[_currentQuestionIndex],
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.mic, size: 16, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            "AI is listening to your response...",
                            style: TextStyle(color: Colors.green, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom control buttons
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: "call_end_btn",
                        onPressed: _onHangUpPressed,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
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
                    ],
                  ),
                ),
              ],
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
