class Principal {
  final String id;
  final String principalName;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String university;
  final bool isActive;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Principal({
    required this.id,
    required this.principalName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.university,
    required this.isActive,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  // Getter for full name
  String get name =>
      principalName.isNotEmpty ? principalName : '$firstName $lastName'.trim();

  // Getter for display name (first name + last name)
  String get displayName => '$firstName $lastName'.trim();

  // Getter for status
  String get status => isActive ? 'Active' : 'Inactive';

  // Getter for college (using university field)
  String get college => university;

  factory Principal.fromJson(Map<String, dynamic> json) {
    return Principal(
      id: json['_id'] ?? json['id'] ?? '',
      principalName: json['principalName'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      university: json['university'] ?? '',
      isActive: json['isActive'] ?? true,
      role: json['role'] ?? 'principal',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'principalName': principalName,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'gender': gender,
      'university': university,
      'isActive': isActive,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Principal copyWith({
    String? id,
    String? principalName,
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    String? university,
    bool? isActive,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Principal(
      id: id ?? this.id,
      principalName: principalName ?? this.principalName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      university: university ?? this.university,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Principal(id: $id, name: $name, email: $email, university: $university, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Principal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
