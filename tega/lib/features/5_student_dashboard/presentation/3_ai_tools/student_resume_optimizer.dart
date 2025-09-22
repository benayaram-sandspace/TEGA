import 'package:flutter/material.dart';
import 'package:tega/features/5_student_dashboard/presentation/3_ai_tools/student_resume_analyser.dart';

class ResumeOptimizerPage extends StatelessWidget {
  const ResumeOptimizerPage({super.key});

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
          "Resume Optimizer",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Resume Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, size: 80, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    "Analyze a New Resume",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Get an instant AI-powered analysis of your resume against a target job description.",
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResumeAnalysisPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "+ Start",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // History Section
            const Text(
              "History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildHistoryItem(
              context,
              title: "Software Engineer at TechCorp",
              date: "Analyzed on 18 Aug 2025",
              score: "Match Score: 82%",
            ),
            _buildHistoryItem(
              context,
              title: "Product Manager at Innovate Solutions",
              date: "Analyzed on 15 Aug 2025",
              score: "Match Score: 75%",
            ),
            _buildHistoryItem(
              context,
              title: "Data Scientist at Data Insights Inc.",
              date: "Analyzed on 12 Aug 2025",
              score: "Match Score: 68%",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, {
    required String title,
    required String date,
    required String score,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                score,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black54,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HistoryDetailPage(title: title, date: date, score: score),
              ),
            );
          },
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// Dummy history details page
class HistoryDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final String score;

  const HistoryDetailPage({
    super.key,
    required this.title,
    required this.date,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Analysis Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              score,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              "Analysis Summary (Dummy):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your resume has strong technical skills and matches well "
              "with the job description. Work on highlighting leadership "
              "experiences and quantifiable achievements to improve the "
              "match score further.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
