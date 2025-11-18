import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class ManageQuestionsTab extends StatefulWidget {
  const ManageQuestionsTab({super.key});

  @override
  State<ManageQuestionsTab> createState() => _ManageQuestionsTabState();
}

class _ManageQuestionsTabState extends State<ManageQuestionsTab> {
  final AuthService _auth = AuthService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  bool _isLoading = false;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];
  List<String> _companies = [];

  String? _selectedCompany;
  String? _selectedCategory;
  String? _selectedDifficulty;

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
    await _loadCompanies();
    await _loadQuestions();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);

      // Load questions from cache
      final cachedQuestions = await _cacheService.getCompanyQuestionsData();
      if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(cachedQuestions);
        });
      }

      // Load companies from cache
      final cachedCompanies = await _cacheService.getCompanyListData();
      if (cachedCompanies != null && cachedCompanies.isNotEmpty) {
        setState(() {
          _companies = List<String>.from(cachedCompanies);
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
    super.dispose();
  }

  Future<void> _loadCompanies({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _companies.isNotEmpty) {
      _loadCompaniesInBackground();
      return;
    }

    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminCompanyList),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final companies =
              (data['companies'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            final companyList = companies
                .map((c) {
                  // Extract company name from object or use string directly
                  if (c is Map<String, dynamic>) {
                    return (c['name'] ?? c['companyName'] ?? '').toString();
                  }
                  return c.toString();
                })
                .where((name) => name.isNotEmpty)
                .toList();

            setState(() {
              _companies = companyList;
            });

            // Cache the data
            await _cacheService.setCompanyListData(companyList);

            // Reset toast flag on successful load (internet is back)
            _cacheService.resetNoInternetToastFlag();
          }
        }
      }
    } catch (e) {
      // Silently fail - companies list is optional
    }
  }

  Future<void> _loadCompaniesInBackground() async {
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminCompanyList),
        headers: headers,
      );

      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final companies =
              (data['companies'] ?? data['data'] ?? []) as List<dynamic>;
          final companyList = companies
              .map((c) {
                if (c is Map<String, dynamic>) {
                  return (c['name'] ?? c['companyName'] ?? '').toString();
                }
                return c.toString();
              })
              .where((name) => name.isNotEmpty)
              .toList();

          setState(() {
            _companies = companyList;
          });

          // Cache the data
          await _cacheService.setCompanyListData(companyList);

          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
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
        Uri.parse(ApiEndpoints.adminCompanyQuestionsAll),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final list =
              (data['questions'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _questions = List<Map<String, dynamic>>.from(list);
              _isLoading = false;
            });

            // Cache the data
            await _cacheService.setCompanyQuestionsData(_questions);

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
        final cachedQuestions = await _cacheService.getCompanyQuestionsData();
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
        Uri.parse(ApiEndpoints.adminCompanyQuestionsAll),
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
          await _cacheService.setCompanyQuestionsData(_questions);

          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
          'Are you sure you want to delete this question? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.delete(
        Uri.parse(ApiEndpoints.adminCompanyQuestionDelete(questionId)),
        headers: headers,
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadQuestions(forceRefresh: true);
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(
          errorData['message'] ??
              'Failed to delete question: ${res.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredQuestions() {
    Iterable<Map<String, dynamic>> items = _questions;

    // Company filter
    if (_selectedCompany != null) {
      items = items.where((q) {
        final company = (q['companyName'] ?? '').toString();
        return company == _selectedCompany;
      });
    }

    // Category filter
    if (_selectedCategory != null) {
      items = items.where((q) {
        final category = (q['category'] ?? '').toString();
        return category == _selectedCategory;
      });
    }

    // Difficulty filter
    if (_selectedDifficulty != null) {
      items = items.where((q) {
        final difficulty = (q['difficulty'] ?? '').toString().toLowerCase();
        return difficulty == _selectedDifficulty?.toLowerCase();
      });
    }

    return items.toList();
  }

  double _calculateSuccessRate(Map<String, dynamic> question) {
    final totalAttempts = (question['totalAttempts'] ?? 0) as int;
    final correctAttempts = (question['correctAttempts'] ?? 0) as int;
    if (totalAttempts == 0) return 0.0;
    return (correctAttempts / totalAttempts) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: isMobile
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
                ? 16
                : isTablet
                ? 18
                : 20,
          ),
          _errorMessage != null && !_isLoadingFromCache
              ? _buildErrorState(isMobile, isTablet, isDesktop)
              : _buildQuestionList(isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 12
            : isTablet
            ? 16
            : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 6
                      : isTablet
                      ? 7
                      : 8,
                ),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 6
                        : isTablet
                        ? 7
                        : 8,
                  ),
                ),
                child: Icon(
                  Icons.filter_alt_rounded,
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
              Flexible(
                child: Text(
                  'Search & Filter Questions',
                  style: TextStyle(
                    fontSize: isMobile
                        ? 16
                        : isTablet
                        ? 17
                        : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isMobile
                ? 16
                : isTablet
                ? 18
                : 20,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildCompanyDropdown(
                        isMobile,
                        isTablet,
                        isDesktop,
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
                      child: _buildCategoryDropdown(
                        isMobile,
                        isTablet,
                        isDesktop,
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
                      child: _buildDifficultyDropdown(
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCompanyDropdown(isMobile, isTablet, isDesktop),
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
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown(bool isMobile, bool isTablet, bool isDesktop) {
    return DropdownButtonFormField<String>(
      value: _selectedCompany,
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
        hintText: 'All Companies',
        prefixIcon: Icons.business_rounded,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            'All Companies',
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
        ..._companies.map(
          (company) => DropdownMenuItem(
            value: company,
            child: Text(
              company,
              overflow: TextOverflow.ellipsis,
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
        ),
      ],
      onChanged: (value) => setState(() => _selectedCompany = value),
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
    return DropdownButtonFormField<String>(
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
      items: [
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
          value: 'reasoning',
          child: Text(
            'Reasoning',
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
          value: 'hr',
          child: Text(
            'HR',
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
      ],
      onChanged: (value) => setState(() => _selectedCategory = value),
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
    return DropdownButtonFormField<String>(
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
        prefixIcon: Icons.person_rounded,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
      ),
      items: [
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
      ],
      onChanged: (value) => setState(() => _selectedDifficulty = value),
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
    required IconData prefixIcon,
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
      prefixIcon: Icon(
        prefixIcon,
        color: AdminDashboardStyles.textLight,
        size: isMobile
            ? 18
            : isTablet
            ? 19
            : 20,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
        vertical: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          isMobile
              ? 8
              : isTablet
              ? 9
              : 10,
        ),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          isMobile
              ? 8
              : isTablet
              ? 9
              : 10,
        ),
        borderSide: BorderSide(color: AdminDashboardStyles.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          isMobile
              ? 8
              : isTablet
              ? 9
              : 10,
        ),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
    );
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

    final filteredQuestions = _getFilteredQuestions();

    if (filteredQuestions.isEmpty) {
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
      itemCount: filteredQuestions.length,
      separatorBuilder: (_, __) => SizedBox(
        height: isMobile
            ? 12
            : isTablet
            ? 14
            : 16,
      ),
      itemBuilder: (context, index) {
        return _buildQuestionCard(
          filteredQuestions[index],
          isMobile,
          isTablet,
          isDesktop,
        );
      },
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final companyName = (question['companyName'] ?? '').toString();
    final difficulty = (question['difficulty'] ?? 'medium').toString();
    final category = (question['category'] ?? 'technical').toString();
    final questionText =
        (question['questionText'] ?? question['question'] ?? '').toString();
    final questionType = (question['questionType'] ?? 'mcq').toString();
    final points = (question['points'] ?? 10).toString();
    final successRate = _calculateSuccessRate(question);
    final questionId = (question['_id'] ?? question['id']).toString();

    Color getDifficultyColor(String diff) {
      switch (diff.toLowerCase()) {
        case 'hard':
          return const Color(0xFFEF4444);
        case 'medium':
          return const Color(0xFFF59E0B);
        case 'easy':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF6B7280);
      }
    }

    Color getCategoryColor(String cat) {
      switch (cat.toLowerCase()) {
        case 'technical':
          return const Color(0xFF8B5CF6);
        case 'coding':
          return const Color(0xFF3B82F6);
        case 'aptitude':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF6B7280);
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 12
            : isTablet
            ? 16
            : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 10
              : isTablet
              ? 11
              : 12,
        ),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
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
                    _buildTag(
                      companyName,
                      const Color(0xFFDBEAFE),
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
                    _buildTag(
                      difficulty,
                      getDifficultyColor(difficulty).withOpacity(0.2),
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
                    _buildTag(
                      category,
                      getCategoryColor(category).withOpacity(0.2),
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: isMobile
                    ? 6
                    : isTablet
                    ? 7
                    : 8,
              ),
              IconButton(
                onPressed: () => _deleteQuestion(questionId),
                icon: Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: isMobile
                      ? 18
                      : isTablet
                      ? 19
                      : 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
          Text(
            questionText,
            style: TextStyle(
              fontSize: isMobile
                  ? 13
                  : isTablet
                  ? 14
                  : 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Flexible(
                      child: _buildMetadataItem(
                        icon: Icons.description_rounded,
                        label: 'Type',
                        value: questionType,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ),
                    SizedBox(
                      width: isMobile
                          ? 12
                          : isTablet
                          ? 14
                          : 16,
                    ),
                    Flexible(
                      child: _buildMetadataItem(
                        icon: Icons.person_rounded,
                        label: 'Points',
                        value: points,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ),
                    SizedBox(
                      width: isMobile
                          ? 12
                          : isTablet
                          ? 14
                          : 16,
                    ),
                    Flexible(
                      child: _buildMetadataItem(
                        icon: Icons.trending_up_rounded,
                        label: 'Success Rate',
                        value: '${successRate.toStringAsFixed(0)}%',
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataItem(
                      icon: Icons.description_rounded,
                      label: 'Type',
                      value: questionType,
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(
                      height: isMobile
                          ? 6
                          : isTablet
                          ? 7
                          : 8,
                    ),
                    _buildMetadataItem(
                      icon: Icons.person_rounded,
                      label: 'Points',
                      value: points,
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(
                      height: isMobile
                          ? 6
                          : isTablet
                          ? 7
                          : 8,
                    ),
                    _buildMetadataItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Success Rate',
                      value: '${successRate.toStringAsFixed(0)}%',
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
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
        color: color,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 14
              : isTablet
              ? 15
              : 16,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile
              ? 11
              : isTablet
              ? 11.5
              : 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isMobile
              ? 14
              : isTablet
              ? 15
              : 16,
          color: AdminDashboardStyles.textLight,
        ),
        SizedBox(
          width: isMobile
              ? 5
              : isTablet
              ? 5.5
              : 6,
        ),
        Flexible(
          child: Text(
            '$label: ',
            style: TextStyle(
              fontSize: isMobile
                  ? 12
                  : isTablet
                  ? 12.5
                  : 13,
              color: AdminDashboardStyles.textLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile
                  ? 12
                  : isTablet
                  ? 12.5
                  : 13,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
