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
      final bool isCancelled = code == 2 || msg.toLowerCase().contains('cancel');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCancelled ? 'Payment cancelled' : 'Payment failed: $msg'),
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

  String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

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
            final id = (e['_id'] ?? e['id'] ?? e['courseId'] ?? e['course']?['_id'] ?? e['course']?['id'] ?? '').toString();
            if (id.isNotEmpty) ownedIds.add(id);
            final t = (e['title'] ?? e['name'] ?? e['slug'] ?? e['key'] ?? e['code'] ?? e['course']?['title'] ?? e['course']?['name'] ?? e['course']?['slug'] ?? '').toString();
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
        final title = (c['title'] ?? c['name'] ?? c['courseTitle'] ?? c['slug'] ?? c['key'] ?? 'Course').toString();
        final price = (c['effectivePrice'] ?? c['offerPrice'] ?? c['price'] ?? 0);
        final owned = _ownedCourseIds.contains(id) || ownedKeys.contains(_norm(title));
        return {'id': id, 'title': title, 'price': price, 'owned': owned};
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
        final dynamic rawAmount = order['amount'] ?? order['chargedAmount'];
        final int amountPaise = rawAmount is int
            ? rawAmount
            : (rawAmount is num ? (rawAmount * 100).round() : 0);
        _paymentService.openPayment(
          orderId: order['orderId'],
          keyId: (order['keyId'] ?? EnvConfig.razorpayKeyId),
          name: 'TEGA Payment',
          description: _notesController.text.trim().isEmpty
              ? 'Course Enrollment'
              : _notesController.text.trim(),
          amount: amountPaise,
          currency: 'INR',
          prefillEmail: user?.email ?? '',
          prefillContact: user?.phone ?? '',
          notes: {
            'courseId': courseId,
          },
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
          .map((c) => (c['id'] == courseId || (key != null && _norm(c['title'] ?? '') == key))
              ? {...c, 'owned': true}
              : c)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: null,
      body: _loadingCourses
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B5FFF)))
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No courses available'),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: _loadCourses, child: const Text('Reload')),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final cross = width > 1200 ? 3 : width > 800 ? 2 : 1;
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cross,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.8,
                              ),
                              itemCount: _courses.length,
                              itemBuilder: (context, index) {
                                final c = _courses[index];
                                final owned = c['owned'] == true;
                                final price = c['price'] is num ? c['price'] as num : 0;
                                return _CourseCard(
                                  title: c['title'] ?? 'Course',
                                  priceText: '₹${price.toStringAsFixed(0)}',
                                  owned: owned,
                                  onPay: (_loading || owned)
                                      ? null
                                      : () {
                                          _courseIdController.text = c['id'] as String;
                                          _notesController.text = c['title'] ?? 'Course Enrollment';
                                          _startPayment();
                                        },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String priceText;
  final bool owned;
  final VoidCallback? onPay;
  const _CourseCard({required this.title, required this.priceText, required this.owned, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(priceText, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: owned ? Colors.grey[300] : const Color(0xFF1E63F8),
                foregroundColor: owned ? Colors.grey[700] : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(owned ? 'Owned' : 'Pay'),
            ),
          ),
        ],
      ),
    );
  }
}


