import 'package:flutter/material.dart';
import 'package:tega/features/5_student_dashboard/data/payment_service.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/config/env_config.dart';

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
  bool _loading = false; // used for manual payment fallback button
  bool _loadingCourses = true;
  List<Map<String, dynamic>> _courses = [];
  Set<String> _ownedCourseIds = {};

  @override
  void initState() {
    super.initState();
    _paymentService.initializeRazorpay(
      onSuccess: _onSuccess,
      onError: _onError,
      onExternalWallet: (_) {},
    );
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

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final headers = await AuthService().getAuthHeaders();
      final service = StudentDashboardService();
      final all = await service.getAllCourses(headers);
      final enrolled = await service.getEnrolledCourses(headers);
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
    } catch (_) {
      _courses = [];
      _ownedCourseIds = {};
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9C88FF)),
            )
          : _courses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No courses available',
                    style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _loadCourses,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9C88FF),
                      side: const BorderSide(color: Color(0xFF9C88FF)),
                    ),
                    child: const Text('Reload'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final c = _courses[index];
                final owned = c['owned'] == true;
                final price = c['price'] is num ? c['price'] as num : 0;
                final durationMinutes = c['durationMinutes'] is num
                    ? (c['durationMinutes'] as num).toInt()
                    : 0;
                final videoDurationSeconds = c['videoDurationSeconds'] is num
                    ? (c['videoDurationSeconds'] as num).toInt()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CourseCard(
                    title: c['title'] ?? 'Course',
                    description: c['description'] ?? '',
                    durationMinutes: durationMinutes,
                    videoDurationSeconds: videoDurationSeconds,
                    priceText: '₹${price.toStringAsFixed(0)}',
                    owned: owned,
                    onPay: (_loading || owned)
                        ? null
                        : () {
                            _courseIdController.text = c['id'] as String;
                            _notesController.text =
                                c['title'] ?? 'Course Enrollment';
                            _startPayment();
                          },
                  ),
                );
              },
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
  final VoidCallback? onPay;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.videoDurationSeconds,
    required this.priceText,
    required this.owned,
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: owned ? null : onPay,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: owned ? const Color(0xFF4CAF50) : const Color(0xFFE5E7EB),
            width: owned ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: owned
                  ? const Color(0xFF4CAF50).withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // Price and Status Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceText,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (owned) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF4CAF50),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          owned ? 'Purchased' : 'Available',
                          style: TextStyle(
                            color: owned
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2196F3),
                            fontSize: 11,
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
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            // Duration Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF6B7280),
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(durationMinutes),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
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
