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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get _filteredCompanies {
    if (_searchQuery.isEmpty) {
      return _companies;
    }
    return _companies.where((company) {
      final name = (company['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeDesktop = MediaQuery.of(context).size.width >= 1440;
    final isDesktop =
        MediaQuery.of(context).size.width >= 1024 &&
        MediaQuery.of(context).size.width < 1440;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Company Specific Questions',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        _loadCompaniesAndQuestions(forceRefresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search companies...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Companies Grid
                  Expanded(
                    child: _filteredCompanies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context).disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No companies found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLargeDesktop
                                      ? 4
                                      : isDesktop
                                      ? 3
                                      : isTablet
                                      ? 2
                                      : 1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                ),
                            itemCount: _filteredCompanies.length,
                            itemBuilder: (context, index) {
                              final company = _filteredCompanies[index];
                              final name =
                                  company['name']?.toString() ?? 'Unknown';
                              final count = company['questionCount'] as int?;
                              final logo = company['logo'];
                              final logoToUse =
                                  (logo is String && logo.isNotEmpty)
                                  ? logo
                                  : _getFallbackLogo(name);

                              return _CompanyCard(
                                name: name,
                                count: count,
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
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onStartQuiz,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: logoUrl != null && logoUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: logoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.business,
                            color: Theme.of(context).primaryColor,
                          ),
                          placeholder: (_, __) => CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (count != null) ...[
                const SizedBox(height: 8),
                Text(
                  '$count Questions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
