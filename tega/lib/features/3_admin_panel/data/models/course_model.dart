import 'package:flutter/foundation.dart';

@immutable
class Course {
  final String? id;
  final String title;
  final String description;
  final String? shortDescription;
  final String? thumbnail;
  final String? banner;
  final String? previewVideo;
  final CourseInstructor instructor;
  final double price;
  final double? originalPrice;
  final String currency;
  final bool isFree;
  final String level;
  final String category;
  final List<String> tags;
  final CourseDuration estimatedDuration;
  final int totalLectures;
  final int totalQuizzes;
  final int totalMaterials;
  final List<CourseModule>? modules;
  final bool isLive;
  final String? liveStreamUrl;
  final DateTime? nextLiveSession;
  final int liveViewers;
  final String status;
  final DateTime? publishedAt;
  final String slug;
  final String? metaDescription;
  final List<String> keywords;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? enrollmentCount;

  const Course({
    this.id,
    required this.title,
    required this.description,
    this.shortDescription,
    this.thumbnail,
    this.banner,
    this.previewVideo,
    required this.instructor,
    required this.price,
    this.originalPrice,
    this.currency = 'INR',
    this.isFree = false,
    required this.level,
    required this.category,
    this.tags = const [],
    required this.estimatedDuration,
    this.totalLectures = 0,
    this.totalQuizzes = 0,
    this.totalMaterials = 0,
    this.modules,
    this.isLive = false,
    this.liveStreamUrl,
    this.nextLiveSession,
    this.liveViewers = 0,
    this.status = 'draft',
    this.publishedAt,
    required this.slug,
    this.metaDescription,
    this.keywords = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.enrollmentCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      shortDescription: json['shortDescription'] as String?,
      thumbnail: json['thumbnail'] as String?,
      banner: json['banner'] as String?,
      previewVideo: json['previewVideo'] as String?,
      instructor: CourseInstructor.fromJson(
        json['instructor'] as Map<String, dynamic>,
      ),
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      currency: json['currency'] as String? ?? 'INR',
      isFree: json['isFree'] as bool? ?? false,
      level: json['level'] as String,
      category: json['category'] as String,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      estimatedDuration: CourseDuration.fromJson(
        json['estimatedDuration'] as Map<String, dynamic>,
      ),
      totalLectures: (json['totalLectures'] as num?)?.toInt() ?? 0,
      totalQuizzes: (json['totalQuizzes'] as num?)?.toInt() ?? 0,
      totalMaterials: (json['totalMaterials'] as num?)?.toInt() ?? 0,
      modules: json['modules'] != null
          ? (json['modules'] as List)
                .map(
                  (module) =>
                      CourseModule.fromJson(module as Map<String, dynamic>),
                )
                .toList()
          : null,
      isLive: json['isLive'] as bool? ?? false,
      liveStreamUrl: json['liveStreamUrl'] as String?,
      nextLiveSession: json['nextLiveSession'] != null
          ? DateTime.parse(json['nextLiveSession'] as String)
          : null,
      liveViewers: (json['liveViewers'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      slug: json['slug'] as String,
      metaDescription: json['metaDescription'] as String?,
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'])
          : [],
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      enrollmentCount: (json['enrollmentCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'thumbnail': thumbnail,
      'banner': banner,
      'previewVideo': previewVideo,
      'instructor': instructor.toJson(),
      'price': price,
      'originalPrice': originalPrice,
      'currency': currency,
      'isFree': isFree,
      'level': level,
      'category': category,
      'tags': tags,
      'estimatedDuration': estimatedDuration.toJson(),
      'totalLectures': totalLectures,
      'totalQuizzes': totalQuizzes,
      'totalMaterials': totalMaterials,
      'modules': modules?.map((module) => module.toJson()).toList(),
      'isLive': isLive,
      'liveStreamUrl': liveStreamUrl,
      'nextLiveSession': nextLiveSession?.toIso8601String(),
      'liveViewers': liveViewers,
      'status': status,
      'publishedAt': publishedAt?.toIso8601String(),
      'slug': slug,
      'metaDescription': metaDescription,
      'keywords': keywords,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'enrollmentCount': enrollmentCount,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? shortDescription,
    String? thumbnail,
    String? banner,
    String? previewVideo,
    CourseInstructor? instructor,
    double? price,
    double? originalPrice,
    String? currency,
    bool? isFree,
    String? level,
    String? category,
    List<String>? tags,
    CourseDuration? estimatedDuration,
    int? totalLectures,
    int? totalQuizzes,
    int? totalMaterials,
    List<CourseModule>? modules,
    bool? isLive,
    String? liveStreamUrl,
    DateTime? nextLiveSession,
    int? liveViewers,
    String? status,
    DateTime? publishedAt,
    String? slug,
    String? metaDescription,
    List<String>? keywords,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? enrollmentCount,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      thumbnail: thumbnail ?? this.thumbnail,
      banner: banner ?? this.banner,
      previewVideo: previewVideo ?? this.previewVideo,
      instructor: instructor ?? this.instructor,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      currency: currency ?? this.currency,
      isFree: isFree ?? this.isFree,
      level: level ?? this.level,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      totalLectures: totalLectures ?? this.totalLectures,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      totalMaterials: totalMaterials ?? this.totalMaterials,
      modules: modules ?? this.modules,
      isLive: isLive ?? this.isLive,
      liveStreamUrl: liveStreamUrl ?? this.liveStreamUrl,
      nextLiveSession: nextLiveSession ?? this.nextLiveSession,
      liveViewers: liveViewers ?? this.liveViewers,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      slug: slug ?? this.slug,
      metaDescription: metaDescription ?? this.metaDescription,
      keywords: keywords ?? this.keywords,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Course &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.shortDescription == shortDescription &&
        other.thumbnail == thumbnail &&
        other.banner == banner &&
        other.previewVideo == previewVideo &&
        other.instructor == instructor &&
        other.price == price &&
        other.originalPrice == originalPrice &&
        other.currency == currency &&
        other.isFree == isFree &&
        other.level == level &&
        other.category == category &&
        listEquals(other.tags, tags) &&
        other.estimatedDuration == estimatedDuration &&
        other.totalLectures == totalLectures &&
        other.totalQuizzes == totalQuizzes &&
        other.totalMaterials == totalMaterials &&
        listEquals(other.modules, modules) &&
        other.isLive == isLive &&
        other.liveStreamUrl == liveStreamUrl &&
        other.nextLiveSession == nextLiveSession &&
        other.liveViewers == liveViewers &&
        other.status == status &&
        other.publishedAt == publishedAt &&
        other.slug == slug &&
        other.metaDescription == metaDescription &&
        listEquals(other.keywords, keywords) &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.enrollmentCount == enrollmentCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        shortDescription.hashCode ^
        thumbnail.hashCode ^
        banner.hashCode ^
        previewVideo.hashCode ^
        instructor.hashCode ^
        price.hashCode ^
        originalPrice.hashCode ^
        currency.hashCode ^
        isFree.hashCode ^
        level.hashCode ^
        category.hashCode ^
        tags.hashCode ^
        estimatedDuration.hashCode ^
        totalLectures.hashCode ^
        totalQuizzes.hashCode ^
        totalMaterials.hashCode ^
        (modules?.hashCode ?? 0) ^
        isLive.hashCode ^
        liveStreamUrl.hashCode ^
        nextLiveSession.hashCode ^
        liveViewers.hashCode ^
        status.hashCode ^
        publishedAt.hashCode ^
        slug.hashCode ^
        metaDescription.hashCode ^
        keywords.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        enrollmentCount.hashCode;
  }
}

@immutable
class CourseInstructor {
  final String name;
  final String? avatar;
  final String? bio;
  final CourseInstructorSocialLinks? socialLinks;

  const CourseInstructor({
    required this.name,
    this.avatar,
    this.bio,
    this.socialLinks,
  });

  factory CourseInstructor.fromJson(Map<String, dynamic> json) {
    return CourseInstructor(
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      socialLinks: json['socialLinks'] != null
          ? CourseInstructorSocialLinks.fromJson(
              json['socialLinks'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'socialLinks': socialLinks?.toJson(),
    };
  }

  CourseInstructor copyWith({
    String? name,
    String? avatar,
    String? bio,
    CourseInstructorSocialLinks? socialLinks,
  }) {
    return CourseInstructor(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseInstructor &&
        other.name == name &&
        other.avatar == avatar &&
        other.bio == bio &&
        other.socialLinks == socialLinks;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        avatar.hashCode ^
        bio.hashCode ^
        socialLinks.hashCode;
  }
}

@immutable
class CourseInstructorSocialLinks {
  final String? linkedin;
  final String? twitter;
  final String? website;

  const CourseInstructorSocialLinks({
    this.linkedin,
    this.twitter,
    this.website,
  });

  factory CourseInstructorSocialLinks.fromJson(Map<String, dynamic> json) {
    return CourseInstructorSocialLinks(
      linkedin: json['linkedin'] as String?,
      twitter: json['twitter'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'linkedin': linkedin, 'twitter': twitter, 'website': website};
  }

  CourseInstructorSocialLinks copyWith({
    String? linkedin,
    String? twitter,
    String? website,
  }) {
    return CourseInstructorSocialLinks(
      linkedin: linkedin ?? this.linkedin,
      twitter: twitter ?? this.twitter,
      website: website ?? this.website,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseInstructorSocialLinks &&
        other.linkedin == linkedin &&
        other.twitter == twitter &&
        other.website == website;
  }

  @override
  int get hashCode {
    return linkedin.hashCode ^ twitter.hashCode ^ website.hashCode;
  }
}

@immutable
class CourseDuration {
  final int hours;
  final int minutes;

  const CourseDuration({required this.hours, this.minutes = 0});

  factory CourseDuration.fromJson(Map<String, dynamic> json) {
    return CourseDuration(
      hours: (json['hours'] as num).toInt(),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'hours': hours, 'minutes': minutes};
  }

  CourseDuration copyWith({int? hours, int? minutes}) {
    return CourseDuration(
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseDuration &&
        other.hours == hours &&
        other.minutes == minutes;
  }

  @override
  int get hashCode {
    return hours.hashCode ^ minutes.hashCode;
  }

  String get formattedDuration {
    if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }
}

@immutable
class CourseModule {
  final String id;
  final String title;
  final String? description;
  final int order;
  final bool isUnlocked;
  final String unlockCondition;
  final List<CourseLecture> lectures;

  const CourseModule({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    this.isUnlocked = false,
    this.unlockCondition = 'immediate',
    this.lectures = const [],
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    return CourseModule(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num).toInt(),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockCondition: json['unlockCondition'] as String? ?? 'immediate',
      lectures: json['lectures'] != null
          ? (json['lectures'] as List)
                .map(
                  (lecture) =>
                      CourseLecture.fromJson(lecture as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'isUnlocked': isUnlocked,
      'unlockCondition': unlockCondition,
      'lectures': lectures.map((lecture) => lecture.toJson()).toList(),
    };
  }

  CourseModule copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    bool? isUnlocked,
    String? unlockCondition,
    List<CourseLecture>? lectures,
  }) {
    return CourseModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockCondition: unlockCondition ?? this.unlockCondition,
      lectures: lectures ?? this.lectures,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseModule &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.order == order &&
        other.isUnlocked == isUnlocked &&
        other.unlockCondition == unlockCondition &&
        listEquals(other.lectures, lectures);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        order.hashCode ^
        isUnlocked.hashCode ^
        unlockCondition.hashCode ^
        lectures.hashCode;
  }
}

@immutable
class CourseLecture {
  final String id;
  final String title;
  final String? description;
  final String type;
  final int order;
  final int? duration;
  final String? contentUrl;
  final bool isCompleted;
  final bool isLocked;

  const CourseLecture({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.order,
    this.duration,
    this.contentUrl,
    this.isCompleted = false,
    this.isLocked = false,
  });

  factory CourseLecture.fromJson(Map<String, dynamic> json) {
    return CourseLecture(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      order: (json['order'] as num).toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      contentUrl: json['contentUrl'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'order': order,
      'duration': duration,
      'contentUrl': contentUrl,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
    };
  }

  CourseLecture copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? order,
    int? duration,
    String? contentUrl,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return CourseLecture(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      contentUrl: contentUrl ?? this.contentUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseLecture &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.order == order &&
        other.duration == duration &&
        other.contentUrl == contentUrl &&
        other.isCompleted == isCompleted &&
        other.isLocked == isLocked;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        type.hashCode ^
        order.hashCode ^
        duration.hashCode ^
        contentUrl.hashCode ^
        isCompleted.hashCode ^
        isLocked.hashCode;
  }
}
