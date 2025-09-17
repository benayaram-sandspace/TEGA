// lib/pages/college_screens/students/widgets/bulk_import_section.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tega/pages/college_screens/dashboard/quick_actions_pages/college_student_model.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:tega/pages/college_screens/dashboard/quick_actions_pages/import_preview_page.dart';

class BulkImportSection extends StatefulWidget {
  final Function(List<Student>) onImport;
  final bool isLoading;

  const BulkImportSection({
    super.key,
    required this.onImport,
    this.isLoading = false,
  });

  @override
  State<BulkImportSection> createState() => _BulkImportSectionState();
}

class _BulkImportSectionState extends State<BulkImportSection> {
  File? _selectedFile;
  String? _fileName;
  List<Student>? _parsedStudents;
  String? _errorMessage;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _errorMessage = null;
          _parsedStudents = null;
        });

        // Process the file
        await _processFile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // For demo purposes, we'll simulate processing
      // In a real app, you'd parse the CSV/Excel file here
      await Future.delayed(const Duration(seconds: 1));

      // Simulate parsed data
      _parsedStudents = _generateSampleStudents();

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing file: $e';
        _isProcessing = false;
      });
    }
  }

  List<Student> _generateSampleStudents() {
    // Sample data for demonstration
    return [
      Student(
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '9876543210',
        studentId: 'STU001',
        course: 'B.Tech',
        batch: '2024-2028',
        department: 'Computer Science',
        dateOfBirth: DateTime(2005, 5, 15),
        gender: 'Male',
        address: '123 Main St, City',
        guardianName: 'Jane Doe',
        guardianPhone: '9876543211',
        enrollmentDate: DateTime.now(),
      ),
      Student(
        firstName: 'Alice',
        lastName: 'Smith',
        email: 'alice.smith@example.com',
        phone: '9876543212',
        studentId: 'STU002',
        course: 'B.Tech',
        batch: '2024-2028',
        department: 'Electronics',
        dateOfBirth: DateTime(2005, 8, 20),
        gender: 'Female',
        address: '456 Oak Ave, City',
        guardianName: 'Bob Smith',
        guardianPhone: '9876543213',
        enrollmentDate: DateTime.now(),
      ),
      Student(
        firstName: 'Mike',
        lastName: 'Johnson',
        email: 'mike.j@example.com',
        phone: '9876543214',
        studentId: 'STU003',
        course: 'MBA',
        batch: '2024-2026',
        department: 'Business Administration',
        dateOfBirth: DateTime(2001, 3, 10),
        gender: 'Male',
        address: '789 Pine Rd, City',
        guardianName: 'Sarah Johnson',
        guardianPhone: '9876543215',
        enrollmentDate: DateTime.now(),
      ),
    ];
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _parsedStudents = null;
      _errorMessage = null;
    });
  }

  void _downloadTemplate() {
    // TODO: Implement template download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Template download will be implemented'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Import Instructions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInstructionItem(
                '1',
                'Download the CSV/Excel template with required columns',
              ),
              const SizedBox(height: 8),
              _buildInstructionItem(
                '2',
                'Fill in student details following the format guidelines',
              ),
              const SizedBox(height: 8),
              _buildInstructionItem(
                '3',
                'Upload the completed file for bulk import',
              ),
              const SizedBox(height: 8),
              _buildInstructionItem(
                '4',
                'Review parsed data and confirm import',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // File Upload Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DashboardStyles.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.upload_file_rounded,
                      size: 20,
                      color: DashboardStyles.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upload File',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Drop Zone
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null
                          ? Colors.green
                          : Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFile != null
                        ? Colors.green.withOpacity(0.05)
                        : Colors.grey[50],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _selectedFile != null
                              ? Icons.file_present_rounded
                              : Icons.cloud_upload_outlined,
                          size: 48,
                          color: _selectedFile != null
                              ? Colors.green
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fileName ?? 'Click to browse or drag and drop',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedFile != null
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Supports: CSV, XLS, XLSX',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _clearFile,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Remove File'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Preview Section
        if (_isProcessing) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ] else if (_parsedStudents != null && _parsedStudents!.isNotEmpty) ...[
          const SizedBox(height: 24),
          ImportPreviewTable(
            students: _parsedStudents!,
            onRemove: (index) {
              setState(() {
                _parsedStudents!.removeAt(index);
                if (_parsedStudents!.isEmpty) {
                  _parsedStudents = null;
                }
              });
            },
          ),
          const SizedBox(height: 24),

          // Import Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : _clearFile,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.onImport(_parsedStudents!),
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(
                    'Import ${_parsedStudents!.length} Students',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardStyles.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
