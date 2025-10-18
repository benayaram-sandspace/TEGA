import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'form_section_card.dart';

class TestConfigAndScheduleSections extends StatelessWidget {
  final TextEditingController totalMarksController;
  final TextEditingController passingMarksController;
  final TextEditingController durationController;
  final String selectedDifficulty;
  final List<String> difficultyLevels;
  final ValueChanged<String?> onDifficultyChanged;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;

  const TestConfigAndScheduleSections({
    super.key,
    required this.totalMarksController,
    required this.passingMarksController,
    required this.durationController,
    required this.selectedDifficulty,
    required this.difficultyLevels,
    required this.onDifficultyChanged,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Test Configuration',
          icon: Icons.settings_rounded,
          iconColor: const Color(0xFFD32F2F),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth / 2) - 8;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildTextField(
                      controller: totalMarksController,
                      label: 'Total Marks',
                      prefixIcon: Icons.score_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildTextField(
                      controller: passingMarksController,
                      label: 'Passing Marks',
                      prefixIcon: Icons.check_circle_outline,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        FormSectionCard(
          title: 'Schedule',
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFFFB8C00),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth / 2) - 8;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildTextField(
                      controller: durationController,
                      label: 'Duration (min)',
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: 'Difficulty',
                        prefixIcon: Icon(
                          Icons.trending_up_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      items: difficultyLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: onDifficultyChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildDateTimePicker(
                      'Test Date',
                      DateFormat.yMMMd().format(selectedDate),
                      Icons.date_range_rounded,
                      onSelectDate,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildDateTimePicker(
                      'Start Time',
                      selectedTime.format(context),
                      Icons.access_time_rounded,
                      onSelectTime,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: Colors.grey[600])
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimePicker(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
