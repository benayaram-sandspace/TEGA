import 'package:flutter/material.dart';

// Custom Report Builder Page
class CustomReportBuilderPage extends StatefulWidget {
  const CustomReportBuilderPage({Key? key}) : super(key: key);

  @override
  State<CustomReportBuilderPage> createState() =>
      _CustomReportBuilderPageState();
}

class _CustomReportBuilderPageState extends State<CustomReportBuilderPage> {
  // Data selection checkboxes
  bool _candidateInfoSelected = false;
  bool _applicationDetailsSelected = false;
  bool _interviewFeedbackSelected = false;

  // Filter selections
  String? _selectedCollege;
  String? _selectedBranch;
  String? _selectedStatus;
  String? _selectedDateRange;

  // Generate section
  final TextEditingController _reportNameController = TextEditingController();
  String? _selectedExportFormat;

  @override
  void dispose() {
    _reportNameController.dispose();
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
          'Custom Report Builder',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator dots
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(true),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Select Data Section
              const Text(
                'Select Data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Data selection checkboxes
              _buildCheckboxTile(
                title: 'Candidate Information',
                value: _candidateInfoSelected,
                onChanged: (value) {
                  setState(() {
                    _candidateInfoSelected = value ?? false;
                  });
                },
              ),
              _buildCheckboxTile(
                title: 'Application Details',
                value: _applicationDetailsSelected,
                onChanged: (value) {
                  setState(() {
                    _applicationDetailsSelected = value ?? false;
                  });
                },
              ),
              _buildCheckboxTile(
                title: 'Interview Feedback',
                value: _interviewFeedbackSelected,
                onChanged: (value) {
                  setState(() {
                    _interviewFeedbackSelected = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Progress indicator dots
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(true),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Apply Filters Section
              const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // College dropdown
              _buildFilterSection(
                label: 'College',
                child: _buildDropdown(
                  hint: 'Select College',
                  value: _selectedCollege,
                  items: [
                    'Engineering College',
                    'Medical College',
                    'Arts College',
                    'Science College',
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCollege = value;
                    });
                  },
                ),
              ),

              // Branch dropdown
              _buildFilterSection(
                label: 'Branch',
                child: _buildDropdown(
                  hint: 'Select Branch',
                  value: _selectedBranch,
                  items: [
                    'Computer Science',
                    'Mechanical',
                    'Electrical',
                    'Civil',
                    'Electronics',
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBranch = value;
                    });
                  },
                ),
              ),

              // Application Status dropdown
              _buildFilterSection(
                label: 'Application Status',
                child: _buildDropdown(
                  hint: 'Select Status',
                  value: _selectedStatus,
                  items: [
                    'Pending',
                    'In Review',
                    'Approved',
                    'Rejected',
                    'On Hold',
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),

              // Date Range dropdown
              _buildFilterSection(
                label: 'Date Range',
                child: _buildDropdown(
                  hint: 'Select Date Range',
                  value: _selectedDateRange,
                  items: [
                    'Last 7 days',
                    'Last 30 days',
                    'Last 3 months',
                    'Last 6 months',
                    'Last year',
                    'Custom range',
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDateRange = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Progress indicator dots
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(true),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Generate Section
              const Text(
                'Generate',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Report Name
              _buildFilterSection(
                label: 'Report Name',
                child: TextField(
                  controller: _reportNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter Report Name',
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
                      vertical: 14,
                    ),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

              // Export Format
              _buildFilterSection(
                label: 'Export Format',
                child: _buildDropdown(
                  hint: 'Select Format',
                  value: _selectedExportFormat,
                  items: ['PDF', 'Excel (XLSX)', 'CSV', 'Word (DOCX)', 'JSON'],
                  onChanged: (value) {
                    setState(() {
                      _selectedExportFormat = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Generate & Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B3FB5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Generate & Download',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF4B3FB5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFilterSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
        isExpanded: true,
      ),
    );
  }

  void _generateReport() {
    // Validate selections
    if (!_candidateInfoSelected &&
        !_applicationDetailsSelected &&
        !_interviewFeedbackSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one data type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reportNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a report name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedExportFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an export format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4B3FB5)),
        );
      },
    );

    // Simulate report generation
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report "${_reportNameController.text}" generated successfully!',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Download',
            textColor: Colors.white,
            onPressed: () {
              // Handle download action
            },
          ),
        ),
      );

      // Optionally navigate back
      // Navigator.pop(context);
    });
  }
}
