import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class ExamResultsPage extends StatefulWidget {
  const ExamResultsPage({super.key});

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage> {
  final ExamRepository _examRepository = ExamRepository();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  bool _loadingExams = false;
  bool _loadingResults = false;
  bool _isLoadingFromCache = false;
  bool _publishing = false;
  String? _errorMessageExams;
  String? _errorMessageResults;
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _groupedResults = [];
  String? _selectedExamId;
  Set<String> _expandedGroups = {};

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
      setState(() => _isLoadingFromCache = true);

      // Load exams from cache
      final cachedExams = await _cacheService.getExamsData();
      if (cachedExams != null && cachedExams.isNotEmpty) {
        setState(() {
          _exams = cachedExams;
          _isLoadingFromCache = false;
        });
      } else {
        setState(() => _isLoadingFromCache = false);
      }
    } catch (e) {
      setState(() => _isLoadingFromCache = false);
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
      // Make sure loading is false since we have cached data
      if (mounted) {
        setState(() => _loadingExams = false);
      }
      _loadExamsInBackground();
      return;
    }

    setState(() => _loadingExams = true);
    try {
      final exams = await _examRepository.getAllExams();
      if (mounted) {
        setState(() {
          _exams = exams;
          _loadingExams = false;
        });

        // Cache the data
        await _cacheService.setExamsData(exams);
        // Reset toast flag on successful load (internet is back)
        _cacheService.resetNoInternetToastFlag();
        // Show "back online" toast if we were offline
        _cacheService.handleOnlineState(context);
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedExams = await _cacheService.getExamsData();
        if (cachedExams != null && cachedExams.isNotEmpty) {
          // Load from cache
          if (mounted) {
            setState(() {
              _exams = cachedExams;
              _loadingExams = false;
              _errorMessageExams =
                  null; // Clear error since we have cached data
            });
          }
          // Show "offline" toast even if we have cache
          _cacheService.handleOfflineState(context);
          return;
        }

        // No cache available
        if (mounted) {
          setState(() {
            _loadingExams = false;
            _errorMessageExams = 'No internet connection';
          });
          // Show "offline" toast
          _cacheService.handleOfflineState(context);
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _loadingExams = false;
            _errorMessageExams = e.toString();
          });
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
        // Show "back online" toast if we were offline
        _cacheService.handleOnlineState(context);
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
    }
  }

  Future<void> _loadResults({bool forceRefresh = false}) async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;

    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _groupedResults.isNotEmpty) {
      // Make sure loading is false since we have cached data
      if (mounted) {
        setState(() => _loadingResults = false);
      }
      _loadResultsInBackground();
      return;
    }

    setState(() => _loadingResults = true);
    try {
      final results = await _examRepository.getAdminExamResults(
        _selectedExamId!,
      );
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

        // Cache the data
        await _cacheService.setExamResultsData(_selectedExamId!, results);
        // Reset toast flag on successful load (internet is back)
        _cacheService.resetNoInternetToastFlag();
        // Show "back online" toast if we were offline
        _cacheService.handleOnlineState(context);
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedResults = await _cacheService.getExamResultsData(
          _selectedExamId!,
        );
        if (cachedResults != null && cachedResults.isNotEmpty) {
          // Load from cache
          if (mounted) {
            setState(() {
              _groupedResults = cachedResults;
              _loadingResults = false;
              _errorMessageResults =
                  null; // Clear error since we have cached data
              // Auto-expand first group if available
              if (cachedResults.isNotEmpty) {
                final firstGroup = cachedResults.first;
                final key = _getGroupKey(firstGroup);
                _expandedGroups = {key};
              }
            });
          }
          // Show "offline" toast even if we have cache
          _cacheService.handleOfflineState(context);
          return;
        }

        // No cache available
        if (mounted) {
          setState(() {
            _loadingResults = false;
            _errorMessageResults = 'No internet connection';
          });
          // Show "offline" toast
          _cacheService.handleOfflineState(context);
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _loadingResults = false;
            _errorMessageResults = e.toString();
          });
        }
      }
    }
  }

  Future<void> _loadResultsInBackground() async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;

    try {
      final results = await _examRepository.getAdminExamResults(
        _selectedExamId!,
      );
      if (mounted) {
        setState(() {
          _groupedResults = results;
          // Auto-expand first group if available
          if (results.isNotEmpty) {
            final firstGroup = results.first;
            final key = _getGroupKey(firstGroup);
            _expandedGroups = {key};
          }
        });

        // Cache the data
        await _cacheService.setExamResultsData(_selectedExamId!, results);
        // Reset toast flag on successful load (internet is back)
        _cacheService.resetNoInternetToastFlag();
        // Show "back online" toast if we were offline
        _cacheService.handleOnlineState(context);
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
    }
  }

  String _getGroupKey(Map<String, dynamic> group) {
    final examId = (group['examId'] ?? '').toString();
    final examDate = (group['examDate'] ?? '').toString();
    return '$examId-$examDate';
  }

  Future<void> _publishResults(Map<String, dynamic> group) async {
    final examId = (group['examId'] ?? '').toString();
    final examDate = (group['examDate'] ?? '').toString();

    setState(() => _publishing = true);
    try {
      await _examRepository.publishExamResults(
        examId: examId,
        examDate: examDate,
        publish: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Results published successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload results to get updated publish status
        await _loadResults(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish results: $e'),
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

  Future<void> _unpublishResults(Map<String, dynamic> group) async {
    final examId = (group['examId'] ?? '').toString();
    final examDate = (group['examDate'] ?? '').toString();

    setState(() => _publishing = true);
    try {
      await _examRepository.publishExamResults(
        examId: examId,
        examDate: examDate,
        publish: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Results unpublished successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload results to get updated publish status
        await _loadResults(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unpublish results: $e'),
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
                    dropdownColor: Colors.white,
                    menuMaxHeight: 300,
                    style: TextStyle(
                      fontSize: isMobile
                          ? 14
                          : isTablet
                          ? 15
                          : 16,
                      color: Colors.black,
                    ),
                    hint: Text(
                      'Select an exam to view results',
                      style: TextStyle(
                        fontSize: isMobile
                            ? 14
                            : isTablet
                            ? 15
                            : 16,
                        color: Colors.black54,
                      ),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
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
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: isMobile
                          ? 20
                          : isTablet
                          ? 22
                          : 24,
                    ),
                    onChanged: (v) async {
                      setState(() {
                        _selectedExamId = v;
                        _groupedResults = [];
                        _expandedGroups = {};
                      });

                      // Try to load from cache first
                      if (v != null && v.isNotEmpty) {
                        try {
                          setState(() => _isLoadingFromCache = true);
                          final cachedResults = await _cacheService
                              .getExamResultsData(v);
                          if (cachedResults != null &&
                              cachedResults.isNotEmpty) {
                            setState(() {
                              _groupedResults = cachedResults;
                              _isLoadingFromCache = false;
                              // Auto-expand first group if available
                              if (cachedResults.isNotEmpty) {
                                final firstGroup = cachedResults.first;
                                final key = _getGroupKey(firstGroup);
                                _expandedGroups = {key};
                              }
                            });
                          } else {
                            setState(() => _isLoadingFromCache = false);
                          }
                        } catch (e) {
                          setState(() => _isLoadingFromCache = false);
                        }
                      }

                      // Then load fresh data
                      await _loadResults();
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

          if (_errorMessageExams != null &&
              !_isLoadingFromCache &&
              _exams.isEmpty)
            _buildErrorState(
              message: _errorMessageExams!,
              onRetry: () {
                setState(() {
                  _errorMessageExams = null;
                });
                _loadExams(forceRefresh: true);
              },
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            )
          else if (_selectedExamId == null)
            _buildEmptyState(
              promptOnly: true,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            )
          else if (_errorMessageResults != null && !_isLoadingFromCache)
            _buildErrorState(
              message: _errorMessageResults!,
              onRetry: () {
                setState(() {
                  _errorMessageResults = null;
                });
                _loadResults(forceRefresh: true);
              },
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            )
          else if (_loadingResults && !_isLoadingFromCache)
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
          else if (_groupedResults.isEmpty)
            _buildEmptyState(
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results by Date',
                  style: TextStyle(
                    fontSize: isMobile
                        ? 16
                        : isTablet
                        ? 17
                        : 18,
                    fontWeight: FontWeight.w700,
                    color: AdminDashboardStyles.textDark,
                  ),
                ),
                SizedBox(
                  height: isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                ..._groupedResults.map(
                  (group) => _buildResultGroupCard(
                    group,
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

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isTablet
            ? 28
            : 32,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile
                  ? 56
                  : isTablet
                  ? 64
                  : 72,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
            ),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 19
                    : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 8
                  : isTablet
                  ? 9
                  : 10,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 20
                  : isTablet
                  ? 24
                  : 28,
            ),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh,
                size: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? 20
                      : isTablet
                      ? 24
                      : 28,
                  vertical: isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 8
                        : isTablet
                        ? 9
                        : 10,
                  ),
                ),
              ),
            ),
          ],
        ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
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
            promptOnly ? 'Select an exam to view results' : 'No results found',
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
              "Results will appear here once students complete the selected exam.",
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

  Widget _buildResultGroupCard(
    Map<String, dynamic> group,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final key = _getGroupKey(group);
    final isExpanded = _expandedGroups.contains(key);
    final examTitle = (group['examTitle'] ?? 'Untitled Exam').toString();
    final examDate = group['examDate']?.toString() ?? '';
    final courseTitle = group['courseTitle']?.toString();
    final totalStudents = (group['totalStudents'] ?? 0) as int;
    final passedStudents = (group['passedStudents'] ?? 0) as int;
    final failedStudents = (group['failedStudents'] ?? 0) as int;
    final averagePercentageValue = group['averagePercentage'];
    final averagePercentage = averagePercentageValue is int
        ? averagePercentageValue.toDouble()
        : (averagePercentageValue is double
              ? averagePercentageValue
              : (averagePercentageValue != null
                    ? (averagePercentageValue as num).toDouble()
                    : 0.0));
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
      margin: EdgeInsets.only(
        bottom: isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 12
              : isTablet
              ? 14
              : 16,
        ),
        border: Border.all(
          color: AdminDashboardStyles.borderLight.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                isMobile
                    ? 12
                    : isTablet
                    ? 14
                    : 16,
              ),
              topRight: Radius.circular(
                isMobile
                    ? 12
                    : isTablet
                    ? 14
                    : 16,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(
                isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 24,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: EdgeInsets.all(
                          isMobile
                              ? 10
                              : isTablet
                              ? 12
                              : 14,
                        ),
                        decoration: BoxDecoration(
                          color: AdminDashboardStyles.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            isMobile
                                ? 10
                                : isTablet
                                ? 12
                                : 14,
                          ),
                        ),
                        child: Icon(
                          Icons.quiz_rounded,
                          color: AdminDashboardStyles.primary,
                          size: isMobile
                              ? 22
                              : isTablet
                              ? 24
                              : 26,
                        ),
                      ),
                      SizedBox(
                        width: isMobile
                            ? 14
                            : isTablet
                            ? 16
                            : 18,
                      ),
                      // Title and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              examTitle,
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 17
                                    : isTablet
                                    ? 18
                                    : 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (courseTitle != null) ...[
                              SizedBox(
                                height: isMobile
                                    ? 4
                                    : isTablet
                                    ? 5
                                    : 6,
                              ),
                              Text(
                                courseTitle,
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 13
                                      : isTablet
                                      ? 14
                                      : 15,
                                  color: AdminDashboardStyles.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            SizedBox(
                              height: isMobile
                                  ? 8
                                  : isTablet
                                  ? 9
                                  : 10,
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile
                                        ? 6
                                        : isTablet
                                        ? 7
                                        : 8,
                                    vertical: isMobile
                                        ? 3
                                        : isTablet
                                        ? 4
                                        : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(
                                      isMobile
                                          ? 4
                                          : isTablet
                                          ? 5
                                          : 6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: isMobile
                                            ? 13
                                            : isTablet
                                            ? 14
                                            : 15,
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
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: isMobile
                                              ? 12
                                              : isTablet
                                              ? 12.5
                                              : 13,
                                          color: AdminDashboardStyles.textLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPublished) ...[
                                  SizedBox(
                                    width: isMobile
                                        ? 8
                                        : isTablet
                                        ? 9
                                        : 10,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile
                                          ? 6
                                          : isTablet
                                          ? 7
                                          : 8,
                                      vertical: isMobile
                                          ? 3
                                          : isTablet
                                          ? 4
                                          : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminDashboardStyles.accentGreen
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        isMobile
                                            ? 4
                                            : isTablet
                                            ? 5
                                            : 6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: isMobile
                                              ? 13
                                              : isTablet
                                              ? 14
                                              : 15,
                                          color:
                                              AdminDashboardStyles.accentGreen,
                                        ),
                                        SizedBox(
                                          width: isMobile
                                              ? 4
                                              : isTablet
                                              ? 5
                                              : 6,
                                        ),
                                        Text(
                                          'Published',
                                          style: TextStyle(
                                            fontSize: isMobile
                                                ? 12
                                                : isTablet
                                                ? 12.5
                                                : 13,
                                            color: AdminDashboardStyles
                                                .accentGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Expand icon
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AdminDashboardStyles.textLight,
                        size: isMobile
                            ? 24
                            : isTablet
                            ? 26
                            : 28,
                      ),
                    ],
                  ),
                  // Stats row
                  SizedBox(
                    height: isMobile
                        ? 16
                        : isTablet
                        ? 18
                        : 20,
                  ),
                  Wrap(
                    spacing: isMobile
                        ? 8
                        : isTablet
                        ? 10
                        : 12,
                    runSpacing: isMobile
                        ? 8
                        : isTablet
                        ? 10
                        : 12,
                    children: [
                      _buildStatChip(
                        'Total',
                        totalStudents.toString(),
                        Colors.blue,
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      _buildStatChip(
                        'Passed',
                        passedStudents.toString(),
                        Colors.green,
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      _buildStatChip(
                        'Failed',
                        failedStudents.toString(),
                        Colors.red,
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      _buildStatChip(
                        'Avg %',
                        '${averagePercentage.toStringAsFixed(1)}%',
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
          ),
          // Divider
          if (isExpanded)
            Divider(
              height: 1,
              thickness: 1,
              color: AdminDashboardStyles.borderLight.withOpacity(0.3),
            ),
          // Expanded student list
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(
                    isMobile
                        ? 12
                        : isTablet
                        ? 14
                        : 16,
                  ),
                  bottomRight: Radius.circular(
                    isMobile
                        ? 12
                        : isTablet
                        ? 14
                        : 16,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: isMobile
                        ? 16
                        : isTablet
                        ? 18
                        : 20,
                  ),
                  _buildStudentTableHeader(isMobile, isTablet, isDesktop),
                  SizedBox(
                    height: isMobile
                        ? 8
                        : isTablet
                        ? 10
                        : 12,
                  ),
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value as Map<String, dynamic>;
                    return _buildStudentRow(
                      student,
                      index,
                      isMobile,
                      isTablet,
                      isDesktop,
                    );
                  }),
                  SizedBox(
                    height: isMobile
                        ? 16
                        : isTablet
                        ? 18
                        : 20,
                  ),
                ],
              ),
            ),
          // Divider before action buttons
          Divider(
            height: 1,
            thickness: 1,
            color: AdminDashboardStyles.borderLight.withOpacity(0.3),
          ),
          // Publish/Unpublish button at the bottom of the card
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile
                  ? 18
                  : isTablet
                  ? 20
                  : 24,
              vertical: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_publishing)
                        if (!isPublished)
                          // Publish button
                          ElevatedButton.icon(
                            onPressed: () => _publishResults(group),
                            icon: Icon(
                              Icons.publish,
                              size: isMobile
                                  ? 16
                                  : isTablet
                                  ? 17
                                  : 18,
                            ),
                            label: Text(
                              'Publish Results',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 13.5
                                    : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminDashboardStyles.accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile
                                    ? 20
                                    : isTablet
                                    ? 24
                                    : 28,
                                vertical: isMobile
                                    ? 12
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile
                                      ? 8
                                      : isTablet
                                      ? 9
                                      : 10,
                                ),
                              ),
                            ),
                          )
                        else
                          // Unpublish button
                          ElevatedButton.icon(
                            onPressed: () => _unpublishResults(group),
                            icon: Icon(
                              Icons.unpublished,
                              size: isMobile
                                  ? 16
                                  : isTablet
                                  ? 17
                                  : 18,
                            ),
                            label: Text(
                              'Unpublish Results',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 13.5
                                    : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile
                                    ? 20
                                    : isTablet
                                    ? 24
                                    : 28,
                                vertical: isMobile
                                    ? 12
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile
                                      ? 8
                                      : isTablet
                                      ? 9
                                      : 10,
                                ),
                              ),
                            ),
                          )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: isMobile
                                  ? 20
                                  : isTablet
                                  ? 22
                                  : 24,
                              height: isMobile
                                  ? 20
                                  : isTablet
                                  ? 22
                                  : 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AdminDashboardStyles.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? 8
                                  : isTablet
                                  ? 10
                                  : 12,
                            ),
                            Text(
                              isPublished ? 'Unpublishing...' : 'Publishing...',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 13.5
                                    : 14,
                                color: AdminDashboardStyles.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_publishing)
                        if (!isPublished)
                          // Publish button
                          ElevatedButton.icon(
                            onPressed: () => _publishResults(group),
                            icon: Icon(
                              Icons.publish,
                              size: isMobile
                                  ? 16
                                  : isTablet
                                  ? 17
                                  : 18,
                            ),
                            label: Text(
                              'Publish Results',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 13.5
                                    : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminDashboardStyles.accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile
                                    ? 20
                                    : isTablet
                                    ? 24
                                    : 28,
                                vertical: isMobile
                                    ? 12
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile
                                      ? 8
                                      : isTablet
                                      ? 9
                                      : 10,
                                ),
                              ),
                            ),
                          )
                        else
                          // Unpublish button
                          ElevatedButton.icon(
                            onPressed: () => _unpublishResults(group),
                            icon: Icon(
                              Icons.unpublished,
                              size: isMobile
                                  ? 16
                                  : isTablet
                                  ? 17
                                  : 18,
                            ),
                            label: Text(
                              'Unpublish Results',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 13.5
                                    : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile
                                    ? 20
                                    : isTablet
                                    ? 24
                                    : 28,
                                vertical: isMobile
                                    ? 12
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile
                                      ? 8
                                      : isTablet
                                      ? 9
                                      : 10,
                                ),
                              ),
                            ),
                          )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: isMobile
                                  ? 20
                                  : isTablet
                                  ? 22
                                  : 24,
                              height: isMobile
                                  ? 20
                                  : isTablet
                                  ? 22
                                  : 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AdminDashboardStyles.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? 8
                                  : isTablet
                                  ? 10
                                  : 12,
                            ),
                            Text(
                              isPublished ? 'Unpublishing...' : 'Publishing...',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 13.5
                                    : 14,
                                color: AdminDashboardStyles.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    Color color,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
        vertical: isMobile
            ? 8
            : isTablet
            ? 9
            : 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 8
              : isTablet
              ? 9
              : 10,
        ),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile
                  ? 14
                  : isTablet
                  ? 15
                  : 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(
            height: isMobile
                ? 2
                : isTablet
                ? 3
                : 4,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile
                  ? 10
                  : isTablet
                  ? 10.5
                  : 11,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTableHeader(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: isMobile
          ? 10
          : isTablet
          ? 11
          : 12,
      color: AdminDashboardStyles.textLight,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      child: Row(
        children: [
          _cell(
            'STUDENT',
            flex: 3,
            style: style,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          if (!isMobile)
            _cell(
              'EMAIL',
              flex: 3,
              style: style,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          _cell(
            'SCORE',
            flex: 2,
            style: style,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          _cell(
            'PERCENTAGE',
            flex: 2,
            style: style,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          if (!isMobile)
            _cell(
              'ATTEMPT',
              flex: 1,
              style: style,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          _cell(
            'STATUS',
            flex: 2,
            style: style,
            alignEnd: true,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(
    Map<String, dynamic> student,
    int index,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final studentName = (student['studentName'] ?? 'Student').toString();
    final email = (student['email'] ?? '-').toString();
    final score = (student['score'] ?? 0).toString();
    final totalMarks = (student['totalMarks'] ?? 0).toString();
    final percentageValue = student['percentage'];
    final percentage = percentageValue is int
        ? percentageValue.toDouble()
        : (percentageValue is double
              ? percentageValue
              : (percentageValue != null
                    ? (percentageValue as num).toDouble()
                    : 0.0));
    final isPassed = student['isPassed'] ?? false;
    final attemptNumber = (student['attemptNumber'] ?? 1).toString();
    final published = student['published'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
        vertical: isMobile
            ? 4
            : isTablet
            ? 5
            : 6,
      ),
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
      child: Row(
        children: [
          _cell(
            '$studentName ${published ? '✓' : ''}',
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
            '$score / $totalMarks',
            flex: 2,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          _cell(
            '${percentage.toStringAsFixed(1)}%',
            flex: 2,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          ),
          if (!isMobile)
            _cell(
              '#$attemptNumber',
              flex: 1,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
          _cell(
            _buildStatusBadge(isPassed, isMobile, isTablet, isDesktop),
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

  Widget _buildStatusBadge(
    bool isPassed,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final color = isPassed
        ? AdminDashboardStyles.accentGreen
        : AdminDashboardStyles.statusError;
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
        isPassed ? 'PASSED' : 'FAILED',
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
            style ??
            TextStyle(
              color: AdminDashboardStyles.textDark,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
              fontSize: isMobile
                  ? 12
                  : isTablet
                  ? 12.5
                  : 13,
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
