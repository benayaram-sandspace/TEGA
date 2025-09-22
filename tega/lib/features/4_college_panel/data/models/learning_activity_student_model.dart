import 'package:flutter/material.dart';

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
