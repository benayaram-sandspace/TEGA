import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/models/student.dart';
import 'package:tega/services/college_service.dart' as college_service;

class ProgressReportGeneratorPage extends StatefulWidget {
  final Student student;

  const ProgressReportGeneratorPage({super.key, required this.student});

  @override
  State<ProgressReportGeneratorPage> createState() => _ProgressReportGeneratorPageState();
}

class _ProgressReportGeneratorPageState extends State<ProgressReportGeneratorPage> {
  final TextEditingController _reportNameController = TextEditingController();
  String _selectedDateRange = 'Select Date Range';
  String _selectedExportFormat = 'PDF';
  bool _isGenerating = false;
  bool _isLoadingData = true;
  
  // JSON data
  List<college_service.College> _colleges = [];
  List<Student> _allStudents = [];
  college_service.CollegeService _collegeService = college_service.CollegeService();
  
  Map<String, bool> _reportSections = {
    'Student Profile Summary': false,
    'Overall Readiness Trend': false,
    'Skill Graph Analysis': false,
    'Mock Interview Performance': false,
    'Resume Optimizer History': false,
    'Daily Skill Drill Activity': false,
  };

  Map<String, Map<String, dynamic>> _sectionData = {
    'Student Profile Summary': {
      'includePhoto': true,
      'includeContact': true,
      'includeAcademic': true,
    },
    'Overall Readiness Trend': {
      'timeframe': '6 months',
      'includeGraphs': true,
      'includeComparisons': true,
    },
    'Skill Graph Analysis': {
      'skills': ['Programming', 'Communication', 'Problem Solving', 'Leadership'],
      'includeProgress': true,
      'includeRecommendations': true,
    },
    'Mock Interview Performance': {
      'sessions': 5,
      'includeFeedback': true,
      'includeImprovements': true,
    },
    'Resume Optimizer History': {
      'versions': 3,
      'includeChanges': true,
      'includeScore': true,
    },
    'Daily Skill Drill Activity': {
      'days': 30,
      'includeStreaks': true,
      'includeAchievements': true,
    },
  };

  @override
  void initState() {
    super.initState();
    _reportNameController.text = '${widget.student.name}_Progress_Report_${DateTime.now().millisecondsSinceEpoch}';
    _loadDataFromJson();
  }

