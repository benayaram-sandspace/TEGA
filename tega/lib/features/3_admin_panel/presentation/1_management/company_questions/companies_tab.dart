import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class CompaniesTab extends StatefulWidget {
  const CompaniesTab({super.key});

  @override
  State<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<CompaniesTab> {
  final AuthService _auth = AuthService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  bool _isLoading = false;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _companies = [];

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
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);
      
      final cachedCompanies = await _cacheService.getCompanyListWithDetailsData();
      if (cachedCompanies != null && cachedCompanies.isNotEmpty) {
        setState(() {
          _companies = List<Map<String, dynamic>>.from(cachedCompanies);
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
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  Future<void> _loadCompanies({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _companies.isNotEmpty) {
      // Make sure loading is false since we have cached data
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _loadCompaniesInBackground();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminCompanyList),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final companies = (data['companies'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            final companyList = companies.map((c) {
              if (c is Map<String, dynamic>) {
                return c;
              }
              return {'name': c.toString(), 'questionCount': 0};
            }).toList();
            
            setState(() {
              _companies = companyList;
              _isLoading = false;
            });
            
            // Cache the data
            await _cacheService.setCompanyListWithDetailsData(companyList);
            
            // Reset toast flag on successful load (internet is back)
            _cacheService.resetNoInternetToastFlag();
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch companies');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch companies: ${res.statusCode}');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedCompanies = await _cacheService.getCompanyListWithDetailsData();
        if (cachedCompanies != null && cachedCompanies.isNotEmpty) {
          // Load from cache
          if (mounted) {
            setState(() {
              _companies = List<Map<String, dynamic>>.from(cachedCompanies);
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
          final companies = (data['companies'] ?? data['data'] ?? []) as List<dynamic>;
          final companyList = companies.map((c) {
            if (c is Map<String, dynamic>) {
              return c;
            }
            return {'name': c.toString(), 'questionCount': 0};
          }).toList();
          
          setState(() {
            _companies = companyList;
          });
          
          // Cache the data
          await _cacheService.setCompanyListWithDetailsData(companyList);
          
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminDashboardStyles.primary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: isMobile ? 12 : isTablet ? 16 : 20,
      ),
      child: _errorMessage != null && !_isLoadingFromCache
          ? _buildErrorState(isMobile, isTablet, isDesktop)
          : _companies.isEmpty
          ? _buildEmptyState(isMobile, isTablet, isDesktop)
          : _buildCompaniesGrid(isMobile, isTablet, isDesktop),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile ? 56 : isTablet ? 64 : 72,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
            Text(
              'Failed to load companies',
              style: TextStyle(
                fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isMobile ? 20 : isTablet ? 24 : 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadCompanies(forceRefresh: true);
              },
              icon: Icon(Icons.refresh, size: isMobile ? 18 : isTablet ? 20 : 22),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : isTablet ? 24 : 28,
                  vertical: isMobile ? 12 : isTablet ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.business_rounded,
            color: AdminDashboardStyles.primary,
            size: isMobile ? 32 : isTablet ? 36 : 40,
          ),
          SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
          Text(
            'No companies found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminDashboardStyles.textDark,
              fontSize: isMobile ? 14 : isTablet ? 15 : 16,
            ),
          ),
          SizedBox(height: isMobile ? 3 : 4),
          Text(
            'Upload PDFs or add questions to see companies here',
            style: TextStyle(
              fontSize: isMobile ? 12 : isTablet ? 12.5 : 13,
              color: AdminDashboardStyles.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesGrid(bool isMobile, bool isTablet, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final spacing = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
        final runSpacing = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: isMobile ? 2.3 : isTablet ? 2.4 : 2.5,
          ),
          itemCount: _companies.length,
          itemBuilder: (context, index) {
            return _buildCompanyCard(_companies[index], isMobile, isTablet, isDesktop);
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company, bool isMobile, bool isTablet, bool isDesktop) {
    final companyName = (company['name'] ?? company['companyName'] ?? 'Unknown').toString();
    final questionCount = company['questionCount'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : isTablet ? 12 : 14,
        isMobile ? 10 : isTablet ? 11 : 12,
        isMobile ? 10 : isTablet ? 12 : 14,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 36 : isTablet ? 38 : 40,
                height: isMobile ? 36 : isTablet ? 38 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: const Color(0xFF3B82F6),
                  size: isMobile ? 18 : isTablet ? 19 : 20,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : isTablet ? 7 : 8,
                  vertical: isMobile ? 3 : isTablet ? 3.5 : 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(isMobile ? 18 : isTablet ? 19 : 20),
                ),
                child: Text(
                  '$questionCount ${questionCount == 1 ? 'question' : 'questions'}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : isTablet ? 10.5 : 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : isTablet ? 7 : 8),
          Text(
            companyName,
            style: TextStyle(
              fontSize: isMobile ? 13 : isTablet ? 14 : 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 3 : isTablet ? 3.5 : 4),
          Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 3 : isTablet ? 3.5 : 4),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: isMobile ? 12 : isTablet ? 13 : 14,
                  color: AdminDashboardStyles.textLight,
                ),
                SizedBox(width: isMobile ? 5 : isTablet ? 5.5 : 6),
                Flexible(
                  child: Text(
                    'Questions available for practice',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : isTablet ? 10.5 : 11,
                      color: AdminDashboardStyles.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
