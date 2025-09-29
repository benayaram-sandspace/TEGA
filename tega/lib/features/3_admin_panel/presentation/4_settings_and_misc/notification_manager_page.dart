import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

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
class NotificationManagerPage extends StatelessWidget {
  const NotificationManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Cleaner background
      appBar: AppBar(
        // Themed AppBar for a more branded look
        backgroundColor: const Color.fromARGB(255, 249, 249, 249),
        elevation: 4,
        shadowColor: const Color(0xFF4B3FB5).withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComposeNotificationPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NotificationCard(
            iconData: Icons.campaign_rounded, // Using icons
            title: 'Welcome to the Team!',
            audience: 'All Users',
            sentDate: '2023-09-15',
            onTap: () =>
                _handleNotificationTap(context, 'Welcome Notification'),
          ),
          const SizedBox(height: 16),
          NotificationCard(
            iconData: Icons.system_update_alt_rounded,
            title: 'App Update v2.5 Available',
            audience: 'Specific Group',
            sentDate: '2023-09-10',
            onTap: () => _handleNotificationTap(context, 'Update Notification'),
          ),
          const SizedBox(height: 16),
          NotificationCard(
            iconData: Icons.local_offer_rounded,
            title: 'Flash Sale: 50% Off!',
            audience: 'All Users',
            sentDate: '2023-09-05',
            onTap: () => _handleNotificationTap(context, 'Sale Notification'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, String notificationId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tapped on $notificationId')));
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