  Future<void> _loadDataFromJson() async {
    try {
      // Load colleges and students from JSON
      _colleges = await _collegeService.loadColleges();
      
      // Extract all students from all colleges
      _allStudents = [];
      for (var college in _colleges) {
        for (var jsonStudent in college.students) {
          // Convert JSON Student to our Student model
          _allStudents.add(Student.detailed(
            name: jsonStudent.name,
            college: college.name,
            status: 'Active', // Default status
            email: jsonStudent.email,
            studentId: jsonStudent.id,
            branch: jsonStudent.course,
            yearOfStudy: jsonStudent.year.toString(),
            jobReadiness: (jsonStudent.skillScore / 100.0), // Convert to 0-1 scale
          ));
        }
      }
      
      // Update section data with real data from JSON
      _updateSectionDataWithJsonData();
      
      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error loading data from JSON: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _updateSectionDataWithJsonData() {
    // Find the current student in the JSON data
    var jsonStudent = _findStudentInJsonData(widget.student.name);
    var studentCollege = _findStudentCollege(widget.student.name);
    
    if (jsonStudent != null && studentCollege != null) {
      _sectionData = {
        'Student Profile Summary': {
          'includePhoto': true,
          'includeContact': true,
          'includeAcademic': true,
          'studentName': jsonStudent.name,
          'college': studentCollege.name,
          'course': jsonStudent.course,
          'year': jsonStudent.year,
          'email': jsonStudent.email,
          'phone': jsonStudent.phone,
        },
        'Overall Readiness Trend': {
          'timeframe': '6 months',
          'includeGraphs': true,
          'includeComparisons': true,
          'skillScore': jsonStudent.skillScore,
          'interviewPractices': jsonStudent.interviewPractices,
          'collegeAvgSkillScore': studentCollege.avgSkillScore,
          'collegeAvgInterviewPractices': studentCollege.avgInterviewPractices,
        },
        'Skill Graph Analysis': {
          'skills': ['Programming', 'Communication', 'Problem Solving', 'Leadership'],
          'includeProgress': true,
          'includeRecommendations': true,
          'currentSkillScore': jsonStudent.skillScore,
          'targetSkillScore': 90,
          'improvementAreas': _getImprovementAreas(jsonStudent.skillScore),
        },
        'Mock Interview Performance': {
          'sessions': jsonStudent.interviewPractices,
          'includeFeedback': true,
          'includeImprovements': true,
          'averageScore': _calculateAverageScore(jsonStudent.skillScore),
          'totalSessions': jsonStudent.interviewPractices,
          'lastSessionDate': DateTime.now().subtract(Duration(days: 7)).toString().split(' ')[0],
        },
        'Resume Optimizer History': {
          'versions': 3,
          'includeChanges': true,
          'includeScore': true,
          'currentScore': jsonStudent.skillScore,
          'previousScore': jsonStudent.skillScore - 10,
          'improvement': 10,
        },
        'Daily Skill Drill Activity': {
          'days': 30,
          'includeStreaks': true,
          'includeAchievements': true,
          'currentStreak': _calculateStreak(jsonStudent.skillScore),
          'totalDays': 30,
          'achievements': _getAchievements(jsonStudent.skillScore),
        },
      };
    }
  }

  college_service.Student? _findStudentInJsonData(String studentName) {
    for (var college in _colleges) {
      for (var student in college.students) {
        if (student.name.toLowerCase() == studentName.toLowerCase()) {
          return student;
        }
      }
    }
    return null;
  }

  college_service.College? _findStudentCollege(String studentName) {
    for (var college in _colleges) {
      for (var student in college.students) {
        if (student.name.toLowerCase() == studentName.toLowerCase()) {
          return college;
        }
      }
    }
    return null;
  }

  List<String> _getImprovementAreas(int skillScore) {
    if (skillScore < 70) {
      return ['Technical Skills', 'Communication', 'Problem Solving'];
    } else if (skillScore < 85) {
      return ['Leadership', 'Time Management'];
    } else {
      return ['Advanced Technical Skills', 'Industry Knowledge'];
    }
  }

  double _calculateAverageScore(int skillScore) {
    // Simulate interview scores based on skill score
    return (skillScore * 0.8 + 20).toDouble();
  }

  int _calculateStreak(int skillScore) {
    // Simulate streak based on skill score
    return (skillScore / 10).round();
  }

  List<String> _getAchievements(int skillScore) {
    List<String> achievements = [];
    if (skillScore >= 80) achievements.add('Skill Master');
    if (skillScore >= 70) achievements.add('Consistent Performer');
    if (skillScore >= 60) achievements.add('Improving Student');
    return achievements;
  }

  @override
  void dispose() {
    _reportNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Progress Report Generator',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Loading student data from database...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Progress Report Generator',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For Student: ${widget.student.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report Name Section
            const Text(
              'Report Name',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildReportNameField(),
            const SizedBox(height: 24),

            // Customize Report Section
            const Text(
              'Customize Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Selection
            _buildDateRangeSelector(),
            const SizedBox(height: 20),

            // Report Sections
            const Text(
              'Select Report Sections:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Checkbox List with Data Editing
            ..._reportSections.keys.map((section) => _buildCheckboxItemWithData(section)),
            const SizedBox(height: 24),

            // Export Format Section
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Export Format Options
            _buildExportFormatOptions(),
            const SizedBox(height: 32),

            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating...'),
                        ],
                      )
                    : const Text(
                        'Generate Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReportNameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _reportNameController,
        decoration: const InputDecoration(
          hintText: 'Enter report name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return GestureDetector(
      onTap: () => _showDateRangeDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDateRange,
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDateRange == 'Select Date Range' 
                      ? AppColors.textSecondary 
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItemWithData(String section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _reportSections[section]! ? AppColors.primary : AppColors.borderLight,
          width: _reportSections[section]! ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _reportSections[section],
                onChanged: (value) {
                  setState(() {
                    _reportSections[section] = value!;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_reportSections[section]!)
                IconButton(
                  onPressed: () => _showSectionDataDialog(section),
                  icon: Icon(
                    Icons.settings,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
            ],
          ),
          if (_reportSections[section]!)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: _buildSectionDataPreview(section),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionDataPreview(String section) {
    final data = _sectionData[section]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section == 'Student Profile Summary') ...[
          _buildDataItem('Include Photo', data['includePhoto']),
          _buildDataItem('Include Contact', data['includeContact']),
          _buildDataItem('Include Academic', data['includeAcademic']),
        ] else if (section == 'Overall Readiness Trend') ...[
          _buildDataItem('Timeframe', data['timeframe']),
          _buildDataItem('Include Graphs', data['includeGraphs']),
          _buildDataItem('Include Comparisons', data['includeComparisons']),
        ] else if (section == 'Skill Graph Analysis') ...[
          _buildDataItem('Skills', (data['skills'] as List).join(', ')),
          _buildDataItem('Include Progress', data['includeProgress']),
          _buildDataItem('Include Recommendations', data['includeRecommendations']),
        ] else if (section == 'Mock Interview Performance') ...[
          _buildDataItem('Sessions', data['sessions']),
          _buildDataItem('Include Feedback', data['includeFeedback']),
          _buildDataItem('Include Improvements', data['includeImprovements']),
        ] else if (section == 'Resume Optimizer History') ...[
          _buildDataItem('Versions', data['versions']),
          _buildDataItem('Include Changes', data['includeChanges']),
          _buildDataItem('Include Score', data['includeScore']),
        ] else if (section == 'Daily Skill Drill Activity') ...[
          _buildDataItem('Days', data['days']),
          _buildDataItem('Include Streaks', data['includeStreaks']),
          _buildDataItem('Include Achievements', data['includeAchievements']),
        ],
      ],
    );
  }

  Widget _buildDataItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportFormatOptions() {
    return Column(
      children: [
        _buildExportFormatOption('PDF', 'PDF', _selectedExportFormat == 'PDF'),
        const SizedBox(height: 12),
        _buildExportFormatOption('CSV', 'CSV', _selectedExportFormat == 'CSV'),
      ],
    );
  }

  Widget _buildExportFormatOption(String value, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _selectedExportFormat,
            onChanged: (value) {
              setState(() {
                _selectedExportFormat = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 7 days'),
              onTap: () {
                setState(() {
                  _selectedDateRange = 'Last 7 days';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Last 30 days'),
              onTap: () {
                setState(() {
                  _selectedDateRange = 'Last 30 days';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Last 3 months'),
              onTap: () {
                setState(() {
                  _selectedDateRange = 'Last 3 months';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Last 6 months'),
              onTap: () {
                setState(() {
                  _selectedDateRange = 'Last 6 months';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Last year'),
              onTap: () {
                setState(() {
                  _selectedDateRange = 'Last year';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Custom Range'),
              onTap: () {
                Navigator.pop(context);
                _showCustomDateRangeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDateRangeDialog() {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(startDate?.toString().split(' ')[0] ?? 'Select start date'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(endDate?.toString().split(' ')[0] ?? 'Select end date'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    endDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (startDate != null && endDate != null) {
                setState(() {
                  _selectedDateRange = '${startDate!.toString().split(' ')[0]} to ${endDate!.toString().split(' ')[0]}';
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSectionDataDialog(String section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure $section'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildSectionDataEditor(section),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDataEditor(String section) {
    final data = _sectionData[section]!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section == 'Student Profile Summary') ...[
            _buildBooleanEditor('Include Photo', 'includePhoto', data),
            _buildBooleanEditor('Include Contact', 'includeContact', data),
            _buildBooleanEditor('Include Academic', 'includeAcademic', data),
          ] else if (section == 'Overall Readiness Trend') ...[
            _buildDropdownEditor('Timeframe', 'timeframe', data, ['3 months', '6 months', '1 year']),
            _buildBooleanEditor('Include Graphs', 'includeGraphs', data),
            _buildBooleanEditor('Include Comparisons', 'includeComparisons', data),
          ] else if (section == 'Skill Graph Analysis') ...[
            _buildNumberEditor('Number of Skills', 'skills', data, 4),
            _buildBooleanEditor('Include Progress', 'includeProgress', data),
            _buildBooleanEditor('Include Recommendations', 'includeRecommendations', data),
          ] else if (section == 'Mock Interview Performance') ...[
            _buildNumberEditor('Number of Sessions', 'sessions', data, 5),
            _buildBooleanEditor('Include Feedback', 'includeFeedback', data),
            _buildBooleanEditor('Include Improvements', 'includeImprovements', data),
          ] else if (section == 'Resume Optimizer History') ...[
            _buildNumberEditor('Number of Versions', 'versions', data, 3),
            _buildBooleanEditor('Include Changes', 'includeChanges', data),
            _buildBooleanEditor('Include Score', 'includeScore', data),
          ] else if (section == 'Daily Skill Drill Activity') ...[
            _buildNumberEditor('Number of Days', 'days', data, 30),
            _buildBooleanEditor('Include Streaks', 'includeStreaks', data),
            _buildBooleanEditor('Include Achievements', 'includeAchievements', data),
          ],
        ],
      ),
    );
  }

  Widget _buildBooleanEditor(String label, String key, Map<String, dynamic> data) {
    return CheckboxListTile(
      title: Text(label),
      value: data[key] as bool,
      onChanged: (value) {
        setState(() {
          data[key] = value!;
        });
      },
    );
  }

  Widget _buildNumberEditor(String label, String key, Map<String, dynamic> data, int defaultValue) {
    return ListTile(
      title: Text(label),
      subtitle: Text('${data[key]}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (data[key] > 1) data[key] = data[key] - 1;
              });
            },
            icon: const Icon(Icons.remove),
          ),
          Text('${data[key]}'),
          IconButton(
            onPressed: () {
              setState(() {
                data[key] = data[key] + 1;
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownEditor(String label, String key, Map<String, dynamic> data, List<String> options) {
    return ListTile(
      title: Text(label),
      subtitle: Text(data[key]),
      trailing: DropdownButton<String>(
        value: data[key],
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: (value) {
          setState(() {
            data[key] = value!;
          });
        },
      ),
    );
  }

  void _generateReport() async {
    // Get selected sections
    List<String> selectedSections = _reportSections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedSections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one report section'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_reportNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a report name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate the actual file
      File? generatedFile;
      if (_selectedExportFormat == 'PDF') {
        generatedFile = await _generatePDFReport(selectedSections);
      } else {
        generatedFile = await _generateCSVReport(selectedSections);
      }

      setState(() {
        _isGenerating = false;
      });

      if (generatedFile != null) {
        _showDownloadDialog(generatedFile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate report'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDownloadDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Generated Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              file.path.split('/').last,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Size: ${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${file.path}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openFile(file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Open File'),
          ),
        ],
      ),
    );
  }

  Future<File?> _generatePDFReport(List<String> selectedSections) async {
    try {
      final pdf = pw.Document();
      
      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Progress Report - ${widget.student.name}',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Report Info
              pw.Text('Generated on: ${DateTime.now().toString().split(' ')[0]}'),
              pw.Text('Date Range: $_selectedDateRange'),
              pw.Text('Report Name: ${_reportNameController.text}'),
              pw.SizedBox(height: 20),
              
              // Student Information
              pw.Header(
                level: 1,
                child: pw.Text('Student Information'),
              ),
              pw.Text('Name: ${widget.student.name}'),
              pw.Text('College: ${widget.student.college}'),
              pw.Text('Status: ${widget.student.status}'),
              if (widget.student.email != null) pw.Text('Email: ${widget.student.email}'),
              if (widget.student.studentId != null) pw.Text('Student ID: ${widget.student.studentId}'),
              if (widget.student.branch != null) pw.Text('Course: ${widget.student.branch}'),
              if (widget.student.yearOfStudy != null) pw.Text('Year: ${widget.student.yearOfStudy}'),
              pw.SizedBox(height: 20),
              
              // Selected Sections
              pw.Header(
                level: 1,
                child: pw.Text('Report Sections'),
              ),
              ...selectedSections.map((section) => pw.Text('• $section')),
              pw.SizedBox(height: 20),
              
              // Section Details
              for (String section in selectedSections) ...[
                pw.Header(
                  level: 2,
                  child: pw.Text(section),
                ),
                _buildPDFSectionContent(section),
                pw.SizedBox(height: 15),
              ],
            ];
          },
        ),
      );

      // Get directory and create file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_reportNameController.text}.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Save PDF
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  Future<File?> _generateCSVReport(List<String> selectedSections) async {
    try {
      List<List<dynamic>> csvData = [];
      
      // Add headers
      csvData.add(['Field', 'Value']);
      csvData.add(['Report Name', _reportNameController.text]);
      csvData.add(['Student Name', widget.student.name]);
      csvData.add(['College', widget.student.college]);
      csvData.add(['Status', widget.student.status]);
      if (widget.student.email != null) csvData.add(['Email', widget.student.email!]);
      if (widget.student.studentId != null) csvData.add(['Student ID', widget.student.studentId!]);
      if (widget.student.branch != null) csvData.add(['Course', widget.student.branch!]);
      if (widget.student.yearOfStudy != null) csvData.add(['Year', widget.student.yearOfStudy!]);
      csvData.add(['Date Range', _selectedDateRange]);
      csvData.add(['Generated On', DateTime.now().toString()]);
      csvData.add(['', '']); // Empty row
      
      // Add section data
      for (String section in selectedSections) {
        csvData.add(['Section', section]);
        final data = _sectionData[section]!;
        
        for (String key in data.keys) {
          csvData.add([key, data[key].toString()]);
        }
        csvData.add(['', '']); // Empty row
      }
      
      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);
      
      // Get directory and create file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_reportNameController.text}.csv';
      final file = File('${directory.path}/$fileName');
      
      // Save CSV
      await file.writeAsString(csvString);
      
      return file;
    } catch (e) {
      print('Error generating CSV: $e');
      return null;
    }
  }

  pw.Widget _buildPDFSectionContent(String section) {
    final data = _sectionData[section]!;
    
    switch (section) {
      case 'Student Profile Summary':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Include Photo: ${data['includePhoto']}'),
            pw.Text('Include Contact: ${data['includeContact']}'),
            pw.Text('Include Academic: ${data['includeAcademic']}'),
          ],
        );
      case 'Overall Readiness Trend':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Timeframe: ${data['timeframe']}'),
            pw.Text('Include Graphs: ${data['includeGraphs']}'),
            pw.Text('Include Comparisons: ${data['includeComparisons']}'),
          ],
        );
      case 'Skill Graph Analysis':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Skills: ${(data['skills'] as List).join(', ')}'),
            pw.Text('Include Progress: ${data['includeProgress']}'),
            pw.Text('Include Recommendations: ${data['includeRecommendations']}'),
          ],
        );
      case 'Mock Interview Performance':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Sessions: ${data['sessions']}'),
            pw.Text('Include Feedback: ${data['includeFeedback']}'),
            pw.Text('Include Improvements: ${data['includeImprovements']}'),
          ],
        );
      case 'Resume Optimizer History':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Versions: ${data['versions']}'),
            pw.Text('Include Changes: ${data['includeChanges']}'),
            pw.Text('Include Score: ${data['includeScore']}'),
          ],
        );
      case 'Daily Skill Drill Activity':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Days: ${data['days']}'),
            pw.Text('Include Streaks: ${data['includeStreaks']}'),
            pw.Text('Include Achievements: ${data['includeAchievements']}'),
          ],
        );
      default:
        return pw.Text('No additional data available for this section.');
    }
  }

  void _openFile(File file) async {
    try {
      final result = await OpenFile.open(file.path);
      
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File opened successfully: ${file.path.split('/').last}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

