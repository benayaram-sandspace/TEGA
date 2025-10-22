class Offer {
  final String id;
  final String instituteName;
  final List<CourseOffer> courseOffers;
  final List<TegaExamOffer> tegaExamOffers;
  final DateTime validFrom;
  final DateTime validUntil;
  final String description;
  final int? maxStudents;
  final bool isActive;
  final String createdBy;
  final String? lastModifiedBy;
  final int studentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Offer({
    required this.id,
    required this.instituteName,
    required this.courseOffers,
    required this.tegaExamOffers,
    required this.validFrom,
    required this.validUntil,
    required this.description,
    this.maxStudents,
    required this.isActive,
    required this.createdBy,
    this.lastModifiedBy,
    required this.studentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['_id'] ?? json['id'],
      instituteName: json['instituteName'] ?? json['collegeName'] ?? '',
      courseOffers:
          (json['courseOffers'] as List<dynamic>?)
              ?.map((item) => CourseOffer.fromJson(item))
              .toList() ??
          [],
      tegaExamOffers:
          (json['tegaExamOffers'] as List<dynamic>?)
              ?.map((item) => TegaExamOffer.fromJson(item))
              .toList() ??
          [],
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'])
          : DateTime.now(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : DateTime.now().add(const Duration(days: 30)),
      description: json['description'] ?? '',
      maxStudents: json['maxStudents'],
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] ?? '',
      lastModifiedBy: json['lastModifiedBy'],
      studentCount: json['studentCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instituteName': instituteName,
      'courseOffers': courseOffers.map((offer) => offer.toJson()).toList(),
      'tegaExamOffers': tegaExamOffers.map((offer) => offer.toJson()).toList(),
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'description': description,
      'maxStudents': maxStudents,
      'isActive': isActive,
    };
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isActiveAndValid => isActive && !isExpired;
  int get totalOffers => courseOffers.length + tegaExamOffers.length;
  double get totalRevenue =>
      (courseOffers.fold(0.0, (sum, offer) => sum + offer.offerPrice) +
          tegaExamOffers.fold(0.0, (sum, offer) => sum + offer.offerPrice)) *
      studentCount;
}

class CourseOffer {
  final String courseId;
  final String courseName;
  final double originalPrice;
  final double offerPrice;
  final double discountPercentage;
  final String? courseTitle;

  CourseOffer({
    required this.courseId,
    required this.courseName,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercentage,
    this.courseTitle,
  });

  factory CourseOffer.fromJson(Map<String, dynamic> json) {
    return CourseOffer(
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      offerPrice: (json['offerPrice'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      courseTitle: json['courseTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'originalPrice': originalPrice,
      'offerPrice': offerPrice,
      'discountPercentage': discountPercentage,
      'courseTitle': courseTitle,
    };
  }
}

class TegaExamOffer {
  final String examId;
  final String examTitle;
  final double originalPrice;
  final double offerPrice;
  final double discountPercentage;

  TegaExamOffer({
    required this.examId,
    required this.examTitle,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercentage,
  });

  factory TegaExamOffer.fromJson(Map<String, dynamic> json) {
    return TegaExamOffer(
      examId: json['examId'] ?? '',
      examTitle: json['examTitle'] ?? '',
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      offerPrice: (json['offerPrice'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'examTitle': examTitle,
      'originalPrice': originalPrice,
      'offerPrice': offerPrice,
      'discountPercentage': discountPercentage,
    };
  }
}
