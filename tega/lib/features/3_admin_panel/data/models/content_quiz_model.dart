class SkillDrill {
  final String id;
  final String question;
  final String subject;
  final String difficulty;
  final String skill;
  final String questionType;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String imageUrl;
  final bool isActive;
  final String createdAt;
  final List<String> tags;

  SkillDrill({
    required this.id,
    required this.question,
    required this.subject,
    required this.difficulty,
    required this.skill,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.tags,
  });

  factory SkillDrill.fromJson(Map<String, dynamic> json) {
    return SkillDrill(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      subject: json['subject'] ?? '',
      difficulty: json['difficulty'] ?? '',
      skill: json['skill'] ?? '',
      questionType: json['questionType'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'subject': subject,
      'difficulty': difficulty,
      'skill': skill,
      'questionType': questionType,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'tags': tags,
    };
  }
}

class SoftSkillScenario {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String difficulty;
  final String category;
  final List<String> steps;
  final String expectedOutcome;
  final bool isActive;
  final String createdAt;
  final String imageUrl;

  SoftSkillScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.difficulty,
    required this.category,
    required this.steps,
    required this.expectedOutcome,
    required this.isActive,
    required this.createdAt,
    required this.imageUrl,
  });

  factory SoftSkillScenario.fromJson(Map<String, dynamic> json) {
    return SoftSkillScenario(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] ?? '',
      category: json['category'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      expectedOutcome: json['expectedOutcome'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'difficulty': difficulty,
      'category': category,
      'steps': steps,
      'expectedOutcome': expectedOutcome,
      'isActive': isActive,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
    };
  }
}

class OnboardingQuestion {
  final String id;
  final String question;
  final String type;
  final List<String> options;
  final int? correctAnswer;
  final bool isRequired;

  OnboardingQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    this.correctAnswer,
    required this.isRequired,
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      type: json['type'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'],
      isRequired: json['isRequired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'isRequired': isRequired,
    };
  }
}

class OnboardingQuiz {
  final String id;
  final String title;
  final String description;
  final int totalQuestions;
  final int timeLimit;
  final List<OnboardingQuestion> questions;
  final bool isActive;
  final String lastModified;

  OnboardingQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.timeLimit,
    required this.questions,
    required this.isActive,
    required this.lastModified,
  });

  factory OnboardingQuiz.fromJson(Map<String, dynamic> json) {
    return OnboardingQuiz(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      timeLimit: json['timeLimit'] ?? 0,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((q) => OnboardingQuestion.fromJson(q))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      lastModified: json['lastModified'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'totalQuestions': totalQuestions,
      'timeLimit': timeLimit,
      'questions': questions.map((q) => q.toJson()).toList(),
      'isActive': isActive,
      'lastModified': lastModified,
    };
  }
}

class ContentQuizStatistics {
  final int totalActiveDrills;
  final int totalScenarios;
  final int totalQuestions;
  final List<String> categories;
  final List<String> difficultyLevels;
  final List<String> questionTypes;

  ContentQuizStatistics({
    required this.totalActiveDrills,
    required this.totalScenarios,
    required this.totalQuestions,
    required this.categories,
    required this.difficultyLevels,
    required this.questionTypes,
  });

  factory ContentQuizStatistics.fromJson(Map<String, dynamic> json) {
    return ContentQuizStatistics(
      totalActiveDrills: json['totalActiveDrills'] ?? 0,
      totalScenarios: json['totalScenarios'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      difficultyLevels: List<String>.from(json['difficultyLevels'] ?? []),
      questionTypes: List<String>.from(json['questionTypes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalActiveDrills': totalActiveDrills,
      'totalScenarios': totalScenarios,
      'totalQuestions': totalQuestions,
      'categories': categories,
      'difficultyLevels': difficultyLevels,
      'questionTypes': questionTypes,
    };
  }
}

class ContentQuizData {
  final List<SkillDrill> skillDrills;
  final List<SoftSkillScenario> softSkillScenarios;
  OnboardingQuiz onboardingQuiz;
  final ContentQuizStatistics statistics;

  ContentQuizData({
    required this.skillDrills,
    required this.softSkillScenarios,
    required this.onboardingQuiz,
    required this.statistics,
  });

  factory ContentQuizData.fromJson(Map<String, dynamic> json) {
    return ContentQuizData(
      skillDrills:
          (json['skillDrills'] as List<dynamic>?)
              ?.map((drill) => SkillDrill.fromJson(drill))
              .toList() ??
          [],
      softSkillScenarios:
          (json['softSkillScenarios'] as List<dynamic>?)
              ?.map((scenario) => SoftSkillScenario.fromJson(scenario))
              .toList() ??
          [],
      onboardingQuiz: OnboardingQuiz.fromJson(json['onboardingQuiz'] ?? {}),
      statistics: ContentQuizStatistics.fromJson(json['statistics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillDrills': skillDrills.map((drill) => drill.toJson()).toList(),
      'softSkillScenarios': softSkillScenarios
          .map((scenario) => scenario.toJson())
          .toList(),
      'onboardingQuiz': onboardingQuiz.toJson(),
      'statistics': statistics.toJson(),
    };
  }
}
