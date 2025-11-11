import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class ExamResultsPage extends StatefulWidget {
  const ExamResultsPage({super.key});

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage> {
  final ExamRepository _examRepository = ExamRepository();

  bool _loadingExams = false;
  bool _loadingResults = false;
  bool _publishing = false;
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _groupedResults = [];
  String? _selectedExamId;
  Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _loadingExams = true);
    try {
      final exams = await _examRepository.getAllExams();
      if (mounted) {
        setState(() {
          _exams = exams;
          _loadingExams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingExams = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load exams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadResults() async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;
    setState(() => _loadingResults = true);
    try {
      final results = await _examRepository.getAdminExamResults(_selectedExamId!);
      if (mounted) {
        setState(() {
          _groupedResults = results;
          _loadingResults = false;
          // Auto-expand first group if available
          if (results.isNotEmpty) {
            final firstGroup = results.first;
            final key = _getGroupKey(firstGroup);
            _expandedGroups = {key};
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingResults = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getGroupKey(Map<String, dynamic> group) {
    final examId = (group['examId'] ?? '').toString();
    final examDate = (group['examDate'] ?? '').toString();
    return '$examId-$examDate';
  }

  Future<void> _togglePublishStatus(Map<String, dynamic> group) async {
    final examId = (group['examId'] ?? '').toString();
    final examDate = (group['examDate'] ?? '').toString();
    final isPublished = group['isPublished'] ?? false;
    final shouldPublish = !isPublished;

    setState(() => _publishing = true);
    try {
      await _examRepository.publishExamResults(
        examId: examId,
        examDate: examDate,
        publish: shouldPublish,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldPublish
                  ? 'Results published successfully'
                  : 'Results unpublished successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Reload results to get updated publish status
        await _loadResults();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${shouldPublish ? 'publish' : 'unpublish'} results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _publishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmall ? double.infinity : 420,
            child: _loadingExams
                ? const LinearProgressIndicator(minHeight: 4)
                : DropdownButtonFormField<String>(
                    value: _selectedExamId,
                    isExpanded: true,
                    hint: const Text('Select an exam to view results'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
                      ),
                    ),
                    items: _exams.map((e) {
                      final id = (e['_id'] ?? e['id']).toString();
                      final title = (e['title'] ?? 'Untitled').toString();
                      return DropdownMenuItem(
                        value: id,
                        child: Text(title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      setState(() {
                        _selectedExamId = v;
                        _groupedResults = [];
                        _expandedGroups = {};
                      });
                      await _loadResults();
                    },
                  ),
          ),
          const SizedBox(height: 24),

          if (_selectedExamId == null)
            _buildEmptyState(promptOnly: true)
          else if (_loadingResults)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_groupedResults.isEmpty)
            _buildEmptyState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results by Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdminDashboardStyles.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                ..._groupedResults.map((group) => _buildResultGroupCard(group, isSmall)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool promptOnly = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            promptOnly ? 'Select an exam to view results' : 'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (!promptOnly)
            Text(
              "Results will appear here once students complete the selected exam.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildResultGroupCard(Map<String, dynamic> group, bool isSmall) {
    final key = _getGroupKey(group);
    final isExpanded = _expandedGroups.contains(key);
    final examTitle = (group['examTitle'] ?? 'Untitled Exam').toString();
    final examDate = group['examDate']?.toString() ?? '';
    final courseTitle = group['courseTitle']?.toString();
    final totalStudents = (group['totalStudents'] ?? 0) as int;
    final passedStudents = (group['passedStudents'] ?? 0) as int;
    final failedStudents = (group['failedStudents'] ?? 0) as int;
    final averagePercentage = (group['averagePercentage'] ?? 0.0) as double;
    final isPublished = group['isPublished'] ?? false;
    final students = (group['students'] ?? []) as List<dynamic>;

    String formattedDate = examDate;
    try {
      if (examDate.isNotEmpty) {
        final date = DateTime.parse(examDate);
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      // Keep original date string if parsing fails
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with summary stats
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(key);
                } else {
                  _expandedGroups.add(key);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminDashboardStyles.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.quiz_rounded,
                      color: AdminDashboardStyles.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          examTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (courseTitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            courseTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: AdminDashboardStyles.textLight,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AdminDashboardStyles.textLight),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: AdminDashboardStyles.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Summary stats
                  if (!isSmall) ...[
                    _buildStatChip('Total', totalStudents.toString(), Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatChip('Passed', passedStudents.toString(), Colors.green),
                    const SizedBox(width: 12),
                    _buildStatChip('Failed', failedStudents.toString(), Colors.red),
                    const SizedBox(width: 12),
                    _buildStatChip('Avg %', '${averagePercentage.toStringAsFixed(1)}%', AdminDashboardStyles.primary),
                    const SizedBox(width: 16),
                  ],
                  // Publish toggle button
                  if (!_publishing)
                    InkWell(
                      onTap: () => _togglePublishStatus(group),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? AdminDashboardStyles.accentGreen.withOpacity(0.1)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPublished
                                ? AdminDashboardStyles.accentGreen
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPublished ? Icons.visibility : Icons.visibility_off,
                              size: 16,
                              color: isPublished
                                  ? AdminDashboardStyles.accentGreen
                                  : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPublished ? 'Published' : 'Unpublished',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPublished
                                    ? AdminDashboardStyles.accentGreen
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const SizedBox(width: 12),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AdminDashboardStyles.textLight,
                  ),
                ],
              ),
            ),
          ),
          // Summary stats for small screens
          if (isSmall)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatChip('Total', totalStudents.toString(), Colors.blue),
                  _buildStatChip('Passed', passedStudents.toString(), Colors.green),
                  _buildStatChip('Failed', failedStudents.toString(), Colors.red),
                  _buildStatChip('Avg %', '${averagePercentage.toStringAsFixed(1)}%', AdminDashboardStyles.primary),
                ],
              ),
            ),
          // Expanded student list
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStudentTableHeader(isSmall),
                  const SizedBox(height: 8),
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value as Map<String, dynamic>;
                    return _buildStudentRow(student, index, isSmall);
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTableHeader(bool isSmall) {
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AdminDashboardStyles.textLight,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _cell('STUDENT', flex: 3, style: style),
          if (!isSmall) _cell('EMAIL', flex: 3, style: style),
          _cell('SCORE', flex: 2, style: style),
          _cell('PERCENTAGE', flex: 2, style: style),
          if (!isSmall) _cell('ATTEMPT', flex: 1, style: style),
          _cell('STATUS', flex: 2, style: style, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student, int index, bool isSmall) {
    final studentName = (student['studentName'] ?? 'Student').toString();
    final email = (student['email'] ?? '-').toString();
    final score = (student['score'] ?? 0).toString();
    final totalMarks = (student['totalMarks'] ?? 0).toString();
    final percentage = (student['percentage'] ?? 0.0) as double;
    final isPassed = student['isPassed'] ?? false;
    final attemptNumber = (student['attemptNumber'] ?? 1).toString();
    final published = student['published'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Row(
        children: [
          _cell('$studentName ${published ? '✓' : ''}', flex: 3, strong: true),
          if (!isSmall) _cell(email, flex: 3),
          _cell('$score / $totalMarks', flex: 2),
          _cell('${percentage.toStringAsFixed(1)}%', flex: 2),
          if (!isSmall) _cell('#$attemptNumber', flex: 1),
          _cell(_buildStatusBadge(isPassed), flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isPassed) {
    final color = isPassed ? AdminDashboardStyles.accentGreen : AdminDashboardStyles.statusError;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        isPassed ? 'PASSED' : 'FAILED',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _cell(
    dynamic child, {
    required int flex,
    bool strong = false,
    bool alignEnd = false,
    TextStyle? style,
  }) {
    Widget content;
    if (child is String) {
      content = Text(
        child,
        style: style ??
            TextStyle(
              color: AdminDashboardStyles.textDark,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else {
      content = child as Widget;
    }
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: content,
      ),
    );
  }
}
