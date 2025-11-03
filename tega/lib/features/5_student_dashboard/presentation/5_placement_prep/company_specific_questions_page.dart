import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/config/env_config.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/company_quiz_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCompaniesAndQuestions();
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

  Future<void> _loadCompaniesAndQuestions() async {
    try {
      setState(() => _isLoading = true);
      final auth = AuthService();
      final headers = auth.getAuthHeaders();

      final companiesResp = await http.get(
        Uri.parse(ApiEndpoints.companyQuestionsList),
        headers: headers,
      );
      if (companiesResp.statusCode == 200) {
        final data = json.decode(companiesResp.body);
        final list = (data['data'] ?? data['companies'] ?? []) as List<dynamic>;
        _companies = list
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
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // (Questions are loaded on the quiz page; no per-company preload here)

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF6B5FFF),
              size: 20,
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
                isDesktop
                    ? 24
                    : isTablet
                    ? 20
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
                    padding: EdgeInsets.all(isDesktop ? 16 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B5FFF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: isDesktop ? 32 : 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice & Excel',
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 20
                                : isTablet
                                ? 18
                                : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Master company-specific questions and ace your interviews',
                          style: TextStyle(
                            fontSize: isDesktop ? 13 : 12,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
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
                  : Padding(
                      padding: EdgeInsets.all(
                        isDesktop
                            ? 20
                            : isTablet
                            ? 16
                            : 12,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 1200
                              ? 4
                              : width > 900
                              ? 3
                              : width > 600
                              ? 2
                              : 1;
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 2.4,
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

  Widget _buildEmptyState(bool isDesktop, bool isTablet, {String? message}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isDesktop
              ? 40
              : isTablet
              ? 32
              : 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6B5FFF).withOpacity(0.1),
                    const Color(0xFF8F7FFF).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: isDesktop
                    ? 80
                    : isTablet
                    ? 70
                    : 60,
                color: const Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'No Questions Available',
              style: TextStyle(
                fontSize: isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a company to fetch questions',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // No filters in this view
          ],
        ),
      ),
    );
  }
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: logoUrl != null && logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _CompanyLogo(url: logoUrl!),
                    )
                  : const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF6B5FFF),
                    ),
            ),
            const SizedBox(width: 10),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF6B5FFF),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (count != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5FFF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.quiz_outlined,
                            color: Color(0xFF6B5FFF),
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Available Questions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
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
                            style: const TextStyle(
                              color: Color(0xFF6B5FFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onStartQuiz,
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Practice Quiz',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5FFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
    return FadeInImage.assetNetwork(
      placeholder: 'assets/placeholder.png',
      image: resolved,
      fit: BoxFit.cover,
      imageErrorBuilder: (_, __, ___) =>
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
