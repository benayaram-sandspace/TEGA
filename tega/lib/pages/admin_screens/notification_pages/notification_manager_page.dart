import 'package:flutter/material.dart';
import 'package:tega/pages/admin_screens/admin_related_pages/admin_dashboard.dart';

// Compose Notification Page
class ComposeNotificationPage extends StatefulWidget {
  const ComposeNotificationPage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Compose Notification',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Person icon placeholder
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D4C0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title and Description
              const Text(
                'Compose Notification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Craft a new notification to keep your users informed and engaged.',
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Use a Template Section
              const Text(
                'Use a Template (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: 'Select',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
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
              ),
              const SizedBox(height: 24),

              // Notification Title
              const Text(
                'Notification Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter notification title',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4B3FB5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Message
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your message here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFC107),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Target Audience
              const Text(
                'Target Audience',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: 'Select',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
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
              ),
              const SizedBox(height: 40),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _saveDraft();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save as Draft',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _sendNotification();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B3FB5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send Notification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    // Implement save draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification saved as draft'),
        backgroundColor: Color(0xFFFFC107),
      ),
    );
  }

  void _sendNotification() {
    // Validate fields
    if (_titleController.text.isEmpty ||
        _messageController.text.isEmpty ||
        _selectedAudience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Implement send notification functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification sent successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to notification manager
    Navigator.pop(context);
  }
}

// Notification Manager Page - Can be navigated to from anywhere in your app
class NotificationManagerPage extends StatelessWidget {
  const NotificationManagerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Notification Manager',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navigate to Compose Notification page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComposeNotificationPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.black54),
            label: const Text(
              'Add',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NotificationCard(
            imageUrl: 'assets/image1.png',
            title: 'Notification Title',
            audience: 'All Users',
            sentDate: '2023-09-15',
            onTap: () {
              _handleNotificationTap(context, 'Notification 1');
            },
          ),
          const SizedBox(height: 16),
          NotificationCard(
            imageUrl: 'assets/image2.png',
            title: 'Notification Title',
            audience: 'Specific Group',
            sentDate: '2023-09-10',
            onTap: () {
              _handleNotificationTap(context, 'Notification 2');
            },
          ),
          const SizedBox(height: 16),
          NotificationCard(
            imageUrl: 'assets/image3.png',
            title: 'Notification Title',
            audience: 'All Users',
            sentDate: '2023-09-05',
            onTap: () {
              _handleNotificationTap(context, 'Notification 3');
            },
          ),
          const SizedBox(height: 16),
          NotificationCard(
            imageUrl: 'assets/image4.png',
            title: 'Notification Title',
            audience: 'Specific Group',
            sentDate: '2023-08-30',
            onTap: () {
              _handleNotificationTap(context, 'Notification 4');
            },
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, String notificationId) {
    // Navigate to notification details or edit page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tapped on $notificationId')));
  }
}

// Notification Card Widget
class NotificationCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String audience;
  final String sentDate;
  final VoidCallback? onTap;

  const NotificationCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.audience,
    required this.sentDate,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4B3FB5), // Purple/blue color
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D8), // Light beige background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0D0C0),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 50,
                    color: Color(0xFFB8A090),
                  ),
                ),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFC107), // Yellow/gold color for title
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Audience: $audience',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent Date: $sentDate',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
