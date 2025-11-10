import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/skill_assessment_quiz_page.dart';

class SkillAssessmentModulesPage extends StatefulWidget {
  const SkillAssessmentModulesPage({super.key});

  @override
  State<SkillAssessmentModulesPage> createState() =>
      _SkillAssessmentModulesPageState();
}

class _SkillAssessmentModulesPageState
    extends State<SkillAssessmentModulesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _modules = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSkillAssessments();
  }

  Future<void> _loadSkillAssessments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final service = StudentDashboardService();

      final data = await service.getSkillAssessments(headers);
      final modules = data['modules'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _modules = modules
              .map<Map<String, dynamic>>((m) => {
                    'id': m['_id']?.toString() ?? '',
                    'title': m['title']?.toString() ?? 'Untitled Module',
                    'description': m['description']?.toString() ?? '',
                    'questionCount': m['questionCount'] ?? 0,
                    'status': m['status']?.toString() ?? 'not-started',
                    'progress': m['progress'] ?? 0,
                    'assessmentHistory': m['assessmentHistory'] ?? {},
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Skill Assessments'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSkillAssessments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _modules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No skill assessment modules available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
                      itemCount: _modules.length,
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        return _buildModuleCard(module, isDesktop, isTablet);
                      },
                    ),
    );
  }

  Widget _buildModuleCard(
      Map<String, dynamic> module, bool isDesktop, bool isTablet) {
    final title = module['title'] as String;
    final description = module['description'] as String;
    final questionCount = module['questionCount'] as int;
    final status = module['status'] as String;
    final progress = module['progress'] as num;
    final assessmentHistory = module['assessmentHistory'] as Map<String, dynamic>?;
    final totalAttempts = assessmentHistory?['totalAttempts'] ?? 0;
    final correctAnswers = assessmentHistory?['correctAnswers'] ?? 0;

    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'in-progress'
            ? Colors.orange
            : Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isDesktop ? 12 : 8,
            offset: Offset(0, isDesktop ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SkillAssessmentQuizPage(
                  moduleId: module['id'] as String,
                  moduleTitle: title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 12 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                      ),
                      child: Icon(
                        Icons.assessment_rounded,
                        color: const Color(0xFF667eea),
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 10 : 8,
                        vertical: isDesktop ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'completed'
                            ? 'Completed'
                            : status == 'in-progress'
                                ? 'In Progress'
                                : 'Not Started',
                        style: TextStyle(
                          fontSize: isDesktop ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip(
                      Icons.help_outline,
                      '$questionCount Questions',
                      isDesktop,
                    ),
                    SizedBox(width: isDesktop ? 12 : 8),
                    if (totalAttempts > 0)
                      _buildStatChip(
                        Icons.check_circle_outline,
                        '$correctAnswers/$totalAttempts Correct',
                        isDesktop,
                      ),
                  ],
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF667eea),
                    ),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.toStringAsFixed(0)}% Complete',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 10 : 8,
        vertical: isDesktop ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 14 : 12, color: Colors.grey[700]),
          SizedBox(width: isDesktop ? 6 : 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

