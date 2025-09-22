import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [
    {"title": "Assignment due tomorrow", "time": "2h ago", "unread": true},
    {
      "title": "Your course schedule has been updated",
      "time": "5h ago",
      "unread": true,
    },
    {
      "title": "New announcement from your college",
      "time": "1d ago",
      "unread": false,
    },
    {"title": "Exam results are out", "time": "2d ago", "unread": false},
    {
      "title": "Reminder: Project submission deadline",
      "time": "3d ago",
      "unread": false,
    },
  ];

  void _markAllAsSeen() {
    setState(() {
      for (var notif in notifications) {
        notif["unread"] = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "✅ All notifications marked as seen",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF6B5FFF), // ✅ purple from palette
        behavior: SnackBarBehavior.fixed, // default: slides from bottom
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // ✅ light grey background

      appBar: AppBar(
        backgroundColor: Colors.white, // ✅ white header
        elevation: 4,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              if (value == "mark_seen") {
                _markAllAsSeen();
              } else if (value == "delete_read") {
                // TODO: will implement later with backend
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "mark_seen",
                child: Text("Mark all as seen"),
              ),
              const PopupMenuItem(
                value: "delete_read",
                child: Text("Delete read notifications"),
              ),
            ],
          ),
        ],
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final bool unread = notif["unread"] as bool;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B5FFF), Color(0xFF3A7BD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: Text(
                notif["title"] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF3A7BD5), // ✅ blue accent
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  notif["time"] as String,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              trailing: unread
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.orange, // ✅ orange dot for unread
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () {
                // optional: mark individual notification as seen
                setState(() {
                  notif["unread"] = false;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
