import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class RegistrationsPage extends StatefulWidget {
  const RegistrationsPage({super.key});

  @override
  State<RegistrationsPage> createState() => _RegistrationsPageState();
}

class _RegistrationsPageState extends State<RegistrationsPage> {
  final ExamRepository _examRepository = ExamRepository();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  bool _loadingExams = false;
  bool _loadingRegs = false;
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _registrations = [];
  String? _selectedExamId; // null => no filter

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
      // Load exams from cache
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

    setState(() => _loadingExams = true);
    try {
      final exams = await _examRepository.getAllExams();
      setState(() {
        _exams = exams;
        _loadingExams = false;
      });

      // Cache the data
      await _cacheService.setExamsData(exams);
      // Reset toast flag on successful load (internet is back)
      _cacheService.resetNoInternetToastFlag();
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedExams = await _cacheService.getExamsData();
        if (cachedExams != null && cachedExams.isNotEmpty) {
          // Load from cache
          setState(() {
            _exams = cachedExams;
            _loadingExams = false;
          });
          return;
        }

        // No cache available
        setState(() => _loadingExams = false);
      } else {
        // Other errors
        setState(() => _loadingExams = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load exams: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadExamsInBackground() async {
    try {
      final exams = await _examRepository.getAllExams();
      if (mounted) {
        setState(() {
          _exams = exams;
        });

        // Cache the data
        await _cacheService.setExamsData(exams);
        // Reset toast flag on successful load (internet is back)
        _cacheService.resetNoInternetToastFlag();
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
    }
  }

  Future<void> _loadRegistrations({bool forceRefresh = false}) async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;

    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _registrations.isNotEmpty) {
      _loadRegistrationsInBackground();
      return;
    }

    setState(() => _loadingRegs = true);
    try {
      final regs = await _examRepository.getExamRegistrations(_selectedExamId!);
      setState(() {
        _registrations = regs;
        _loadingRegs = false;
      });

      // Cache the data
      await _cacheService.setExamRegistrationsData(_selectedExamId!, regs);
      // Reset toast flag on successful load (internet is back)
      _cacheService.resetNoInternetToastFlag();
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedRegs = await _cacheService.getExamRegistrationsData(
          _selectedExamId!,
        );
        if (cachedRegs != null && cachedRegs.isNotEmpty) {
          // Load from cache
          setState(() {
            _registrations = cachedRegs;
            _loadingRegs = false;
          });
          return;
        }

        // No cache available
        setState(() => _loadingRegs = false);
      } else {
        // Other errors
        setState(() => _loadingRegs = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load registrations: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadRegistrationsInBackground() async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;

    try {
      final regs = await _examRepository.getExamRegistrations(_selectedExamId!);
      if (mounted) {
        setState(() {
          _registrations = regs;
        });

        // Cache the data
        await _cacheService.setExamRegistrationsData(_selectedExamId!, regs);
        // Reset toast flag on successful load (internet is back)
        _cacheService.resetNoInternetToastFlag();
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                  Icons.people_alt_rounded,
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
                child: Text(
                  'Exam Registrations',
                  style: AdminDashboardStyles.welcomeHeader.copyWith(
                    fontSize: isMobile
                        ? 18
                        : isTablet
                        ? 20
                        : 22,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),

          // Exam filter (full width, left-aligned)
          SizedBox(
            width: isMobile
                ? double.infinity
                : isTablet
                ? 400
                : 420,
            child: _loadingExams
                ? LinearProgressIndicator(
                    minHeight: isMobile
                        ? 3
                        : isTablet
                        ? 3.5
                        : 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AdminDashboardStyles.primary,
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedExamId,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: isMobile
                          ? 14
                          : isTablet
                          ? 15
                          : 16,
                    ),
                    hint: Text(
                      'Select an exam to view registrations',
                      style: TextStyle(
                        fontSize: isMobile
                            ? 14
                            : isTablet
                            ? 15
                            : 16,
                      ),
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile
                            ? 12
                            : isTablet
                            ? 13
                            : 14,
                        vertical: isMobile
                            ? 12
                            : isTablet
                            ? 13
                            : 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          isMobile
                              ? 10
                              : isTablet
                              ? 11
                              : 12,
                        ),
                        borderSide: BorderSide(
                          color: AdminDashboardStyles.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          isMobile
                              ? 10
                              : isTablet
                              ? 11
                              : 12,
                        ),
                        borderSide: BorderSide(
                          color: AdminDashboardStyles.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          isMobile
                              ? 10
                              : isTablet
                              ? 11
                              : 12,
                        ),
                        borderSide: BorderSide(
                          color: AdminDashboardStyles.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    items: _exams.map((e) {
                      final id = (e['_id'] ?? e['id']).toString();
                      final title = (e['title'] ?? 'Untitled').toString();
                      return DropdownMenuItem(
                        value: id,
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile
                                ? 14
                                : isTablet
                                ? 15
                                : 16,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      setState(() {
                        _selectedExamId = v;
                        _registrations = []; // Clear previous registrations
                      });

                      // Try to load from cache first
                      if (v != null && v.isNotEmpty) {
                        try {
                          final cachedRegs = await _cacheService
                              .getExamRegistrationsData(v);
                          if (cachedRegs != null && cachedRegs.isNotEmpty) {
                            setState(() {
                              _registrations = cachedRegs;
                            });
                          }
                        } catch (e) {
                          // Silently handle cache errors
                        }
                      }

                      // Then load fresh data
                      await _loadRegistrations();
                    },
                  ),
          ),
          SizedBox(
            height: isMobile
                ? 20
                : isTablet
                ? 22
                : 24,
          ),

          if (_selectedExamId == null)
            _buildEmptyState(
              promptOnly: true,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            )
          else if (_loadingRegs)
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
          else if (_registrations.isEmpty)
            _buildEmptyState(
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            )
          else
            Column(
              children: [
                _buildTableHeader(isMobile, isTablet, isDesktop),
                SizedBox(
                  height: isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _registrations.length,
                  itemBuilder: (context, index) => _buildRow(
                    _registrations[index],
                    isMobile,
                    isTablet,
                    isDesktop,
                  ),
                ),
              ],
            ),
        ],
      ),
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
          _cell('STUDENT', flex: 3, style: style),
          if (!isMobile) _cell('EMAIL', flex: 3, style: style),
          _cell('EXAM', flex: 3, style: style),
          if (!isMobile) _cell('SLOT', flex: 2, style: style),
          _cell('STATUS', flex: 2, style: style, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    bool promptOnly = false,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 32
            : isTablet
            ? 40
            : 48,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: isMobile
                ? 48
                : isTablet
                ? 56
                : 64,
            color: Colors.grey[400],
          ),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),
          Text(
            promptOnly
                ? 'Select an exam to view registrations'
                : 'No registrations yet',
            style: TextStyle(
              fontSize: isMobile
                  ? 16
                  : isTablet
                  ? 17
                  : 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: isMobile
                ? 6
                : isTablet
                ? 7
                : 8,
          ),
          if (!promptOnly)
            Text(
              'Students will appear here once they register for the selected exam.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile
                    ? 13
                    : isTablet
                    ? 13.5
                    : 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    Map<String, dynamic> r,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final student = r['student'] ?? r['studentId'] ?? {};
    final exam = r['exam'] ?? r['examId'] ?? {};
    final name =
        (student is Map
            ? (student['name'] ?? student['username'] ?? 'Student')
            : student?.toString()) ??
        'Student';
    final email = (student is Map ? (student['email'] ?? '-') : '-') as String;
    final examTitle =
        (exam is Map ? (exam['title'] ?? 'Exam') : exam?.toString()) ?? 'Exam';
    final slotId = r['slotId']?.toString() ?? '-';
    final status =
        r['paymentStatus']?.toString() ?? r['status']?.toString() ?? 'pending';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 8
              : isTablet
              ? 9
              : 10,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      margin: EdgeInsets.only(
        top: isMobile
            ? 8
            : isTablet
            ? 9
            : 10,
      ),
      child: Row(
        children: [
          _cell(
            name,
            flex: 3,
            strong: true,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          if (!isMobile)
            _cell(
              email,
              flex: 3,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          _cell(
            examTitle,
            flex: 3,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          if (!isMobile)
            _cell(
              slotId,
              flex: 2,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          _cell(
            _statusBadge(status, isMobile, isTablet, isDesktop),
            flex: 2,
            alignEnd: true,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 16
              : isTablet
              ? 18
              : 20,
        ),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: isMobile
              ? 10
              : isTablet
              ? 10.5
              : 11,
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
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
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
              fontSize: isMobile
                  ? 12
                  : isTablet
                  ? 12.5
                  : 13,
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
