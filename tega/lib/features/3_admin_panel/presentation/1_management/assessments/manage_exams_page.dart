import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
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
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadExams();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedExams = await _cacheService.getExamsData();
      if (cachedExams != null && cachedExams.isNotEmpty) {
        setState(() {
          _exams = cachedExams;
        });
      }
    } catch (e) {
      // Silently handle cache errors
    }
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
  }

  Future<void> _loadExams({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _exams.isNotEmpty) {
      _loadExamsInBackground();
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Some backends return { success, exams: [] }, others { success, data: [] }
      final headers = await _authService.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminExamsAll),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list = (data['exams'] ?? data['data'] ?? []) as List<dynamic>;
          setState(() {
            _exams = List<Map<String, dynamic>>.from(list);
            _isLoading = false;
          });

          // Cache the data
          await _cacheService.setExamsData(_exams);
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        } else {
          throw Exception(data['message'] ?? 'Failed to load exams');
        }
      } else {
        throw Exception('Failed to load exams: ${res.statusCode}');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedExams = await _cacheService.getExamsData();
        if (cachedExams != null && cachedExams.isNotEmpty) {
          // Load from cache
          setState(() {
            _exams = cachedExams;
            _isLoading = false;
          });
          return;
        }

        // No cache available
        setState(() => _isLoading = false);
      } else {
        // Other errors
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading exams: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadExamsInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminExamsAll),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list = (data['exams'] ?? data['data'] ?? []) as List<dynamic>;
          setState(() {
            _exams = List<Map<String, dynamic>>.from(list);
          });

          // Cache the data
          await _cacheService.setExamsData(_exams);
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
    }
  }

  Future<void> _deleteExam(String examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text(
          'Are you sure you want to delete this exam? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
          const SnackBar(
            content: Text('Exam deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadExams(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      child: Column(
        children: [
          _buildHeader(isMobile, isTablet, isDesktop),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),
          _buildTableHeader(isMobile, isTablet, isDesktop),
          SizedBox(
            height: isMobile
                ? 6
                : isTablet
                ? 7
                : 8,
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(
                isMobile
                    ? 32
                    : isTablet
                    ? 36
                    : 40,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AdminDashboardStyles.primary,
                  ),
                ),
              ),
            )
          else if (_exams.isEmpty)
            _buildEmptyState(isMobile, isTablet, isDesktop)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exams.length,
              separatorBuilder: (_, __) => SizedBox(
                height: isMobile
                    ? 8
                    : isTablet
                    ? 10
                    : 12,
              ),
              itemBuilder: (context, index) {
                final exam = _exams[index];
                return _buildExamRow(exam, isMobile, isTablet, isDesktop);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isTablet, bool isDesktop) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            isMobile
                ? 10
                : isTablet
                ? 11
                : 12,
          ),
          decoration: BoxDecoration(
            color: AdminDashboardStyles.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              isMobile
                  ? 10
                  : isTablet
                  ? 11
                  : 12,
            ),
          ),
          child: Icon(
            Icons.description_rounded,
            color: AdminDashboardStyles.primary,
            size: isMobile
                ? 20
                : isTablet
                ? 22
                : 24,
          ),
        ),
        SizedBox(
          width: isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Assessments',
                style: AdminDashboardStyles.welcomeHeader.copyWith(
                  fontSize: isMobile
                      ? 18
                      : isTablet
                      ? 20
                      : 22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isMobile, bool isTablet, bool isDesktop) {
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: isMobile
          ? 10
          : isTablet
          ? 11
          : 12,
      color: AdminDashboardStyles.textLight,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
        vertical: isMobile
            ? 12
            : isTablet
            ? 13
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(
          isMobile
              ? 8
              : isTablet
              ? 9
              : 10,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Row(
        children: [
          _cell('ASSESSMENT', flex: 3, style: style),
          if (!isMobile) _cell('COURSE', flex: 2, style: style),
          _cell('DATE & SLOTS', flex: 3, style: style),
          if (!isMobile) _cell('QUESTIONS', flex: 2, style: style),
          if (!isMobile) _cell('DURATION', flex: 2, style: style),
          _cell('ACTIONS', flex: 2, alignEnd: true, style: style),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isTablet
            ? 28
            : 32,
      ),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(
          color: AdminDashboardStyles.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_rounded,
            size: isMobile
                ? 40
                : isTablet
                ? 44
                : 48,
            color: AdminDashboardStyles.primary.withOpacity(0.6),
          ),
          SizedBox(
            height: isMobile
                ? 6
                : isTablet
                ? 7
                : 8,
          ),
          Text(
            'No exams found',
            style: TextStyle(
              color: AdminDashboardStyles.textDark,
              fontWeight: FontWeight.w600,
              fontSize: isMobile
                  ? 16
                  : isTablet
                  ? 17
                  : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamRow(
    Map<String, dynamic> exam,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    // Extract title
    final String title = (exam['title'] ?? exam['name'] ?? 'Untitled')
        .toString();

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
    final List<dynamic> slots =
        (exam['slots'] ?? exam['timeSlots'] ?? []) as List<dynamic>;
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
      final registeredStudents =
          (firstSlot['registeredStudents'] ?? []) as List<dynamic>;
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
    final int duration =
        (exam['duration'] ?? exam['durationMinutes'] ?? 0) as int;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
        vertical: isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 14
              : isTablet
              ? 16
              : 18,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      margin: EdgeInsets.only(
        bottom: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      constraints: BoxConstraints(
        minHeight: isMobile
            ? 100
            : isTablet
            ? 110
            : 120,
      ),
      child: isMobile
          // Stacked layout on small screens to avoid any overflow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isMobile
                          ? 40
                          : isTablet
                          ? 42
                          : 44,
                      height: isMobile
                          ? 40
                          : isTablet
                          ? 42
                          : 44,
                      decoration: BoxDecoration(
                        color: AdminDashboardStyles.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          isMobile
                              ? 10
                              : isTablet
                              ? 11
                              : 12,
                        ),
                        border: Border.all(
                          color: AdminDashboardStyles.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        size: isMobile
                            ? 20
                            : isTablet
                            ? 21
                            : 22,
                        color: AdminDashboardStyles.primary,
                      ),
                    ),
                    SizedBox(
                      width: isMobile
                          ? 12
                          : isTablet
                          ? 13
                          : 14,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile
                                  ? 14
                                  : isTablet
                                  ? 15
                                  : 16,
                              fontWeight: FontWeight.w700,
                              color: AdminDashboardStyles.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: isMobile
                                ? 6
                                : isTablet
                                ? 7
                                : 8,
                          ),
                          Wrap(
                            spacing: isMobile
                                ? 6
                                : isTablet
                                ? 7
                                : 8,
                            runSpacing: isMobile
                                ? 4
                                : isTablet
                                ? 5
                                : 6,
                            children: [
                              if (exam['isTegaExam'] == true)
                                _badge(
                                  'TEGA',
                                  AdminDashboardStyles.accentBlue,
                                  isMobile,
                                  isTablet,
                                  isDesktop,
                                ),
                              if (courseName.isNotEmpty)
                                _badge(
                                  courseName,
                                  AdminDashboardStyles.primary,
                                  isMobile,
                                  isTablet,
                                  isDesktop,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: isMobile
                          ? 16
                          : isTablet
                          ? 17
                          : 18,
                      color: AdminDashboardStyles.textLight,
                    ),
                    SizedBox(
                      width: isMobile
                          ? 6
                          : isTablet
                          ? 7
                          : 8,
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile
                            ? 13
                            : isTablet
                            ? 13.5
                            : 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isMobile
                      ? 8
                      : isTablet
                      ? 9
                      : 10,
                ),
                Wrap(
                  spacing: isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                  runSpacing: isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                  children: [
                    _chip(
                      icon: Icons.schedule_rounded,
                      label: '${slotsCount} slots',
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                    if (slotRange.isNotEmpty)
                      _chip(
                        icon: Icons.access_time_rounded,
                        label: slotRange,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    if (seatsInfo.isNotEmpty)
                      _chip(
                        icon: Icons.event_seat_rounded,
                        label: seatsInfo,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    if (questions > 0)
                      _chip(
                        icon: Icons.quiz_rounded,
                        label: '$questions questions',
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    if (duration > 0)
                      _chip(
                        icon: Icons.timer_rounded,
                        label: '$duration min',
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                  ],
                ),
                SizedBox(
                  height: isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12,
                ),
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
                            _loadExams(
                              forceRefresh: true,
                            ); // Reload exams after successful update
                          }
                        },
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      SizedBox(
                        width: isMobile
                            ? 6
                            : isTablet
                            ? 7
                            : 8,
                      ),
                      _iconButton(
                        icon: Icons.delete_rounded,
                        color: AdminDashboardStyles.statusError,
                        onTap: () =>
                            _deleteExam((exam['_id'] ?? exam['id']).toString()),
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
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
                        width: isTablet ? 42 : 44,
                        height: isTablet ? 42 : 44,
                        decoration: BoxDecoration(
                          color: AdminDashboardStyles.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 11 : 12,
                          ),
                          border: Border.all(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.assignment_rounded,
                          size: isTablet ? 21 : 22,
                          color: AdminDashboardStyles.primary,
                        ),
                      ),
                      SizedBox(width: isTablet ? 13 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 16,
                                fontWeight: FontWeight.w700,
                                color: AdminDashboardStyles.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 7 : 8),
                            Wrap(
                              spacing: isTablet ? 7 : 8,
                              runSpacing: isTablet ? 5 : 6,
                              children: [
                                if (exam['isTegaExam'] == true)
                                  _badge(
                                    'TEGA',
                                    AdminDashboardStyles.accentBlue,
                                    isMobile,
                                    isTablet,
                                    isDesktop,
                                  ),
                                if (courseName.isNotEmpty)
                                  _badge(
                                    courseName,
                                    AdminDashboardStyles.primary,
                                    isMobile,
                                    isTablet,
                                    isDesktop,
                                  ),
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
                _cell(courseName.isEmpty ? '-' : courseName, flex: 2),

                // Date & Slots
                _cell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: isTablet ? 17 : 18,
                            color: AdminDashboardStyles.textLight,
                          ),
                          SizedBox(width: isTablet ? 7 : 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 13.5 : 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 9 : 10),
                      Wrap(
                        spacing: isTablet ? 7 : 8,
                        runSpacing: isTablet ? 7 : 8,
                        children: [
                          _chip(
                            icon: Icons.schedule_rounded,
                            label: '${slotsCount} slots',
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                          if (slotRange.isNotEmpty)
                            _chip(
                              icon: Icons.access_time_rounded,
                              label: slotRange,
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          if (seatsInfo.isNotEmpty)
                            _chip(
                              icon: Icons.event_seat_rounded,
                              label: seatsInfo,
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          if (questions > 0)
                            _chip(
                              icon: Icons.quiz_rounded,
                              label: '$questions questions',
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          if (duration > 0)
                            _chip(
                              icon: Icons.timer_rounded,
                              label: '$duration min',
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                        ],
                      ),
                    ],
                  ),
                  flex: 3,
                ),

                // Questions
                _cell(questions > 0 ? '$questions questions' : '-', flex: 2),

                // Duration
                _cell('${duration > 0 ? duration : '-'} minutes', flex: 2),

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
                              const SnackBar(
                                content: Text('Edit exam not implemented yet'),
                              ),
                            );
                          },
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        ),
                        SizedBox(width: isTablet ? 7 : 8),
                        _iconButton(
                          icon: Icons.delete_rounded,
                          color: AdminDashboardStyles.statusError,
                          onTap: () => _deleteExam(
                            (exam['_id'] ?? exam['id']).toString(),
                          ),
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
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
        style:
            (style ??
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
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 6
              : isTablet
              ? 7
              : 8,
        ),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.all(
            isMobile
                ? 6
                : isTablet
                ? 7
                : 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(
              isMobile
                  ? 6
                  : isTablet
                  ? 7
                  : 8,
            ),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(
            icon,
            size: isMobile
                ? 16
                : isTablet
                ? 17
                : 18,
            color: color,
          ),
        ),
      ),
    );
  }

  // UI helpers
  Widget _badge(
    String text,
    Color color,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 6
            : isTablet
            ? 7
            : 8,
        vertical: isMobile
            ? 3
            : isTablet
            ? 3.5
            : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 4
              : isTablet
              ? 5
              : 6,
        ),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: isMobile
              ? 9
              : isTablet
              ? 9.5
              : 10,
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 8
            : isTablet
            ? 9
            : 10,
        vertical: isMobile
            ? 4
            : isTablet
            ? 5
            : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(
          isMobile
              ? 16
              : isTablet
              ? 18
              : 20,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile
                ? 12
                : isTablet
                ? 13
                : 14,
            color: AdminDashboardStyles.textLight,
          ),
          SizedBox(
            width: isMobile
                ? 4
                : isTablet
                ? 5
                : 6,
          ),
          Text(
            label,
            style: AdminDashboardStyles.statTitle.copyWith(
              fontSize: isMobile
                  ? 11
                  : isTablet
                  ? 11.5
                  : 12,
            ),
          ),
        ],
      ),
    );
  }
}
