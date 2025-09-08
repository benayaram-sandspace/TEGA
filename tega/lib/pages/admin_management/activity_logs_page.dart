import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  final AdminService _adminService = AdminService.instance;
  
  List<ActivityLog> _allLogs = [];
  List<ActivityLog> _filteredLogs = [];
  bool _isLoading = true;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedAdmin = '';
  String _selectedActionType = '';

  @override
  void initState() {
    super.initState();
    _loadActivityLogs();
  }

  Future<void> _loadActivityLogs() async {
    setState(() => _isLoading = true);
    
    await _adminService.loadData();
    _allLogs = _adminService.getAllActivityLogs();
    _filteredLogs = _allLogs;
    
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredLogs = _allLogs;
      
      // Apply date range filter
      if (_startDate != null && _endDate != null) {
        _filteredLogs = _adminService.getActivityLogsByDateRange(_startDate!, _endDate!);
      }
      
      // Apply admin filter
      if (_selectedAdmin.isNotEmpty) {
        _filteredLogs = _filteredLogs.where((log) => log.adminName == _selectedAdmin).toList();
      }
      
      // Apply action type filter
      if (_selectedActionType.isNotEmpty) {
        _filteredLogs = _filteredLogs.where((log) => log.actionType == _selectedActionType).toList();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedAdmin = '';
      _selectedActionType = '';
      _filteredLogs = _allLogs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Filters Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date Range Filters
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'Start Date',
                              _startDate,
                              (date) {
                                setState(() => _startDate = date);
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              'End Date',
                              _endDate,
                              (date) {
                                setState(() => _endDate = date);
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Admin and Action Type Filters
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              'Filter by Admin',
                              _selectedAdmin,
                              _getAdminNames(),
                              (value) {
                                setState(() => _selectedAdmin = value ?? '');
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterDropdown(
                              'Filter by Action Type',
                              _selectedActionType,
                              _adminService.getAvailableActionTypes(),
                              (value) {
                                setState(() => _selectedActionType = value ?? '');
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // Clear Filters Button
                      if (_startDate != null || _endDate != null || _selectedAdmin.isNotEmpty || _selectedActionType.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                            onPressed: _clearFilters,
                            child: const Text(
                              'Clear Filters',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Activity Log Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Expanded(
                          child: _filteredLogs.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 64,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No activity logs found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _filteredLogs.length,
                                  itemBuilder: (context, index) {
                                    final log = _filteredLogs[index];
                                    return _buildActivityLogCard(log);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, ValueChanged<DateTime?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Text(
              date != null ? _formatDate(date) : 'Select Date',
              style: TextStyle(
                color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              hint: Text(
                label,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLogCard(ActivityLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Admin Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateTime(log.timestamp),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                log.adminName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Action Details
          Text(
            'Target: ${log.target}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Action: ${log.action}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (log.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.details,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          
          // Action Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getActionTypeColor(log.actionType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatActionType(log.actionType),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getActionTypeColor(log.actionType),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getAdminNames() {
    return _allLogs.map((log) => log.adminName).toSet().toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatActionType(String actionType) {
    return actionType.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'user_management':
        return AppColors.info;
      case 'college_management':
        return AppColors.success;
      case 'content_management':
        return AppColors.warning;
      case 'analytics':
        return AppColors.primary;
      case 'admin_management':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
