import 'package:flutter/material.dart';

class JobFilters extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String, String) onFilterChanged;
  final String selectedStatus;
  final String selectedType;

  const JobFilters({
    super.key,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.selectedStatus,
    required this.selectedType,
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
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs, companies, or location...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
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
                        const Color(0xFF6B5FFF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FC),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      widget.onSearchChanged(value);
                    },
                  ),
                  const SizedBox(height: 16),

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
                      const SizedBox(width: 12),
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
        labelStyle: const TextStyle(
          color: Color(0xFF4A5568),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        border: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        enabledBorder: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        focusedBorder: _buildOutlineBorder(const Color(0xFF6B5FFF)),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        isDense: true,
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(
            option.key,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFF718096),
        size: 20,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2D3748),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}
