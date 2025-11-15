import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/data/colleges_data.dart';
import 'package:tega/features/3_admin_panel/data/models/offer_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/offer_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/offers/offer_form_page.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/offers/package_offer_form_page.dart';

class OfferManagementPage extends StatefulWidget {
  const OfferManagementPage({super.key});

  @override
  State<OfferManagementPage> createState() => _OfferManagementPageState();
}

class _OfferManagementPageState extends State<OfferManagementPage> {
  final OfferRepository _offerRepository = OfferRepository();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();
  List<Offer> _offers = [];
  List<Offer> _filteredOffers = [];
  List<Map<String, dynamic>> _packageOffers = [];
  List<Map<String, dynamic>> _filteredPackageOffers = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _error;
  Map<String, dynamic>? _stats;

  final TextEditingController _searchController = TextEditingController();
  String _selectedInstitute = 'All';
  String _selectedStatus = 'All';
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOffers);
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    try {
      // Initialize cache service
      await _cacheService.initialize();
      
      // Try to load from cache first
      await _loadFromCache();
      
      // Then load fresh data
      await _fetchOffers();
      await _fetchPackageOffers();
      await _fetchStats();
    } catch (e) {
      // Ensure loading state is cleared even if initialization fails
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingFromCache = false;
          if (_error == null) {
            _error = 'Failed to initialize: ${e.toString()}';
          }
        });
      }
    } finally {
      // Final safeguard to ensure loading is always cleared
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      }
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedOffers = await _cacheService.getOffersData();
      final cachedPackageOffers = await _cacheService.getPackageOffersData();
      final cachedStats = await _cacheService.getOfferStats();

      if (cachedOffers != null || cachedPackageOffers != null || cachedStats != null) {
        setState(() {
          _isLoadingFromCache = true;
        });

        if (cachedOffers != null) {
          final offersJson = cachedOffers['offers'] as List<dynamic>?;
          if (offersJson != null) {
            setState(() {
              _offers = offersJson.map((json) => Offer.fromJson(json)).toList();
              _filteredOffers = _offers;
            });
            _filterOffers();
          }
        }

        if (cachedPackageOffers != null) {
          setState(() {
            _packageOffers = cachedPackageOffers.cast<Map<String, dynamic>>();
            _filteredPackageOffers = _packageOffers;
          });
          _filterOffers();
        }

        if (cachedStats != null) {
          setState(() {
            _stats = cachedStats;
          });
        }

        setState(() {
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      } else {
        // No cache available, ensure loading state is handled by fetch methods
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    } catch (e) {
      // Silently fail cache loading
      setState(() {
        _isLoadingFromCache = false;
      });
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

  Future<void> _fetchOffers({bool forceRefresh = false}) async {
    try {
      // Skip cache if force refresh or filters are applied
      if (!forceRefresh && _selectedInstitute == 'All' && _selectedStatus == 'All') {
        final cachedData = await _cacheService.getOffersData();
        if (cachedData != null && !_isLoadingFromCache) {
          // Already loaded from cache, just update in background
          setState(() => _isLoading = false);
          _fetchOffersInBackground();
          return;
        }
      }

      if (!_isLoadingFromCache) {
        setState(() => _isLoading = true);
      }

      final result = await _offerRepository.getOffers(
        institute: _selectedInstitute != 'All' ? _selectedInstitute : null,
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );

      // Cache only if no filters are applied
      if (_selectedInstitute == 'All' && _selectedStatus == 'All') {
        await _cacheService.setOffersData({
          'offers': result['offers'].map((o) => o.toJson()).toList(),
        });
      }

      setState(() {
        _offers = result['offers'];
        _filteredOffers = _offers;
        _isLoading = false;
        _isLoadingFromCache = false;
        _error = null; // Clear error on success
      });
      _filterOffers();
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getOffersData();
        if (cachedData != null) {
          final offersJson = cachedData['offers'] as List<dynamic>?;
          if (offersJson != null && offersJson.isNotEmpty) {
            // Load from cache and show toast
            setState(() {
              _offers = offersJson.map((json) => Offer.fromJson(json)).toList();
              _filteredOffers = _offers;
              _isLoading = false;
              _isLoadingFromCache = false;
              _error = null; // Clear error since we have cached data
            });
            _filterOffers();
            return;
          }
        }
        
        // No cache available, show error
        setState(() {
          _error = 'No internet connection';
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      } else {
        // Other errors
      setState(() {
        _error = e.toString();
        _isLoading = false;
          _isLoadingFromCache = false;
      });
      }
    }
  }

  Future<void> _fetchOffersInBackground() async {
    try {
      final result = await _offerRepository.getOffers();
      await _cacheService.setOffersData({
        'offers': result['offers'].map((o) => o.toJson()).toList(),
      });
      
      if (mounted && _selectedInstitute == 'All' && _selectedStatus == 'All') {
        setState(() {
          _offers = result['offers'];
          _filteredOffers = _offers;
        });
        _filterOffers();
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  Future<void> _fetchPackageOffers({bool forceRefresh = false}) async {
    try {
      // Skip cache if force refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getPackageOffersData();
        if (cachedData != null && !_isLoadingFromCache) {
          // Already loaded from cache, just update in background
          // Don't set loading to false here as it might be controlled by _fetchOffers
          _fetchPackageOffersInBackground();
          return;
        }
      }

      final packages = await _offerRepository.getPackageOffers();
      
      // Cache the package offers
      await _cacheService.setPackageOffersData(packages);

      setState(() {
        _packageOffers = packages;
        _filteredPackageOffers = packages;
      });
      _filterOffers();
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getPackageOffersData();
        if (cachedData != null && cachedData.isNotEmpty) {
          // Load from cache and show toast
          setState(() {
            _packageOffers = cachedData.cast<Map<String, dynamic>>();
            _filteredPackageOffers = _packageOffers;
          });
          _filterOffers();
          
        }
      }
      // Handle other errors silently for package offers
    }
  }

  Future<void> _fetchPackageOffersInBackground() async {
    try {
      final packages = await _offerRepository.getPackageOffers();
      await _cacheService.setPackageOffersData(packages);
      
      if (mounted) {
        setState(() {
          _packageOffers = packages;
          _filteredPackageOffers = packages;
        });
        _filterOffers();
      }
    } catch (e) {
      // Silently fail in background refresh
    }
  }

  Future<void> _fetchStats({bool forceRefresh = false}) async {
    try {
      // Skip cache if force refresh
      if (!forceRefresh) {
        final cachedStats = await _cacheService.getOfferStats();
        if (cachedStats != null && !_isLoadingFromCache) {
          // Already loaded from cache, just update in background
          _fetchStatsInBackground();
          return;
        }
      }

      final stats = await _offerRepository.getOfferStats();
      
      // Cache the stats
      await _cacheService.setOfferStats(stats);

      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedStats = await _cacheService.getOfferStats();
        if (cachedStats != null) {
          setState(() {
            _stats = cachedStats;
          });
        }
        // Don't show toast for stats errors - let offers error handling show it
      }
      // Handle other errors silently for stats
    }
  }

  Future<void> _fetchStatsInBackground() async {
    try {
      final stats = await _offerRepository.getOfferStats();
      await _cacheService.setOfferStats(stats);
      
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      // If it's a network error, try to load from cache
      if (_isNoInternetError(e)) {
        final cachedStats = await _cacheService.getOfferStats();
        if (cachedStats != null && mounted) {
          setState(() {
            _stats = cachedStats;
          });
        }
      }
      // Silently fail other errors in background refresh
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterOffers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterOffers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOffers = _offers.where((offer) {
        final instituteName = offer.instituteName.toLowerCase();
        final description = offer.description.toLowerCase();
        return instituteName.contains(query) || description.contains(query);
      }).toList();

      _filteredPackageOffers = _packageOffers.where((package) {
        final packageName = (package['packageName'] ?? '').toString().toLowerCase();
        final description = (package['description'] ?? '').toString().toLowerCase();
        final instituteName = (package['instituteName'] ?? '').toString().toLowerCase();
        return packageName.contains(query) ||
            description.contains(query) ||
            instituteName.contains(query);
      }).toList();
    });
  }

  Future<void> _createOffer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const OfferFormPage()),
    );

    if (result == true) {
      _fetchOffers(forceRefresh: true);
      _fetchStats(forceRefresh: true);
    }
  }

  Future<void> _createPackageOffer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const PackageOfferFormPage()),
    );

    if (result == true) {
      _fetchOffers(forceRefresh: true);
      _fetchPackageOffers(forceRefresh: true);
      _fetchStats(forceRefresh: true);
    }
  }

  Future<void> _editPackageOffer(Map<String, dynamic> packageOffer) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PackageOfferFormPage(
          packageOffer: packageOffer,
          isEdit: true,
        ),
      ),
    );

    if (result == true) {
      _fetchPackageOffers(forceRefresh: true);
      _fetchStats(forceRefresh: true);
    }
  }

  Future<void> _deletePackageOffer(Map<String, dynamic> packageOffer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package Offer'),
        content: Text(
          'Are you sure you want to delete the package "${packageOffer['packageName'] ?? 'Unknown'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final packageId = packageOffer['_id'] ?? packageOffer['packageId'];
        await _offerRepository.deletePackageOffer(packageId.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package offer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPackageOffers(forceRefresh: true);
        _fetchStats(forceRefresh: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete package offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editOffer(Offer offer) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => OfferFormPage(offer: offer, isEdit: true),
      ),
    );

    if (result == true) {
      _fetchOffers(forceRefresh: true);
      _fetchStats(forceRefresh: true);
    }
  }

  Future<void> _deleteOffer(Offer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text(
          'Are you sure you want to delete the offer for ${offer.instituteName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _offerRepository.deleteOffer(offer.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchOffers(forceRefresh: true);
        _fetchStats(forceRefresh: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteShade2,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatsCards(),
            _buildFiltersAndSearch(),
            _isLoading && !_isLoadingFromCache
                ? _buildShimmerList()
                : _error != null && !_isLoadingFromCache
                ? _buildErrorWidget()
                : _buildOfferList(),
            const SizedBox(height: 100), // Extra space for FAB
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildStatsCards() {
    final totalOffers = _stats?['totalOffers'] ?? _offers.length;
    final activeOffers =
        _stats?['activeOffers'] ??
        _offers.where((o) => o.isActiveAndValid).length;
    final expiredOffers =
        _stats?['expiredOffers'] ?? _offers.where((o) => o.isExpired).length;
    final totalEnrollments = _stats?['totalEnrollments'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth < 900;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 16 : 20,
            ),
            child: Column(
              children: [
                // Compact header with main stat
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.warmOrange.withOpacity(0.1),
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        turns: 0,
                        child: Icon(
                          Icons.analytics_rounded,
                          color: AppColors.warmOrange,
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            child: const Text('Offer Overview'),
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: AppColors.textSecondary,
                            ),
                            child: const Text('Manage your offers'),
                          ),
                        ],
                      ),
                    ),
                    // Main stat badge with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warmOrange,
                            AppColors.orangeShade3,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        scale: 1.0,
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                totalOffers.toString(),
                                key: ValueKey(totalOffers),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 10,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                // Responsive secondary stats layout
                if (isSmallScreen) ...[
                  // Stack vertically on small screens
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedStatItem(
                              'Active',
                              activeOffers.toString(),
                              Icons.check_circle_rounded,
                              AppColors.success,
                              0,
                              isSmallScreen: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAnimatedStatItem(
                              'Expired',
                              expiredOffers.toString(),
                              Icons.schedule_rounded,
                              AppColors.error,
                              100,
                              isSmallScreen: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAnimatedStatItem(
                        'Enrollments',
                        totalEnrollments.toString(),
                        Icons.people_rounded,
                        AppColors.info,
                        200,
                        isSmallScreen: true,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ] else if (isMediumScreen) ...[
                  // 2x2 grid on medium screens
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedStatItem(
                              'Active',
                              activeOffers.toString(),
                              Icons.check_circle_rounded,
                              AppColors.success,
                              0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAnimatedStatItem(
                              'Expired',
                              expiredOffers.toString(),
                              Icons.schedule_rounded,
                              AppColors.error,
                              100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAnimatedStatItem(
                        'Enrollments',
                        totalEnrollments.toString(),
                        Icons.people_rounded,
                        AppColors.info,
                        200,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ] else ...[
                  // Full row on large screens
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedStatItem(
                          'Active',
                          activeOffers.toString(),
                          Icons.check_circle_rounded,
                          AppColors.success,
                          0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnimatedStatItem(
                          'Expired',
                          expiredOffers.toString(),
                          Icons.schedule_rounded,
                          AppColors.error,
                          100,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnimatedStatItem(
                          'Enrollments',
                          totalEnrollments.toString(),
                          Icons.people_rounded,
                          AppColors.info,
                          200,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    int delay, {
    bool isSmallScreen = false,
    bool isFullWidth = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animation, child) {
        final clampedAnimation = animation.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedAnimation,
          child: Opacity(
            opacity: clampedAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: isFullWidth && isSmallScreen
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: color,
                          size: isSmallScreen ? 14 : 16,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                value,
                                key: ValueKey(value),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          icon,
                          color: color,
                          size: isSmallScreen ? 14 : 16,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            value,
                            key: ValueKey(value),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          child: Text(title, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersAndSearch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 16 : 20,
          ),
          child: Column(
            children: [
              _buildSearchBar(isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Padding(
                padding: EdgeInsets.only(left: isSmallScreen ? 0 : 2),
                child: _buildFiltersSection(isSmallScreen),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    // Animation durations
    const animationDuration = Duration(milliseconds: 550);
    const staggerDelay = Duration(milliseconds: 60);
    
    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      width: 200,
      height: _isFabExpanded ? 200 : 56,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Create Package FAB - slides up from main FAB (appears first)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _isFabExpanded ? 1.0 : 0.0),
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              // Apply stagger delay for opening, immediate for closing
              final adjustedValue = _isFabExpanded 
                  ? (value * animationDuration.inMilliseconds - staggerDelay.inMilliseconds) / animationDuration.inMilliseconds
                  : value;
              final finalValue = adjustedValue.clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(0, -140 * finalValue),
                child: Opacity(
                  opacity: finalValue,
                  child: Transform.scale(
                    scale: 0.75 + (0.25 * finalValue),
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        setState(() => _isFabExpanded = false);
                        Future.delayed(animationDuration, () {
                          _createPackageOffer();
                        });
                      },
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.pureWhite,
                      elevation: 2 + (4 * finalValue),
                      heroTag: 'package_offer',
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text(
                        'Create Package',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Create Offer FAB - slides up from main FAB (appears second with delay)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _isFabExpanded ? 1.0 : 0.0),
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              // Apply stagger delay for opening, immediate for closing
              final adjustedValue = _isFabExpanded 
                  ? (value * animationDuration.inMilliseconds - (staggerDelay.inMilliseconds * 2)) / animationDuration.inMilliseconds
                  : value;
              final finalValue = adjustedValue.clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(0, -76 * finalValue),
                child: Opacity(
                  opacity: finalValue,
                  child: Transform.scale(
                    scale: 0.75 + (0.25 * finalValue),
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        setState(() => _isFabExpanded = false);
                        Future.delayed(animationDuration, () {
                          _createOffer();
                        });
                      },
                      backgroundColor: AppColors.warmOrange,
                      foregroundColor: AppColors.pureWhite,
                      elevation: 2 + (4 * finalValue),
                      heroTag: 'regular_offer',
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Create Offer',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Main FAB with + icon that rotates to X
          FloatingActionButton(
            onPressed: () {
              setState(() => _isFabExpanded = !_isFabExpanded);
            },
            backgroundColor: AppColors.warmOrange,
            foregroundColor: AppColors.pureWhite,
            elevation: 4,
            heroTag: 'main_fab',
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _isFabExpanded ? 0.125 : 0.0),
              duration: animationDuration,
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159, // Convert turns to radians
                  child: const Icon(Icons.add_rounded, size: 28),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isSmallScreen) {
    return Column(
      children: [
        _buildFilterChip(
          'Institute',
          _selectedInstitute,
          Icons.school_rounded,
          ['All', ...collegesData],
          (value) {
            setState(() {
              _selectedInstitute = value!;
            });
            _fetchOffers();
          },
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        if (isSmallScreen) ...[
          // Stack vertically on small screens
          _buildFilterChip(
            'Status',
            _selectedStatus,
            Icons.filter_list_rounded,
            const ['All', 'active', 'expired', 'inactive'],
            (value) {
              setState(() {
                _selectedStatus = value!;
              });
              _fetchOffers();
            },
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedInstitute = 'All';
                    _selectedStatus = 'All';
                    _searchController.clear();
                  });
                  _fetchOffers(forceRefresh: true);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear_all_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          // Side by side on larger screens
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'Status',
                  _selectedStatus,
                  Icons.filter_list_rounded,
                  const ['All', 'active', 'expired', 'inactive'],
                  (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _fetchOffers();
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedInstitute = 'All';
                        _selectedStatus = 'All';
                        _searchController.clear();
                      });
                      _fetchOffers(forceRefresh: true);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.clear_all_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Clear',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    IconData icon,
    List<String> options,
    Function(String?) onChanged, {
    bool isSmallScreen = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 10 : 12,
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Row(
              children: [
                if (option == 'active')
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (option == 'expired')
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (option == 'inactive')
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.textDisabled,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 6),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option == 'All' ? 'All $label' : option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        isExpanded: true,
        isDense: true,
        dropdownColor: AppColors.pureWhite,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        menuMaxHeight: 300,
      ),
    );
  }

  Widget _buildErrorWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    return Center(
      child: Container(
        margin: EdgeInsets.all(isMobile ? 20 : isTablet ? 24 : 28),
        padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(isMobile ? 16 : isTablet ? 18 : 20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, 4),
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
              'Failed to load offers',
              style: TextStyle(
                fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),
            ElevatedButton.icon(
              onPressed: () {
                _fetchOffers(forceRefresh: true);
                _fetchPackageOffers(forceRefresh: true);
                _fetchStats(forceRefresh: true);
              },
              icon: Icon(Icons.refresh_rounded, size: isMobile ? 16 : isTablet ? 17 : 18),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmOrange,
                foregroundColor: AppColors.pureWhite,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : isTablet ? 24 : 28,
                  vertical: isMobile ? 12 : isTablet ? 13 : 14,
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

  Widget _buildSearchBar(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search offers...',
          hintStyle: TextStyle(
            color: AppColors.textDisabled,
            fontSize: isSmallScreen ? 12 : 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: isSmallScreen ? 18 : 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterOffers();
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 80,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOfferList() {
    final allItems = <Widget>[];

    // Add regular offers with refined animations
    for (var i = 0; i < _filteredOffers.length; i++) {
      allItems.add(
        _buildOfferListItem(_filteredOffers[i])
            .animate()
            .fadeIn(
              duration: 600.ms,
              delay: (i * 80).ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 600.ms,
              delay: (i * 80).ms,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              delay: (i * 80).ms,
              curve: Curves.easeOutBack,
            ),
      );
    }

    // Add package offers with refined animations
    for (var i = 0; i < _filteredPackageOffers.length; i++) {
      allItems.add(
        _buildPackageOfferListItem(_filteredPackageOffers[i])
            .animate()
            .fadeIn(
              duration: 600.ms,
              delay: ((_filteredOffers.length + i) * 80).ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 600.ms,
              delay: ((_filteredOffers.length + i) * 80).ms,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              delay: ((_filteredOffers.length + i) * 80).ms,
              curve: Curves.easeOutBack,
            ),
      );
    }

    if (allItems.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warmOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  size: 48,
                  color: AppColors.warmOrange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No offers found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _offers.isEmpty && _packageOffers.isEmpty
                    ? 'Create your first institutional offer to get started'
                    : 'Try adjusting your search or filter criteria',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: allItems);
  }

  Widget _buildOfferListItem(Offer offer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final bool isActive = offer.isActiveAndValid;
    final bool isExpired = offer.isExpired;

    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        0,
        isMobile ? 12 : 16,
        isMobile ? 10 : 12,
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOfferDetails(offer),
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.warmOrange.withOpacity(0.1),
          highlightColor: AppColors.warmOrange.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.success.withOpacity(0.2)
                    : isExpired
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Container(
                  constraints: BoxConstraints(
                    minHeight: isMobile ? 60 : 68,
                  ),
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.warmOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: AppColors.warmOrange,
                          size: isMobile ? 18 : 20,
                      ),
                    ),
                      SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.instituteName,
                            style: TextStyle(
                                fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                          ),
                            SizedBox(height: isMobile ? 3 : 4),
                          Text(
                            offer.description,
                            style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                              color: AppColors.textSecondary,
                                height: 1.3,
                            ),
                              maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                            SizedBox(height: isMobile ? 4 : 6),
                            _buildStatusBadge(isActive, isExpired, isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
                SizedBox(height: isMobile ? 12 : 14),
                // Stats row
                isMobile
                    ? Column(
                        children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '${offer.courseOffers.length}',
                        'Courses',
                        Icons.school_rounded,
                        AppColors.info,
                                  isMobile: true,
                      ),
                    ),
                              SizedBox(width: isMobile ? 4 : 8),
                    Expanded(
                      child: _buildStatItem(
                        '${offer.tegaExamOffers.length}',
                        'Exams',
                        Icons.quiz_rounded,
                        AppColors.warning,
                                  isMobile: true,
                      ),
                    ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 4 : 6),
                          Row(
                            children: [
                    Expanded(
                      child: _buildStatItem(
                        '${offer.studentCount}',
                        'Students',
                        Icons.people_rounded,
                        AppColors.success,
                                  isMobile: true,
                      ),
                    ),
                              SizedBox(width: isMobile ? 4 : 8),
                    Expanded(
                      child: _buildStatItem(
                        '₹${_formatCurrency(offer.totalRevenue)}',
                        'Revenue',
                        Icons.currency_rupee_rounded,
                        AppColors.warmOrange,
                                  isMobile: true,
                      ),
                    ),
                  ],
                ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              '${offer.courseOffers.length}',
                              'Courses',
                              Icons.school_rounded,
                              AppColors.info,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              '${offer.tegaExamOffers.length}',
                              'Exams',
                              Icons.quiz_rounded,
                              AppColors.warning,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              '${offer.studentCount}',
                              'Students',
                              Icons.people_rounded,
                              AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              '₹${_formatCurrency(offer.totalRevenue)}',
                              'Revenue',
                              Icons.currency_rupee_rounded,
                              AppColors.warmOrange,
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isMobile ? 12 : 14),
                // Footer section
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: isMobile ? 11 : 12,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: isMobile ? 3 : 4),
                        Flexible(
                          child: Text(
                          'Until ${offer.validUntil.day}/${offer.validUntil.month}/${offer.validUntil.year}',
                          style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.edit_rounded,
                          color: AppColors.info,
                          onPressed: () => _editOffer(offer),
                          isMobile: isMobile,
                        ),
                        SizedBox(width: isMobile ? 4 : 6),
                        _buildIconButton(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          onPressed: () => _deleteOffer(offer),
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageOfferListItem(Map<String, dynamic> packageOffer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final bool isActive = packageOffer['isActive'] == true;
    final validUntil = packageOffer['validUntil'] != null
        ? DateTime.parse(packageOffer['validUntil'])
        : DateTime.now().add(const Duration(days: 30));
    final bool isExpired = validUntil.isBefore(DateTime.now());
    final bool isActiveAndValid = isActive && !isExpired;

    final includedCourses = packageOffer['includedCourses'] as List<dynamic>? ?? [];
    final includedExam = packageOffer['includedExam'];
    final hasExam = includedExam != null && includedExam != '';

    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        0,
        isMobile ? 12 : 16,
        isMobile ? 10 : 12,
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.info.withOpacity(0.1),
          highlightColor: AppColors.info.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActiveAndValid
                    ? AppColors.success.withOpacity(0.2)
                    : isExpired
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Container(
                  constraints: BoxConstraints(
                    minHeight: isMobile ? 60 : 68,
                  ),
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.info,
                          size: isMobile ? 18 : 20,
                      ),
                    ),
                      SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            packageOffer['packageName'] ?? 'Package Offer',
                            style: TextStyle(
                                fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                          ),
                            SizedBox(height: isMobile ? 3 : 4),
                          Text(
                            packageOffer['description'] ?? '',
                            style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                              color: AppColors.textSecondary,
                                height: 1.3,
                            ),
                              maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                            SizedBox(height: isMobile ? 4 : 6),
                            _buildStatusBadge(isActiveAndValid, isExpired, isMobile),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 14),
                // Stats row
                isMobile
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  '${includedCourses.length}',
                                  'Courses',
                                  Icons.school_rounded,
                                  AppColors.info,
                                  isMobile: true,
                            ),
                          ),
                              SizedBox(width: isMobile ? 4 : 8),
                              Expanded(
                                child: _buildStatItem(
                                  hasExam ? '1' : '0',
                                  'Exams',
                                  Icons.quiz_rounded,
                                  AppColors.warning,
                                  isMobile: true,
                      ),
                    ),
                  ],
                ),
                          SizedBox(height: isMobile ? 4 : 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  '₹${_formatCurrency((packageOffer['price'] ?? 0).toDouble())}',
                                  'Price',
                                  Icons.currency_rupee_rounded,
                                  AppColors.warmOrange,
                                  isMobile: true,
                                ),
                              ),
                              Expanded(child: SizedBox()), // Spacer for symmetry
                            ],
                          ),
                        ],
                      )
                    : Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '${includedCourses.length}',
                        'Courses',
                        Icons.school_rounded,
                        AppColors.info,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        hasExam ? '1' : '0',
                        'Exams',
                        Icons.quiz_rounded,
                        AppColors.warning,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        '₹${_formatCurrency((packageOffer['price'] ?? 0).toDouble())}',
                        'Price',
                        Icons.currency_rupee_rounded,
                        AppColors.warmOrange,
                      ),
                    ),
                          Expanded(child: SizedBox()), // Spacer for symmetry with 4-stat cards
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 14),
                // Footer section
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: isMobile ? 11 : 12,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: isMobile ? 3 : 4),
                        Flexible(
                          child: Text(
                          'Until ${validUntil.day}/${validUntil.month}/${validUntil.year}',
                          style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.edit_rounded,
                          color: AppColors.info,
                          onPressed: () => _editPackageOffer(packageOffer),
                          isMobile: isMobile,
                        ),
                        SizedBox(width: isMobile ? 4 : 6),
                        _buildIconButton(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          onPressed: () => _deletePackageOffer(packageOffer),
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: isMobile ? 36 : 48,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 0,
        vertical: isMobile ? 2 : 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          children: [
              Icon(icon, size: isMobile ? 11 : 13, color: color),
              SizedBox(width: isMobile ? 2 : 3),
              Flexible(
                child: Text(
              value,
              style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
          SizedBox(height: isMobile ? 2 : 3),
        Text(
          label,
          style: TextStyle(
              fontSize: isMobile ? 9 : 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
        ),
      ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isMobile = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: isMobile ? 14 : 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool isExpired, bool isMobile) {
    Color color;
    String text;
    IconData icon;

    if (isActive) {
      color = AppColors.success;
      text = 'Active';
      icon = Icons.check_circle_rounded;
    } else if (isExpired) {
      color = AppColors.error;
      text = 'Expired';
      icon = Icons.schedule_rounded;
    } else {
      color = AppColors.textDisabled;
      text = 'Inactive';
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMobile ? 5 : 6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isMobile ? 11 : 12),
          SizedBox(width: isMobile ? 3 : 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }


  void _showOfferDetails(Offer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offer.instituteName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${offer.description}'),
              const SizedBox(height: 16),
              Text(
                'Valid From: ${offer.validFrom.day}/${offer.validFrom.month}/${offer.validFrom.year}',
              ),
              Text(
                'Valid Until: ${offer.validUntil.day}/${offer.validUntil.month}/${offer.validUntil.year}',
              ),
              if (offer.maxStudents != null)
                Text('Max Students: ${offer.maxStudents}'),
              Text('Student Count: ${offer.studentCount}'),
              Text('Total Revenue: ₹${offer.totalRevenue.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              if (offer.courseOffers.isNotEmpty) ...[
                const Text(
                  'Course Offers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...offer.courseOffers.map(
                  (course) => Text(
                    '• ${course.courseName}: ₹${course.offerPrice.toStringAsFixed(0)} (${course.discountPercentage.toStringAsFixed(0)}% off)',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (offer.tegaExamOffers.isNotEmpty) ...[
                const Text(
                  'TEGA Exam Offers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...offer.tegaExamOffers.map(
                  (exam) => Text(
                    '• ${exam.examTitle}: ₹${exam.offerPrice.toStringAsFixed(0)} (${exam.discountPercentage.toStringAsFixed(0)}% off)',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editOffer(offer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C88FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
