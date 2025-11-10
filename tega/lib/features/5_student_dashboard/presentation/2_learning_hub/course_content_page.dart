import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/5_student_dashboard/data/payment_service.dart';
import 'package:tega/core/config/env_config.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';

class CourseContentPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseContentPage({super.key, required this.course});

  @override
  State<CourseContentPage> createState() => _CourseContentPageState();
}

class _CourseContentPageState extends State<CourseContentPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _lectures = [];
  int _currentLectureIndex = 0;
  bool _isEnrolled = false;

  // Video controls state
  bool _showControls = true;
  bool _isFullscreen = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Module expansion state
  Map<String, bool> _expandedModules = {};

  // Performance optimization
  bool _isVideoLoading = false;

  // Payment service
  final PaymentService _paymentService = PaymentService();
  bool _isPaymentLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
    _initializeRazorpay();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _paymentService.dispose();
    // Reset system UI when leaving the page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _loadCourseContent() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final courseId = widget.course['id'];
      if (courseId == null || courseId.toString().isEmpty) {
        throw Exception('Invalid course ID');
      }

      final authService = AuthService();
      final headers = await authService.getAuthHeaders();

      final apiUrl = ApiEndpoints.realTimeCourseContent(courseId);

      // Get course content from backend with timeout
      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['course'] != null) {
          final courseData = data['course'];
          _isEnrolled = data['isEnrolled'] ?? false;

          // Extract lectures from modules
          final modules = courseData['modules'] as List<dynamic>? ?? [];
          _lectures = [];

          for (final module in modules) {
            final moduleLectures = module['lectures'] as List<dynamic>? ?? [];

            for (final lecture in moduleLectures) {
              bool isPreview = lecture['isPreview'] ?? false;
              final isRestricted = lecture['isRestricted'] ?? false;

              // Extract video key for signed URL generation
              String videoKey = '';
              if (_isEnrolled || isPreview) {
                videoKey = lecture['videoContent']?['r2Key'] ?? '';
              }

              // Best-effort duration extraction
              final dynamic durationSecondsRaw =
                  lecture['videoContent']?['durationSeconds'] ??
                  lecture['durationSeconds'] ??
                  ((lecture['videoContent']?['durationMs'] ??
                              lecture['durationMs'])
                          is int
                      ? ((lecture['videoContent']?['durationMs'] ??
                                    lecture['durationMs']) /
                                1000)
                            .round()
                      : null);

              final dynamic durationValue =
                  durationSecondsRaw ?? lecture['duration'] ?? '0:00';

              final lectureData = {
                'id': lecture['_id'] ?? lecture['id'] ?? '',
                'title': lecture['title'] ?? 'Untitled Lecture',
                'description': lecture['description'] ?? '',
                'duration': durationValue,
                'videoKey': videoKey, // Store video key instead of direct URL
                'videoUrl': '', // Will be populated when we get signed URL
                'isPreview': isPreview,
                'isRestricted': isRestricted,
                'isLocked':
                    !_isEnrolled &&
                    !isPreview, // Lock if not enrolled and not preview
                'moduleTitle': module['title'] ?? 'Module',
                'order': lecture['order'] ?? 0,
              };
              _lectures.add(lectureData);
            }
          }

          // Sort lectures by order
          _lectures.sort(
            (a, b) => (a['order'] as int).compareTo(b['order'] as int),
          );

          // Ensure only Introduction is marked as preview
          if (_lectures.isNotEmpty) {
            // Find an introduction lecture by title; fallback to the very first lecture
            int introIndex = _lectures.indexWhere(
              (l) => (l['title'] as String).toLowerCase().contains('intro'),
            );
            if (introIndex < 0) introIndex = 0;
            for (int i = 0; i < _lectures.length; i++) {
              final bool isIntro = i == introIndex;
              _lectures[i]['isPreview'] = isIntro;
              _lectures[i]['isLocked'] = !_isEnrolled && !isIntro;
            }
          }

          // Initialize module expansion state (all expanded by default)
          _expandedModules.clear();
          for (final module in modules) {
            final moduleTitle = module['title'] ?? 'Module';
            _expandedModules[moduleTitle] = true;
          }

          if (_lectures.isNotEmpty) {
            // Find the first available (unlocked) lecture
            int firstAvailableIndex = -1;
            for (int i = 0; i < _lectures.length; i++) {
              if (!_lectures[i]['isLocked']) {
                firstAvailableIndex = i;
                break;
              }
            }

            if (firstAvailableIndex >= 0) {
              await _initializeVideo(firstAvailableIndex);
            } else {
              // All lectures are locked, show the first one as locked
              setState(() {
                _currentLectureIndex = 0;
                _isVideoInitialized = false;
              });
            }
          } else {
            // No lectures available - set state to show empty state
            setState(() {
              _currentLectureIndex = 0;
              _isVideoInitialized = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load course content');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You may not have permission to view this course.',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          'Course not found. It may have been removed or is not available.',
        );
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else if (response.statusCode == 0) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ??
                'Failed to load course content (${response.statusCode})',
          );
        } catch (e) {
          throw Exception(
            'Failed to load course content (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getSignedVideoUrl(String courseId, String lectureId) async {
    try {
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();

      final apiUrl = ApiEndpoints.videoDeliverySignedUrl(courseId, lectureId);

      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Video URL request timeout. Please try again.');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['signedUrl'] != null) {
          return data['signedUrl'] as String;
        } else {
          throw Exception(data['message'] ?? 'Failed to get signed URL');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for video access.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You may not have permission to view this video.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Video not found. It may have been removed.');
      } else if (response.statusCode >= 500) {
        throw Exception(
          'Server error while getting video URL. Please try again.',
        );
      } else {
        throw Exception('Failed to get signed URL (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (index >= _lectures.length) return;

    setState(() {
      _isVideoLoading = true;
      _errorMessage = null;
    });

    final lecture = _lectures[index];
    final videoKey = lecture['videoKey'] as String;

    if (videoKey.isEmpty) {
      setState(() {
        _errorMessage = 'No video available for this lecture';
        _isVideoInitialized = false;
        _isVideoLoading = false;
      });
      return;
    }

    // Get signed URL for the video
    String videoUrl;
    try {
      videoUrl = await _getSignedVideoUrl(widget.course['id'], lecture['id']);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get video access: $e';
        _isVideoInitialized = false;
        _isVideoLoading = false;
      });
      return;
    }

    try {
      // Validate URL format
      final uri = Uri.tryParse(videoUrl);
      if (uri == null || !uri.hasAbsolutePath) {
        throw Exception('Invalid video URL format');
      }

      // Dispose previous controller
      await _videoController?.dispose();

      // Create new controller
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      // Add listeners
      _videoController!.addListener(_videoListener);

      await _videoController!.initialize();

      // Set initial duration
      if (_videoController!.value.isInitialized) {
        _totalDuration = _videoController!.value.duration;
      }

      setState(() {
        _isVideoInitialized = true;
        _currentLectureIndex = index;
        _errorMessage = null;
        _isVideoLoading = false;
      });

      // Auto-play the first video
      if (index == 0) {
        _videoController!.play();
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to load video. The video file may be unavailable or corrupted.';
        _isVideoInitialized = false;
        _isVideoLoading = false;
      });
    }
  }

  void _videoListener() {
    if (_videoController!.value.hasError) {
      _handleVideoError();
    } else {
      setState(() {
        _currentPosition = _videoController!.value.position;
        _totalDuration = _videoController!.value.duration;
      });
    }
  }

  void _handleVideoError() {
    setState(() {
      _errorMessage =
          'Video file not found. The video may have been moved or is temporarily unavailable.';
      _isVideoInitialized = false;
    });
  }

  // Video control methods
  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _seekTo(Duration position) {
    _videoController!.seekTo(position);
  }

  void _skipForward() {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition <= _totalDuration) {
      _seekTo(newPosition);
    }
  }

  void _skipBackward() {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      _seekTo(newPosition);
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      // Hide system UI and go landscape
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Show system UI and go portrait
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _hideControls() {
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
    }
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });

    // Hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _videoController!.value.isPlaying) {
        _hideControls();
      }
    });
  }

  void _skipToNextAvailableVideo() {
    // Find the next available (unlocked) lecture
    for (int i = _currentLectureIndex + 1; i < _lectures.length; i++) {
      if (!_lectures[i]['isLocked']) {
        _initializeVideo(i);
        return;
      }
    }

    // If no more available lectures, show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No more available lectures in this course'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _selectLecture(int index) {
    if (index != _currentLectureIndex) {
      final lecture = _lectures[index];

      if (lecture['isLocked']) {
        // Show enrollment prompt for locked lectures
        _showEnrollmentPrompt();
        return;
      }

      _initializeVideo(index);
    }
  }

  void _initializeRazorpay() {
    _paymentService.initializeRazorpay(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Verify payment with backend
      final result = await _paymentService.verifyPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment successful! You now have access to the course.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Reload course content to reflect enrollment
          _loadCourseContent();
        }
      } else {
        throw Exception(result['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isPaymentLoading = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isPaymentLoading = false;
    });

    try {
      final int code = (response.code is int) ? response.code as int : -1;
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

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isPaymentLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startPayment() async {
    try {
      setState(() {
        _isPaymentLoading = true;
      });

      // Create Razorpay order
      final orderResult = await _paymentService.createOrder(
        courseId: widget.course['_id'] ?? widget.course['id'] ?? '',
      );

      if (orderResult['success'] == true) {
        // Get user details for prefill
        final authService = AuthService();
        final user = authService.currentUser;

        // Open Razorpay payment
        // Backend returns amount in paise, so use it directly
        final amountPaise = orderResult['amount'] is int
            ? orderResult['amount'] as int
            : ((orderResult['chargedAmount'] ?? 0) is num
                  ? ((orderResult['chargedAmount'] as num) * 100).round()
                  : 0);

        _paymentService.openPayment(
          orderId: orderResult['orderId'],
          keyId: EnvConfig
              .razorpayKeyId, // Backend doesn't return keyId, use env config
          name: 'TEGA Learning Platform',
          description:
              'Course Enrollment - ${widget.course['title'] ?? 'Course'}',
          amount: amountPaise,
          currency: orderResult['currency'] ?? 'INR',
          prefillEmail: user?.email ?? '',
          prefillContact: user?.phone ?? '',
          notes: {
            'courseId': widget.course['_id'] ?? widget.course['id'] ?? '',
            'courseName': widget.course['title'] ?? 'Course',
          },
        );
      } else {
        throw Exception(
          orderResult['message'] ?? 'Failed to create payment order',
        );
      }
    } catch (e) {
      setState(() {
        _isPaymentLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEnrollmentPrompt() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6B5FFF),
                        const Color(0xFF6B5FFF).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Premium icon with glow effect
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Premium Content',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock your learning potential',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Course info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B5FFF).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6B5FFF).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: Color(0xFF6B5FFF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.course['title'] ?? 'Course',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Premium Course',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF6B5FFF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Benefits list
                      Column(
                        children: [
                          _buildBenefitItem(
                            Icons.video_library_outlined,
                            'Access to all premium lectures',
                          ),
                          _buildBenefitItem(
                            Icons.workspace_premium_outlined,
                            'Course completion certificate',
                          ),
                          _buildBenefitItem(
                            Icons.support_agent_outlined,
                            '24/7 learning support',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Title and description
                      const Text(
                        'This lecture is locked',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buy the course to unlock all premium videos or go back.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Action button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B5FFF).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              if (_isEnrolled) {
                                // Jump to first available lecture
                                int targetIndex = 0;
                                for (int i = 0; i < _lectures.length; i++) {
                                  if (!_lectures[i]['isLocked']) {
                                    targetIndex = i;
                                    break;
                                  }
                                }
                                _initializeVideo(targetIndex);
                              } else {
                                _startPayment();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: _isPaymentLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Processing...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isEnrolled
                                              ? 'Continue Learning'
                                              : 'Buy Course',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6B5FFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: const Color(0xFF6B5FFF),
                          ),
                          child: const Text(
                            'Go Back',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6B5FFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleModuleExpansion(String moduleTitle) {
    setState(() {
      _expandedModules[moduleTitle] = !(_expandedModules[moduleTitle] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isFullscreen) {
      // Fullscreen mode - only show video player
      return _buildVideoPlayer();
    }

    // If no lectures available, show empty state
    if (_lectures.isEmpty) {
      return _buildNoVideosState();
    }

    return Column(
      children: [
        // Fixed Header
        _buildHeader(),
        // Fixed Video Player
        _buildVideoPlayer(),
        // Scrollable Course Content
        Expanded(child: _buildScrollableContent()),
      ],
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        top: MediaQuery.of(context).padding.top + (isTablet ? 16 : 12),
        bottom: isTablet ? 16 : 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
            padding: EdgeInsets.all(isTablet ? 8 : 4),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course['title'] ?? 'Course',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: isTablet ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_lectures.isNotEmpty)
                  Text(
                    _lectures[_currentLectureIndex]['title'],
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey,
                    ),
                    maxLines: isTablet ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!_isEnrolled)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              ),
              child: Text(
                'Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: _isFullscreen
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 12 : 8,
            ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: _isFullscreen
            ? BorderRadius.zero
            : BorderRadius.circular(isTablet ? 12 : 8),
        boxShadow: _isFullscreen
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: isTablet ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: _isFullscreen
            ? BorderRadius.zero
            : BorderRadius.circular(isTablet ? 12 : 8),
        child:
            _lectures.isNotEmpty && _lectures[_currentLectureIndex]['isLocked']
            ? Container(
                height: _isFullscreen
                    ? double.infinity
                    : isTablet
                    ? 300
                    : 200,
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Premium Content',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enroll to access this lecture',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showEnrollmentPrompt,
                        icon: const Icon(Icons.lock_open, size: 16),
                        label: const Text('Enroll to Unlock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B5FFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _errorMessage != null
            ? Container(
                height: isTablet ? 300 : 200,
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Video Error',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                              if (_lectures.isNotEmpty) {
                                _initializeVideo(_currentLectureIndex);
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5FFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _skipToNextAvailableVideo,
                            icon: const Icon(Icons.skip_next, size: 16),
                            label: const Text('Skip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : _isVideoLoading
            ? Container(
                height: _isFullscreen
                    ? double.infinity
                    : isTablet
                    ? 300
                    : 200,
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading video...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            : _isVideoInitialized && _videoController != null
            ? _buildAdvancedVideoPlayer()
            : Container(
                height: _isFullscreen
                    ? double.infinity
                    : isTablet
                    ? 300
                    : 200,
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Select a lecture to start watching',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAdvancedVideoPlayer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: () {
        _showControlsTemporarily();
      },
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapPosition = details.globalPosition.dx;

        if (tapPosition < screenWidth / 2) {
          // Double tap left side - rewind 10 seconds
          _skipBackward();
        } else {
          // Double tap right side - forward 10 seconds
          _skipForward();
        }
      },
      onPanUpdate: (details) {
        // Drag up gesture for fullscreen
        if (details.delta.dy < -10) {
          _toggleFullscreen();
        }
      },
      child: Container(
        height: _isFullscreen
            ? double.infinity
            : isTablet
            ? 300
            : 200,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: _isFullscreen ? 16 / 9 : 16 / 9,
                child: VideoPlayer(_videoController!),
              ),
            ),

            // Controls Overlay
            if (_showControls)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Center Play Button (only shows when paused)
                      if (!_videoController!.value.isPlaying)
                        Center(child: _buildCenterPlayButton()),
                      // YouTube-style Bottom Controls
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildYouTubeControls(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          _buildYouTubeProgressBar(),
          // Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Play/Pause Button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Rewind 10s
                GestureDetector(
                  onTap: _skipBackward,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Forward 10s
                GestureDetector(
                  onTap: _skipForward,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Time Display
                Text(
                  '${_formatTime(_currentPosition)} / ${_formatTime(_totalDuration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                // Fullscreen Button
                GestureDetector(
                  onTap: _toggleFullscreen,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildYouTubeProgressBar() {
    return GestureDetector(
      onTapDown: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final progress = localPosition.dx / renderBox.size.width;
        final newPosition = Duration(
          milliseconds: (_totalDuration.inMilliseconds * progress).round(),
        );
        _seekTo(newPosition);
      },
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          children: [
            // Background
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Progress
            Container(
              height: 4,
              width: _totalDuration.inMilliseconds > 0
                  ? (MediaQuery.of(context).size.width - 24) *
                        (_currentPosition.inMilliseconds /
                            _totalDuration.inMilliseconds)
                  : 0,
              decoration: BoxDecoration(
                color: Colors.red, // YouTube red color
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Thumb (only visible on hover/touch)
            Positioned(
              left: _totalDuration.inMilliseconds > 0
                  ? (MediaQuery.of(context).size.width - 24) *
                            (_currentPosition.inMilliseconds /
                                _totalDuration.inMilliseconds) -
                        6
                  : -6,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Widget _buildScrollableContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        16,
        isTablet ? 24 : 16,
        32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Content Sections
            _buildCourseContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContent() {
    if (_lectures.isEmpty) {
      return _buildNoVideosState();
    }

    // Group lectures by module
    final Map<String, List<Map<String, dynamic>>> groupedLectures = {};
    for (final lecture in _lectures) {
      final moduleTitle = lecture['moduleTitle'] as String;
      if (!groupedLectures.containsKey(moduleTitle)) {
        groupedLectures[moduleTitle] = [];
      }
      groupedLectures[moduleTitle]!.add(lecture);
    }

    return Column(
      children: groupedLectures.entries.map((entry) {
        final moduleTitle = entry.key;
        final moduleLectures = entry.value;

        return _buildModuleSection(moduleTitle, moduleLectures);
      }).toList(),
    );
  }

  Widget _buildModuleSection(
    String moduleTitle,
    List<Map<String, dynamic>> lectures,
  ) {
    final isExpanded = _expandedModules[moduleTitle] ?? true;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Module Header
          GestureDetector(
            onTap: () => _toggleModuleExpansion(moduleTitle),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.playlist_play,
                    color: const Color(0xFF6B5FFF),
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Expanded(
                    child: Text(
                      moduleTitle,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${lectures.length} lectures',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lectures List (only show if expanded)
          if (isExpanded)
            ...lectures.map((lecture) {
              final isSelected =
                  _lectures.indexOf(lecture) == _currentLectureIndex;
              final isPreview = lecture['isPreview'] as bool;
              final isLocked = lecture['isLocked'] as bool;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6B5FFF).withOpacity(0.05)
                      : Colors.transparent,
                  border: isSelected
                      ? const Border(
                          left: BorderSide(color: Color(0xFF6B5FFF), width: 3),
                        )
                      : null,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 12 : 8,
                  ),
                  leading: Container(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey[300]
                          : isSelected
                          ? const Color(0xFF6B5FFF)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                    ),
                    child: Icon(
                      isLocked
                          ? Icons.lock
                          : isSelected
                          ? Icons.play_arrow
                          : Icons.play_circle_outline,
                      color: isLocked
                          ? Colors.grey[600]
                          : isSelected
                          ? Colors.white
                          : Colors.grey[600],
                      size: isTablet ? 20 : 16,
                    ),
                  ),
                  title: Text(
                    lecture['title'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isLocked
                          ? Colors.grey[500]
                          : isSelected
                          ? const Color(0xFF6B5FFF)
                          : Colors.black87,
                      fontSize: isTablet ? 16 : 14,
                    ),
                    maxLines: isTablet ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isTablet ? 14 : 12,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: isTablet ? 6 : 4),
                      Text(
                        _formatDuration(lecture['duration']),
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (isPreview) ...[
                        SizedBox(width: isTablet ? 10 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 8 : 6,
                            vertical: isTablet ? 3 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(
                              isTablet ? 8 : 6,
                            ),
                          ),
                          child: Text(
                            'Preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (isLocked) ...[
                        SizedBox(width: isTablet ? 10 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 8 : 6,
                            vertical: isTablet ? 3 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(
                              isTablet ? 8 : 6,
                            ),
                          ),
                          child: Text(
                            'Locked',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => _selectLecture(_lectures.indexOf(lecture)),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    // Handle both String and double duration formats
    if (duration is String) {
      return duration; // Already formatted as string
    } else if (duration is double) {
      // Convert seconds to MM:SS format
      final minutes = (duration / 60).floor();
      final seconds = (duration % 60).round();
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (duration is int) {
      // Convert seconds to MM:SS format
      final minutes = (duration / 60).floor();
      final seconds = duration % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:00'; // Default fallback
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Course Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourseContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoVideosState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Empty State Content
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 48 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.video_library_outlined,
                        size: isTablet ? 80 : 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 24),

                    // Title
                    Text(
                      'No Videos Available',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 16 : 12),

                    // Description
                    Text(
                      'This course doesn\'t have any video content yet.\nThe instructor may be working on adding materials.',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 32 : 24),

                    // Action Buttons
                    Column(
                      children: [
                        // Go Back Button
                        SizedBox(
                          width: isTablet ? 200 : 160,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Go Back'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 16 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 12 : 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),

                        // Refresh Button
                        SizedBox(
                          width: isTablet ? 200 : 160,
                          child: OutlinedButton.icon(
                            onPressed: _loadCourseContent,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B5FFF),
                              side: const BorderSide(
                                color: Color(0xFF6B5FFF),
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 16 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 12 : 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 32 : 24),

                    // Additional Info
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[600],
                            size: isTablet ? 20 : 18,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Text(
                              'Check back later or contact support if you believe this is an error.',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
