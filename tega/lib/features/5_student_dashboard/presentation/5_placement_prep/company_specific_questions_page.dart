import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/config/env_config.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/company_quiz_page.dart';
import 'package:tega/core/services/placement_prep_cache_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CompanySpecificQuestionsPage extends StatefulWidget {
  const CompanySpecificQuestionsPage({super.key});

  @override
  State<CompanySpecificQuestionsPage> createState() =>
      _CompanySpecificQuestionsPageState();
}

class _CompanySpecificQuestionsPageState
    extends State<CompanySpecificQuestionsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _companies = [];
  String? _errorMessage;
  final PlacementPrepCacheService _cacheService = PlacementPrepCacheService();

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadCompaniesAndQuestions();
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

  String? _getFallbackLogo(String companyName) {
    final normalized = companyName.trim().toLowerCase();
    const domainMap = {
      'accenture': 'accenture.com',
      'infosys': 'infosys.com',
      'tcs': 'tcs.com',
      'tata consultancy services': 'tcs.com',
      'tech mahindra': 'techmahindra.com',
      'virtusa': 'virtusa.com',
      'wipro': 'wipro.com',
      'cognizant': 'cognizant.com',
      'hcl': 'hcltech.com',
      'hcl technologies': 'hcltech.com',
      'amazon': 'amazon.com',
      'google': 'google.com',
      'microsoft': 'microsoft.com',
      'deloitte': 'deloitte.com',
      'capgemini': 'capgemini.com',
      'ibm': 'ibm.com',
      'oracle': 'oracle.com',
    };
    String? domain = domainMap[normalized];
    if (domain == null) {
      // Try a simple heuristic by removing spaces and appending .com
      final guess = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (guess.isNotEmpty) domain = '$guess.com';
    }
    return domain != null ? 'https://logo.clearbit.com/$domain' : null;
  }

  Future<void> _loadCompaniesAndQuestions({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Try to load from cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedCompanies = await _cacheService.getCompaniesData();
        if (cachedCompanies != null && cachedCompanies.isNotEmpty && mounted) {
          setState(() {
            _companies = cachedCompanies;
            _isLoading = false;
            _errorMessage = null;
          });
          // Still fetch in background to update cache
          _fetchCompaniesInBackground();
          return;
        }
      }

      // Fetch from API
      await _fetchCompaniesInBackground();
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          setState(() {
            _errorMessage = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fetchCompaniesInBackground() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();

      final companiesResp = await http.get(
        Uri.parse(ApiEndpoints.companyQuestionsList),
        headers: headers,
      );
      if (companiesResp.statusCode == 200) {
        final data = json.decode(companiesResp.body);
        final list = (data['data'] ?? data['companies'] ?? []) as List<dynamic>;
        final companies = list
            .map<Map<String, dynamic>>((e) {
              if (e is Map) {
                final name = (e['companyName'] ?? e['name'] ?? e['title'] ?? '')
                    .toString();
                final count =
                    e['questionCount'] ??
                    e['count'] ??
                    e['totalQuestions'] ??
                    e['questions']?.length;
                final logo = e['logo'] ?? e['imageUrl'];
                return {'name': name, 'count': count, 'logo': logo};
              }
              return {'name': e.toString(), 'count': null, 'logo': null};
            })
            .where((m) => (m['name'] as String).isNotEmpty)
            .toList();

        // Cache the data
        await _cacheService.setCompaniesData(companies);

        if (mounted) {
          setState(() {
            _companies = companies;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load companies';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          setState(() {
            _errorMessage = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  // (Questions are loaded on the quiz page; no per-company preload here)

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
            ),
            child: Icon(
              Icons.arrow_back,
              color: const Color(0xFF6B5FFF),
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 18
                  : 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 32
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6B5FFF).withOpacity(0.08),
                    const Color(0xFF8F7FFF).withOpacity(0.04),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isLargeDesktop
                          ? 20
                          : isDesktop
                          ? 16
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 10
                          : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                      ),
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 16
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 10
                            : 12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B5FFF).withOpacity(0.3),
                          blurRadius: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 12
                              : isTablet
                              ? 10
                              : isSmallScreen
                              ? 6
                              : 8,
                          offset: Offset(
                            0,
                            isLargeDesktop
                                ? 6
                                : isDesktop
                                ? 4
                                : isTablet
                                ? 3
                                : isSmallScreen
                                ? 2
                                : 3,
                          ),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: isLargeDesktop
                          ? 40
                          : isDesktop
                          ? 32
                          : isTablet
                          ? 30
                          : isSmallScreen
                          ? 22
                          : 28,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 8
                        : 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice & Excel',
                          style: TextStyle(
                            fontSize: isLargeDesktop
                                ? 26
                                : isDesktop
                                ? 22
                                : isTablet
                                ? 20
                                : isSmallScreen
                                ? 16
                                : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(
                          height: isLargeDesktop || isDesktop
                              ? 6
                              : isTablet
                              ? 5
                              : 4,
                        ),
                        Text(
                          'Master company-specific questions and ace your interviews',
                          style: TextStyle(
                            fontSize: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 15
                                : isTablet
                                ? 14
                                : isSmallScreen
                                ? 11
                                : 13,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: isLargeDesktop || isDesktop
                              ? 3
                              : isTablet
                              ? 2
                              : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Companies Grid (light theme)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B5FFF),
                      ),
                    )
                  : _errorMessage != null && _companies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(
                          isLargeDesktop
                              ? 32
                              : isDesktop
                              ? 28
                              : isTablet
                              ? 24
                              : isSmallScreen
                              ? 16
                              : 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: isLargeDesktop
                                  ? 80
                                  : isDesktop
                                  ? 72
                                  : isTablet
                                  ? 64
                                  : isSmallScreen
                                  ? 48
                                  : 56,
                              color: Colors.grey[400],
                            ),
                            SizedBox(
                              height: isLargeDesktop
                                  ? 24
                                  : isDesktop
                                  ? 20
                                  : isTablet
                                  ? 18
                                  : isSmallScreen
                                  ? 12
                                  : 16,
                            ),
                            Text(
                              _errorMessage == 'No internet connection'
                                  ? 'No internet connection'
                                  : 'Something went wrong',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isLargeDesktop
                                    ? 18
                                    : isDesktop
                                    ? 16
                                    : isTablet
                                    ? 15
                                    : isSmallScreen
                                    ? 12
                                    : 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_errorMessage == 'No internet connection') ...[
                              SizedBox(
                                height: isLargeDesktop
                                    ? 8
                                    : isDesktop
                                    ? 6
                                    : isTablet
                                    ? 5
                                    : isSmallScreen
                                    ? 4
                                    : 5,
                              ),
                              Text(
                                'Please check your connection and try again',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isLargeDesktop
                                      ? 14
                                      : isDesktop
                                      ? 13
                                      : isTablet
                                      ? 12
                                      : isSmallScreen
                                      ? 10
                                      : 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            SizedBox(
                              height: isLargeDesktop
                                  ? 24
                                  : isDesktop
                                  ? 20
                                  : isTablet
                                  ? 18
                                  : isSmallScreen
                                  ? 12
                                  : 16,
                            ),
                            ElevatedButton(
                              onPressed: () => _loadCompaniesAndQuestions(
                                forceRefresh: true,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B5FFF),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLargeDesktop
                                      ? 24
                                      : isDesktop
                                      ? 20
                                      : isTablet
                                      ? 18
                                      : isSmallScreen
                                      ? 12
                                      : 16,
                                  vertical: isLargeDesktop
                                      ? 14
                                      : isDesktop
                                      ? 12
                                      : isTablet
                                      ? 11
                                      : isSmallScreen
                                      ? 8
                                      : 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isLargeDesktop
                                        ? 12
                                        : isDesktop
                                        ? 10
                                        : isTablet
                                        ? 9
                                        : isSmallScreen
                                        ? 6
                                        : 8,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: isLargeDesktop
                                        ? 22
                                        : isDesktop
                                        ? 20
                                        : isTablet
                                        ? 19
                                        : isSmallScreen
                                        ? 16
                                        : 18,
                                  ),
                                  SizedBox(
                                    width: isLargeDesktop
                                        ? 8
                                        : isDesktop
                                        ? 6
                                        : isTablet
                                        ? 5
                                        : isSmallScreen
                                        ? 4
                                        : 5,
                                  ),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: isLargeDesktop
                                          ? 16
                                          : isDesktop
                                          ? 15
                                          : isTablet
                                          ? 14
                                          : isSmallScreen
                                          ? 12
                                          : 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(
                        isLargeDesktop
                            ? 28
                            : isDesktop
                            ? 24
                            : isTablet
                            ? 20
                            : isSmallScreen
                            ? 12
                            : 16,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 1400
                              ? 4
                              : width > 1000
                              ? 3
                              : width > 600
                              ? 2
                              : 1;
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: isLargeDesktop
                                      ? 16
                                      : isDesktop
                                      ? 14
                                      : isTablet
                                      ? 12
                                      : isSmallScreen
                                      ? 8
                                      : 10,
                                  crossAxisSpacing: isLargeDesktop
                                      ? 16
                                      : isDesktop
                                      ? 14
                                      : isTablet
                                      ? 12
                                      : isSmallScreen
                                      ? 8
                                      : 10,
                                  childAspectRatio: isLargeDesktop || isDesktop
                                      ? 2.6
                                      : isTablet
                                      ? 2.4
                                      : isSmallScreen
                                      ? 2.2
                                      : 2.3,
                                ),
                            itemCount: _companies.length,
                            itemBuilder: (context, index) {
                              final item = _companies[index];
                              final name = (item['name'] ?? '').toString();
                              final count = item['count'];
                              final logo = item['logo'];
                              final logoToUse =
                                  (logo is String && logo.isNotEmpty)
                                  ? logo
                                  : _getFallbackLogo(name);
                              return _CompanyCard(
                                name: name,
                                count: count is int ? count : null,
                                logoUrl: logoToUse,
                                onStartQuiz: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CompanyQuizPage(companyName: name),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // No filters needed in the grid view design
}

// (Question card removed in grid-only view)

class _CompanyCard extends StatelessWidget {
  final String name;
  final int? count;
  final String? logoUrl;
  final VoidCallback onStartQuiz;
  const _CompanyCard({
    required this.name,
    this.count,
    this.logoUrl,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDesktop = screenWidth >= 1440;
    final isDesktop = screenWidth >= 1024 && screenWidth < 1440;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isSmallScreen = screenWidth < 400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 18
              : isDesktop
              ? 16
              : isTablet
              ? 14
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: isLargeDesktop
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 10
                : isSmallScreen
                ? 6
                : 8,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 7
                  : isDesktop
                  ? 5
                  : isTablet
                  ? 4
                  : isSmallScreen
                  ? 2
                  : 3,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 8
              : 10,
        ),
        child: Row(
          children: [
            Container(
              width: isLargeDesktop
                  ? 56
                  : isDesktop
                  ? 48
                  : isTablet
                  ? 44
                  : isSmallScreen
                  ? 32
                  : 40,
              height: isLargeDesktop
                  ? 56
                  : isDesktop
                  ? 48
                  : isTablet
                  ? 44
                  : isSmallScreen
                  ? 32
                  : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
              ),
              child: logoUrl != null && logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 16
                            : isDesktop
                            ? 14
                            : isTablet
                            ? 12
                            : isSmallScreen
                            ? 8
                            : 10,
                      ),
                      child: _CompanyLogo(url: logoUrl!),
                    )
                  : Icon(
                      Icons.apartment_rounded,
                      color: const Color(0xFF6B5FFF),
                      size: isLargeDesktop
                          ? 28
                          : isDesktop
                          ? 24
                          : isTablet
                          ? 22
                          : isSmallScreen
                          ? 16
                          : 20,
                    ),
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 6
                  : 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: isLargeDesktop
                                ? 18
                                : isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : isSmallScreen
                                ? 12
                                : 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: isLargeDesktop || isDesktop
                              ? 2
                              : isTablet
                              ? 2
                              : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFF6B5FFF),
                        size: isLargeDesktop
                            ? 24
                            : isDesktop
                            ? 20
                            : isTablet
                            ? 18
                            : isSmallScreen
                            ? 14
                            : 16,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 6
                        : isDesktop
                        ? 5
                        : isTablet
                        ? 4
                        : isSmallScreen
                        ? 2
                        : 3,
                  ),
                  if (count != null)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            isLargeDesktop
                                ? 6
                                : isDesktop
                                ? 5
                                : isTablet
                                ? 4.5
                                : isSmallScreen
                                ? 3
                                : 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5FFF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 8
                                  : isDesktop
                                  ? 7
                                  : isTablet
                                  ? 6
                                  : isSmallScreen
                                  ? 4
                                  : 5,
                            ),
                          ),
                          child: Icon(
                            Icons.quiz_outlined,
                            color: const Color(0xFF6B5FFF),
                            size: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 14
                                : isTablet
                                ? 13
                                : isSmallScreen
                                ? 10
                                : 12,
                          ),
                        ),
                        SizedBox(
                          width: isLargeDesktop
                              ? 8
                              : isDesktop
                              ? 7
                              : isTablet
                              ? 6
                              : isSmallScreen
                              ? 4
                              : 5,
                        ),
                        Text(
                          'Available Questions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isLargeDesktop
                                ? 13
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 9
                                : 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: isLargeDesktop
                              ? 8
                              : isDesktop
                              ? 7
                              : isTablet
                              ? 6
                              : isSmallScreen
                              ? 4
                              : 5,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeDesktop
                                ? 8
                                : isDesktop
                                ? 7
                                : isTablet
                                ? 6
                                : isSmallScreen
                                ? 4
                                : 5,
                            vertical: isLargeDesktop
                                ? 4
                                : isDesktop
                                ? 3.5
                                : isTablet
                                ? 3
                                : isSmallScreen
                                ? 2
                                : 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5FFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF6B5FFF).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            '${count} Qs',
                            style: TextStyle(
                              color: const Color(0xFF6B5FFF),
                              fontWeight: FontWeight.w700,
                              fontSize: isLargeDesktop
                                  ? 12
                                  : isDesktop
                                  ? 11
                                  : isTablet
                                  ? 10
                                  : isSmallScreen
                                  ? 8
                                  : 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 8
                        : isDesktop
                        ? 7
                        : isTablet
                        ? 6
                        : isSmallScreen
                        ? 4
                        : 5,
                  ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 44
                        : isDesktop
                        ? 40
                        : isTablet
                        ? 38
                        : isSmallScreen
                        ? 32
                        : 36,
                    child: ElevatedButton.icon(
                      onPressed: onStartQuiz,
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 17
                            : isSmallScreen
                            ? 14
                            : 16,
                      ),
                      label: Text(
                        'Practice Quiz',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isLargeDesktop
                              ? 14
                              : isDesktop
                              ? 13
                              : isTablet
                              ? 12
                              : isSmallScreen
                              ? 10
                              : 11,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5FFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isLargeDesktop
                                ? 10
                                : isDesktop
                                ? 9
                                : isTablet
                                ? 8
                                : isSmallScreen
                                ? 6
                                : 7,
                          ),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeDesktop
                              ? 14
                              : isDesktop
                              ? 12
                              : isTablet
                              ? 11
                              : isSmallScreen
                              ? 8
                              : 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String url;
  const _CompanyLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveUrl(url);
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFF6B5FFF).withOpacity(0.08),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
          ),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.apartment_rounded, color: Color(0xFF6B5FFF)),
    );
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = EnvConfig.baseUrl;
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/$raw';
  }
}
