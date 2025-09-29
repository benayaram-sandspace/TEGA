import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tega/features/3_admin_panel/data/models/content_quiz_model.dart';

class ContentQuizRepository {
  static final ContentQuizRepository _instance = ContentQuizRepository._internal();
  factory ContentQuizRepository() => _instance;
  ContentQuizRepository._internal();

  ContentQuizData? _data;
  List<QuizAttempt> _quizAttempts = [];
  List<SkillDrill> _skillDrills = [];
  List<SoftSkillScenario> _scenarios = [];
  OnboardingQuiz? _onboardingQuiz;
  bool _isLoaded = false;
  String? _currentUserId;

  Future<ContentQuizData> loadData() async {
    if (_isLoaded && _data != null) {
      return _data!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/content_quiz_data.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _data = ContentQuizData.fromJson(jsonData);
      
      // Initialize local lists
      _skillDrills = _data!.skillDrills;
      _scenarios = _data!.softSkillScenarios;
      _onboardingQuiz = _data!.onboardingQuiz;
      
      _isLoaded = true;
      return _data!;
    } catch (e) {
      throw Exception('Failed to load content quiz data: $e');
    }
  }

  Future<List<SkillDrill>> getSkillDrills() async {
    await loadData();
    return List.from(_skillDrills);
  }

  Future<List<SoftSkillScenario>> getSoftSkillScenarios() async {
    await loadData();
    return List.from(_scenarios);
  }

  Future<OnboardingQuiz> getOnboardingQuiz() async {
    await loadData();
    return _onboardingQuiz!;
  }

  Future<ContentQuizStatistics> getStatistics() async {
    await loadData();
    return _data!.statistics;
  }

