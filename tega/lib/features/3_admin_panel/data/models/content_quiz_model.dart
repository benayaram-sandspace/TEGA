// Enums for enhanced functionality
enum LearningStyle {
  visual,
  auditory,
  kinesthetic,
  adaptive,
}

enum GradeLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  dragDrop,
  essay,
}

class ScenarioStep {
  final int stepNumber;
  final String title;
  final String description;
  final String instruction;
  final List<String> resources;
  final int estimatedTime; // in minutes
  final List<String> objectives;
  final Map<String, dynamic> hints;

  ScenarioStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.instruction,
    this.resources = const [],
    required this.estimatedTime,
    this.objectives = const [],
    this.hints = const {},
  });

  factory ScenarioStep.fromJson(Map<String, dynamic> json) {
    return ScenarioStep(
      stepNumber: json['stepNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instruction: json['instruction'] ?? '',
      resources: List<String>.from(json['resources'] ?? []),
      estimatedTime: json['estimatedTime'] ?? 0,
      objectives: List<String>.from(json['objectives'] ?? []),
      hints: Map<String, dynamic>.from(json['hints'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'instruction': instruction,
      'resources': resources,
      'estimatedTime': estimatedTime,
      'objectives': objectives,
      'hints': hints,
    };
  }
}

class SkillDrill {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String difficulty;
  final String skill;
  final String questionType;
  final String category;
  final List<String> questions;
  final List<String> options;
  final List<int> correctAnswers;
  final List<String> explanations;
  final List<String> imageUrls;
  final bool isActive;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? lastModified;
  final String createdBy;
  final String modifiedBy;
  final List<String> tags;
  final int estimatedTime; // in seconds
  final String prerequisite;
  final Map<String, dynamic> metadata;
  final LearningStyle learningStyle;
  final GradeLevel gradeLevel;

  SkillDrill({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.difficulty,
    required this.skill,
    required this.questionType,
    required this.category,
    required this.questions,
    required this.options,
    required this.correctAnswers,
    required this.explanations,
    required this.imageUrls,
    required this.isActive,
    this.isPublished = false,
    required this.createdAt,
    this.publishedAt,
    this.lastModified,
    required this.createdBy,
    this.modifiedBy = '',
    required this.tags,
    required this.estimatedTime,
    this.prerequisite = '',
    this.metadata = const {},
    this.learningStyle = LearningStyle.adaptive,
    this.gradeLevel = GradeLevel.beginner,
  });

  factory SkillDrill.fromJson(Map<String, dynamic> json) {
    return SkillDrill(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      difficulty: json['difficulty'] ?? '',
      skill: json['skill'] ?? '',
      questionType: json['questionType'] ?? '',
      category: json['category'] ?? '',
      questions: List<String>.from(json['questions'] ?? []),
      options: List<String>.from(json['options'] ?? []),
      correctAnswers: List<int>.from(json['correctAnswers'] ?? []),
      explanations: List<String>.from(json['explanations'] ?? []),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      isActive: json['isActive'] ?? true,
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : null,
      createdBy: json['createdBy'] ?? '',
      modifiedBy: json['modifiedBy'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      estimatedTime: json['estimatedTime'] ?? 0,
      prerequisite: json['prerequisite'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      learningStyle: LearningStyle.values.firstWhere(
        (e) => e.name == json['learningStyle'],
        orElse: () => LearningStyle.adaptive,
      ),
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.name == json['gradeLevel'],
        orElse: () => GradeLevel.beginner,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty': difficulty,
      'skill': skill,
      'questionType': questionType,
      'category': category,
      'questions': questions,
      'options': options,
      'correctAnswers': correctAnswers,
      'explanations': explanations,
      'imageUrls': imageUrls,
      'isActive': isActive,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
      'tags': tags,
      'estimatedTime': estimatedTime,
      'prerequisite': prerequisite,
      'metadata': metadata,
      'learningStyle': learningStyle.name,
      'gradeLevel': gradeLevel.name,
    };
  }
}

class SoftSkillScenario {
  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final List<String> tags;
  final DifficultyLevel difficulty;
  final String category;
  final String subCategory;
  final List<ScenarioStep> steps;
  final String expectedOutcome;
  final List<String> keyGoals;
  final List<String> commonMistakes;
  final bool isActive;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? lastModified;
  final String createdBy;
  final String modifiedBy;
  final String imageUrl;
  final List<String> multimediaUrls; // videos, audio, documents
  final int estimatedDuration; // in minutes
  final String prerequisites;
  final String recommendedAge;
  final LearningStyle targetLearningStyle;
  final Map<String, dynamic> metadata;
  final List<String> relatedSkillDrills;

  SoftSkillScenario({
    required this.id,
    required this.title,
    required this.description,
    this.shortDescription = '',
    required this.tags,
    required this.difficulty,
    required this.category,
    required this.subCategory,
    required this.steps,
    required this.expectedOutcome,
    this.keyGoals = const [],
    this.commonMistakes = const [],
    required this.isActive,
    this.isPublished = false,
    required this.createdAt,
    this.publishedAt,
    this.lastModified,
    required this.createdBy,
    this.modifiedBy = '',
    required this.imageUrl,
    this.multimediaUrls = const [],
    required this.estimatedDuration,
    this.prerequisites = '',
    this.recommendedAge = '',
    this.targetLearningStyle = LearningStyle.adaptive,
    this.metadata = const {},
    this.relatedSkillDrills = const [],
  });

  factory SoftSkillScenario.fromJson(Map<String, dynamic> json) {
    return SoftSkillScenario(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      steps: (json['steps'] as List<dynamic>?)
          ?.map((step) => ScenarioStep.fromJson(step))
          .toList() ?? [],
      expectedOutcome: json['expectedOutcome'] ?? '',
      keyGoals: List<String>.from(json['keyGoals'] ?? []),
      commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
      isActive: json['isActive'] ?? true,
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : null,
      createdBy: json['createdBy'] ?? '',
      modifiedBy: json['modifiedBy'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      multimediaUrls: List<String>.from(json['multimediaUrls'] ?? []),
      estimatedDuration: json['estimatedDuration'] ?? 0,
      prerequisites: json['prerequisites'] ?? '',
      recommendedAge: json['recommendedAge'] ?? '',
      targetLearningStyle: LearningStyle.values.firstWhere(
        (e) => e.name == json['targetLearningStyle'],
        orElse: () => LearningStyle.adaptive,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      relatedSkillDrills: List<String>.from(json['relatedSkillDrills'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'tags': tags,
      'difficulty': difficulty.name,
      'category': category,
      'subCategory': subCategory,
      'steps': steps.map((step) => step.toJson()).toList(),
      'expectedOutcome': expectedOutcome,
      'keyGoals': keyGoals,
      'commonMistakes': commonMistakes,
      'isActive': isActive,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
      'imageUrl': imageUrl,
      'multimediaUrls': multimediaUrls,
      'estimatedDuration': estimatedDuration,
      'prerequisites': prerequisites,
      'recommendedAge': recommendedAge,
      'targetLearningStyle': targetLearningStyle.name,
      'metadata': metadata,
      'relatedSkillDrills': relatedSkillDrills,
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

// New models for enhanced functionality
class QuizAttempt {
  final String id;
  final String userId;
  final String quizId;
  final String quizType; // skillDrill, scenario, onboarding
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent; // in seconds
  final List<QuizAnswer> answers;
  final int score;
  final bool isPassed;
  final String status; // in_progress, completed, abandoned
  final Map<String, dynamic> metadata;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.quizType,
    required this.startedAt,
    this.completedAt,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.answers,
    required this.score,
    required this.isPassed,
    required this.status,
    this.metadata = const {},
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      userId: json['userId'],
      quizId: json['quizId'],
      quizType: json['quizType'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      timeSpent: json['timeSpent'],
      answers: (json['answers'] as List<dynamic>?)
          ?.map((answer) => QuizAnswer.fromJson(answer))
          .toList() ?? [],
      score: json['score'],
      isPassed: json['isPassed'],
      status: json['status'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'quizType': quizType,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpent': timeSpent,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'score': score,
      'isPassed': isPassed,
      'status': status,
      'metadata': metadata,
    };
  }
}

class QuizAnswer {
  final String questionId;
  final String answer;
  final bool isCorrect;
  final int timeToAnswer; // in seconds
  final String explanation;
  final List<String> hints;

  QuizAnswer({
    required this.questionId,
    required this.answer,
    required this.isCorrect,
    required this.timeToAnswer,
    required this.explanation,
    required this.hints,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'],
      answer: json['answer'],
      isCorrect: json['isCorrect'],
      timeToAnswer: json['timeToAnswer'],
      explanation: json['explanation'],
      hints: List<String>.from(json['hints'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer,
      'isCorrect': isCorrect,
      'timeToAnswer': timeToAnswer,
      'explanation': explanation,
      'hints': hints,
    };
  }
}

class ContentQuizData {
  final List<SkillDrill> skillDrills;
  final List<SoftSkillScenario> softSkillScenarios;
  OnboardingQuiz onboardingQuiz;
  final ContentQuizStatistics statistics;
  final List<QuizAttempt> recentAttempts;
  final Map<String, dynamic> analytics;

  ContentQuizData({
    required this.skillDrills,
    required this.softSkillScenarios,
    required this.onboardingQuiz,
    required this.statistics,
    required this.recentAttempts,
    this.analytics = const {},
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
      recentAttempts: (json['recentAttempts'] as List<dynamic>?)
              ?.map((attempt) => QuizAttempt.fromJson(attempt))
              .toList() ??
          [],
      analytics: Map<String, dynamic>.from(json['analytics'] ?? {}),
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
