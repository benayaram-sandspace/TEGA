import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/principal_dashboard_cache_service.dart';
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
  final PrincipalDashboardCacheService _cacheService =
      PrincipalDashboardCacheService();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
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

    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadStudents();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _cacheService.getStudentsData();
      if (cachedData != null && mounted) {
        setState(() {
          _isLoadingFromCache = true;
        });

        final students = _parseStudentsFromData(cachedData);
        if (mounted) {
          setState(() {
            _allStudents = students;
            _filteredStudents = students;
            _isLoading = false;
            _isLoadingFromCache = false;
          });
          _listAnimationController.forward();
        }
      }
    } catch (e) {
      // Silently handle cache errors
      if (mounted) {
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    }
  }

  List<Student> _parseStudentsFromData(List<dynamic> studentsList) {
    return studentsList.map((studentData) {
      final student = studentData as Map<String, dynamic>;
      final firstName = student['firstName'] as String? ?? '';
      final lastName = student['lastName'] as String? ?? '';
      final name = '$firstName $lastName'.trim();
      final yearOfStudy = student['yearOfStudy'] as int? ?? 12;
      final accountStatus = student['accountStatus'] as String? ?? 'pending';

      // Extract student ID from backend (custom studentId)
      final studentIdValue = student['studentId'];
      final studentId = studentIdValue != null
          ? studentIdValue.toString().trim()
          : '';

      // Extract MongoDB _id (ObjectId) - needed for API calls
      final mongoIdValue = student['_id'] ?? student['id'];
      final mongoId = mongoIdValue != null
          ? mongoIdValue.toString().trim()
          : '';

      // Extract email and phone from backend
      final email = student['email'] as String?;
      final phone =
          student['phone'] as String? ?? student['contactNumber'] as String?;

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
      final avatarUrl =
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=150&background=8B5CF6&color=fff';

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
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
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

  Future<void> _loadStudents({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && !_isLoadingFromCache && _allStudents.isNotEmpty) {
      _loadStudentsInBackground();
      return;
    }

    if (!_isLoadingFromCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(ApiEndpoints.principalStudents), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['students'] != null) {
          final studentsList = data['students'] as List<dynamic>;
          final students = _parseStudentsFromData(studentsList);

          if (mounted) {
            setState(() {
              _allStudents = students;
              _filteredStudents = students;
              _isLoading = false;
              _isLoadingFromCache = false;
            });

            // Cache the students data
            await _cacheService.setStudentsData(studentsList);

            _listAnimationController.forward();

            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load students';
              _isLoading = false;
              _isLoadingFromCache = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load students: ${response.statusCode}';
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getStudentsData();
        if (cachedData != null && mounted) {
          final students = _parseStudentsFromData(cachedData);
          setState(() {
            _allStudents = students;
            _filteredStudents = students;
            _isLoading = false;
            _isLoadingFromCache = false;
            _errorMessage = null;
          });
          _listAnimationController.forward();

          // Handle offline state
          _cacheService.handleOfflineState(context);
        } else {
          // No cache available
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = 'No internet connection';
            });

            // Handle offline state
            _cacheService.handleOfflineState(context);
          }
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _errorMessage = 'Error loading students: $e';
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    }
  }

  Future<void> _loadStudentsInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(ApiEndpoints.principalStudents), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['students'] != null) {
          final studentsList = data['students'] as List<dynamic>;
          final students = _parseStudentsFromData(studentsList);

          if (mounted) {
            setState(() {
              _allStudents = students;
              _filteredStudents = students;
            });

            // Cache the students data
            await _cacheService.setStudentsData(studentsList);

            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        }
      }
    } catch (e) {
      // Silently handle background errors
      if (_isNoInternetError(e)) {
        _cacheService.handleOfflineState(context);
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, size: isMobile ? 22 : 24),
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
          style: TextStyle(
            color: DashboardStyles.textDark,
            fontSize: isMobile
                ? 15
                : isTablet
                ? 15.5
                : 16,
          ),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
      );
    } else {
      return AppBar(
        title: Text(
          'Students',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile
                ? 18
                : isTablet
                ? 19
                : 20,
          ),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          _buildFilterMenu(isMobile, isTablet),
          IconButton(
            icon: Icon(Icons.search, size: isMobile ? 22 : 24),
            onPressed: _startSearch,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: _buildAppBar(),
      body: _isLoading && !_isLoadingFromCache
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _allStudents.isEmpty
          ? _buildErrorState(isMobile, isTablet)
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _filteredStudents.isEmpty
                  ? _buildEmptyState(isMobile, isTablet)
                  : _buildStudentList(isMobile, isTablet),
            ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile
              ? 24.0
              : isTablet
              ? 32.0
              : 40.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile
                  ? 56
                  : isTablet
                  ? 64
                  : 72,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'No internet connection',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            ElevatedButton.icon(
              onPressed: () => _loadStudents(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterMenu(bool isMobile, bool isTablet) {
    final filterOptions = ['All', 'approved', 'pending', 'rejected'];
    return Stack(
      alignment: Alignment.center,
      children: [
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list, size: isMobile ? 22 : 24),
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
                  choice == 'All'
                      ? 'All'
                      : choice[0].toUpperCase() + choice.substring(1),
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              );
            }).toList();
          },
        ),
        if (_selectedStatus != 'All')
          Positioned(
            top: isMobile ? 10 : 12,
            right: isMobile ? 10 : 12,
            child: Container(
              height: isMobile ? 7 : 8,
              width: isMobile ? 7 : 8,
              decoration: const BoxDecoration(
                color: DashboardStyles.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentList(bool isMobile, bool isTablet) {
    final padding = isMobile
        ? 12.0
        : isTablet
        ? 14.0
        : 16.0;
    return ListView.builder(
      key: ValueKey(_filteredStudents.length),
      padding: EdgeInsets.all(padding),
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
        return _buildAnimatedStudentTile(
          _filteredStudents[index],
          animation,
          isMobile,
          isTablet,
        );
      },
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile
              ? 24.0
              : isTablet
              ? 32.0
              : 40.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: isMobile
                  ? 64
                  : isTablet
                  ? 72
                  : 80,
              color: Colors.grey,
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'No Students Found',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Try adjusting your search or filter.',
              style: TextStyle(
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStudentTile(
    Student student,
    Animation<double> animation,
    bool isMobile,
    bool isTablet,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: _buildStudentTile(student, isMobile, isTablet),
      ),
    );
  }

  Widget _buildStudentTile(Student student, bool isMobile, bool isTablet) {
    // Responsive values
    final margin = isMobile
        ? 8.0
        : isTablet
        ? 10.0
        : 12.0;
    final borderRadius = isMobile
        ? 12.0
        : isTablet
        ? 14.0
        : 16.0;
    final avatarRadius = isMobile
        ? 20.0
        : isTablet
        ? 22.0
        : 24.0;
    final padding = isMobile
        ? 10.0
        : isTablet
        ? 11.0
        : 12.0;
    final nameFontSize = isMobile
        ? 14.0
        : isTablet
        ? 14.5
        : 15.0;
    final idFontSize = isMobile
        ? 12.0
        : isTablet
        ? 12.5
        : 13.0;
    final statusFontSize = isMobile
        ? 10.0
        : isTablet
        ? 10.5
        : 11.0;
    final statusPadding = isMobile
        ? 8.0
        : isTablet
        ? 9.0
        : 10.0;
    final statusVerticalPadding = isMobile
        ? 4.0
        : isTablet
        ? 4.5
        : 5.0;

    return Container(
      margin: EdgeInsets.only(bottom: margin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.cardBackground,
            Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.02)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: isMobile
                ? 12
                : isTablet
                ? 14
                : 15,
            offset: Offset(0, isMobile ? 3 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: isMobile ? 5 : 6,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: padding,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: avatarRadius,
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
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile
                                          ? 16
                                          : isTablet
                                          ? 18
                                          : 20,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: isMobile ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: nameFontSize,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isMobile ? 3 : 4),
                                Text(
                                  student.studentId ?? '',
                                  style: TextStyle(
                                    fontSize: idFontSize,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 6 : 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: statusPadding,
                              vertical: statusVerticalPadding,
                            ),
                            decoration: BoxDecoration(
                              color: student.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              student.status,
                              style: TextStyle(
                                color: student.statusColor,
                                fontSize: statusFontSize,
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
