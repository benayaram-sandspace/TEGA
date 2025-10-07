import 'package:flutter/material.dart';

class ConfigureStudentReportPage extends StatefulWidget {
  const ConfigureStudentReportPage({super.key});

  @override
  State<ConfigureStudentReportPage> createState() =>
      _ConfigureStudentReportPageState();
}

class _ConfigureStudentReportPageState
    extends State<ConfigureStudentReportPage> {
  String _selectedExportFormat = 'PDF';
  String? _selectedCollege;
  String? _selectedStudent;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _colleges = [
    'Engineering College',
    'Medical College',
    'Arts College',
    'Science College',
    'Commerce College',
  ];

  final List<String> _students = [
    'John Smith',
    'Sarah Johnson',
    'Michael Brown',
    'Emily Davis',
    'David Wilson',
    'Jessica Miller',
  ];

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
          'Configure Student-Wise Report',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Section
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Start Date and End Date Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectStartDate,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8B84B)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                _startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _startDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectEndDate,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8B84B)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                _endDate != null
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _endDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // College(s) Section
            const Text(
              'College(s)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // College Dropdown
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8B84B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Select College(s)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                initialValue: _selectedCollege,
                items: _colleges.map((college) {
                  return DropdownMenuItem(value: college, child: Text(college));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCollege = value;
                  });
                },
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 32),

            // Student(s) Section
            const Text(
              'Student(s)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Student Dropdown
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8B84B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Select Student(s)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                initialValue: _selectedStudent,
                items: _students.map((student) {
                  return DropdownMenuItem(value: student, child: Text(student));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudent = value;
                  });
                },
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.keyboard_arrow_up, color: Colors.grey, size: 16),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Export Format Section
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Export Format Buttons
            Row(
              children: [
                _buildFormatButton('PDF', _selectedExportFormat == 'PDF'),
                const SizedBox(width: 12),
                _buildFormatButton('CSV', _selectedExportFormat == 'CSV'),
              ],
            ),

            const Spacer(),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8B84B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
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
                    onPressed: _downloadReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B3FB5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Download Report',
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
    );
  }

  Widget _buildFormatButton(String format, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExportFormat = format;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8B84B) : Colors.white,
          border: Border.all(color: const Color(0xFFE8B84B), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          format,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4B3FB5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4B3FB5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _downloadReport() {
    // Validate inputs
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a college'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show success message and download logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloading $_selectedExportFormat report for $_selectedStudent...',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Implement actual download logic here
    // For now, just close the page after a delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }
}

// Function to navigate to this page
void _generateStudentReport(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ConfigureStudentReportPage()),
  );
}
