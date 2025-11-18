import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/placement_prep/edit_question_page.dart';

class QuestionsTab extends StatefulWidget {
  const QuestionsTab({super.key});

  @override
  State<QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<QuestionsTab> {
  final _searchController = TextEditingController();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  String? _selectedType;
  String? _selectedCategory;
  String? _selectedDifficulty;

  bool _isLoading = false;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadQuestions();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);

      final cachedQuestions = await _cacheService
          .getPlacementPrepQuestionsData();
      if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(cachedQuestions);
          _isLoadingFromCache = false;
        });
      } else {
        setState(() => _isLoadingFromCache = false);
      }
    } catch (e) {
      setState(() => _isLoadingFromCache = false);
    }
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? 12
            : isTablet
            ? 16
            : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(isMobile, isTablet, isDesktop),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),
          _errorMessage != null && !_isLoadingFromCache
              ? _buildErrorState(isMobile, isTablet, isDesktop)
              : _buildQuestionList(isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile, bool isTablet, bool isDesktop) {
    final labelStyle = TextStyle(
      fontSize: isMobile
          ? 14
          : isTablet
          ? 15
          : 16,
      fontWeight: FontWeight.w700,
      color: AdminDashboardStyles.textDark,
    );

    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 9
                      : 10,
                ),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 8
                        : isTablet
                        ? 9
                        : 10,
                  ),
                ),
                child: Icon(
                  Icons.filter_alt_rounded,
                  color: AdminDashboardStyles.accentBlue,
                  size: isMobile
                      ? 16
                      : isTablet
                      ? 17
                      : 18,
                ),
              ),
              SizedBox(
                width: isMobile
                    ? 8
                    : isTablet
                    ? 9
                    : 10,
              ),
              Flexible(
                child: Text('Search & Filter Questions', style: labelStyle),
              ),
            ],
          ),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),

          // Stack fields vertically to avoid overflow on small screens
          _buildSearchField(isMobile, isTablet, isDesktop),
          SizedBox(
            height: isMobile
                ? 10
                : isTablet
                ? 11
                : 12,
          ),
          _buildTypeDropdown(isMobile, isTablet, isDesktop),
          SizedBox(
            height: isMobile
                ? 10
                : isTablet
                ? 11
                : 12,
          ),
          _buildCategoryDropdown(isMobile, isTablet, isDesktop),
          SizedBox(
            height: isMobile
                ? 10
                : isTablet
                ? 11
                : 12,
          ),
          _buildDifficultyDropdown(isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isMobile, bool isTablet, bool isDesktop) {
    return TextField(
      controller: _searchController,
      style: TextStyle(
        fontSize: isMobile
            ? 13
            : isTablet
            ? 13.5
            : 14,
      ),
      decoration: _inputDecoration(
        hintText: 'Search questions...',
        prefixIcon: Icons.search_rounded,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
      ),
      onChanged: (_) {
        // Will hook into search later
        setState(() {});
      },
    );
  }

  Widget _buildTypeDropdown(bool isMobile, bool isTablet, bool isDesktop) {
    final items = [
      DropdownMenuItem(
        value: null,
        child: Text(
          'All Types',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'mcq',
        child: Text(
          'MCQ',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'coding',
        child: Text(
          'Coding',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'subjective',
        child: Text(
          'Subjective',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'behavioral',
        child: Text(
          'Behavioral',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
    ];
    return DropdownButtonFormField<String?>(
      value: _selectedType,
      isExpanded: true,
      style: TextStyle(
        fontSize: isMobile
            ? 13
            : isTablet
            ? 13.5
            : 14,
        color: Colors.black,
      ),
      decoration: _inputDecoration(
        hintText: 'All Types',
        prefixIcon: Icons.description_rounded,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
      ),
      items: items,
      onChanged: (v) => setState(() => _selectedType = v),
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: isMobile
            ? 20
            : isTablet
            ? 22
            : 24,
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isMobile, bool isTablet, bool isDesktop) {
    final items = [
      DropdownMenuItem(
        value: null,
        child: Text(
          'All Categories',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'assessment',
        child: Text(
          'Assessment',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'technical',
        child: Text(
          'Technical',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'interview',
        child: Text(
          'Interview',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'aptitude',
        child: Text(
          'Aptitude',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'logical',
        child: Text(
          'Logical',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'verbal',
        child: Text(
          'Verbal',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
    ];
    return DropdownButtonFormField<String?>(
      value: _selectedCategory,
      isExpanded: true,
      style: TextStyle(
        fontSize: isMobile
            ? 13
            : isTablet
            ? 13.5
            : 14,
        color: Colors.black,
      ),
      decoration: _inputDecoration(
        hintText: 'All Categories',
        prefixIcon: Icons.book_outlined,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
      ),
      items: items,
      onChanged: (v) => setState(() => _selectedCategory = v),
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: isMobile
            ? 20
            : isTablet
            ? 22
            : 24,
      ),
    );
  }

  Widget _buildDifficultyDropdown(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final items = [
      DropdownMenuItem(
        value: null,
        child: Text(
          'All Difficulties',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'easy',
        child: Text(
          'Easy',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'medium',
        child: Text(
          'Medium',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
      DropdownMenuItem(
        value: 'hard',
        child: Text(
          'Hard',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            color: Colors.black,
          ),
        ),
      ),
    ];
    return DropdownButtonFormField<String?>(
      value: _selectedDifficulty,
      isExpanded: true,
      style: TextStyle(
        fontSize: isMobile
            ? 13
            : isTablet
            ? 13.5
            : 14,
        color: Colors.black,
      ),
      decoration: _inputDecoration(
        hintText: 'All Difficulties',
        prefixIcon: Icons.military_tech_rounded,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
      ),
      items: items,
      onChanged: (v) => setState(() => _selectedDifficulty = v),
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: isMobile
            ? 20
            : isTablet
            ? 22
            : 24,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: isMobile
            ? 13
            : isTablet
            ? 13.5
            : 14,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: AdminDashboardStyles.textLight,
              size: isMobile
                  ? 18
                  : isTablet
                  ? 19
                  : 20,
            )
          : null,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 12
            : isTablet
            ? 13
            : 14,
        vertical: isMobile
            ? 12
            : isTablet
            ? 13
            : 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
    );
  }

  Future<void> _loadQuestions({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _questions.isNotEmpty) {
      _loadQuestionsInBackground();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementQuestions),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          // Backend returns 'questions' array (not 'data')
          final list =
              (data['questions'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _questions = List<Map<String, dynamic>>.from(list);
              _isLoading = false;
            });

            // Cache the data
            await _cacheService.setPlacementPrepQuestionsData(_questions);

            // Reset toast flag on successful load (internet is back)
            _cacheService.resetNoInternetToastFlag();
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch questions');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(
          errorData['message'] ??
              'Failed to fetch questions: ${res.statusCode}',
        );
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedQuestions = await _cacheService
            .getPlacementPrepQuestionsData();
        if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
          // Load from cache
          if (mounted) {
            setState(() {
              _questions = List<Map<String, dynamic>>.from(cachedQuestions);
              _isLoading = false;
              _errorMessage = null; // Clear error since we have cached data
            });
          }
          return;
        }

        // No cache available, show error
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection';
          });
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  Future<void> _loadQuestionsInBackground() async {
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementQuestions),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list =
              (data['questions'] ?? data['data'] ?? []) as List<dynamic>;
          setState(() {
            _questions = List<Map<String, dynamic>>.from(list);
          });

          // Cache the data
          await _cacheService.setPlacementPrepQuestionsData(_questions);

          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isTablet
            ? 28
            : 32,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile
                  ? 56
                  : isTablet
                  ? 64
                  : 72,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
            ),
            Text(
              'Failed to load questions',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 19
                    : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 8
                  : isTablet
                  ? 9
                  : 10,
            ),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(
              height: isMobile
                  ? 20
                  : isTablet
                  ? 24
                  : 28,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadQuestions(forceRefresh: true);
              },
              icon: Icon(
                Icons.refresh,
                size: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? 20
                      : isTablet
                      ? 24
                      : 28,
                  vertical: isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 8
                        : isTablet
                        ? 9
                        : 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionList(bool isMobile, bool isTablet, bool isDesktop) {
    if (_isLoading && !_isLoadingFromCache) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            isMobile
                ? 24
                : isTablet
                ? 28
                : 32,
          ),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AdminDashboardStyles.primary,
            ),
          ),
        ),
      );
    }

    // Simple client-side filter (search/type/category/difficulty) for now
    Iterable<Map<String, dynamic>> items = _questions;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where(
        (e) =>
            (e['title'] ?? '').toString().toLowerCase().contains(q) ||
            (e['question'] ?? e['description'] ?? '')
                .toString()
                .toLowerCase()
                .contains(q),
      );
    }
    if (_selectedType != null) {
      items = items.where((e) {
        final questionType = (e['type'] ?? '').toString().toLowerCase();
        return questionType == _selectedType?.toLowerCase();
      });
    }
    if (_selectedCategory != null) {
      items = items.where(
        (e) => (e['category'] ?? '').toString() == _selectedCategory,
      );
    }
    if (_selectedDifficulty != null) {
      items = items.where(
        (e) =>
            (e['difficulty'] ?? '').toString().toLowerCase() ==
            _selectedDifficulty,
      );
    }

    final list = items.toList();
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          isMobile
              ? 24
              : isTablet
              ? 28
              : 32,
        ),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(
            isMobile
                ? 10
                : isTablet
                ? 11
                : 12,
          ),
          border: Border.all(
            color: AdminDashboardStyles.primary.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.live_help_rounded,
              color: AdminDashboardStyles.primary,
              size: isMobile
                  ? 32
                  : isTablet
                  ? 36
                  : 40,
            ),
            SizedBox(
              height: isMobile
                  ? 8
                  : isTablet
                  ? 9
                  : 10,
            ),
            Text(
              'No questions found',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AdminDashboardStyles.textDark,
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
              ),
            ),
            SizedBox(height: isMobile ? 3 : 4),
            Text(
              'Try adjusting filters or add new questions',
              style: TextStyle(
                fontSize: isMobile
                    ? 12
                    : isTablet
                    ? 12.5
                    : 13,
                color: AdminDashboardStyles.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => SizedBox(
        height: isMobile
            ? 10
            : isTablet
            ? 11
            : 12,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildQuestionCard(item, isMobile, isTablet, isDesktop);
      },
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> item,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final title = (item['title'] ?? 'Untitled').toString();
    final desc = (item['question'] ?? item['description'] ?? '').toString();
    final difficulty = (item['difficulty'] ?? 'easy').toString().toLowerCase();
    final type = (item['questionType'] ?? item['type'] ?? 'mcq')
        .toString()
        .toLowerCase();
    final source = (item['source'] ?? 'Skill Assessment').toString();
    final module = (item['module'] is Map)
        ? (item['module']['title'] ?? 'assessment')
        : (item['module'] ?? 'assessment');
    final category = (item['category'] ?? 'General').toString();

    Color diffColor;
    switch (difficulty) {
      case 'medium':
        diffColor = const Color(0xFFFFC107);
        break;
      case 'hard':
        diffColor = const Color(0xFFEF4444);
        break;
      default:
        diffColor = const Color(0xFF22C55E);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3FF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      padding: EdgeInsets.all(
        isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile
                ? 32
                : isTablet
                ? 34
                : 36,
            height: isMobile
                ? 32
                : isTablet
                ? 34
                : 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                isMobile
                    ? 8
                    : isTablet
                    ? 9
                    : 10,
              ),
              border: Border.all(color: AdminDashboardStyles.borderLight),
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: AdminDashboardStyles.accentBlue,
              size: isMobile
                  ? 18
                  : isTablet
                  ? 19
                  : 20,
            ),
          ),
          SizedBox(
            width: isMobile
                ? 10
                : isTablet
                ? 11
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile
                              ? 14
                              : isTablet
                              ? 15
                              : 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: isMobile
                          ? 6
                          : isTablet
                          ? 7
                          : 8,
                    ),
                    _actionIcon(
                      Icons.edit_rounded,
                      AdminDashboardStyles.accentBlue,
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EditQuestionPage(question: item),
                          ),
                        );
                        if (result == true) {
                          _loadQuestions(forceRefresh: true);
                        }
                      },
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(
                      width: isMobile
                          ? 6
                          : isTablet
                          ? 7
                          : 8,
                    ),
                    _actionIcon(
                      Icons.delete_rounded,
                      AdminDashboardStyles.statusError,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Delete not implemented'),
                          ),
                        );
                      },
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                  ],
                ),
                SizedBox(
                  height: isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                ),
                Wrap(
                  spacing: isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                  runSpacing: isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                  children: [
                    _chip(difficulty, diffColor, isMobile, isTablet, isDesktop),
                    _chip(
                      type,
                      const Color(0xFF60A5FA),
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
                    _chip(
                      source,
                      const Color(0xFFA7F3D0),
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  SizedBox(
                    height: isMobile
                        ? 10
                        : isTablet
                        ? 11
                        : 12,
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: isMobile
                          ? 12
                          : isTablet
                          ? 12.5
                          : 13,
                      color: AdminDashboardStyles.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(
                  height: isMobile
                      ? 10
                      : isTablet
                      ? 11
                      : 12,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: isMobile
                          ? 14
                          : isTablet
                          ? 15
                          : 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: isMobile ? 5 : 6),
                    Text(
                      module.toString(),
                      style: TextStyle(
                        fontSize: isMobile
                            ? 12
                            : isTablet
                            ? 12.5
                            : 13,
                        color: AdminDashboardStyles.textLight,
                      ),
                    ),
                    SizedBox(
                      width: isMobile
                          ? 12
                          : isTablet
                          ? 14
                          : 16,
                    ),
                    Icon(
                      Icons.category_rounded,
                      size: isMobile
                          ? 14
                          : isTablet
                          ? 15
                          : 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: isMobile ? 5 : 6),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: isMobile
                            ? 12
                            : isTablet
                            ? 12.5
                            : 13,
                        color: AdminDashboardStyles.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String text,
    Color color,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 8
            : isTablet
            ? 9
            : 10,
        vertical: isMobile
            ? 5
            : isTablet
            ? 5.5
            : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(
          isMobile
              ? 14
              : isTablet
              ? 15
              : 16,
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile
              ? 11
              : isTablet
              ? 11.5
              : 12,
          fontWeight: FontWeight.w700,
          color: _readableColorOn(color.withOpacity(0.15), fallback: color),
        ),
      ),
    );
  }

  Color _readableColorOn(Color background, {required Color fallback}) {
    // Quick contrast check; if background is light, return darker text (fallback)
    final luminance = background.computeLuminance();
    return luminance > 0.6 ? Colors.black87 : fallback;
  }

  Widget _actionIcon(
    IconData icon,
    Color color, {
    required VoidCallback onTap,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        isMobile
            ? 6
            : isTablet
            ? 7
            : 8,
      ),
      child: Container(
        padding: EdgeInsets.all(
          isMobile
              ? 6
              : isTablet
              ? 7
              : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isMobile
                ? 6
                : isTablet
                ? 7
                : 8,
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          size: isMobile
              ? 16
              : isTablet
              ? 17
              : 18,
          color: color,
        ),
      ),
    );
  }
}
