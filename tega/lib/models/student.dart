class Student {
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

  Student({
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
  });

  // Factory constructor for basic student info
  factory Student.basic(String name, String college, String status) {
    return Student(
      name: name,
      college: college,
      status: status,
    );
  }

  // Factory constructor for detailed student info
  factory Student.detailed({
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
  }) {
    return Student(
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
    );
  }
}

