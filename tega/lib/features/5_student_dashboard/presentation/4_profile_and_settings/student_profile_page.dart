import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';
import 'package:tega/core/constants/api_constants.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _profileData = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => StudentHomePage()),
              );
            },
          ),
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileInfo(),
                const SizedBox(height: 24),
                _buildProfileSections(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor: const Color(0xFF6B5FFF),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B5FFF), Color(0xFF4A47A3)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildProfileAvatar(),
                  const SizedBox(height: 16),
                  Text(
                    _getFullName(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _getAcademicInfo(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.email,
            'Email',
            _profileData?['email'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.phone,
            'Phone',
            _profileData?['phone'] ??
                _profileData?['contactNumber'] ??
                'Not provided',
          ),
          _buildInfoRow(
            Icons.badge,
            'Student ID',
            _profileData?['studentId'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.cake,
            'Date of Birth',
            _getFormattedDate(_profileData?['dob']),
          ),
          _buildInfoRow(
            Icons.person_outline,
            'Gender',
            _profileData?['gender'] ?? 'Not specified',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: [
        _buildSectionCard('Academic Details', Icons.school, [
          _buildInfoRow(
            Icons.account_balance,
            'Institute',
            _profileData?['institute'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.menu_book,
            'Course',
            _profileData?['course'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.trending_up,
            'Major',
            _profileData?['major'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.calendar_today,
            'Year of Study',
            _profileData?['yearOfStudy']?.toString() ?? 'Not specified',
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard('Address Information', Icons.location_on, [
          _buildInfoRow(
            Icons.home,
            'Address',
            _profileData?['address'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.place,
            'Landmark',
            _profileData?['landmark'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.location_city,
            'City',
            _profileData?['city'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.map,
            'District',
            _profileData?['district'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.pin_drop,
            'ZIP Code',
            _profileData?['zipcode'] ?? 'Not provided',
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard('Professional Information', Icons.work, [
          _buildInfoRow(
            Icons.title,
            'Title',
            _profileData?['title'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.description,
            'Summary',
            _profileData?['summary'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.link,
            'LinkedIn',
            _profileData?['linkedin'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.web,
            'Website',
            _profileData?['website'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.code,
            'GitHub',
            _profileData?['github'] ?? 'Not provided',
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6B5FFF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFullName() {
    final firstName = _profileData?['firstName'] ?? '';
    final lastName = _profileData?['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return _profileData?['studentName'] ?? 'Student';
    }
  }

  String _getAcademicInfo() {
    final course = _profileData?['course'] ?? '';
    final year = _profileData?['yearOfStudy']?.toString() ?? '';
    final institute = _profileData?['institute'] ?? '';

    List<String> info = [];
    if (course.isNotEmpty) info.add(course);
    if (year.isNotEmpty) info.add('Year $year');
    if (institute.isNotEmpty) info.add(institute);

    return info.isNotEmpty
        ? info.join(' • ')
        : 'Academic information not provided';
  }

  String _getFormattedDate(dynamic date) {
    if (date == null) return 'Not provided';
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildProfileAvatar() {
    final profilePhoto = _profileData?['profilePhoto'];
    final username = _profileData?['username'] ?? _profileData?['email'] ?? 'U';
    final initials = _getInitials(username);

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF6B5FFF),
          backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
              ? NetworkImage(profilePhoto)
              : null,
          child: profilePhoto == null || profilePhoto.isEmpty
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile photo upload coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6B5FFF), width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Color(0xFF6B5FFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String username) {
    if (username.isEmpty) return 'U';

    // Extract name from email if it's an email
    String name = username;
    if (username.contains('@')) {
      name = username.split('@')[0];
    }

    // Split by common separators and get first two words
    final words = name
        .split(RegExp(r'[._\s]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    // Return first letter of first two words
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }
}
