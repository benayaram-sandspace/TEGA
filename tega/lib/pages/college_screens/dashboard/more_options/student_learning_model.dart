import 'package:flutter/material.dart';

// class Student {
//   final String name;
//   final int grade;
//   final double gpa;
//   final String avatarUrl;
//   final String status;
//   final Color statusColor;

//   const Student({
//     required this.name,
//     required this.grade,
//     required this.gpa,
//     required this.avatarUrl,
//     required this.status,
//     required this.statusColor,
//   });
// }

class Activity {
  final String title;
  final String type;
  final String studentName;
  final String studentAvatarUrl;
  final String timestamp;
  final IconData icon;
  final Color color;

  const Activity({
    required this.title,
    required this.type,
    required this.studentName,
    required this.studentAvatarUrl,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
