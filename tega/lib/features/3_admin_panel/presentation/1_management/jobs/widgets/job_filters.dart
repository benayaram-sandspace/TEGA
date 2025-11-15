import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class JobFilters extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String, String) onFilterChanged;
  final String selectedStatus;
  final String selectedType;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const JobFilters({
    super.key,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.selectedStatus,
    required this.selectedType,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  State<JobFilters> createState() => _JobFiltersState();
}

class _JobFiltersState extends State<JobFilters> {
  final TextEditingController _searchController = TextEditingController();

  final List<MapEntry<String, String>> _statusOptions = [
    const MapEntry('All Status', 'all'),
    const MapEntry('Open', 'open'),
    const MapEntry('Active', 'active'),
    const MapEntry('Expired', 'expired'),
    const MapEntry('Paused', 'paused'),
  ];

  final List<MapEntry<String, String>> _typeOptions = [
    const MapEntry('All Types', 'all'),
    const MapEntry('Jobs', 'job'),
    const MapEntry('Internships', 'internship'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: EdgeInsets.fromLTRB(
                widget.isMobile ? 12 : widget.isTablet ? 14 : 16,
                widget.isMobile ? 6 : widget.isTablet ? 7 : 8,
                widget.isMobile ? 12 : widget.isTablet ? 14 : 16,
                widget.isMobile ? 6 : widget.isTablet ? 7 : 8,
              ),
              padding: EdgeInsets.all(widget.isMobile ? 12 : widget.isTablet ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(widget.isMobile ? 10 : widget.isTablet ? 11 : 12),
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
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: widget.isMobile ? 13 : widget.isTablet ? 14 : 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search jobs, companies, or location...',
                      hintStyle: TextStyle(
                        fontSize: widget.isMobile ? 13 : widget.isTablet ? 14 : 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: widget.isMobile ? 18 : widget.isTablet ? 19 : 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: widget.isMobile ? 18 : widget.isTablet ? 19 : 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                                setState(() {});
                              },
                            )
                          : null,
                      border: _buildOutlineBorder(const Color(0xFFE2E8F0)),
                      enabledBorder: _buildOutlineBorder(
                        const Color(0xFFE2E8F0),
                      ),
                      focusedBorder: _buildOutlineBorder(
                        AdminDashboardStyles.primary,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FC),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: widget.isMobile ? 12 : widget.isTablet ? 13 : 14,
                        horizontal: widget.isMobile ? 14 : widget.isTablet ? 15 : 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      widget.onSearchChanged(value);
                    },
                  ),
                  SizedBox(height: widget.isMobile ? 12 : widget.isTablet ? 14 : 16),

                  // Filter Dropdowns in a Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFilter(
                          "Status",
                          _statusOptions,
                          widget.selectedStatus,
                          (value) {
                            if (value != null) {
                              widget.onFilterChanged(
                                value,
                                widget.selectedType,
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 10 : widget.isTablet ? 11 : 12),
                      Expanded(
                        child: _buildDropdownFilter(
                          "Type",
                          _typeOptions,
                          widget.selectedType,
                          (value) {
                            if (value != null) {
                              widget.onFilterChanged(
                                widget.selectedStatus,
                                value,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<MapEntry<String, String>> options,
    String selectedValue,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: const Color(0xFF4A5568),
          fontWeight: FontWeight.w500,
          fontSize: widget.isMobile ? 13 : widget.isTablet ? 13.5 : 14,
        ),
        border: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        enabledBorder: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        focusedBorder: _buildOutlineBorder(AdminDashboardStyles.primary),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        contentPadding: EdgeInsets.symmetric(
          vertical: widget.isMobile ? 14 : widget.isTablet ? 15 : 16,
          horizontal: widget.isMobile ? 14 : widget.isTablet ? 15 : 16,
        ),
        isDense: true,
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(
            option.key,
            style: TextStyle(
              fontSize: widget.isMobile ? 13 : widget.isTablet ? 13.5 : 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: const Color(0xFF718096),
        size: widget.isMobile ? 18 : widget.isTablet ? 19 : 20,
      ),
      style: TextStyle(
        fontSize: widget.isMobile ? 13 : widget.isTablet ? 13.5 : 14,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.isMobile ? 10 : widget.isTablet ? 11 : 12),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}
