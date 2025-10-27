import 'package:flutter/material.dart';
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600, // Bolder label for better hierarchy
            color: AdminDashboardStyles.textDark,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50, // Subtle background color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Softer corners
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4B3FB5), // Primary theme color on focus
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4B3FB5),
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          initialValue: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compose Notification',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Refined Header Image ---
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.edit_notifications_outlined,
                  size: 80,
                  color: Color(0xFFD4A574),
                ),
              ),
              const SizedBox(height: 32),

              // --- Title and Description ---
              const Text(
                'Create a New Message',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Craft a new notification to keep your users informed and engaged.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),

              // --- Use a Template Section ---
              _buildDropdownField(
                label: 'Use a Template (Optional)',
                hint: 'Select a template',
                value: _selectedTemplate,
                items: const [
                  DropdownMenuItem(
                    value: 'template1',
                    child: Text('Welcome Template'),
                  ),
                  DropdownMenuItem(
                    value: 'template2',
                    child: Text('Update Template'),
                  ),
                  DropdownMenuItem(
                    value: 'template3',
                    child: Text('Promotion Template'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTemplate = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // --- Notification Title ---
              _buildTextField(
                controller: _titleController,
                label: 'Notification Title',
                hint: 'Enter notification title',
              ),
              const SizedBox(height: 24),

              // --- Message ---
              _buildTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Enter your message here...',
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // --- Target Audience ---
              _buildDropdownField(
                label: 'Target Audience',
                hint: 'Select an audience',
                value: _selectedAudience,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(
                    value: 'specific',
                    child: Text('Specific Group'),
                  ),
                  DropdownMenuItem(
                    value: 'premium',
                    child: Text('Premium Users'),
                  ),
                  DropdownMenuItem(value: 'new', child: Text('New Users')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAudience = value;
                  });
                },
              ),
              const SizedBox(height: 40),

              // --- Action Buttons ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.drafts_outlined), // Added icon
                      label: const Text('Save Draft'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendNotification,
                      icon: const Icon(Icons.send_rounded), // Added icon
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B3FB5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2, // Subtle elevation for primary action
                        shadowColor: const Color(0xFF4B3FB5).withOpacity(0.4),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
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
  String? _errorMessage;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final notifications = await _notificationService.getAdminNotifications();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      _initializeAnimations();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
    final unreadNotifications = _notifications
        .where((n) => n['isRead'] == false || n['isRead'] == null)
        .length;

    return Container(
      color: AdminDashboardStyles.background,
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header Section with Unread count and Mark all as read
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AdminDashboardStyles.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: AdminDashboardStyles.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unread Notifications',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AdminDashboardStyles.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$unreadNotifications',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AdminDashboardStyles.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (unreadNotifications > 0) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _markAllAsRead,
                                icon: const Icon(Icons.done_all, size: 18),
                                label: const Text('Mark all as read'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AdminDashboardStyles.primary,
                                  backgroundColor: AdminDashboardStyles.primary
                                      .withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AdminDashboardStyles.primary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: AdminDashboardStyles.textLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              color: AdminDashboardStyles.textLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminDashboardStyles.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AdminDashboardStyles.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t sent any notifications yet',
            style: TextStyle(
              color: AdminDashboardStyles.textLight,
              fontSize: 14,
            ),
          ),
        ],
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

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.surface,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(
                        notification['type']?.toString() ?? 'info',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getNotificationIcon(
                        notification['type']?.toString() ?? 'info',
                      ),
                      color: _getTypeColor(
                        notification['type']?.toString() ?? 'info',
                      ),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title']?.toString() ?? 'Notification',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AdminDashboardStyles.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message']?.toString() ?? 'No message',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AdminDashboardStyles.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        notification['status']?.toString() ?? 'sent',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (notification['status']?.toString() ?? 'sent')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(
                          notification['status']?.toString() ?? 'sent',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: AdminDashboardStyles.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification['recipientModel']?.toString() ?? 'All',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminDashboardStyles.textLight,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AdminDashboardStyles.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(notification['createdAt']?.toString()),
                    style: const TextStyle(
                      fontSize: 12,
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
