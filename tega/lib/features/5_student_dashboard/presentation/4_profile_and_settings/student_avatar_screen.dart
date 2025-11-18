import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/5_student_dashboard/presentation/shared/widgets/profile_picture_widget.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
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

  String _getFullName() {
    if (_profileData == null) return 'Student';
    final firstName = _profileData!['firstName'] ?? '';
    final lastName = _profileData!['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return _profileData!['studentName'] ?? 'Student';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Center avatar
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'avatarHero',
                  child: ProfilePictureWidget(
                    profilePhotoUrl: _profileData?['profilePhoto'],
                    username:
                        _profileData?['username'] ?? _profileData?['email'],
                    firstName: _profileData?['firstName'],
                    lastName: _profileData?['lastName'],
                    radius: 140,
                    showBorder: true,
                  ),
                ),
                const SizedBox(height: 30),
                if (!_isLoading)
                  Text(
                    _getFullName(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),

          // Back arrow button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context); // closes and returns to student home
              },
            ),
          ),
        ],
      ),
    );
  }
}
