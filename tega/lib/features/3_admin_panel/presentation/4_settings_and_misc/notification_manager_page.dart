import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/data/services/notification_service.dart';

// Compose Notification Page
class ComposeNotificationPage extends StatefulWidget {
  const ComposeNotificationPage({super.key});

  @override
  State<ComposeNotificationPage> createState() =>
      _ComposeNotificationPageState();
}

class _ComposeNotificationPageState extends State<ComposeNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedTemplate;
  String? _selectedAudience;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Helper method for consistent TextField styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile
                ? 14
                : isTablet
                ? 15
                : 16,
            fontWeight: FontWeight.w600,
            color: AdminDashboardStyles.textDark,
          ),
        ),
        SizedBox(
          height: isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: isMobile
                ? 14
                : isTablet
                ? 15
                : 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: isMobile
                  ? 13
                  : isTablet
                  ? 14
                  : 15,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              borderSide: const BorderSide(
                color: Color(0xFF4B3FB5),
                width: 2.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile
                  ? 14
                  : isTablet
                  ? 15
                  : 16,
              vertical: isMobile
                  ? 12
                  : isTablet
                  ? 13
                  : 14,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for consistent Dropdown styling
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile
                ? 14
                : isTablet
                ? 15
                : 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(
          height: isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        DropdownButtonFormField<String>(
          value: value,
          style: TextStyle(
            fontSize: isMobile
                ? 14
                : isTablet
                ? 15
                : 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: isMobile
                  ? 13
                  : isTablet
                  ? 14
                  : 15,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 10
                    : isTablet
                    ? 11
                    : 12,
              ),
              borderSide: const BorderSide(
                color: Color(0xFF4B3FB5),
                width: 2.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile
                  ? 14
                  : isTablet
                  ? 15
                  : 16,
              vertical: isMobile
                  ? 12
                  : isTablet
                  ? 13
                  : 14,
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 16
                    : isTablet
                    ? 18
                    : 20,
                vertical: isMobile
                    ? 12
                    : isTablet
                    ? 14
                    : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                      size: isMobile
                          ? 18
                          : isTablet
                          ? 20
                          : 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Compose Notification',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isMobile
                            ? 18
                            : isTablet
                            ? 19
                            : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 48 : 56,
                  ), // Balance the back button
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
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
                      // --- Refined Header Image ---
                      Container(
                        width: double.infinity,
                        height: isMobile
                            ? 150
                            : isTablet
                            ? 175
                            : 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6D8),
                          borderRadius: BorderRadius.circular(
                            isMobile
                                ? 16
                                : isTablet
                                ? 18
                                : 20,
                          ),
                        ),
                        child: Icon(
                          Icons.edit_notifications_outlined,
                          size: isMobile
                              ? 60
                              : isTablet
                              ? 70
                              : 80,
                          color: const Color(0xFFD4A574),
                        ),
                      ),
                      SizedBox(
                        height: isMobile
                            ? 24
                            : isTablet
                            ? 28
                            : 32,
                      ),

                      // --- Title and Description ---
                      Text(
                        'Create a New Message',
                        style: TextStyle(
                          fontSize: isMobile
                              ? 22
                              : isTablet
                              ? 24
                              : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        'Craft a new notification to keep your users informed and engaged.',
                        style: TextStyle(
                          fontSize: isMobile
                              ? 14
                              : isTablet
                              ? 15
                              : 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(
                        height: isMobile
                            ? 24
                            : isTablet
                            ? 28
                            : 32,
                      ),

                      // --- Use a Template Section ---
                      _buildDropdownField(
                        label: 'Use a Template (Optional)',
                        hint: 'Select a template',
                        value: _selectedTemplate,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                        items: [
                          DropdownMenuItem(
                            value: 'template1',
                            child: Text(
                              'Welcome Template',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'template2',
                            child: Text(
                              'Update Template',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'template3',
                            child: Text(
                              'Promotion Template',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTemplate = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: isMobile
                            ? 20
                            : isTablet
                            ? 22
                            : 24,
                      ),

                      // --- Notification Title ---
                      _buildTextField(
                        controller: _titleController,
                        label: 'Notification Title',
                        hint: 'Enter notification title',
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      SizedBox(
                        height: isMobile
                            ? 20
                            : isTablet
                            ? 22
                            : 24,
                      ),

                      // --- Message ---
                      _buildTextField(
                        controller: _messageController,
                        label: 'Message',
                        hint: 'Enter your message here...',
                        maxLines: 5,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      SizedBox(
                        height: isMobile
                            ? 20
                            : isTablet
                            ? 22
                            : 24,
                      ),

                      // --- Target Audience ---
                      _buildDropdownField(
                        label: 'Target Audience',
                        hint: 'Select an audience',
                        value: _selectedAudience,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              'All Users',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'specific',
                            child: Text(
                              'Specific Group',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'premium',
                            child: Text(
                              'Premium Users',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'new',
                            child: Text(
                              'New Users',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 13
                                    : isTablet
                                    ? 14
                                    : 16,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAudience = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: isMobile
                            ? 32
                            : isTablet
                            ? 36
                            : 40,
                      ),

                      // --- Action Buttons ---
                      isMobile
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _sendNotification,
                                    icon: Icon(
                                      Icons.send_rounded,
                                      size: isMobile
                                          ? 18
                                          : isTablet
                                          ? 19
                                          : 20,
                                    ),
                                    label: Text(
                                      'Send',
                                      style: TextStyle(
                                        fontSize: isMobile
                                            ? 14
                                            : isTablet
                                            ? 15
                                            : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B3FB5),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isMobile
                                            ? 14
                                            : isTablet
                                            ? 15
                                            : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile
                                              ? 10
                                              : isTablet
                                              ? 11
                                              : 12,
                                        ),
                                      ),
                                      elevation: 2,
                                      shadowColor: const Color(
                                        0xFF4B3FB5,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _saveDraft,
                                    icon: Icon(
                                      Icons.drafts_outlined,
                                      size: isMobile
                                          ? 18
                                          : isTablet
                                          ? 19
                                          : 20,
                                    ),
                                    label: Text(
                                      'Save Draft',
                                      style: TextStyle(
                                        fontSize: isMobile
                                            ? 14
                                            : isTablet
                                            ? 15
                                            : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isMobile
                                            ? 14
                                            : isTablet
                                            ? 15
                                            : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile
                                              ? 10
                                              : isTablet
                                              ? 11
                                              : 12,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _saveDraft,
                                    icon: Icon(
                                      Icons.drafts_outlined,
                                      size: isTablet ? 18 : 20,
                                    ),
                                    label: Text(
                                      'Save Draft',
                                      style: TextStyle(
                                        fontSize: isTablet ? 15 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 15 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          isTablet ? 11 : 12,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 12 : 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _sendNotification,
                                    icon: Icon(
                                      Icons.send_rounded,
                                      size: isTablet ? 18 : 20,
                                    ),
                                    label: Text(
                                      'Send',
                                      style: TextStyle(
                                        fontSize: isTablet ? 15 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B3FB5),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 15 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          isTablet ? 11 : 12,
                                        ),
                                      ),
                                      elevation: 2,
                                      shadowColor: const Color(
                                        0xFF4B3FB5,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification saved as draft'),
        backgroundColor: Color(0xFFFFC107),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendNotification() {
    if (_titleController.text.isEmpty ||
        _messageController.text.isEmpty ||
        _selectedAudience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification sent successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }
}

// Notification Manager Page
class NotificationManagerPage extends StatefulWidget {
  const NotificationManagerPage({super.key});

  @override
  State<NotificationManagerPage> createState() =>
      _NotificationManagerPageState();
}

class _NotificationManagerPageState extends State<NotificationManagerPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _cardAnimations;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  final NotificationService _notificationService = NotificationService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

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
    await _loadNotifications();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);

      final cachedNotifications = await _cacheService.getNotificationsData();

      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        setState(() {
          _notifications = cachedNotifications;
          _isLoadingFromCache = false;
        });
        _initializeAnimations();
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

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _notifications.isNotEmpty) {
      _loadNotificationsInBackground();
      return;
    }

    if (!_isLoadingFromCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final notifications = await _notificationService.getAdminNotifications();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _isLoadingFromCache = false;
        _errorMessage = null; // Clear error on success
      });

      _initializeAnimations();

      // Cache the data
      await _cacheService.setNotificationsData(notifications);
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedNotifications = await _cacheService.getNotificationsData();
        if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
          // Load from cache and show toast
          setState(() {
            _notifications = cachedNotifications;
            _isLoading = false;
            _isLoadingFromCache = false;
            _errorMessage = null; // Clear error since we have cached data
          });
          _initializeAnimations();
          return;
        }

        // No cache available, show error
        setState(() {
          _errorMessage = 'No internet connection';
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      } else {
        // Other errors
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      }
    }
  }

  Future<void> _loadNotificationsInBackground() async {
    try {
      final notifications = await _notificationService.getAdminNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
        _initializeAnimations();

        // Cache the data
        await _cacheService.setNotificationsData(notifications);
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Initialize card animations
    _cardAnimations = List.generate(
      _notifications.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _cardScaleAnimations = _cardAnimations
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
        .toList();

    _cardSlideAnimations = _cardAnimations
        .map(
          (controller) =>
              Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              ),
        )
        .toList();

    _animationController.forward();
    _startCardAnimations();
  }

  void _startCardAnimations() {
    for (int i = 0; i < _cardAnimations.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _cardAnimations[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _cardAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    final unreadNotifications = _notifications
        .where((n) => n['isRead'] == false || n['isRead'] == null)
        .length;

    return Container(
      color: AdminDashboardStyles.background,
      child: _isLoading && !_isLoadingFromCache
          ? _buildLoadingState(isMobile, isTablet, isDesktop)
          : _errorMessage != null && !_isLoadingFromCache
          ? _buildErrorState(isMobile, isTablet, isDesktop)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header Section with Unread count and Mark all as read
                    Container(
                      margin: EdgeInsets.all(
                        isMobile
                            ? 16
                            : isTablet
                            ? 18
                            : 20,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile
                            ? 16
                            : isTablet
                            ? 18
                            : 20,
                        vertical: isMobile
                            ? 12
                            : isTablet
                            ? 14
                            : 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          isMobile
                              ? 14
                              : isTablet
                              ? 15
                              : 16,
                        ),
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
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  isMobile
                                      ? 8
                                      : isTablet
                                      ? 9
                                      : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminDashboardStyles.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    isMobile
                                        ? 8
                                        : isTablet
                                        ? 9
                                        : 10,
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_active,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unread Notifications',
                                    style: TextStyle(
                                      fontSize: isMobile
                                          ? 12
                                          : isTablet
                                          ? 13
                                          : 14,
                                      color: AdminDashboardStyles.textLight,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 2 : 2),
                                  Text(
                                    '$unreadNotifications',
                                    style: TextStyle(
                                      fontSize: isMobile
                                          ? 18
                                          : isTablet
                                          ? 19
                                          : 20,
                                      fontWeight: FontWeight.bold,
                                      color: AdminDashboardStyles.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (unreadNotifications > 0) ...[
                            SizedBox(
                              height: isMobile
                                  ? 12
                                  : isTablet
                                  ? 14
                                  : 16,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _markAllAsRead,
                                icon: Icon(
                                  Icons.done_all,
                                  size: isMobile
                                      ? 16
                                      : isTablet
                                      ? 17
                                      : 18,
                                ),
                                label: Text(
                                  'Mark all as read',
                                  style: TextStyle(
                                    fontSize: isMobile
                                        ? 13
                                        : isTablet
                                        ? 14
                                        : 15,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AdminDashboardStyles.primary,
                                  backgroundColor: AdminDashboardStyles.primary
                                      .withOpacity(0.1),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile
                                        ? 14
                                        : isTablet
                                        ? 15
                                        : 16,
                                    vertical: isMobile
                                        ? 10
                                        : isTablet
                                        ? 11
                                        : 12,
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
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Notifications List
                    Expanded(
                      child: _notifications.isEmpty
                          ? _buildEmptyState(isMobile, isTablet, isDesktop)
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile
                                    ? 16
                                    : isTablet
                                    ? 18
                                    : 20,
                              ),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return AnimatedBuilder(
                                  animation: _cardAnimations[index],
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _cardScaleAnimations[index].value,
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[index],
                                        child: _buildNotificationCard(
                                          notification,
                                          index,
                                          isMobile,
                                          isTablet,
                                          isDesktop,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState(bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AdminDashboardStyles.primary,
            ),
          ),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: AdminDashboardStyles.textLight,
              fontSize: isMobile
                  ? 14
                  : isTablet
                  ? 15
                  : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile
              ? 20
              : isTablet
              ? 24
              : 28,
        ),
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
              'Failed to load notifications',
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
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: isMobile
                  ? 24
                  : isTablet
                  ? 28
                  : 32,
            ),
            ElevatedButton.icon(
              onPressed: () => _loadNotifications(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                size: isMobile
                    ? 16
                    : isTablet
                    ? 17
                    : 18,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile
                      ? 13
                      : isTablet
                      ? 14
                      : 15,
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
                      ? 13
                      : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 11
                        : 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile
              ? 16
              : isTablet
              ? 20
              : 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: isMobile
                  ? 48
                  : isTablet
                  ? 56
                  : 64,
              color: AdminDashboardStyles.textLight,
            ),
            SizedBox(
              height: isMobile
                  ? 12
                  : isTablet
                  ? 14
                  : 16,
            ),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 19
                    : 20,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textDark,
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 8
                  : isTablet
                  ? 10
                  : 12,
            ),
            Text(
              'You haven\'t sent any notifications yet',
              style: TextStyle(
                color: AdminDashboardStyles.textLight,
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();

      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
      });

      // Update cache
      await _cacheService.setNotificationsData(_notifications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to mark notifications as read: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    int index,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.surface,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 14
              : isTablet
              ? 15
              : 16,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(context, notification['title']),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 14
              : isTablet
              ? 15
              : 16,
        ),
        child: Padding(
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
                      color: _getTypeColor(
                        notification['type']?.toString() ?? 'info',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        isMobile
                            ? 10
                            : isTablet
                            ? 11
                            : 12,
                      ),
                    ),
                    child: Icon(
                      _getNotificationIcon(
                        notification['type']?.toString() ?? 'info',
                      ),
                      color: _getTypeColor(
                        notification['type']?.toString() ?? 'info',
                      ),
                      size: isMobile
                          ? 20
                          : isTablet
                          ? 22
                          : 24,
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? 12
                        : isTablet
                        ? 14
                        : 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title']?.toString() ?? 'Notification',
                          style: TextStyle(
                            fontSize: isMobile
                                ? 15
                                : isTablet
                                ? 15.5
                                : 16,
                            fontWeight: FontWeight.bold,
                            color: AdminDashboardStyles.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                        Text(
                          notification['message']?.toString() ?? 'No message',
                          style: TextStyle(
                            fontSize: isMobile
                                ? 13
                                : isTablet
                                ? 13.5
                                : 14,
                            color: AdminDashboardStyles.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                          ? 3.5
                          : 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        notification['status']?.toString() ?? 'sent',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        isMobile
                            ? 10
                            : isTablet
                            ? 11
                            : 12,
                      ),
                    ),
                    child: Text(
                      (notification['status']?.toString() ?? 'sent')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: isMobile
                            ? 9
                            : isTablet
                            ? 9.5
                            : 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(
                          notification['status']?.toString() ?? 'sent',
                        ),
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
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: isMobile
                        ? 14
                        : isTablet
                        ? 15
                        : 16,
                    color: AdminDashboardStyles.textLight,
                  ),
                  SizedBox(width: isMobile ? 3 : 4),
                  Expanded(
                    child: Text(
                      notification['recipientModel']?.toString() ?? 'All',
                      style: TextStyle(
                        fontSize: isMobile
                            ? 11
                            : isTablet
                            ? 11.5
                            : 12,
                        color: AdminDashboardStyles.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.schedule,
                    size: isMobile
                        ? 14
                        : isTablet
                        ? 15
                        : 16,
                    color: AdminDashboardStyles.textLight,
                  ),
                  SizedBox(width: isMobile ? 3 : 4),
                  Text(
                    _formatDate(notification['createdAt']?.toString()),
                    style: TextStyle(
                      fontSize: isMobile
                          ? 11
                          : isTablet
                          ? 11.5
                          : 12,
                      color: AdminDashboardStyles.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'welcome':
        return AppColors.success;
      case 'update':
        return AppColors.info;
      case 'promotion':
        return AppColors.warning;
      case 'course':
        return AdminDashboardStyles.primary;
      default:
        return AdminDashboardStyles.textLight;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AdminDashboardStyles.textLight;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'welcome':
        return Icons.campaign_rounded;
      case 'update':
        return Icons.system_update_alt_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'course':
        return Icons.school_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'info':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _handleNotificationTap(BuildContext context, String notificationId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped on $notificationId'),
        backgroundColor: AdminDashboardStyles.primary,
      ),
    );
  }
}

// --- Beautified Notification Card Widget ---
class NotificationCard extends StatelessWidget {
  final IconData iconData; // Changed from imageUrl to IconData
  final String title;
  final String audience;
  final String sentDate;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.iconData,
    required this.title,
    required this.audience,
    required this.sentDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Using Card for better elevation and semantics
      color: const Color(0xFF4B3FB5),
      elevation: 4,
      shadowColor: const Color(0xFF4B3FB5).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        // Using InkWell for material tap feedback
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image container with gradient and icon ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFFF5E6D8),
                child: Center(
                  child: Icon(
                    iconData,
                    size: 70,
                    color: const Color(0xFFB8A090),
                  ),
                ),
              ),
            ),
            // --- Text content ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 20,
                      fontWeight: FontWeight.bold, // Bolder title
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        audience,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sentDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
