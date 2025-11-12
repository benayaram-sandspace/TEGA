import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/tabs/student_details_tab.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final AuthService _authService = AuthService();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isSearching = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
          _filterStudents();
        });
      }
    });

    _loadStudents();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    
    // Handle MongoDB date objects that might come as Map
    if (dateValue is Map) {
      // MongoDB date might be in format: {"$date": "2024-01-01T00:00:00.000Z"}
      if (dateValue.containsKey('\$date')) {
        final dateStr = dateValue['\$date'];
        if (dateStr is String) {
          try {
            return DateTime.parse(dateStr);
          } catch (e) {
            return DateTime.now();
          }
        } else if (dateStr is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateStr);
        }
      }
      // Try to find any date-like field
      for (var key in ['date', 'Date', 'timestamp', 'Timestamp']) {
        if (dateValue.containsKey(key)) {
          return _parseDateTime(dateValue[key]);
        }
      }
    }
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        // Try parsing as ISO 8601 with timezone
        try {
          return DateTime.parse(dateValue.replaceAll('Z', '+00:00'));
        } catch (e2) {
          return DateTime.now();
        }
      }
    }
    
    if (dateValue is int) {
      // Handle Unix timestamp (milliseconds or seconds)
      if (dateValue > 1000000000000) {
        // Milliseconds
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        // Seconds
        return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      }
    }
    
    return DateTime.now();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.principalStudents),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['students'] != null) {
          final studentsList = data['students'] as List<dynamic>;
          final students = studentsList.map((studentData) {
            final student = studentData as Map<String, dynamic>;
            final firstName = student['firstName'] as String? ?? '';
            final lastName = student['lastName'] as String? ?? '';
            final name = '$firstName $lastName'.trim();
            final yearOfStudy = student['yearOfStudy'] as int? ?? 12;
            final accountStatus = student['accountStatus'] as String? ?? 'pending';
            
            // Extract student ID from backend (custom studentId)
            final studentIdValue = student['studentId'];
            final studentId = studentIdValue != null ? studentIdValue.toString().trim() : '';
            
            // Extract MongoDB _id (ObjectId) - needed for API calls
            final mongoIdValue = student['_id'] ?? student['id'];
            final mongoId = mongoIdValue != null ? mongoIdValue.toString().trim() : '';
            
            // Extract email and phone from backend
            final email = student['email'] as String?;
            final phone = student['phone'] as String? ?? student['contactNumber'] as String?;
            
            // Parse registration date
            DateTime? registeredAt;
            try {
              final createdAtValue = student['createdAt'];
              if (createdAtValue != null) {
                registeredAt = _parseDateTime(createdAtValue);
              }
            } catch (e) {
              registeredAt = null;
            }
            
            // Get status color based on accountStatus
            final statusMap = _getStatusFromBackend(accountStatus);
            
            // Generate avatar URL from name
            final avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=150&background=8B5CF6&color=fff';
            
            return Student(
              name: name,
              grade: yearOfStudy,
              gpa: 3.5, // Default GPA, can be updated later if available from backend
              avatarUrl: avatarUrl,
              status: accountStatus.isEmpty ? 'pending' : accountStatus,
              statusColor: statusMap['color'] as Color,
              studentId: studentId,
              id: mongoId, // MongoDB _id for API calls
              registeredAt: registeredAt,
              email: email,
              phone: phone,
            );
          }).toList();

          setState(() {
            _allStudents = students;
            _filteredStudents = students;
            _isLoading = false;
          });
          
          _listAnimationController.forward();
        } else {
          setState(() {
            _errorMessage = 'Failed to load students';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load students: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading students: $e';
        _isLoading = false;
      });
    }
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return first + last;
  }

  Map<String, dynamic> _getStatusFromBackend(String accountStatus) {
    // Map backend accountStatus to color
    switch (accountStatus.toLowerCase()) {
      case 'approved':
        return {'color': DashboardStyles.accentGreen};
      case 'pending':
        return {'color': DashboardStyles.accentOrange};
      case 'rejected':
        return {'color': Colors.red};
      default:
        return {'color': DashboardStyles.primary};
    }
  }

  void _filterStudents() {
    List<Student> results = _allStudents;
    if (_searchQuery.isNotEmpty) {
      results = results
          .where(
            (student) =>
                student.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedStatus != 'All') {
      results = results
          .where((student) => student.status == _selectedStatus)
          .toList();
    }
    setState(() {
      _filteredStudents = results;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _filterStudents();
    });
    _searchFocusNode.unfocus();
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopSearch,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search students...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: DashboardStyles.textDark, fontSize: 16),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
      );
    } else {
      return AppBar(
        title: const Text(
          'Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          _buildFilterMenu(),
          IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : _buildStudentList(),
                ),
    );
  }

  Widget _buildFilterMenu() {
    final filterOptions = ['All', 'approved', 'pending', 'rejected'];
    return Stack(
      alignment: Alignment.center,
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (String status) {
            setState(() {
              _selectedStatus = status;
              _filterStudents();
            });
          },
          itemBuilder: (BuildContext context) {
            return filterOptions.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(
                  choice == 'All' ? 'All' : choice[0].toUpperCase() + choice.substring(1),
                ),
              );
            }).toList();
          },
        ),
        if (_selectedStatus != 'All')
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: DashboardStyles.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      key: ValueKey(_filteredStudents.length),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final animation = CurvedAnimation(
          parent: _listAnimationController,
          curve: Interval(
            (0.1 * index).clamp(0.0, 1.0),
            (0.5 + 0.1 * index).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        return _buildAnimatedStudentTile(_filteredStudents[index], animation);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Students Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStudentTile(
    Student student,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: _buildStudentTile(student),
      ),
    );
  }

  Widget _buildStudentTile(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.cardBackground,
            Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.02)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(color: student.statusColor),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentDetailsPage(student: student),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: NetworkImage(student.avatarUrl),
                            onBackgroundImageError: (_, __) {},
                            child: student.avatarUrl.isEmpty
                                ? Text(
                                    _getInitials(
                                      student.name.split(' ').isNotEmpty
                                          ? student.name.split(' ')[0]
                                          : '',
                                      student.name.split(' ').length > 1
                                          ? student.name.split(' ')[1]
                                          : '',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.studentId ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: student.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              student.status,
                              style: TextStyle(
                                color: student.statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
