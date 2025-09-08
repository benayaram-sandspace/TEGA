import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/content_quiz_models.dart';

class ContentQuizService {
  static final ContentQuizService _instance = ContentQuizService._internal();
  factory ContentQuizService() => _instance;
  ContentQuizService._internal();

  ContentQuizData? _data;
  bool _isLoaded = false;

  Future<ContentQuizData> loadData() async {
    if (_isLoaded && _data != null) {
      return _data!;
    }

    try {
      final String jsonString = await rootBundle.loadString('lib/data/content_quiz_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _data = ContentQuizData.fromJson(jsonData);
      _isLoaded = true;
      return _data!;
    } catch (e) {
      throw Exception('Failed to load content quiz data: $e');
    }
  }

  Future<List<SkillDrill>> getSkillDrills() async {
    final data = await loadData();
    return data.skillDrills;
  }

  Future<List<SoftSkillScenario>> getSoftSkillScenarios() async {
    final data = await loadData();
    return data.softSkillScenarios;
  }

  Future<OnboardingQuiz> getOnboardingQuiz() async {
    final data = await loadData();
    return data.onboardingQuiz;
  }

  Future<ContentQuizStatistics> getStatistics() async {
    final data = await loadData();
    return data.statistics;
  }

  Future<List<SkillDrill>> searchSkillDrills(String query) async {
    final drills = await getSkillDrills();
    if (query.isEmpty) return drills;
    
    return drills.where((drill) {
      return drill.question.toLowerCase().contains(query.toLowerCase()) ||
             drill.subject.toLowerCase().contains(query.toLowerCase()) ||
             drill.skill.toLowerCase().contains(query.toLowerCase()) ||
             drill.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
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
      if (questionType != null && drill.questionType != questionType) return false;
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
             scenario.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
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

  // Add new skill drill
  Future<void> addSkillDrill(SkillDrill drill) async {
    final data = await loadData();
    data.skillDrills.add(drill);
    // In a real app, you would save this to a backend or local storage
  }

  // Add new soft skill scenario
  Future<void> addSoftSkillScenario(SoftSkillScenario scenario) async {
    final data = await loadData();
    data.softSkillScenarios.add(scenario);
    // In a real app, you would save this to a backend or local storage
  }

  // Update onboarding quiz
  Future<void> updateOnboardingQuiz(OnboardingQuiz quiz) async {
    final data = await loadData();
    data.onboardingQuiz = quiz;
    // In a real app, you would save this to a backend or local storage
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
    return scenarios.map((scenario) => scenario.category).toSet().toList()..sort();
  }
}