  // Enhanced CRUD operations
  Future<SkillDrill?> getSkillDrillById(String id) async {
    await loadData();
    try {
      return _skillDrills.firstWhere((drill) => drill.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<SoftSkillScenario?> getScenarioById(String id) async {
    await loadData();
    try {
      return _scenarios.firstWhere((scenario) => scenario.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<SkillDrill>> searchSkillDrills(String query) async {
    final drills = await getSkillDrills();
    if (query.isEmpty) return drills;

    return drills.where((drill) {
      return drill.title.toLowerCase().contains(query.toLowerCase()) ||
          drill.description.toLowerCase().contains(query.toLowerCase()) ||
          drill.subject.toLowerCase().contains(query.toLowerCase()) ||
          drill.skill.toLowerCase().contains(query.toLowerCase()) ||
          drill.category.toLowerCase().contains(query.toLowerCase()) ||
          drill.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          );
    }).toList();
  }

  Future<List<SkillDrill>> filterSkillDrills({
    String? skill,
    String? questionType,
    String? difficulty,
  }) async {
    final drills = await getSkillDrills();

    return drills.where((drill) {
      if (skill != null && drill.skill != skill) return false;
      if (questionType != null && drill.questionType != questionType) {
        return false;
      }
      if (difficulty != null && drill.difficulty != difficulty) return false;
      return true;
    }).toList();
  }

  Future<List<SoftSkillScenario>> searchSoftSkillScenarios(String query) async {
    final scenarios = await getSoftSkillScenarios();
    if (query.isEmpty) return scenarios;

    return scenarios.where((scenario) {
      return scenario.title.toLowerCase().contains(query.toLowerCase()) ||
          scenario.description.toLowerCase().contains(query.toLowerCase()) ||
          scenario.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          );
    }).toList();
  }

  Future<List<SoftSkillScenario>> filterSoftSkillScenarios({
    String? category,
    String? difficulty,
  }) async {
    final scenarios = await getSoftSkillScenarios();

    return scenarios.where((scenario) {
      if (category != null && scenario.category != category) return false;
      if (difficulty != null && scenario.difficulty != difficulty) return false;
      return true;
    }).toList();
  }

  // Enhanced CRUD operations
  Future<bool> addSkillDrill(SkillDrill drill) async {
    try {
      await loadData();
      _skillDrills.add(drill);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSkillDrill(SkillDrill updatedDrill) async {
    try {
      await loadData();
      final index = _skillDrills.indexWhere((drill) => drill.id == updatedDrill.id);
      if (index != -1) {
        _skillDrills[index] = updatedDrill;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSkillDrill(String id) async {
    try {
      await loadData();
      _skillDrills.removeWhere((drill) => drill.id == id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addSoftSkillScenario(SoftSkillScenario scenario) async {
    try {
      await loadData();
      _scenarios.add(scenario);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSoftSkillScenario(SoftSkillScenario updatedScenario) async {
    try {
      await loadData();
      final index = _scenarios.indexWhere((scenario) => scenario.id == updatedScenario.id);
      if (index != -1) {
        _scenarios[index] = updatedScenario;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSoftSkillScenario(String id) async {
    try {
      await loadData();
      _scenarios.removeWhere((scenario) => scenario.id == id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOnboardingQuiz(OnboardingQuiz quiz) async {
    try {
      await loadData();
      _onboardingQuiz = quiz;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get unique skills for filtering
  Future<List<String>> getUniqueSkills() async {
    final drills = await getSkillDrills();
    return drills.map((drill) => drill.skill).toSet().toList()..sort();
  }

  // Get unique question types for filtering
  Future<List<String>> getUniqueQuestionTypes() async {
    final drills = await getSkillDrills();
    return drills.map((drill) => drill.questionType).toSet().toList()..sort();
  }

  // Get unique categories for filtering
  Future<List<String>> getUniqueCategories() async {
    final scenarios = await getSoftSkillScenarios();
    return scenarios.map((scenario) => scenario.category).toSet().toList()
      ..sort();
  }

  // Quiz Attempt Management
  Future<QuizAttempt> startQuizAttempt({
    required String userId,
    required String quizId,
    required String quizType,
    required int totalQuestions,
  }) async {
    final attempt = QuizAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      quizId: quizId,
      quizType: quizType,
      startedAt: DateTime.now(),
      totalQuestions: totalQuestions,
      correctAnswers: 0,
      timeSpent: 0,
      answers: [],
      score: 0,
      isPassed: false,
      status: 'in_progress',
    );

    _quizAttempts.add(attempt);
    _currentUserId = userId;
    return attempt;
  }

  Future<bool> updateQuizAttempt(QuizAttempt updatedAttempt) async {
    try {
      final index = _quizAttempts.indexWhere((attempt) => attempt.id == updatedAttempt.id);
      if (index != -1) {
        _quizAttempts[index] = updatedAttempt;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeQuizAttempt(String attemptId, int score, bool isPassed) async {
    try {
      final index = _quizAttempts.indexWhere((attempt) => attempt.id == attemptId);
      if (index != -1) {
        final attempt = _quizAttempts[index];
        final completedAttempt = QuizAttempt(
          id: attempt.id,
          userId: attempt.userId,
          quizId: attempt.quizId,
          quizType: attempt.quizType,
          startedAt: attempt.startedAt,
          completedAt: DateTime.now(),
          totalQuestions: attempt.totalQuestions,
          correctAnswers: attempt.correctAnswers,
          timeSpent: DateTime.now().difference(attempt.startedAt).inSeconds,
          answers: attempt.answers,
          score: score,
          isPassed: isPassed,
          status: 'completed',
        );
        _quizAttempts[index] = completedAttempt;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<QuizAttempt>> getUserQuizAttempts(String userId) async {
    return _quizAttempts.where((attempt) => attempt.userId == userId).toList();
  }

  Future<List<QuizAttempt>> getQuizAttemptsByQuiz(String quizId) async {
    return _quizAttempts.where((attempt) => attempt.quizId == quizId).toList();
  }

  // Analytics and Statistics
  Future<Map<String, dynamic>> getQuizAnalytics(String quizId) async {
    final attempts = await getQuizAttemptsByQuiz(quizId);
    final completedAttempts = attempts.where((a) => a.status == 'completed').toList();
    
    if (completedAttempts.isEmpty) {
      return {
        'totalAttempts': attempts.length,
        'completedAttempts': 0,
        'averageScore': 0.0,
        'passRate': 0.0,
        'averageTimeSpent': 0.0,
      };
    }

    final totalScore = completedAttempts.fold(0, (sum, attempt) => sum + attempt.score);
    final passedAttempts = completedAttempts.where((a) => a.isPassed).length;
    final totalTime = completedAttempts.fold(0, (sum, attempt) => sum + attempt.timeSpent);

    return {
      'totalAttempts': attempts.length,
      'completedAttempts': completedAttempts.length,
      'averageScore': totalScore / completedAttempts.length,
      'passRate': (passedAttempts / completedAttempts.length) * 100,
      'averageTimeSpent': totalTime / completedAttempts.length,
      'bestScore': completedAttempts.map((a) => a.score).reduce((a, b) => a > b ? a : b),
      'worstScore': completedAttempts.map((a) => a.score).reduce((a, b) => a < b ? a : b),
    };
  }

  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final attempts = await getUserQuizAttempts(userId);
    final completedAttempts = attempts.where((a) => a.status == 'completed').toList();
    
    if (completedAttempts.isEmpty) {
      return {
        'totalQuizzes': 0,
        'completedQuizzes': 0,
        'averageScore': 0.0,
        'totalTimeSpent': 0,
        'skillsMastered': 0,
      };
    }

    final totalScore = completedAttempts.fold(0, (sum, attempt) => sum + attempt.score);
    final totalTime = completedAttempts.fold(0, (sum, attempt) => sum + attempt.timeSpent);
    final passedQuizzes = completedAttempts.where((a) => a.isPassed).length;

    return {
      'totalQuizzes': attempts.length,
      'completedQuizzes': completedAttempts.length,
      'averageScore': totalScore / completedAttempts.length,
      'totalTimeSpent': totalTime,
      'skillsMastered': passedQuizzes,
      'completionRate': (completedAttempts.length / attempts.length) * 100,
    };
  }

  // Bulk Operations
  Future<bool> bulkUpdateSkillDrillStatus(List<String> ids, bool isActive) async {
    try {
      await loadData();
      for (final id in ids) {
        final index = _skillDrills.indexWhere((drill) => drill.id == id);
        if (index != -1) {
          final drill = _skillDrills[index];
          _skillDrills[index] = SkillDrill(
            id: drill.id,
            title: drill.title,
            description: drill.description,
            subject: drill.subject,
            difficulty: drill.difficulty,
            skill: drill.skill,
            questionType: drill.questionType,
            category: drill.category,
            questions: drill.questions,
            options: drill.options,
            correctAnswers: drill.correctAnswers,
            explanations: drill.explanations,
            imageUrls: drill.imageUrls,
            isActive: isActive,
            isPublished: drill.isPublished,
            createdAt: drill.createdAt,
            publishedAt: drill.publishedAt,
            lastModified: DateTime.now(),
            createdBy: drill.createdBy,
            modifiedBy: _currentUserId ?? drill.modifiedBy,
            tags: drill.tags,
            estimatedTime: drill.estimatedTime,
            prerequisite: drill.prerequisite,
            metadata: drill.metadata,
            learningStyle: drill.learningStyle,
            gradeLevel: drill.gradeLevel,
          );
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Advanced Filtering
  Future<List<SkillDrill>> getSkillDrillsByLearningStyle(LearningStyle style) async {
    final drills = await getSkillDrills();
    return drills.where((drill) => drill.learningStyle == style).toList();
  }

  Future<List<SkillDrill>> getSkillDrillsByGradeLevel(GradeLevel level) async {
    final drills = await getSkillDrills();
    return drills.where((drill) => drill.gradeLevel == level).toList();
  }

  Future<List<SoftSkillScenario>> getScenariosByDifficulty(DifficultyLevel difficulty) async {
    final scenarios = await getSoftSkillScenarios();
    return scenarios.where((scenario) => scenario.difficulty == difficulty).toList();
  }

  // Content Management
  Future<List<SkillDrill>> getPublishedSkillDrills() async {
    final drills = await getSkillDrills();
    return drills.where((drill) => drill.isPublished && drill.isActive).toList();
  }

  Future<List<SoftSkillScenario>> getPublishedScenarios() async {
    final scenarios = await getSoftSkillScenarios();
    return scenarios.where((scenario) => scenario.isPublished && scenario.isActive).toList();
  }

  Future<bool> publishContent(String id, String type) async {
    try {
      await loadData();
      if (type == 'skillDrill') {
        final index = _skillDrills.indexWhere((drill) => drill.id == id);
        if (index != -1) {
          final drill = _skillDrills[index];
          _skillDrills[index] = SkillDrill(
            id: drill.id,
            title: drill.title,
            description: drill.description,
            subject: drill.subject,
            difficulty: drill.difficulty,
            skill: drill.skill,
            questionType: drill.questionType,
            category: drill.category,
            questions: drill.questions,
            options: drill.options,
            correctAnswers: drill.correctAnswers,
            explanations: drill.explanations,
            imageUrls: drill.imageUrls,
            isActive: drill.isActive,
            isPublished: true,
            createdAt: drill.createdAt,
            publishedAt: DateTime.now(),
            lastModified: DateTime.now(),
            createdBy: drill.createdBy,
            modifiedBy: _currentUserId ?? drill.modifiedBy,
            tags: drill.tags,
            estimatedTime: drill.estimatedTime,
            prerequisite: drill.prerequisite,
            metadata: drill.metadata,
            learningStyle: drill.learningStyle,
            gradeLevel: drill.gradeLevel,
          );
          return true;
        }
      } else if (type == 'scenario') {
        final index = _scenarios.indexWhere((scenario) => scenario.id == id);
        if (index != -1) {
          final scenario = _scenarios[index];
          _scenarios[index] = SoftSkillScenario(
            id: scenario.id,
            title: scenario.title,
            description: scenario.description,
            shortDescription: scenario.shortDescription,
            tags: scenario.tags,
            difficulty: scenario.difficulty,
            category: scenario.category,
            subCategory: scenario.subCategory,
            steps: scenario.steps,
            expectedOutcome: scenario.expectedOutcome,
            keyGoals: scenario.keyGoals,
            commonMistakes: scenario.commonMistakes,
            isActive: scenario.isActive,
            isPublished: true,
            createdAt: scenario.createdAt,
            publishedAt: DateTime.now(),
            lastModified: DateTime.now(),
            createdBy: scenario.createdBy,
            modifiedBy: _currentUserId ?? scenario.modifiedBy,
            imageUrl: scenario.imageUrl,
            multimediaUrls: scenario.multimediaUrls,
            estimatedDuration: scenario.estimatedDuration,
            prerequisites: scenario.prerequisites,
            recommendedAge: scenario.recommendedAge,
            targetLearningStyle: scenario.targetLearningStyle,
            metadata: scenario.metadata,
            relatedSkillDrills: scenario.relatedSkillDrills,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
