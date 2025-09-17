// lib/pages/college_screens/students/models/student_model.dart

class Student {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String studentId;
  final String course;
  final String batch;
  final String department;
  final DateTime dateOfBirth;
  final String gender;
  final String address;
  final String guardianName;
  final String guardianPhone;
  final String? profileImage;
  final DateTime enrollmentDate;
  final String status;

  Student({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.studentId,
    required this.course,
    required this.batch,
    required this.department,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.guardianName,
    required this.guardianPhone,
    this.profileImage,
    required this.enrollmentDate,
    this.status = 'Active',
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'studentId': studentId,
      'course': course,
      'batch': batch,
      'department': department,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'address': address,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'profileImage': profileImage,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'status': status,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      studentId: json['studentId'] ?? '',
      course: json['course'] ?? '',
      batch: json['batch'] ?? '',
      department: json['department'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      guardianName: json['guardianName'] ?? '',
      guardianPhone: json['guardianPhone'] ?? '',
      profileImage: json['profileImage'],
      enrollmentDate: DateTime.parse(json['enrollmentDate']),
      status: json['status'] ?? 'Active',
    );
  }

  // For CSV import
  factory Student.fromCsv(List<String> row) {
    // Assuming CSV columns: FirstName, LastName, Email, Phone, StudentID, Course, Batch, Department, DOB, Gender, Address, GuardianName, GuardianPhone
    return Student(
      firstName: row[0],
      lastName: row[1],
      email: row[2],
      phone: row[3],
      studentId: row[4],
      course: row[5],
      batch: row[6],
      department: row[7],
      dateOfBirth: DateTime.parse(row[8]),
      gender: row[9],
      address: row[10],
      guardianName: row[11],
      guardianPhone: row[12],
      enrollmentDate: DateTime.now(),
      status: 'Active',
    );
  }
}
