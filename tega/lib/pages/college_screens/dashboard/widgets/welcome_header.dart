import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final int notificationCount;
  final VoidCallback onNotificationTap;

  // MODIFIED: Constructor no longer asks for profileImageUrl
  const WelcomeHeader({
    super.key,
    required this.greeting,
    required this.userName,
    required this.notificationCount,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                greeting,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: textTheme.titleMedium?.copyWith(color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationBell(),
            const SizedBox(width: 8),
            _buildProfileAvatar(), // The placeholder is back
          ],
        ),
      ],
    );
  }

  // MODIFIED: This now only builds the static placeholder avatar
  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person_outline, size: 28, color: Colors.grey.shade600),
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black54,
            size: 30,
          ),
          onPressed: onNotificationTap,
        ),
        if (notificationCount > 0)
          Container(
            margin: const EdgeInsets.only(top: 4, right: 6),
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              notificationCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
