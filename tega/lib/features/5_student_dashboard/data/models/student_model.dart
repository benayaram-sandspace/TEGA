class Student {
  final String? id; // Added for API identification
  final String name;
  final String college;
  final String status;
  final String? email;
  final String? studentId;
  final String? branch;
  final String? yearOfStudy;
  final double? cgpa;
  final double? percentage;
  final List<String>? interests;
  final double? jobReadiness;
  final String? profileImageUrl; // Added for profile image
  final int notificationCount; // Added for notifications
  final String? course; // Added to match your UI needs
  final String? year; // Added to match your UI needs

  Student({
    this.id,
    required this.name,
    required this.college,
    required this.status,
    this.email,
    this.studentId,
    this.branch,
    this.yearOfStudy,
    this.cgpa,
    this.percentage,
    this.interests,
    this.jobReadiness,
    this.profileImageUrl,
    this.notificationCount = 0,
    this.course,
    this.year,
  });

  // Factory constructor for basic student info
  factory Student.basic(String name, String college, String status) {
    return Student(name: name, college: college, status: status);
  }

  // Factory constructor for detailed student info
  factory Student.detailed({
    String? id,
    required String name,
    required String college,
    required String status,
    String? email,
    String? studentId,
    String? branch,
    String? yearOfStudy,
    double? cgpa,
    double? percentage,
    List<String>? interests,
    double? jobReadiness,
    String? profileImageUrl,
    int notificationCount = 0,
    String? course,
    String? year,
  }) {
    return Student(
      id: id,
      name: name,
      college: college,
      status: status,
      email: email,
      studentId: studentId,
      branch: branch,
      yearOfStudy: yearOfStudy,
      cgpa: cgpa,
      percentage: percentage,
      interests: interests,
      jobReadiness: jobReadiness,
      profileImageUrl: profileImageUrl,
      notificationCount: notificationCount,
      course: course,
      year: year,
    );
  }

  // Factory constructor from JSON (for API responses)
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      college: json['college'] ?? '',
      status: json['status'] ?? '',
      email: json['email'],
      studentId: json['student_id']?.toString(),
      branch: json['branch'],
      yearOfStudy: json['year_of_study']?.toString(),
      cgpa: json['cgpa']?.toDouble(),
      percentage: json['percentage']?.toDouble(),
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      jobReadiness: json['job_readiness']?.toDouble(),
      profileImageUrl: json['profile_image_url'],
      notificationCount: json['notification_count'] ?? 0,
      course:
          json['course'] ??
          '${json['branch'] ?? ''} | ${json['year_of_study'] ?? ''}',
      year: json['year'] ?? json['year_of_study'],
    );
  }

  // Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'college': college,
      'status': status,
      'email': email,
      'student_id': studentId,
      'branch': branch,
      'year_of_study': yearOfStudy,
      'cgpa': cgpa,
      'percentage': percentage,
      'interests': interests,
      'job_readiness': jobReadiness,
      'profile_image_url': profileImageUrl,
      'notification_count': notificationCount,
      'course': course,
      'year': year,
    };
  }

  // Copy with method for updating student data
  Student copyWith({
    String? id,
    String? name,
    String? college,
    String? status,
    String? email,
    String? studentId,
    String? branch,
    String? yearOfStudy,
    double? cgpa,
    double? percentage,
    List<String>? interests,
    double? jobReadiness,
    String? profileImageUrl,
    int? notificationCount,
    String? course,
    String? year,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      college: college ?? this.college,
      status: status ?? this.status,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      branch: branch ?? this.branch,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      cgpa: cgpa ?? this.cgpa,
      percentage: percentage ?? this.percentage,
      interests: interests ?? this.interests,
      jobReadiness: jobReadiness ?? this.jobReadiness,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      notificationCount: notificationCount ?? this.notificationCount,
      course: course ?? this.course,
      year: year ?? this.year,
    );
  }
}
