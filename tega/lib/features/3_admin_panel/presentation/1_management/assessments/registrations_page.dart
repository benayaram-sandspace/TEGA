import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class RegistrationsPage extends StatefulWidget {
  const RegistrationsPage({super.key});

  @override
  State<RegistrationsPage> createState() => _RegistrationsPageState();
}

class _RegistrationsPageState extends State<RegistrationsPage> {
  final ExamRepository _examRepository = ExamRepository();

  bool _loadingExams = false;
  bool _loadingRegs = false;
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _registrations = [];
  String? _selectedExamId; // null => no filter

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _loadingExams = true);
    try {
      final exams = await _examRepository.getAllExams();
      setState(() {
        _exams = exams;
        _loadingExams = false;
      });
      // Do NOT auto-select; the reference UI shows a prompt to pick an exam
    } catch (e) {
      setState(() => _loadingExams = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load exams: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadRegistrations() async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;
    setState(() => _loadingRegs = true);
    try {
      final regs = await _examRepository.getExamRegistrations(_selectedExamId!);
      setState(() {
        _registrations = regs;
        _loadingRegs = false;
      });
    } catch (e) {
      setState(() => _loadingRegs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load registrations: $e'), backgroundColor: Colors.red),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_alt_rounded, color: AdminDashboardStyles.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Exam Registrations', style: AdminDashboardStyles.welcomeHeader.copyWith(fontSize: 22)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exam filter (full width, left-aligned)
          SizedBox(
            width: isSmall ? double.infinity : 420,
            child: _loadingExams
                ? const LinearProgressIndicator(minHeight: 4)
                : DropdownButtonFormField<String>(
                    value: _selectedExamId,
                    isExpanded: true,
                    hint: const Text('Select an exam to view registrations'),
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
                      return DropdownMenuItem(value: id, child: Text(title, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) async {
                      setState(() => _selectedExamId = v);
                      await _loadRegistrations();
                    },
                  ),
          ),
          const SizedBox(height: 24),

          if (_selectedExamId == null)
            _buildEmptyState(promptOnly: true)
          else if (_loadingRegs)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_registrations.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                _buildTableHeader(isSmall),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _registrations.length,
                  itemBuilder: (context, index) => _buildRow(_registrations[index], isSmall),
                ),
              ],
            ),
        ],
      ),
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
          _cell('STUDENT', flex: 3, style: style),
          if (!isSmall) _cell('EMAIL', flex: 3, style: style),
          _cell('EXAM', flex: 3, style: style),
          if (!isSmall) _cell('SLOT', flex: 2, style: style),
          _cell('STATUS', flex: 2, style: style, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool promptOnly = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            promptOnly ? 'Select an exam to view registrations' : 'No registrations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (!promptOnly)
            Text(
              'Students will appear here once they register for the selected exam.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> r, bool isSmall) {
    final student = r['student'] ?? r['studentId'] ?? {};
    final exam = r['exam'] ?? r['examId'] ?? {};
    final name = (student is Map ? (student['name'] ?? student['username'] ?? 'Student') : student?.toString()) ?? 'Student';
    final email = (student is Map ? (student['email'] ?? '-') : '-') as String;
    final examTitle = (exam is Map ? (exam['title'] ?? 'Exam') : exam?.toString()) ?? 'Exam';
    final slotId = r['slotId']?.toString() ?? '-';
    final status = r['paymentStatus']?.toString() ?? r['status']?.toString() ?? 'pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _cell(name, flex: 3, strong: true),
          if (!isSmall) _cell(email, flex: 3),
          _cell(examTitle, flex: 3),
          if (!isSmall) _cell(slotId, flex: 2),
          _cell(_statusBadge(status), flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AdminDashboardStyles.accentGreen;
        break;
      case 'failed':
        color = AdminDashboardStyles.statusError;
        break;
      default:
        color = AdminDashboardStyles.statusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.2),
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
        style: (style ??
            TextStyle(
              color: AdminDashboardStyles.textDark,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            )),
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


