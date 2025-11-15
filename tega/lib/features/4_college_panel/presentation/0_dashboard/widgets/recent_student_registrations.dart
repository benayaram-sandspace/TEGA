import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentRegistration {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? course;
  final String? year;
  final bool isActive;
  final DateTime createdAt;

  StudentRegistration({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.course,
    this.year,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return first + last;
  }
}

class RecentStudentRegistrations extends StatelessWidget {
  final List<StudentRegistration> students;

  const RecentStudentRegistrations({
    super.key,
    required this.students,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm:ss a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    final displayStudents = students.take(4).toList();
    final isScrollable = students.length > 4;

    // Responsive padding
    final padding = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
    final headerFontSize = isMobile ? 16.0 : isTablet ? 17.0 : 18.0;
    final badgeFontSize = isMobile ? 11.0 : isTablet ? 11.5 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
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
          // Header
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Student Registrations',
                    style: TextStyle(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${students.length} students${isScrollable ? ' (scrollable)' : ''}',
                      style: TextStyle(
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Student Cards
          if (displayStudents.isEmpty)
            Padding(
              padding: EdgeInsets.all(isMobile ? 32 : 40),
              child: Center(
                child: Text(
                  'No student registrations found',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: isMobile ? 6 : 8,
              ),
              child: Column(
                children: displayStudents.map((student) {
                  return Container(
                    margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                    padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Avatar, Name, Status
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 20 : isTablet ? 22 : 24,
                              backgroundColor: const Color(0xFF8B5CF6),
                              child: Text(
                                student.initials,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.fullName,
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isMobile ? 3 : 4),
                                  Text(
                                    student.email,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 10,
                                vertical: isMobile ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: student.isActive
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                student.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        // Bottom Row: Course, Year, Registration Date
                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Course', student.course ?? 'Not specified', isMobile),
                                  SizedBox(height: isMobile ? 8 : 10),
                                  _buildInfoRow('Year', student.year ?? 'Not specified', isMobile),
                                  SizedBox(height: isMobile ? 8 : 10),
                                  _buildDateInfo(student.createdAt, isMobile),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoColumn('Course', student.course ?? 'Not specified', isMobile, isTablet),
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: _buildInfoColumn('Year', student.year ?? 'Not specified', isMobile, isTablet),
                                    ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: _buildDateColumn(student.createdAt, isMobile, isTablet),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isMobile, bool isTablet) {
    return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
          label,
                                    style: TextStyle(
            fontSize: isMobile ? 10 : 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
        SizedBox(height: isMobile ? 3 : 4),
                                  Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                                      fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
    );
  }

  Widget _buildDateColumn(DateTime date, bool isMobile, bool isTablet) {
    return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registration Date',
                                    style: TextStyle(
            fontSize: isMobile ? 10 : 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
        SizedBox(height: isMobile ? 3 : 4),
                                  Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                                      fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
                                      height: 1.3,
                                    ),
                                  ),
        SizedBox(height: isMobile ? 1 : 2),
                                  Text(
          _formatTime(date),
                                    style: TextStyle(
            fontSize: isMobile ? 11 : 12,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                  ),
                                ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 100 : 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
                              ),
                            ),
                          ],
    );
  }

  Widget _buildDateInfo(DateTime date, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 100 : 120,
          child: Text(
            'Date:',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
                    ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 2),
              Text(
                _formatTime(date),
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey[600],
              ),
            ),
        ],
      ),
        ),
      ],
    );
  }
}

