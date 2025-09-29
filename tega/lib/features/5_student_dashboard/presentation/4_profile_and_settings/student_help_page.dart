import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            question: "How do I update my resume?",
            answer:
                "You can update your resume by navigating to the 'Resume Optimizer' from the home screen. There you can upload a new version or edit your existing details.",
          ),
          _buildFaqItem(
            question: "How is the Job Readiness Score calculated?",
            answer:
                "The score is calculated based on your completed skill drills, mock interview performance, resume strength, and the skills you have mastered in the 'Skills Hub'.",
          ),
          _buildFaqItem(
            question: "Can I retake a Skill Drill?",
            answer:
                "Yes, you can retake skill drills to improve your score. Your highest score will be recorded on your profile.",
          ),
          const Divider(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Contact Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Email Support"),
            subtitle: const Text("support@tega.com"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.call_outlined),
            title: const Text("Call Center"),
            subtitle: const Text("+91 1800 123 4567"),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.centerLeft,
        children: [Text(answer, style: TextStyle(color: Colors.grey.shade700))],
      ),
    );
  }
}
