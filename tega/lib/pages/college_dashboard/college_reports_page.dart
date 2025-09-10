import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/services/college_service.dart';

class CollegeReportsPage extends StatefulWidget {
  final College college;

  const CollegeReportsPage({super.key, required this.college});

  @override
  State<CollegeReportsPage> createState() => _CollegeReportsPageState();
}

class _CollegeReportsPageState extends State<CollegeReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedReportType = 'Performance Report';
  String _selectedTimeframe = 'Last 30 Days';
  String _selectedFormat = 'PDF';

  final List<String> _reportTypes = [
    'Performance Report',
    'Engagement Report',
    'Progress Report',
    'Student Summary',
    'Custom Report',
  ];

  final List<String> _timeframes = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
    'Custom Range',
  ];

  final List<String> _formats = [
    'PDF',
    'Excel',
    'CSV',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGenerateReportTab(),
                _buildReportHistoryTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports & Insights',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate comprehensive reports and gain insights into student performance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Generate Report'),
          Tab(text: 'Report History'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildGenerateReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Report Cards
          _buildQuickReportCards(),
          const SizedBox(height: 24),
          
          // Custom Report Builder
          _buildCustomReportBuilder(),
          const SizedBox(height: 24),
          
          // Report Templates
          _buildReportTemplates(),
        ],
      ),
    );
  }

  Widget _buildReportHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report History List
          _buildReportHistoryList(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Insights
          _buildKeyInsights(),
          const SizedBox(height: 24),
          
          // Performance Trends
          _buildPerformanceTrends(),
          const SizedBox(height: 24),
          
          // Recommendations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildQuickReportCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickReportCard(
                'Student Performance',
                'Comprehensive performance analysis',
                Icons.analytics,
                AppColors.primary,
                () => _generateQuickReport('performance'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickReportCard(
                'Engagement Report',
                'Student engagement metrics',
                Icons.people,
                AppColors.info,
                () => _generateQuickReport('engagement'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickReportCard(
                'Progress Summary',
                'Overall progress overview',
                Icons.trending_up,
                AppColors.success,
                () => _generateQuickReport('progress'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickReportCard(
                'Custom Report',
                'Build your own report',
                Icons.build,
                AppColors.warning,
                () => _showCustomReportBuilder(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomReportBuilder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Report Builder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Report Type
          _buildDropdownField(
            'Report Type',
            _selectedReportType,
            _reportTypes,
            (value) => setState(() => _selectedReportType = value!),
          ),
          const SizedBox(height: 16),
          
          // Timeframe
          _buildDropdownField(
            'Timeframe',
            _selectedTimeframe,
            _timeframes,
            (value) => setState(() => _selectedTimeframe = value!),
          ),
          const SizedBox(height: 16),
          
          // Format
          _buildDropdownField(
            'Export Format',
            _selectedFormat,
            _formats,
            (value) => setState(() => _selectedFormat = value!),
          ),
          const SizedBox(height: 24),
          
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateCustomReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Generate Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isExpanded: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildReportTemplates() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Templates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._getReportTemplates().map((template) => _buildTemplateItem(template)),
        ],
      ),
    );
  }

  Widget _buildTemplateItem(Map<String, dynamic> template) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: template['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              template['icon'],
              color: template['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  template['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _useTemplate(template),
            child: const Text('Use Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._getReportHistory().map((report) => _buildReportHistoryItem(report)),
      ],
    );
  }

  Widget _buildReportHistoryItem(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Generated on ${report['date']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _downloadReport(report),
                icon: const Icon(Icons.download, color: AppColors.primary),
                tooltip: 'Download',
              ),
              IconButton(
                onPressed: () => _shareReport(report),
                icon: const Icon(Icons.share, color: AppColors.info),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._getKeyInsights().map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: insight['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'],
              color: insight['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  insight['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTrendCard(
                  'Average Score',
                  '${_getAverageScore()}%',
                  '+5%',
                  AppColors.success,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendCard(
                  'Completion Rate',
                  '${_getCompletionRate()}%',
                  '+12%',
                  AppColors.info,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendCard(
                  'Engagement',
                  '${_getEngagementRate()}%',
                  '+8%',
                  AppColors.warning,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendCard(
                  'Satisfaction',
                  '${_getSatisfactionRate()}%',
                  '+3%',
                  AppColors.primary,
                  Icons.sentiment_satisfied,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    String title,
    String value,
    String change,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._getRecommendations().map((recommendation) => _buildRecommendationItem(recommendation)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: recommendation['priority'] == 'High' ? AppColors.error :
                     recommendation['priority'] == 'Medium' ? AppColors.warning : AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  recommendation['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: recommendation['priority'] == 'High' ? AppColors.error.withOpacity(0.1) :
                     recommendation['priority'] == 'Medium' ? AppColors.warning.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: recommendation['priority'] == 'High' ? AppColors.error :
                       recommendation['priority'] == 'Medium' ? AppColors.warning : AppColors.success,
                width: 0.5,
              ),
            ),
            child: Text(
              recommendation['priority'],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: recommendation['priority'] == 'High' ? AppColors.error :
                       recommendation['priority'] == 'Medium' ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _generateQuickReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $type report...'),
        backgroundColor: AppColors.primary,
      ),
    );
    // TODO: Implement report generation
  }

  void _showCustomReportBuilder() {
    // This is already shown in the custom report builder section
  }

  void _generateCustomReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating custom report: $_selectedReportType'),
        backgroundColor: AppColors.primary,
      ),
    );
    // TODO: Implement custom report generation
  }

  void _useTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Using template: ${template['title']}'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Implement template usage
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${report['title']}...'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implement report download
  }

  void _shareReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${report['title']}...'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Implement report sharing
  }

  // Helper methods
  List<Map<String, dynamic>> _getReportTemplates() {
    return [
      {
        'title': 'Monthly Performance Summary',
        'description': 'Comprehensive monthly performance overview',
        'icon': Icons.calendar_month,
        'color': AppColors.primary,
      },
      {
        'title': 'Student Progress Report',
        'description': 'Individual student progress tracking',
        'icon': Icons.person,
        'color': AppColors.info,
      },
      {
        'title': 'Engagement Analysis',
        'description': 'Student engagement metrics and trends',
        'icon': Icons.analytics,
        'color': AppColors.success,
      },
    ];
  }

  List<Map<String, dynamic>> _getReportHistory() {
    return [
      {
        'title': 'Performance Report - December 2024',
        'date': 'Dec 15, 2024',
      },
      {
        'title': 'Engagement Report - November 2024',
        'date': 'Nov 30, 2024',
      },
      {
        'title': 'Student Summary - Q3 2024',
        'date': 'Oct 15, 2024',
      },
    ];
  }

  List<Map<String, dynamic>> _getKeyInsights() {
    return [
      {
        'title': 'Performance Improvement',
        'description': 'Average student performance has increased by 15% this month',
        'icon': Icons.trending_up,
        'color': AppColors.success,
      },
      {
        'title': 'Engagement Peak',
        'description': 'Student engagement is highest on Tuesday and Wednesday mornings',
        'icon': Icons.schedule,
        'color': AppColors.info,
      },
      {
        'title': 'Support Needed',
        'description': '12 students need additional support in communication skills',
        'icon': Icons.support_agent,
        'color': AppColors.warning,
      },
    ];
  }

  List<Map<String, dynamic>> _getRecommendations() {
    return [
      {
        'title': 'Increase Communication Skills Training',
        'description': 'Focus on students with low communication scores',
        'priority': 'High',
      },
      {
        'title': 'Schedule More Morning Sessions',
        'description': 'Take advantage of higher engagement during morning hours',
        'priority': 'Medium',
      },
      {
        'title': 'Implement Peer Learning Groups',
        'description': 'Create study groups for better collaboration',
        'priority': 'Low',
      },
    ];
  }

  int _getAverageScore() {
    if (widget.college.students.isEmpty) return 0;
    final totalScore = widget.college.students.fold<int>(
      0,
      (sum, student) => sum + student.skillScore,
    );
    return (totalScore / widget.college.students.length).round();
  }

  int _getCompletionRate() {
    if (widget.college.students.isEmpty) return 0;
    final completedStudents = widget.college.students.where((student) => student.skillScore >= 70).length;
    return ((completedStudents / widget.college.students.length) * 100).round();
  }

  int _getEngagementRate() {
    // Simulate engagement rate
    return 78;
  }

  int _getSatisfactionRate() {
    // Simulate satisfaction rate
    return 85;
  }
}
