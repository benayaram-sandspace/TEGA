enum TemplateCategory {
  professional,
  creative,
  modern,
  classic,
  minimalist,
  executive,
}

enum TemplateColorScheme { purple, blue, green, orange, red, gray, black }

class TemplateMetadata {
  final String id;
  final String name;
  final String description;
  final TemplateCategory category;
  final TemplateColorScheme colorScheme;
  final String previewImage;
  final List<String> features;
  final bool isPremium;
  final double rating;
  final int downloads;

  const TemplateMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.colorScheme,
    required this.previewImage,
    required this.features,
    this.isPremium = false,
    this.rating = 4.5,
    this.downloads = 0,
  });
}

class ResumeData {
  // Personal Information
  String fullName;
  String title;
  String email;
  String phone;
  String location;
  String linkedin;
  String website;
  String summary;

  // Experience
  List<WorkExperience> experiences;

  // Education
  List<Education> educations;

  // Skills
  List<String> skills;

  // Projects
  List<Project> projects;

  // Certifications
  List<Certification> certifications;

  // Languages
  List<String> languages;

  // Additional Info
  List<String> interests;
  List<String> achievements;

  ResumeData({
    this.fullName = '',
    this.title = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.website = '',
    this.summary = '',
    this.experiences = const [],
    this.educations = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.languages = const [],
    this.interests = const [],
    this.achievements = const [],
  });

  ResumeData copyWith({
    String? fullName,
    String? title,
    String? email,
    String? phone,
    String? location,
    String? linkedin,
    String? website,
    String? summary,
    List<WorkExperience>? experiences,
    List<Education>? educations,
    List<String>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
    List<String>? languages,
    List<String>? interests,
    List<String>? achievements,
  }) {
    return ResumeData(
      fullName: fullName ?? this.fullName,
      title: title ?? this.title,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
      summary: summary ?? this.summary,
      experiences: experiences ?? this.experiences,
      educations: educations ?? this.educations,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      achievements: achievements ?? this.achievements,
    );
  }

  bool get isEmpty {
    return fullName.isEmpty &&
        email.isEmpty &&
        phone.isEmpty &&
        location.isEmpty &&
        linkedin.isEmpty &&
        website.isEmpty &&
        summary.isEmpty &&
        experiences.isEmpty &&
        educations.isEmpty &&
        skills.isEmpty &&
        projects.isEmpty &&
        certifications.isEmpty &&
        languages.isEmpty &&
        interests.isEmpty &&
        achievements.isEmpty;
  }

  int get completionPercentage {
    int filled = 0;
    const int total = 10;

    if (fullName.isNotEmpty) filled++;
    if (email.isNotEmpty) filled++;
    if (phone.isNotEmpty) filled++;
    if (summary.isNotEmpty) filled++;
    if (experiences.isNotEmpty) filled++;
    if (educations.isNotEmpty) filled++;
    if (skills.isNotEmpty) filled++;
    if (projects.isNotEmpty) filled++;
    if (certifications.isNotEmpty) filled++;
    if (languages.isNotEmpty) filled++;

    return (filled / total * 100).round();
  }
}

class WorkExperience {
  final String company;
  final String position;
  final String location;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final String description;
  final List<String> achievements;

  const WorkExperience({
    required this.company,
    required this.position,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    this.description = '',
    this.achievements = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'description': description,
      'achievements': achievements,
    };
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      isCurrent: json['isCurrent'] ?? false,
      description: json['description'] ?? '',
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }
}

class Education {
  final String degree;
  final String institution;
  final String location;
  final String startDate;
  final String endDate;
  final String gpa;
  final String description;

  const Education({
    required this.degree,
    required this.institution,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.gpa = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'gpa': gpa,
      'description': description,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'] ?? '',
      institution: json['institution'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      gpa: json['gpa'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Project {
  final String name;
  final String description;
  final String technologies;
  final String startDate;
  final String endDate;
  final String url;
  final String github;

  const Project({
    required this.name,
    required this.description,
    required this.technologies,
    required this.startDate,
    required this.endDate,
    this.url = '',
    this.github = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'technologies': technologies,
      'startDate': startDate,
      'endDate': endDate,
      'url': url,
      'github': github,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      technologies: json['technologies'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      url: json['url'] ?? '',
      github: json['github'] ?? '',
    );
  }
}

class Certification {
  final String name;
  final String issuer;
  final String date;
  final String credentialId;
  final String url;

  const Certification({
    required this.name,
    required this.issuer,
    required this.date,
    this.credentialId = '',
    this.url = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'date': date,
      'credentialId': credentialId,
      'url': url,
    };
  }

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      date: json['date'] ?? '',
      credentialId: json['credentialId'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
