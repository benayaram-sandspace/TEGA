import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildSettingsSection(
            title: "General",
            context: context, // Pass context to the helper
            children: [
              SwitchListTile(
                title: const Text("Enable Notifications"),
                subtitle: const Text("Receive alerts and updates"),
                secondary: const Icon(Icons.notifications_outlined),
                value: true, // Placeholder value
                onChanged: (bool value) {
                  // Logic for notifications
                },
              ),
            ],
          ),
          _buildSettingsSection(
            title: "Account",
            context: context, // Pass context
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text("Change Password"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Language"),
                subtitle: const Text("English"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    required BuildContext context, // Added context here
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0.2,
          // Use the theme's card color
          color: Theme.of(context).cardColor,
          child: Column(children: children),
        ),
      ],
    );
  }
}
