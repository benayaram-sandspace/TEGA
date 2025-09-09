import 'package:flutter/material.dart';

class AiInterviewPage extends StatelessWidget {
  const AiInterviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Interview Simulator",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Icon(Icons.more_vert, color: Colors.black),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section - Interview Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Software Engineering Interview",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  "15:32 remaining",
                  style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Question 3 of 8",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  "Intermediate Level",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: 0.3,
              backgroundColor: Colors.grey[200],
              color: Colors.deepPurple,
              minHeight: 4,
            ),
            const SizedBox(height: 16),

            // Video Call Simulation
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg", // placeholder woman
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg", // placeholder man
                      height: 80,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: "call_end_btn", // 👈 unique tag
                        onPressed: () {},
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: "mic_off_btn", // 👈 unique tag
                        onPressed: () {},
                        backgroundColor: Colors.black54,
                        child: const Icon(Icons.mic_off, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Question
            const Text(
              "Current Question:",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              "Describe a challenging project you worked on and how you overcame obstacles to complete it successfully.",
              style: TextStyle(fontSize: 15),
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
            const SizedBox(height: 20),

            // Real-time Feedback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Real-time Feedback",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Updating live",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFeedbackCard("Clarity", "Good", Colors.green),
                _buildFeedbackCard("Relevance", "Improve", Colors.orange),
                _buildFeedbackCard("Confidence", "Excellent", Colors.blue),
                _buildFeedbackCard("Pacing", "Too Fast", Colors.red),
              ],
            ),

            const SizedBox(height: 24),

            // Body Language Analysis
            const Text(
              "Body Language Analysis",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBodyLang(
              Icons.sentiment_satisfied,
              "Good eye contact maintained",
              "You're engaging well with the interviewer",
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildBodyLang(
              Icons.pan_tool,
              "Excessive hand movements",
              "Try to keep gestures more controlled",
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildBodyLang(
              Icons.accessibility_new,
              "Good posture",
              "You appear confident and professional",
              Colors.blue,
            ),

            const SizedBox(height: 24),

            // Suggested Improvements
            const Text(
              "Suggested Improvements",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(
              "Try to include more specific examples about the technical challenges you faced.",
              Colors.blue.shade50,
            ),
            const SizedBox(height: 10),
            _buildSuggestionCard(
              "Slow down your speech a bit to improve clarity and allow the interviewer to process your answers.",
              Colors.orange.shade50,
            ),
            const SizedBox(height: 10),
            _buildSuggestionCard(
              "Your structured approach to problem-solving comes across well. Continue highlighting this strength.",
              Colors.green.shade50,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeedbackCard(String title, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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

  static Widget _buildBodyLang(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildSuggestionCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
