import 'package:flutter/material.dart';
import 'package:tega/features/5_student_dashboard/data/payment_service.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/config/env_config.dart';
import 'package:tega/core/services/payment_page_cache_service.dart';

class StartPaymentPage extends StatefulWidget {
  const StartPaymentPage({super.key});

  @override
  State<StartPaymentPage> createState() => _StartPaymentPageState();
}

class OwnedMemory {
  static final Set<String> ids = <String>{};
  static final Set<String> keys = <String>{};
}

class _StartPaymentPageState extends State<StartPaymentPage> {
  final _courseIdController = TextEditingController();
  final _notesController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  final PaymentPageCacheService _cacheService = PaymentPageCacheService();
  bool _loading = false; // used for manual payment fallback button
  bool _loadingCourses = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _allItems = []; // Combined courses and exams
  Set<String> _ownedCourseIds = {};

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _paymentService.initializeRazorpay(
      onSuccess: _onSuccess,
      onError: _onError,
      onExternalWallet: (_) {},
    );
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadCourses();
  }

  @override
  void dispose() {
    _courseIdController.dispose();
    _notesController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  void _onSuccess(response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onError(response) {
    try {
      final int code = response.code as int? ?? -1;
      final String msg = (response.message ?? '').toString();
      final bool isCancelled =
          code == 2 || msg.toLowerCase().contains('cancel');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCancelled ? 'Payment cancelled' : 'Payment failed: $msg',
          ),
          backgroundColor: isCancelled ? Colors.grey : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedCourses = await _cacheService.getCoursesData();
      final cachedExams = await _cacheService.getExamsData();

      if (cachedCourses != null && cachedExams != null && mounted) {
        setState(() {
          _courses = cachedCourses;
          _exams = cachedExams;
          _allItems = [..._courses, ..._exams];
          _loadingCourses = false;
        });
        // Still fetch in background to update cache
        _fetchCoursesAndExamsInBackground();
        return;
      }
    }

    setState(() => _loadingCourses = true);
    await _fetchCoursesAndExamsInBackground();
  }

  Future<void> _fetchCoursesAndExamsInBackground() async {
    try {
      final headers = await AuthService().getAuthHeaders();
      final service = StudentDashboardService();
      final all = await service.getAllCourses(headers);
      final enrolled = await service.getEnrolledCourses(headers);

      // Fetch exams
      final auth = AuthService();
      final studentId = auth.currentUser?.id;
      List<Map<String, dynamic>> exams = [];
      if (studentId != null) {
        try {
          final backendExams = await service.getAvailableExams(
            studentId,
            headers,
          );
          exams = _processExamsData(backendExams);
        } catch (e) {
          // If exam fetch fails, continue with courses only
        }
      }
      // Build sets for owned detection by id and by normalized title/slug
      final Set<String> ownedIds = {...OwnedMemory.ids};
      final Set<String> ownedKeys = {...OwnedMemory.keys};
      for (final e in enrolled) {
        try {
          if (e is Map) {
            final id =
                (e['_id'] ??
                        e['id'] ??
                        e['courseId'] ??
                        e['course']?['_id'] ??
                        e['course']?['id'] ??
                        '')
                    .toString();
            if (id.isNotEmpty) ownedIds.add(id);
            final t =
                (e['title'] ??
                        e['name'] ??
                        e['slug'] ??
                        e['key'] ??
                        e['code'] ??
                        e['course']?['title'] ??
                        e['course']?['name'] ??
                        e['course']?['slug'] ??
                        '')
                    .toString();
            if (t.trim().isNotEmpty) ownedKeys.add(_norm(t));
          } else {
            final t = e.toString();
            if (t.trim().isNotEmpty) ownedKeys.add(_norm(t));
          }
        } catch (_) {}
      }
      _ownedCourseIds = ownedIds;
      _courses = all.map<Map<String, dynamic>>((c) {
        final id = (c['_id'] ?? c['id'] ?? c['courseId'] ?? '').toString();
        final title =
            (c['title'] ??
                    c['name'] ??
                    c['courseTitle'] ??
                    c['slug'] ??
                    c['key'] ??
                    'Course')
                .toString();
        final description = (c['description'] ?? c['courseDescription'] ?? '')
            .toString();

        // Extract duration - handle different formats
        int totalMinutes = 0;
        int totalVideoSeconds = 0;

        // Try to get total video duration directly first
        if (c['totalVideoDuration'] != null) {
          final videoDur = c['totalVideoDuration'];
          if (videoDur is num) {
            totalVideoSeconds = videoDur.toInt();
          }
        }

        // Calculate total video duration from modules and lectures
        if (totalVideoSeconds == 0 &&
            c['modules'] != null &&
            c['modules'] is List) {
          final modules = c['modules'] as List;
          for (final module in modules) {
            if (module is Map) {
              // Check for lectures array
              if (module['lectures'] != null && module['lectures'] is List) {
                final lectures = module['lectures'] as List;
                for (final lecture in lectures) {
                  if (lecture is Map) {
                    final lectureType =
                        lecture['type']?.toString().toLowerCase() ?? '';
                    final lectureDuration = lecture['duration'];

                    // Check if it's a video type
                    if ((lectureType == 'video' || lectureType.isEmpty) &&
                        lectureDuration != null) {
                      try {
                        if (lectureDuration is num) {
                          // Duration is in seconds
                          totalVideoSeconds += lectureDuration.toInt();
                        } else if (lectureDuration is String) {
                          // Try to parse as number
                          final parsed = int.tryParse(lectureDuration);
                          if (parsed != null) {
                            totalVideoSeconds += parsed;
                          }
                        }
                      } catch (_) {
                        // Skip invalid durations
                      }
                    }
                  }
                }
              }

              // Also check for content array (alternative structure)
              if (module['content'] != null && module['content'] is List) {
                final content = module['content'] as List;
                for (final item in content) {
                  if (item is Map) {
                    final itemType =
                        item['type']?.toString().toLowerCase() ?? '';
                    final itemDuration = item['duration'];
                    if ((itemType == 'video' || itemType.isEmpty) &&
                        itemDuration != null) {
                      try {
                        if (itemDuration is num) {
                          totalVideoSeconds += itemDuration.toInt();
                        }
                      } catch (_) {}
                    }
                  }
                }
              }
            }
          }
        }

        // Convert video seconds to minutes
        final videoMinutes = (totalVideoSeconds / 60).round();

        // Get estimated duration as fallback
        if (c['estimatedDuration'] != null && c['estimatedDuration'] is Map) {
          // Format: { hours: X, minutes: Y }
          final hours = (c['estimatedDuration']['hours'] ?? 0) as num;
          final minutes = (c['estimatedDuration']['minutes'] ?? 0) as num;
          totalMinutes = (hours * 60 + minutes).round();
        } else if (c['duration'] != null) {
          // Duration might be in seconds, minutes, or hours
          final dur = c['duration'] as num;
          if (dur > 10000) {
            // Likely in seconds, convert to minutes
            totalMinutes = (dur / 60).round();
          } else if (dur > 100) {
            // Likely in minutes
            totalMinutes = dur.round();
          } else {
            // Likely in hours, convert to minutes
            totalMinutes = (dur * 60).round();
          }
        } else if (c['totalDuration'] != null) {
          final dur = c['totalDuration'] as num;
          totalMinutes = dur > 10000
              ? (dur / 60).round()
              : dur > 100
              ? dur.round()
              : (dur * 60).round();
        }

        // Use video duration if available, otherwise use estimated duration
        final finalDuration = videoMinutes > 0 ? videoMinutes : totalMinutes;

        // If no video duration found, use estimated duration as video duration fallback
        // (assuming estimated duration represents video content)
        final finalVideoSeconds = totalVideoSeconds > 0
            ? totalVideoSeconds
            : (totalMinutes > 0 ? totalMinutes * 60 : 0);

        final price =
            (c['effectivePrice'] ?? c['offerPrice'] ?? c['price'] ?? 0);
        final owned =
            _ownedCourseIds.contains(id) || ownedKeys.contains(_norm(title));
        return {
          'id': id,
          'title': title,
          'description': description,
          'durationMinutes': finalDuration,
          'videoDurationSeconds': finalVideoSeconds,
          'price': price,
          'owned': owned,
        };
      }).toList();

      // Cache courses data
      await _cacheService.setCoursesData(_courses);
      await _cacheService.setExamsData(exams);
      _exams = exams;

      // Combine courses and exams
      _allItems = [..._courses, ..._exams];
    } catch (_) {
      _courses = [];
      _exams = [];
      _allItems = [];
      _ownedCourseIds = {};
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  List<Map<String, dynamic>> _processExamsData(List<dynamic> backendExams) {
    return backendExams.map<Map<String, dynamic>>((exam) {
      final examData = exam as Map<String, dynamic>;

      final id = (examData['_id'] ?? examData['id'] ?? '').toString();
      final title = (examData['title'] ?? 'Exam').toString();
      final description = (examData['description'] ?? 'TEGA Exam').toString();

      // Get price - check if payment is required
      final requiresPayment = examData['requiresPayment'] == true;
      final price = requiresPayment ? (examData['price'] ?? 0) : 0;

      // Check if user has paid (from registration data)
      final registration = examData['registration'];
      final hasPaid =
          registration != null &&
          (registration['paymentStatus'] == 'paid' ||
              registration['paymentStatus'] == 'completed');

      // Get duration in minutes
      final durationMinutes = examData['duration'] ?? 120;

      return {
        'id': id,
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'videoDurationSeconds': 0, // Exams don't have video duration
        'price': price,
        'owned': hasPaid || !requiresPayment,
        'type': 'exam', // Mark as exam
        'isTegaExam': examData['isTegaExam'] == true,
      };
    }).toList();
  }

  Future<void> _startPayment() async {
    final courseId = _courseIdController.text.trim();
    if (courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course ID missing'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final order = await _paymentService.createOrder(courseId: courseId);
      if (order['success'] == true) {
        final user = AuthService().currentUser;
        // Backend returns amount in paise, so use it directly
        final int amountPaise = order['amount'] is int
            ? order['amount'] as int
            : ((order['chargedAmount'] ?? 0) is num
                  ? ((order['chargedAmount'] as num) * 100).round()
                  : 0);
        _paymentService.openPayment(
          orderId: order['orderId'],
          keyId: EnvConfig
              .razorpayKeyId, // Backend doesn't return keyId, use env config
          name: 'TEGA Payment',
          description: _notesController.text.trim().isEmpty
              ? 'Course Enrollment'
              : _notesController.text.trim(),
          amount: amountPaise,
          currency: order['currency'] ?? 'INR',
          prefillEmail: user?.email ?? '',
          prefillContact: user?.phone ?? '',
          notes: {'courseId': courseId},
        );
      } else {
        final msg = (order['message'] ?? 'Failed to create order').toString();
        if (msg.toLowerCase().contains('already have access')) {
          _markOwned(courseId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already own this course'),
              backgroundColor: Colors.grey,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        throw Exception(msg);
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('already have access')) {
        _markOwned(courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already own this course'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return; // suppress red error toast for this case
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markOwned(String courseId, {String? title}) {
    if (courseId.isEmpty && (title == null || title.trim().isEmpty)) return;
    final key = title == null ? null : _norm(title);
    setState(() {
      if (courseId.isNotEmpty) {
        _ownedCourseIds.add(courseId);
        OwnedMemory.ids.add(courseId);
      }
      if (key != null && key.isNotEmpty) {
        OwnedMemory.keys.add(key);
      }
      _courses = _courses
          .map(
            (c) =>
                (c['id'] == courseId ||
                    (key != null && _norm(c['title'] ?? '') == key))
                ? {...c, 'owned': true}
                : c,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: _loadingCourses
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF9C88FF),
                strokeWidth: isLargeDesktop
                    ? 4
                    : isDesktop
                    ? 3.5
                    : isTablet
                    ? 3
                    : isSmallScreen
                    ? 2.5
                    : 3,
              ),
            )
          : _allItems.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 48
                      : isDesktop
                      ? 40
                      : isTablet
                      ? 36
                      : isSmallScreen
                      ? 24
                      : 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: isLargeDesktop
                          ? 80
                          : isDesktop
                          ? 72
                          : isTablet
                          ? 64
                          : isSmallScreen
                          ? 48
                          : 56,
                      color: const Color(0xFF9C88FF),
                    ),
                    SizedBox(
                      height: isLargeDesktop
                          ? 24
                          : isDesktop
                          ? 20
                          : isTablet
                          ? 18
                          : isSmallScreen
                          ? 12
                          : 16,
                    ),
                    Text(
                      'No courses or exams available',
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 24
                            : isDesktop
                            ? 22
                            : isTablet
                            ? 20
                            : isSmallScreen
                            ? 16
                            : 18,
                        color: const Color(0xFF2C3E50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: isLargeDesktop
                          ? 24
                          : isDesktop
                          ? 20
                          : isTablet
                          ? 18
                          : isSmallScreen
                          ? 12
                          : 16,
                    ),
                    OutlinedButton(
                      onPressed: () => _loadCourses(forceRefresh: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9C88FF),
                        side: const BorderSide(color: Color(0xFF9C88FF)),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeDesktop
                              ? 32
                              : isDesktop
                              ? 28
                              : isTablet
                              ? 24
                              : isSmallScreen
                              ? 16
                              : 20,
                          vertical: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 14
                              : isTablet
                              ? 12
                              : isSmallScreen
                              ? 8
                              : 10,
                        ),
                      ),
                      child: Text(
                        'Reload',
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 18
                              : isDesktop
                              ? 16
                              : isTablet
                              ? 15
                              : isSmallScreen
                              ? 13
                              : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadCourses(forceRefresh: true),
              color: const Color(0xFF9C88FF),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 24
                      : isTablet
                      ? 20
                      : isSmallScreen
                      ? 12
                      : 16,
                  isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 12
                      : 16,
                  isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 24
                      : isTablet
                      ? 20
                      : isSmallScreen
                      ? 12
                      : 16,
                  isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 28
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 16
                      : 20,
                ),
                itemCount: _allItems.length,
                itemBuilder: (context, index) {
                  final item = _allItems[index];
                  final owned = item['owned'] == true;
                  final price = item['price'] is num ? item['price'] as num : 0;
                  final durationMinutes = item['durationMinutes'] is num
                      ? (item['durationMinutes'] as num).toInt()
                      : 0;
                  final videoDurationSeconds =
                      item['videoDurationSeconds'] is num
                      ? (item['videoDurationSeconds'] as num).toInt()
                      : 0;
                  final isExam = item['type'] == 'exam';
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 14
                          : isTablet
                          ? 12
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                    child: _CourseCard(
                      title: item['title'] ?? (isExam ? 'Exam' : 'Course'),
                      description: item['description'] ?? '',
                      durationMinutes: durationMinutes,
                      videoDurationSeconds: videoDurationSeconds,
                      priceText: '₹${price.toStringAsFixed(0)}',
                      owned: owned,
                      isExam: isExam,
                      onPay: (_loading || owned)
                          ? null
                          : () {
                              _courseIdController.text = item['id'] as String;
                              _notesController.text =
                                  item['title'] ??
                                  (isExam
                                      ? 'Exam Payment'
                                      : 'Course Enrollment');
                              _startPayment();
                            },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final int durationMinutes; // in minutes
  final int videoDurationSeconds; // in seconds
  final String priceText;
  final bool owned;
  final bool isExam;
  final VoidCallback? onPay;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.videoDurationSeconds,
    required this.priceText,
    required this.owned,
    this.isExam = false,
    required this.onPay,
  });

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0h 0m';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  // Responsive breakpoints helper
  bool _isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1440;
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024 &&
      MediaQuery.of(context).size.width < 1440;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    final isLargeDesktop = _isLargeDesktop(context);
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);
    final isSmallScreen = _isSmallScreen(context);

    return InkWell(
      onTap: owned ? null : onPay,
      borderRadius: BorderRadius.circular(
        isLargeDesktop
            ? 16
            : isDesktop
            ? 14
            : isTablet
            ? 12
            : isSmallScreen
            ? 10
            : 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          border: Border.all(
            color: owned ? const Color(0xFF4CAF50) : const Color(0xFFE5E7EB),
            width: owned
                ? (isLargeDesktop || isDesktop
                      ? 2.5
                      : isTablet
                      ? 2
                      : isSmallScreen
                      ? 1.5
                      : 2)
                : (isLargeDesktop || isDesktop
                      ? 1.5
                      : isTablet
                      ? 1.2
                      : isSmallScreen
                      ? 0.8
                      : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: owned
                  ? const Color(0xFF4CAF50).withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 8
                  : isSmallScreen
                  ? 4
                  : 6,
              offset: Offset(
                0,
                isLargeDesktop
                    ? 4
                    : isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : isSmallScreen
                    ? 1
                    : 2,
              ),
            ),
          ],
        ),
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isExam)
                        Container(
                          margin: EdgeInsets.only(
                            right: isLargeDesktop
                                ? 10
                                : isDesktop
                                ? 8
                                : isTablet
                                ? 7
                                : isSmallScreen
                                ? 5
                                : 6,
                          ),
                          padding: EdgeInsets.all(
                            isLargeDesktop
                                ? 6
                                : isDesktop
                                ? 5
                                : isTablet
                                ? 4.5
                                : isSmallScreen
                                ? 3.5
                                : 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C88FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 8
                                  : isDesktop
                                  ? 7
                                  : isTablet
                                  ? 6
                                  : isSmallScreen
                                  ? 5
                                  : 6,
                            ),
                          ),
                          child: Icon(
                            Icons.quiz,
                            color: const Color(0xFF9C88FF),
                            size: isLargeDesktop
                                ? 18
                                : isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : isSmallScreen
                                ? 12
                                : 14,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isLargeDesktop
                                ? 18
                                : isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : isSmallScreen
                                ? 12
                                : 14,
                            color: const Color(0xFF1F2937),
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                // Price and Status Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceText,
                      style: TextStyle(
                        color: const Color(0xFF1F2937),
                        fontSize: isLargeDesktop
                            ? 18
                            : isDesktop
                            ? 17
                            : isTablet
                            ? 16
                            : isSmallScreen
                            ? 13
                            : 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(
                      height: isLargeDesktop
                          ? 6
                          : isDesktop
                          ? 5
                          : isTablet
                          ? 4
                          : isSmallScreen
                          ? 3
                          : 4,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (owned) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFF4CAF50),
                            size: isLargeDesktop
                                ? 18
                                : isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : isSmallScreen
                                ? 12
                                : 14,
                          ),
                          SizedBox(
                            width: isLargeDesktop
                                ? 6
                                : isDesktop
                                ? 5
                                : isTablet
                                ? 4
                                : isSmallScreen
                                ? 3
                                : 4,
                          ),
                        ],
                        Text(
                          owned ? 'Purchased' : 'Available',
                          style: TextStyle(
                            color: owned
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2196F3),
                            fontSize: isLargeDesktop
                                ? 13
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 9
                                : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Description
            if (description.isNotEmpty) ...[
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                description,
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: isLargeDesktop
                      ? 15
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 11
                      : 12,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(
              height: isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 10
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            // Duration Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isLargeDesktop
                        ? 6
                        : isDesktop
                        ? 5
                        : isTablet
                        ? 4.5
                        : isSmallScreen
                        ? 3.5
                        : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 8
                          : isDesktop
                          ? 7
                          : isTablet
                          ? 6
                          : isSmallScreen
                          ? 5
                          : 6,
                    ),
                  ),
                  child: Icon(
                    isExam ? Icons.access_time : Icons.calendar_today_outlined,
                    color: const Color(0xFF6B7280),
                    size: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 11
                        : 12,
                  ),
                ),
                SizedBox(
                  width: isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 8
                      : isTablet
                      ? 7
                      : isSmallScreen
                      ? 5
                      : 6,
                ),
                Text(
                  isExam
                      ? '${durationMinutes} min'
                      : _formatDuration(durationMinutes),
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
