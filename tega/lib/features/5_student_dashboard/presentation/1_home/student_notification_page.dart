import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/notification_service.dart';
import 'package:tega/core/services/notifications_cache_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final NotificationsCacheService _cacheService = NotificationsCacheService();
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadNotifications();
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedNotifications = await _cacheService.getNotificationsData();
      if (cachedNotifications != null && cachedNotifications.isNotEmpty && mounted) {
        setState(() {
          notifications = cachedNotifications
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          isLoading = false;
          errorMessage = null;
        });
        // Still fetch in background to update cache
        _fetchNotificationsInBackground();
        return;
      }
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Fetch from API
    await _fetchNotificationsInBackground();
  }

  Future<void> _fetchNotificationsInBackground() async {
    try {
      final fetchedNotifications = await _notificationService
          .getStudentNotifications();

      // Cache notifications data
      final notificationsData = fetchedNotifications
          .map((n) => n.toJson())
          .toList();
      await _cacheService.setNotificationsData(notificationsData);

      if (mounted) {
        setState(() {
          notifications = fetchedNotifications;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedNotifications = await _cacheService.getNotificationsData();
          if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
            setState(() {
              notifications = cachedNotifications
                  .map((json) => NotificationModel.fromJson(json))
                  .toList();
              errorMessage = null; // Clear error since we have cached data
              isLoading = false;
            });
            return;
          }
          // No cache available, show error
          setState(() {
            errorMessage = 'No internet connection';
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Unable to load notifications. Please try again.';
            isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      // Mark individual notification as read (placeholder for future backend)
      final success = await _notificationService.markNotificationAsRead(notification.id);

      if (success) {
        setState(() {
          // Mark this notification as read locally
          notifications = notifications.map((n) {
            if (n.id == notification.id) {
              return NotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
                readAt: DateTime.now(),
                metadata: n.metadata,
              );
            }
            return n;
          }).toList();
        });

        // Update cache
        final notificationsData = notifications
            .map((n) => n.toJson())
            .toList();
        await _cacheService.setNotificationsData(notificationsData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification marked as read'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silently handle individual notification errors
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await _notificationService.markNotificationsAsRead();

      if (success) {
        setState(() {
          // Mark all notifications as read locally
          notifications = notifications
              .map(
                (n) => NotificationModel(
                  id: n.id,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  isRead: true,
                  createdAt: n.createdAt,
                  readAt: DateTime.now(),
                  metadata: n.metadata,
                ),
              )
              .toList();
        });

        // Update cache
        final notificationsData = notifications
            .map((n) => n.toJson())
            .toList();
        await _cacheService.setNotificationsData(notificationsData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('All notifications marked as read'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      // Delete notification (placeholder for future backend)
      final success = await _notificationService.deleteNotification(notification.id);

      if (success) {
        setState(() {
          notifications.removeWhere((n) => n.id == notification.id);
        });

        // Update cache
        final notificationsData = notifications
            .map((n) => n.toJson())
            .toList();
        await _cacheService.setNotificationsData(notificationsData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 24
            : isDesktop
            ? 20
            : isTablet
            ? 18
            : isSmallScreen
            ? 12
            : 16,
        vertical: isLargeDesktop
            ? 16
            : isDesktop
            ? 14
            : isTablet
            ? 13
            : isSmallScreen
            ? 10
            : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 8
                : isDesktop
                ? 6
                : isTablet
                ? 5
                : isSmallScreen
                ? 3
                : 4,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 2
                  : isDesktop
                  ? 1.5
                  : isTablet
                  ? 1
                  : isSmallScreen
                  ? 0.5
                  : 1,
            ),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (notifications.isNotEmpty && notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: Icon(
                Icons.done_all,
                size: isLargeDesktop
                    ? 22
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 19
                    : isSmallScreen
                    ? 16
                    : 18,
              ),
              label: Text(
                'Mark all as read',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 17
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 11
                      : 13,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9C88FF),
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 10
                      : 12,
                  vertical: isLargeDesktop
                      ? 12
                      : isDesktop
                      ? 10
                      : isTablet
                      ? 9
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
              ),
            ),
          if (notifications.isNotEmpty && notifications.any((n) => !n.isRead))
            SizedBox(
              width: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
            ),
            icon: Icon(
              Icons.more_vert,
              color: Colors.black87,
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 18
                  : 20,
            ),
            onSelected: (value) {
              if (value == "mark_all_read") {
                _markAllAsRead();
              } else if (value == "refresh") {
                _loadNotifications(forceRefresh: true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "mark_all_read",
                child: Row(
                  children: [
                    Icon(
                      Icons.done_all,
                      size: isLargeDesktop
                          ? 22
                          : isDesktop
                          ? 20
                          : isTablet
                          ? 19
                          : isSmallScreen
                          ? 16
                          : 18,
                      color: const Color(0xFF9C88FF),
                    ),
                    SizedBox(
                      width: isLargeDesktop || isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 6
                          : 10,
                    ),
                    Text(
                      'Mark all as read',
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 17
                            : isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 11
                            : 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "refresh",
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: isLargeDesktop
                          ? 22
                          : isDesktop
                          ? 20
                          : isTablet
                          ? 19
                          : isSmallScreen
                          ? 16
                          : 18,
                      color: const Color(0xFF9C88FF),
                    ),
                    SizedBox(
                      width: isLargeDesktop || isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 6
                          : 10,
                    ),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 17
                            : isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 11
                            : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(forceRefresh: true),
      color: const Color(0xFF9C88FF),
      child: ListView.separated(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => SizedBox(
          height: isLargeDesktop
              ? 14
              : isDesktop
              ? 12
              : isTablet
              ? 11
              : isSmallScreen
              ? 8
              : 10,
        ),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64.0
              : isDesktop
              ? 48.0
              : isTablet
              ? 40.0
              : isSmallScreen
              ? 24.0
              : 32.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C88FF)),
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
              'Loading notifications...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 17
                    : isSmallScreen
                    ? 14
                    : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isNoInternet = errorMessage == 'No internet connection';
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64.0
              : isDesktop
              ? 48.0
              : isTablet
              ? 40.0
              : isSmallScreen
              ? 24.0
              : 32.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isLargeDesktop
                  ? 80
                  : isDesktop
                  ? 64
                  : isTablet
                  ? 60
                  : isSmallScreen
                  ? 48
                  : 56,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            Text(
              isNoInternet ? 'No internet connection' : 'Error loading notifications',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 19
                    : isSmallScreen
                    ? 16
                    : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (isNoInternet) ...[
              SizedBox(
                height: isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 11
                      : 13,
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              SizedBox(
                height: isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 15
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 11
                      : 13,
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 26
                  : isSmallScreen
                  ? 20
                  : 24,
            ),
            ElevatedButton.icon(
              onPressed: () => _loadNotifications(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isLargeDesktop
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 40
                      : isDesktop
                      ? 32
                      : isTablet
                      ? 28
                      : isSmallScreen
                      ? 20
                      : 24,
                  vertical: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 10
                      : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 8
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 64.0
              : isDesktop
              ? 48.0
              : isTablet
              ? 40.0
              : isSmallScreen
              ? 24.0
              : 32.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 32
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF9C88FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: isLargeDesktop
                    ? 80
                    : isDesktop
                    ? 64
                    : isTablet
                    ? 60
                    : isSmallScreen
                    ? 48
                    : 56,
                color: const Color(0xFF9C88FF),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            Text(
              'You\'ll see important updates, course announcements, and system notifications here when they arrive.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: isLargeDesktop
                    ? 17
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 11
                    : 13,
                height: 1.4,
              ),
              maxLines: isLargeDesktop || isDesktop
                  ? 3
                  : isTablet
                  ? 2
                  : 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 40
                  : isDesktop
                  ? 32
                  : isTablet
                  ? 28
                  : isSmallScreen
                  ? 20
                  : 24,
            ),
            ElevatedButton.icon(
              onPressed: () => _loadNotifications(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              label: Text(
                'Refresh',
                style: TextStyle(
                  fontSize: isLargeDesktop
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 40
                      : isDesktop
                      ? 32
                      : isTablet
                      ? 28
                      : isSmallScreen
                      ? 20
                      : 24,
                  vertical: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 10
                      : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 8
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

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 15
              : isSmallScreen
              ? 10
              : 14,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 8
                : isTablet
                ? 7
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
                  ? 2.5
                  : isSmallScreen
                  ? 1
                  : 2,
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
        },
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 15
              : isSmallScreen
              ? 10
              : 14,
        ),
        child: Padding(
          padding: EdgeInsets.all(
            isLargeDesktop
                ? 20
                : isDesktop
                ? 16
                : isTablet
                ? 15
                : isSmallScreen
                ? 12
                : 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [notification.color, notification.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  notification.icon,
                  color: Colors.white,
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 24
                      : isTablet
                      ? 22
                      : isSmallScreen
                      ? 18
                      : 20,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 13
                    : isSmallScreen
                    ? 8
                    : 12,
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: isLargeDesktop
                                  ? 20
                                  : isDesktop
                                  ? 18
                                  : isTablet
                                  ? 17
                                  : isSmallScreen
                                  ? 14
                                  : 16,
                              color: const Color(0xFF3A7BD5),
                              fontWeight: !notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: isLargeDesktop || isDesktop
                                ? 2
                                : isTablet
                                ? 2
                                : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: isLargeDesktop
                                ? 14
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 8
                                : 10,
                            height: isLargeDesktop
                                ? 14
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 8
                                : 10,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.message != null) ...[
                      SizedBox(
                        height: isLargeDesktop || isDesktop
                            ? 8
                            : isTablet
                            ? 7
                            : isSmallScreen
                            ? 4
                            : 6,
                      ),
                      Text(
                        notification.message!,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 11
                              : 13,
                        ),
                        maxLines: isLargeDesktop || isDesktop
                            ? 3
                            : isTablet
                            ? 2
                            : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(
                      height: isLargeDesktop || isDesktop
                          ? 8
                          : isTablet
                          ? 7
                          : isSmallScreen
                          ? 4
                          : 6,
                    ),
                    Row(
                      children: [
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isLargeDesktop
                                ? 14
                                : isDesktop
                                ? 13
                                : isTablet
                                ? 12
                                : isSmallScreen
                                ? 10
                                : 11,
                          ),
                        ),
                        const Spacer(),
                        // Action buttons
                        if (!notification.isRead)
                          InkWell(
                            onTap: () => _markAsRead(notification),
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 8
                                  : isDesktop
                                  ? 6
                                  : isTablet
                                  ? 5.5
                                  : isSmallScreen
                                  ? 4
                                  : 5,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isLargeDesktop
                                    ? 8
                                    : isDesktop
                                    ? 6
                                    : isTablet
                                    ? 5.5
                                    : isSmallScreen
                                    ? 4
                                    : 5,
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                size: isLargeDesktop
                                    ? 22
                                    : isDesktop
                                    ? 20
                                    : isTablet
                                    ? 19
                                    : isSmallScreen
                                    ? 16
                                    : 18,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: isLargeDesktop
                              ? 12
                              : isDesktop
                              ? 10
                              : isTablet
                              ? 9
                              : isSmallScreen
                              ? 6
                              : 8,
                        ),
                        InkWell(
                          onTap: () => _deleteNotification(notification),
                          borderRadius: BorderRadius.circular(
                            isLargeDesktop
                                ? 8
                                : isDesktop
                                ? 6
                                : isTablet
                                ? 5.5
                                : isSmallScreen
                                ? 4
                                : 5,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              isLargeDesktop
                                  ? 8
                                  : isDesktop
                                  ? 6
                                  : isTablet
                                  ? 5.5
                                  : isSmallScreen
                                  ? 4
                                  : 5,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: isLargeDesktop
                                  ? 22
                                  : isDesktop
                                  ? 20
                                  : isTablet
                                  ? 19
                                  : isSmallScreen
                                  ? 16
                                  : 18,
                              color: Colors.red,
                            ),
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
      ),
    );
  }
}
