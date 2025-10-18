import 'package:flutter/material.dart';
import 'form_section_card.dart'; // Assuming this is your custom card widget

class TestBasicInfoSection extends StatefulWidget {
  final TextEditingController testNameController;
  final TextEditingController descriptionController;
  final String? selectedCourse;
  final List<String> courses;
  final ValueChanged<String?> onCourseChanged;

  const TestBasicInfoSection({
    super.key,
    required this.testNameController,
    required this.descriptionController,
    required this.selectedCourse,
    required this.courses,
    required this.onCourseChanged,
  });

  @override
  State<TestBasicInfoSection> createState() => _TestBasicInfoSectionState();
}

class _TestBasicInfoSectionState extends State<TestBasicInfoSection> {
  final _formKey = GlobalKey<FormState>();

  // State for the custom description field
  final FocusNode _descriptionFocusNode = FocusNode();
  String? _descriptionErrorText;

  @override
  void initState() {
    super.initState();
    widget.testNameController.addListener(() => setState(() {}));
    widget.descriptionController.addListener(() => setState(() {}));
    _descriptionFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.testNameController.removeListener(() => setState(() {}));
    widget.descriptionController.removeListener(() => setState(() {}));
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  // This helper is still used for the first two fields
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    // ... (This helper function remains unchanged)
    const primaryColor = Color(0xFF1976D2);
    final textTheme = Theme.of(context).textTheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
      hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
      floatingLabelStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0,
        horizontal: 12.0,
      ),
      fillColor: Colors.grey.shade50,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1976D2);

    // --- MANUALLY BUILT DESCRIPTION FIELD WIDGET ---
    // This custom widget gives us full control over alignment.
    Widget buildDescriptionField() {
      // Determine border color based on focus and error state
      Color borderColor = _descriptionFocusNode.hasFocus
          ? primaryColor
          : (_descriptionErrorText != null
                ? Colors.red.shade400
                : Colors.grey.shade300);
      double borderWidth = _descriptionFocusNode.hasFocus ? 1.5 : 1.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Custom floating label
          Text(
            '  Description',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _descriptionFocusNode.hasFocus
                  ? primaryColor
                  : Colors.grey.shade600,
              fontWeight: _descriptionFocusNode.hasFocus
                  ? FontWeight.w500
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // 2. The main container with our custom border and fill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. The Icon, perfectly aligned with top padding
                Padding(
                  padding: const EdgeInsets.only(top: 18.0, right: 8.0),
                  child: Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
                // 4. The TextFormField, expanded to fill the space
                Expanded(
                  child: TextFormField(
                    controller: widget.descriptionController,
                    focusNode: _descriptionFocusNode,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Brief description about the test',
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade400),
                      border: InputBorder.none, // No internal border
                      contentPadding: const EdgeInsets.only(top: 18.0),
                    ),
                    validator: (value) {
                      final error = value == null || value.isEmpty
                          ? 'Description cannot be empty'
                          : null;
                      // Manually update error text state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _descriptionErrorText = error;
                        });
                      });
                      return error;
                    },
                  ),
                ),
              ],
            ),
          ),
          // 5. Custom error text display
          if (_descriptionErrorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 6.0),
              child: Text(
                _descriptionErrorText!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              ),
            ),
        ],
      );
    }

    return FormSectionCard(
      title: 'Basic Information',
      icon: Icons.info_outline_rounded,
      iconColor: primaryColor,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              controller: widget.testNameController,
              decoration: _buildInputDecoration(
                labelText: 'Test Name',
                hintText: 'E.g., Mid-Semester Examination',
                icon: Icons.title_rounded,
                suffixIcon: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.testNameController.text.isNotEmpty
                      ? 1.0
                      : 0.0,
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => widget.testNameController.clear(),
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a test name'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: widget.selectedCourse,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: primaryColor,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Select Course',
                icon: Icons.school_rounded,
              ),
              dropdownColor: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              items: widget.courses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(course, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: widget.onCourseChanged,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select a course'
                  : null,
            ),
            const SizedBox(height: 16),
            // Use our new custom-built field here
            buildDescriptionField(),
          ],
        ),
      ),
    );
  }
}
