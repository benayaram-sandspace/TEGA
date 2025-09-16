import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;

  const SearchBarWidget({super.key, required this.controller});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  void initState() {
    super.initState();
    // Add a listener to the controller to rebuild the widget when text changes.
    // This is needed to show/hide the clear button.
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Search students, courses, or activities...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey.shade400),
          // Show the clear button only if the text field is not empty
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          // The listener in initState handles the UI update.
          // You can add search logic here if needed.
        },
      ),
    );
  }
}
