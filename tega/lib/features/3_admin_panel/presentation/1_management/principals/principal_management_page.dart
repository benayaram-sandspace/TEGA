import 'package:flutter/material.dart';
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

  String _selectedCollege = 'All';
  String _selectedGender = 'All';
  List<Principal> _principals = [];
  List<Principal> _filteredPrincipals = [];

  // Loading and error states
  bool _isLoading = true;
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
    _fetchPrincipalsFromAPI();
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
            _fetchPrincipalsFromAPI(); // Refresh principal data
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

  Future<void> _fetchPrincipalsFromAPI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
        });
        _startStaggeredAnimations();
      } else {
        setState(() {
          _errorMessage = 'Failed to load principals';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _buildCreatePrincipalFAB(),
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
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 12 : 16,
              ),
              child: _buildFilterSection(screenWidth),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState(screenWidth)
                  : _filteredPrincipals.isEmpty
                  ? _buildEmptyState(screenWidth)
                  : _buildPrincipalList(screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          isSmallScreen
              ? Column(
                  children: [
                    _buildSearchBar(isSmallScreen),
                    const SizedBox(height: 12),
                    _buildCollegeFilter(isSmallScreen),
                    const SizedBox(height: 12),
                    _buildGenderFilter(isSmallScreen),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchBar(isSmallScreen)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCollegeFilter(isSmallScreen)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGenderFilter(isSmallScreen)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return GestureDetector(
      onTap: () {}, // Prevent unfocusing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => _applyFilters(),
          decoration: InputDecoration(
            hintText: 'Search principals...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: isSmallScreen ? 20 : 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ),
    );
  }

  Widget _buildCollegeFilter(bool isSmallScreen) {
    return GestureDetector(
      onTap: () {}, // Prevent unfocusing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
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
              fontSize: isSmallScreen ? 12 : 14,
            ),
            prefixIcon: Icon(
              Icons.school,
              color: Colors.grey.shade500,
              size: isSmallScreen ? 18 : 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
          ),
          items: collegeOptions.map((college) {
            return DropdownMenuItem<String>(
              value: college,
              child: Text(
                college,
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          menuMaxHeight: 400,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildGenderFilter(bool isSmallScreen) {
    return GestureDetector(
      onTap: () {}, // Prevent unfocusing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
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
              fontSize: isSmallScreen ? 12 : 14,
            ),
            prefixIcon: Icon(
              Icons.person,
              color: Colors.grey.shade500,
              size: isSmallScreen ? 18 : 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
          ),
          items: genderOptions.map((gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(
                gender,
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
            );
          }).toList(),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading principals...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 16 : 24),
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              Icons.error_outline,
              size: isSmallScreen ? 48 : 64,
              color: const Color(0xFFEF4444),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Error Loading Principals',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton.icon(
              onPressed: _fetchPrincipalsFromAPI,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 16 : 24),
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              size: isSmallScreen ? 48 : 64,
              color: const Color(0xFF6B7280),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'No Principals Found',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'No principals match your current filters. Try adjusting your search criteria.',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    '• Clear your search terms\n• Try different college filters\n• Check your gender selection',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
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

  Widget _buildPrincipalList(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 8 : 12,
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
                  child: _buildPrincipalCard(principal, isSmallScreen),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrincipalCard(Principal principal, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: isSmallScreen ? 48 : 56,
                  height: isSmallScreen ? 48 : 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(
                      isSmallScreen ? 24 : 28,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      principal.name.isNotEmpty
                          ? principal.name[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                // Principal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        principal.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        principal.email,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        principal.university,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
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
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
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
                      fontSize: isSmallScreen ? 10 : 12,
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

  Widget _buildCreatePrincipalFAB() {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.school_rounded, size: 20),
            label: const Text(
              'Create Principal',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms, delay: 300.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}
