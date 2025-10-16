import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tega/data/colleges_fallback.dart';
import 'package:tega/data/colleges_data.dart';

class CollegeInfo {
  final String id;
  final String name;

  CollegeInfo({required this.id, required this.name});

  factory CollegeInfo.fromJson(Map<String, dynamic> json) {
    return CollegeInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

// Your existing detailed classes
class College {
  final String id;
  final String name;
  final String city;
  final String state;
  final String address;
  final String status;
  final int totalStudents;
  final int dailyActiveStudents;
  final double avgSkillScore;
  final double avgInterviewPractices;
  final PrimaryAdmin primaryAdmin;
  final List<CollegeAdmin> admins;
  final List<Student> students;

  College({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.address,
    required this.status,
    required this.totalStudents,
    required this.dailyActiveStudents,
    required this.avgSkillScore,
    required this.avgInterviewPractices,
    required this.primaryAdmin,
    required this.admins,
    required this.students,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      state: json['state'],
      address: json['address'],
      status: json['status'],
      totalStudents: json['totalStudents'],
      dailyActiveStudents: json['dailyActiveStudents'],
      avgSkillScore: json['avgSkillScore'].toDouble(),
      avgInterviewPractices: json['avgInterviewPractices'].toDouble(),
      primaryAdmin: PrimaryAdmin.fromJson(json['primaryAdmin']),
      admins: (json['admins'] as List)
          .map((admin) => CollegeAdmin.fromJson(admin))
          .toList(),
      students: (json['students'] as List)
          .map((student) => Student.fromJson(student))
          .toList(),
    );
  }
}

class PrimaryAdmin {
  final String name;
  final String email;
  final String phone;

  PrimaryAdmin({required this.name, required this.email, required this.phone});

  factory PrimaryAdmin.fromJson(Map<String, dynamic> json) {
    return PrimaryAdmin(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class CollegeAdmin {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String role;

  CollegeAdmin({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.role,
  });

  factory CollegeAdmin.fromJson(Map<String, dynamic> json) {
    return CollegeAdmin(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      role: json['role'],
    );
  }
}

class Student {
  final String id;
  final String name;
  final String course;
  final int year;
  final String email;
  final String phone;
  final int skillScore;
  final int interviewPractices;

  Student({
    required this.id,
    required this.name,
    required this.course,
    required this.year,
    required this.email,
    required this.phone,
    required this.skillScore,
    required this.interviewPractices,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      course: json['course'],
      year: json['year'],
      email: json['email'],
      phone: json['phone'],
      skillScore: json['skillScore'],
      interviewPractices: json['interviewPractices'],
    );
  }

  get college => null;
  get status => null;
  static basic(String s, String t, String u) {}
}

class CollegeService {
  static final CollegeService _instance = CollegeService._internal();
  factory CollegeService() => _instance;
  CollegeService._internal();

  List<College> _colleges = [];
  Future<List<CollegeInfo>> fetchCollegeList() async {
    try {
      // Use the complete college data from the new data file
      // This data is sourced from backend src/data/colleges.js
      final colleges = collegesData
          .map((name) => CollegeInfo(id: name, name: name))
          .toList();

      return colleges;
    } catch (e) {
      // Fallback to the original fallback data if something goes wrong
      final fallback = fallbackColleges
          .map((name) => CollegeInfo(id: name, name: name))
          .toList();
      if (fallback.isNotEmpty) return fallback;
      throw Exception('Could not load college data');
    }
  }

  // Your existing methods for local data management are unchanged below
  Future<List<College>> loadColleges() async {
    try {
      final String response = await rootBundle.loadString(
        'lib/data/colleges_data.json',
      );
      final data = await json.decode(response);

      _colleges = (data['colleges'] as List)
          .map((college) => College.fromJson(college))
          .toList();

      return _colleges;
    } catch (e) {
      return [];
    }
  }

  List<College> getAllColleges() {
    return _colleges;
  }

  College? getCollegeById(String id) {
    try {
      return _colleges.firstWhere((college) => college.id == id);
    } catch (e) {
      return null;
    }
  }

  List<College> searchColleges(String query) {
    if (query.isEmpty) return _colleges;

    return _colleges.where((college) {
      return college.name.toLowerCase().contains(query.toLowerCase()) ||
          college.city.toLowerCase().contains(query.toLowerCase()) ||
          college.id.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<bool> addCollege(College college) async {
    try {
      _colleges.add(college);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCollege(College updatedCollege) async {
    try {
      final index = _colleges.indexWhere(
        (college) => college.id == updatedCollege.id,
      );
      if (index != -1) {
        _colleges[index] = updatedCollege;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCollege(String id) async {
    try {
      _colleges.removeWhere((college) => college.id == id);
      return true;
    } catch (e) {
      return false;
    }
  }

  List<CollegeAdmin> getCollegeAdmins(String collegeId) {
    final college = getCollegeById(collegeId);
    return college?.admins ?? [];
  }

  List<Student> getCollegeStudents(String collegeId) {
    final college = getCollegeById(collegeId);
    return college?.students ?? [];
  }

  Future<bool> addAdminToCollege(String collegeId, CollegeAdmin admin) async {
    try {
      final college = getCollegeById(collegeId);
      if (college != null) {
        final updatedAdmins = List<CollegeAdmin>.from(college.admins)
          ..add(admin);
        final updatedCollege = College(
          id: college.id,
          name: college.name,
          city: college.city,
          state: college.state,
          address: college.address,
          status: college.status,
          totalStudents: college.totalStudents,
          dailyActiveStudents: college.dailyActiveStudents,
          avgSkillScore: college.avgSkillScore,
          avgInterviewPractices: college.avgInterviewPractices,
          primaryAdmin: college.primaryAdmin,
          admins: updatedAdmins,
          students: college.students,
        );
        return await updateCollege(updatedCollege);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addStudentToCollege(String collegeId, Student student) async {
    try {
      final college = getCollegeById(collegeId);
      if (college != null) {
        final updatedStudents = List<Student>.from(college.students)
          ..add(student);
        final updatedCollege = College(
          id: college.id,
          name: college.name,
          city: college.city,
          state: college.state,
          address: college.address,
          status: college.status,
          totalStudents: college.totalStudents + 1,
          dailyActiveStudents: college.dailyActiveStudents,
          avgSkillScore: college.avgSkillScore,
          avgInterviewPractices: college.avgInterviewPractices,
          primaryAdmin: college.primaryAdmin,
          admins: college.admins,
          students: updatedStudents,
        );
        return await updateCollege(updatedCollege);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
