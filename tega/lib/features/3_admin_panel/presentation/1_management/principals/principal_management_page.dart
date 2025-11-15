import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/models/principal_model.dart';
import 'package:tega/data/colleges_data.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/create_principal_page.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'principal_profile_page.dart';

class PrincipalManagementPage extends StatefulWidget {
  const PrincipalManagementPage({super.key});

  @override
  State<PrincipalManagementPage> createState() =>
      _PrincipalManagementPageState();
}

class _PrincipalManagementPageState extends State<PrincipalManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  String _selectedCollege = 'All';
  String _selectedGender = 'All';
  List<Principal> _principals = [];
  List<Principal> _filteredPrincipals = [];

  // Loading and error states
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;

  // Enhanced animation controllers
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  // Get colleges list with "All" option
  List<String> get collegeOptions => ['All', ...collegesData];

  // Gender options
  List<String> get genderOptions => ['All', 'Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();
    
    // Try to load from cache first
    await _loadFromCache();
    
    // Then load fresh data
    await _fetchPrincipalsFromAPI();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);
      
      final cachedData = await _cacheService.getPrincipalsData();

      if (cachedData != null && cachedData['success'] == true) {
        final principalsData = cachedData['principals'] as List<dynamic>;
        setState(() {
          _principals = principalsData
              .map((principal) => Principal.fromJson(principal))
              .toList();
          _filteredPrincipals = List.from(_principals);
          _isLoadingFromCache = false;
        });
        _startStaggeredAnimations();
      } else {
        setState(() => _isLoadingFromCache = false);
      }
    } catch (e) {
      setState(() => _isLoadingFromCache = false);
    }
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      50, // Maximum expected principals
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 30)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
        .toList();

    _slideAnimations = _animationControllers
        .map(
          (controller) =>
              Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              ),
        )
        .toList();
  }

  void _startStaggeredAnimations() {
    for (
      int i = 0;
      i < _filteredPrincipals.length && i < _animationControllers.length;
      i++
    ) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  void _navigateToCreatePrincipalPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePrincipalPage(
          onPrincipalCreated: () {
            _fetchPrincipalsFromAPI(forceRefresh: true); // Refresh principal data
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _fetchPrincipalsFromAPI({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _principals.isNotEmpty) {
      _fetchPrincipalsFromAPIInBackground();
      return;
    }

    if (!_isLoadingFromCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _dashboardService.getAllPrincipals();
      if (data['success'] == true) {
        final principalsData = data['principals'] as List<dynamic>;
        setState(() {
          _principals = principalsData
              .map((principal) => Principal.fromJson(principal))
              .toList();
          _filteredPrincipals = List.from(_principals);
          _isLoading = false;
          _isLoadingFromCache = false;
          _errorMessage = null; // Clear error on success
        });
        _startStaggeredAnimations();
        
        // Cache the data
        await _cacheService.setPrincipalsData(data);
      } else {
        throw Exception(data['message'] ?? 'Failed to load principals');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getPrincipalsData();
        if (cachedData != null && cachedData['success'] == true) {
          final principalsData = cachedData['principals'] as List<dynamic>;
          if (principalsData.isNotEmpty) {
            // Load from cache and show toast
            setState(() {
              _principals = principalsData
                  .map((principal) => Principal.fromJson(principal))
                  .toList();
              _filteredPrincipals = List.from(_principals);
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = null; // Clear error since we have cached data
            });
            _startStaggeredAnimations();
            return;
          }
        }
        
        // No cache available, show error
        setState(() {
          _errorMessage = 'No internet connection';
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      } else {
        // Other errors
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      }
    }
  }

  Future<void> _fetchPrincipalsFromAPIInBackground() async {
    try {
      final data = await _dashboardService.getAllPrincipals();
      if (data['success'] == true && mounted) {
        final principalsData = data['principals'] as List<dynamic>;
        setState(() {
          _principals = principalsData
              .map((principal) => Principal.fromJson(principal))
              .toList();
          _filteredPrincipals = List.from(_principals);
        });
        _startStaggeredAnimations();
        
        // Cache the data
        await _cacheService.setPrincipalsData(data);
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPrincipals = _principals.where((principal) {
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            principal.name.toLowerCase().contains(searchQuery) ||
            principal.email.toLowerCase().contains(searchQuery) ||
            principal.university.toLowerCase().contains(searchQuery) ||
            principal.id.toLowerCase().contains(searchQuery);

        final matchesCollege =
            _selectedCollege == 'All' ||
            principal.university == _selectedCollege;

        final matchesGender =
            _selectedGender == 'All' ||
            principal.gender.toLowerCase() == _selectedGender.toLowerCase();

        return matchesSearch && matchesCollege && matchesGender;
      }).toList();
    });
    _startStaggeredAnimations();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _buildCreatePrincipalFAB(isMobile, isTablet, isDesktop),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : isTablet ? 20 : 24,
                isMobile ? 16 : isTablet ? 20 : 24,
                isMobile ? 16 : isTablet ? 20 : 24,
                isMobile ? 12 : isTablet ? 14 : 16,
              ),
              child: _buildFilterSection(isMobile, isTablet, isDesktop),
            ),
            Expanded(
              child: _isLoading && !_isLoadingFromCache
                  ? _buildLoadingState(isMobile, isTablet, isDesktop)
                  : _errorMessage != null && !_isLoadingFromCache
                  ? _buildErrorState(isMobile, isTablet, isDesktop)
                  : _filteredPrincipals.isEmpty
                  ? _buildEmptyState(isMobile, isTablet, isDesktop)
                  : _buildPrincipalList(isMobile, isTablet, isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Principals',
            style: TextStyle(
              fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          isMobile
              ? Column(
                  children: [
                    _buildSearchBar(isMobile, isTablet, isDesktop),
                    SizedBox(height: isMobile ? 10 : 12),
                    _buildCollegeFilter(isMobile, isTablet, isDesktop),
                    SizedBox(height: isMobile ? 10 : 12),
                    _buildGenderFilter(isMobile, isTablet, isDesktop),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchBar(isMobile, isTablet, isDesktop)),
                    SizedBox(width: isTablet ? 12 : 16),
                    Expanded(child: _buildCollegeFilter(isMobile, isTablet, isDesktop)),
                    SizedBox(width: isTablet ? 12 : 16),
                    Expanded(child: _buildGenderFilter(isMobile, isTablet, isDesktop)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile, bool isTablet, bool isDesktop) {
    return GestureDetector(
      onTap: () {}, // Prevent unfocusing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => _applyFilters(),
          decoration: InputDecoration(
            hintText: 'Search principals...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isMobile ? 13 : isTablet ? 14 : 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: isMobile ? 18 : isTablet ? 20 : 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: isMobile ? 16 : isTablet ? 18 : 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : isTablet ? 14 : 16,
              vertical: isMobile ? 12 : isTablet ? 14 : 16,
            ),
          ),
          style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 16),
        ),
      ),
    );
  }

  Widget _buildCollegeFilter(bool isMobile, bool isTablet, bool isDesktop) {
    return GestureDetector(
      onTap: () {}, // Prevent unfocusing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedCollege,
          onChanged: (value) {
            setState(() {
              _selectedCollege = value!;
            });
            _applyFilters();
          },
          decoration: InputDecoration(
            labelText: 'College',
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobile ? 11 : isTablet ? 12 : 14,
            ),
            prefixIcon: Icon(
              Icons.school,
              color: Colors.grey.shade500,
              size: isMobile ? 16 : isTablet ? 18 : 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : isTablet ? 14 : 16,
              vertical: isMobile ? 12 : isTablet ? 14 : 16,
            ),
          ),
          items: collegeOptions.map((college) {
            return DropdownMenuItem<String>(
              value: college,
              child: Text(
                college,
                style: TextStyle(fontSize: isMobile ? 12 : isTablet ? 13 : 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          menuMaxHeight: isMobile ? 300 : 400,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildGenderFilter(bool isMobile, bool isTablet, bool isDesktop) {
    return GestureDetector(
      onTap: () {}, // Prevent unfocusing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
            _applyFilters();
          },
          decoration: InputDecoration(
            labelText: 'Gender',
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobile ? 11 : isTablet ? 12 : 14,
            ),
            prefixIcon: Icon(
              Icons.person,
              color: Colors.grey.shade500,
              size: isMobile ? 16 : isTablet ? 18 : 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : isTablet ? 14 : 16,
              vertical: isMobile ? 12 : isTablet ? 14 : 16,
            ),
          ),
          items: genderOptions.map((gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(
                gender,
                style: TextStyle(fontSize: isMobile ? 12 : isTablet ? 13 : 14),
              ),
            );
          }).toList(),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          Text(
            'Loading principals...',
            style: TextStyle(
              fontSize: isMobile ? 14 : isTablet ? 15 : 16,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(isMobile ? 20 : isTablet ? 24 : 28),
        padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : isTablet ? 18 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile ? 56 : isTablet ? 64 : 72,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
            Text(
              'Failed to load principals',
              style: TextStyle(
                fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),
            ElevatedButton.icon(
              onPressed: () => _fetchPrincipalsFromAPI(forceRefresh: true),
              icon: Icon(Icons.refresh, size: isMobile ? 16 : isTablet ? 17 : 18),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : isTablet ? 24 : 28,
                  vertical: isMobile ? 12 : isTablet ? 13 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
        padding: EdgeInsets.all(isMobile ? 20 : isTablet ? 22 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: isMobile ? 48 : isTablet ? 56 : 64,
              color: const Color(0xFF6B7280),
            ),
            SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
            Text(
              'No Principals Found',
              style: TextStyle(
                fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: isMobile ? 8 : isTablet ? 10 : 12),
            Text(
              'No principals match your current filters. Try adjusting your search criteria.',
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
              ),
              child: Column(
                children: [
                  Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : isTablet ? 10 : 12),
                  Text(
                    '• Clear your search terms\n• Try different college filters\n• Check your gender selection',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrincipalList(bool isMobile, bool isTablet, bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : isTablet ? 18 : 20,
        vertical: isMobile ? 8 : isTablet ? 10 : 12,
      ),
      itemCount: _filteredPrincipals.length,
      itemBuilder: (context, index) {
        final principal = _filteredPrincipals[index];
        final animationIndex = index % _animationControllers.length;

        return AnimatedBuilder(
          animation: _animationControllers[animationIndex],
          builder: (context, child) {
            return FadeTransition(
              opacity: _animationControllers[animationIndex],
              child: SlideTransition(
                position: _slideAnimations[animationIndex],
                child: ScaleTransition(
                  scale: _scaleAnimations[animationIndex],
                  child: _buildPrincipalCard(principal, isMobile, isTablet, isDesktop),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrincipalCard(Principal principal, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : isTablet ? 14 : 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PrincipalProfilePage(principal: principal),
              ),
            );
          },
          borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: isMobile ? 48 : isTablet ? 52 : 56,
                  height: isMobile ? 48 : isTablet ? 52 : 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(
                      isMobile ? 24 : isTablet ? 26 : 28,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      principal.name.isNotEmpty
                          ? principal.name[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : isTablet ? 14 : 16),
                // Principal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        principal.name,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 4 : isTablet ? 5 : 6),
                      Text(
                        principal.email,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 4 : isTablet ? 5 : 6),
                      Text(
                        principal.university,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : isTablet ? 12.5 : 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : isTablet ? 10 : 12,
                    vertical: isMobile ? 4 : isTablet ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: principal.isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: principal.isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    principal.status,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : isTablet ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: principal.isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePrincipalFAB(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
            boxShadow: [
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreatePrincipalPage,
            backgroundColor: AdminDashboardStyles.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
            ),
            icon: Icon(
              Icons.school_rounded,
              size: isMobile ? 18 : isTablet ? 19 : 20,
            ),
            label: Text(
              'Create Principal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms, delay: 300.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}
