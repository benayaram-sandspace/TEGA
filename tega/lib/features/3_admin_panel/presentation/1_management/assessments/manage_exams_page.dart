import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/assessments/edit_exam_page.dart';

class ManageExamsPage extends StatefulWidget {
  const ManageExamsPage({super.key});

  @override
  State<ManageExamsPage> createState() => _ManageExamsPageState();
}

class _ManageExamsPageState extends State<ManageExamsPage> {
  final ExamRepository _examRepository = ExamRepository();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      // Some backends return { success, exams: [] }, others { success, data: [] }
      final headers = await _authService.getAuthHeaders();
      final res = await http.get(Uri.parse(ApiEndpoints.adminExamsAll), headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list = (data['exams'] ?? data['data'] ?? []) as List<dynamic>;
          setState(() {
            _exams = List<Map<String, dynamic>>.from(list);
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load exams');
        }
      } else {
        throw Exception('Failed to load exams: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exams: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExam(String examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text('Are you sure you want to delete this exam? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _examRepository.deleteExam(examId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam deleted'), backgroundColor: Colors.green),
        );
      }
      _loadExams();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTableHeader(isSmall),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_exams.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exams.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final exam = _exams[index];
                return _buildExamRow(exam, isSmall);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminDashboardStyles.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_rounded, color: AdminDashboardStyles.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage Assessments', style: AdminDashboardStyles.welcomeHeader.copyWith(fontSize: 22)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isSmall) {
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AdminDashboardStyles.textLight,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Row(
        children: [
          _cell('ASSESSMENT', flex: 3, style: style),
          if (!isSmall) _cell('COURSE', flex: 2, style: style),
          _cell('DATE & SLOTS', flex: 3, style: style),
          if (!isSmall) _cell('QUESTIONS', flex: 2, style: style),
          if (!isSmall) _cell('DURATION', flex: 2, style: style),
          _cell('ACTIONS', flex: 2, alignEnd: true, style: style),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_rounded, size: 48, color: AdminDashboardStyles.primary.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text('No exams found', style: TextStyle(color: AdminDashboardStyles.textDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildExamRow(Map<String, dynamic> exam, bool isSmall) {
    // Extract title
    final String title = (exam['title'] ?? exam['name'] ?? 'Untitled').toString();
    
    // Extract course name (can be null for TEGA exams)
    final dynamic course = exam['courseId'] ?? exam['course'];
    String courseName = '';
    if (course != null) {
      if (course is Map) {
        courseName = (course['courseName'] ?? course['title'] ?? '').toString();
      } else {
        courseName = course.toString();
      }
    }
    // If empty and not a TEGA exam, show empty string, otherwise show "TEGA Exam"
    if (courseName.isEmpty && exam['isTegaExam'] == true) {
      courseName = 'TEGA Exam';
    }
    
    // Extract slots
    final List<dynamic> slots = (exam['slots'] ?? exam['timeSlots'] ?? []) as List<dynamic>;
    final int slotsCount = slots.length;
    
    // Extract exam date
    DateTime? examDate;
    if (exam['examDate'] != null) {
      examDate = _tryParseDateTime(exam['examDate']);
    }
    final String dateStr = examDate != null ? _formatDate(examDate) : '-';
    
    // Extract first slot time range and seats
    String slotRange = '';
    String seatsInfo = '';
    if (slots.isNotEmpty) {
      final firstSlot = slots.first as Map<String, dynamic>;
      final startTime = firstSlot['startTime']?.toString() ?? '';
      final endTime = firstSlot['endTime']?.toString() ?? '';
      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        slotRange = '$startTime - $endTime';
      }
      
      // Calculate seats left for first slot
      final maxParticipants = (firstSlot['maxParticipants'] ?? 30) as int;
      final registeredStudents = (firstSlot['registeredStudents'] ?? []) as List<dynamic>;
      final seatsLeft = maxParticipants - registeredStudents.length;
      seatsInfo = '($seatsLeft seats left)';
    }
    
    // Extract questions count from questionPaperId
    int questions = 0;
    final questionPaper = exam['questionPaperId'] ?? exam['questionPaper'];
    if (questionPaper is Map) {
      questions = (questionPaper['totalQuestions'] ?? 0) as int;
    }
    
    // Extract duration
    final int duration = (exam['duration'] ?? exam['durationMinutes'] ?? 0) as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 16),
      constraints: const BoxConstraints(minHeight: 120),
      child: isSmall
          // Stacked layout on small screens to avoid any overflow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AdminDashboardStyles.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.assignment_rounded, size: 22, color: AdminDashboardStyles.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminDashboardStyles.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (exam['isTegaExam'] == true) _badge('TEGA', AdminDashboardStyles.accentBlue),
                              if (courseName.isNotEmpty) _badge(courseName, AdminDashboardStyles.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.event_rounded, size: 18, color: AdminDashboardStyles.textLight),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(icon: Icons.schedule_rounded, label: '${slotsCount} slots'),
                    if (slotRange.isNotEmpty) _chip(icon: Icons.access_time_rounded, label: slotRange),
                    if (seatsInfo.isNotEmpty) _chip(icon: Icons.event_seat_rounded, label: seatsInfo),
                    if (questions > 0) _chip(icon: Icons.quiz_rounded, label: '$questions questions'),
                    if (duration > 0) _chip(icon: Icons.timer_rounded, label: '$duration min'),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconButton(
                        icon: Icons.edit_rounded,
                        color: AdminDashboardStyles.accentBlue,
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditExamPage(exam: exam),
                            ),
                          );
                          if (result == true) {
                            _loadExams(); // Reload exams after successful update
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _iconButton(
                        icon: Icons.delete_rounded,
                        color: AdminDashboardStyles.statusError,
                        onTap: () => _deleteExam((exam['_id'] ?? exam['id']).toString()),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // Wide layout: keep multi-column row
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assessment
                _cell(
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdminDashboardStyles.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.2)),
                        ),
                        child: Icon(
                          Icons.assignment_rounded,
                          size: 22,
                          color: AdminDashboardStyles.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AdminDashboardStyles.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (exam['isTegaExam'] == true)
                                  _badge('TEGA', AdminDashboardStyles.accentBlue),
                                if (courseName.isNotEmpty)
                                  _badge(courseName, AdminDashboardStyles.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  flex: 3,
                ),

                // Course (separate column on wide screens)
                _cell(
                  courseName.isEmpty ? '-' : courseName,
                  flex: 2,
                ),

                // Date & Slots
                _cell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_rounded, size: 18, color: AdminDashboardStyles.textLight),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(icon: Icons.schedule_rounded, label: '${slotsCount} slots'),
                          if (slotRange.isNotEmpty) _chip(icon: Icons.access_time_rounded, label: slotRange),
                          if (seatsInfo.isNotEmpty) _chip(icon: Icons.event_seat_rounded, label: seatsInfo),
                          // extra chips to enrich/bulk up card height
                          if (questions > 0) _chip(icon: Icons.quiz_rounded, label: '$questions questions'),
                          if (duration > 0) _chip(icon: Icons.timer_rounded, label: '$duration min'),
                        ],
                      ),
                    ],
                  ),
                  flex: 3,
                ),

                // Questions
                _cell(
                  questions > 0 ? '$questions questions' : '-',
                  flex: 2,
                ),

                // Duration
                _cell(
                  '${duration > 0 ? duration : '-'} minutes',
                  flex: 2,
                ),

                // Actions
                _cell(
                  FittedBox(
                    alignment: Alignment.centerRight,
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _iconButton(
                          icon: Icons.edit_rounded,
                          color: AdminDashboardStyles.accentBlue,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit exam not implemented yet')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _iconButton(
                          icon: Icons.delete_rounded,
                          color: AdminDashboardStyles.statusError,
                          onTap: () => _deleteExam((exam['_id'] ?? exam['id']).toString()),
                        ),
                      ],
                    ),
                  ),
                  flex: 2,
                  alignEnd: true,
                ),
              ],
            ),
    );
  }

  DateTime? _tryParseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$mm/$dd/${dt.year}';
    // Keep it simple; avoids adding intl dependency
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
        style: (style ??
                TextStyle(
                  color: AdminDashboardStyles.textDark,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                )),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
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

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // UI helpers
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AdminDashboardStyles.textLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: AdminDashboardStyles.statTitle,
          ),
        ],
      ),
    );
  }
}


