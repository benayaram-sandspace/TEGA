import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/data/colleges_data.dart';
import 'package:tega/features/3_admin_panel/data/models/offer_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/offer_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/1_management/offers/offer_form_page.dart';

class OfferManagementPage extends StatefulWidget {
  const OfferManagementPage({super.key});

  @override
  State<OfferManagementPage> createState() => _OfferManagementPageState();
}

class _OfferManagementPageState extends State<OfferManagementPage> {
  final OfferRepository _offerRepository = OfferRepository();
  List<Offer> _offers = [];
  List<Offer> _filteredOffers = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  final TextEditingController _searchController = TextEditingController();
  String _selectedInstitute = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOffers();
    _fetchStats();
    _searchController.addListener(_filterOffers);
  }

  Future<void> _fetchOffers() async {
    try {
      setState(() => _isLoading = true);
      final result = await _offerRepository.getOffers(
        institute: _selectedInstitute != 'All' ? _selectedInstitute : null,
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );
      setState(() {
        _offers = result['offers'];
        _filteredOffers = _offers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _offerRepository.getOfferStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Handle error silently for stats
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
    });
  }

  Future<void> _createOffer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const OfferFormPage()),
    );

    if (result == true) {
      _fetchOffers();
      _fetchStats();
    }
  }

  Future<void> _editOffer(Offer offer) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => OfferFormPage(offer: offer, isEdit: true),
      ),
    );

    if (result == true) {
      _fetchOffers();
      _fetchStats();
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
        _fetchOffers();
        _fetchStats();
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

  Future<void> _toggleOfferStatus(Offer offer) async {
    try {
      await _offerRepository.toggleOfferStatus(offer.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offer ${offer.isActive ? 'deactivated' : 'activated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _fetchOffers();
      _fetchStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle offer status: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            _isLoading
                ? _buildShimmerList()
                : _error != null
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
        return Transform.scale(
          scale: animation,
          child: Opacity(
            opacity: animation,
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
                        AnimatedRotation(
                          duration: Duration(milliseconds: 400 + delay),
                          curve: Curves.easeInOut,
                          turns: animation * 0.1,
                          child: Icon(
                            icon,
                            color: color,
                            size: isSmallScreen ? 14 : 16,
                          ),
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
                        AnimatedRotation(
                          duration: Duration(milliseconds: 400 + delay),
                          curve: Curves.easeInOut,
                          turns: animation * 0.1,
                          child: Icon(
                            icon,
                            color: color,
                            size: isSmallScreen ? 14 : 16,
                          ),
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
    return FloatingActionButton.extended(
      onPressed: _createOffer,
      backgroundColor: AppColors.warmOrange,
      foregroundColor: AppColors.pureWhite,
      elevation: 2,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Create Offer',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                  _fetchOffers();
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
                      _fetchOffers();
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
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchOffers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmOrange,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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
    if (_filteredOffers.isEmpty) {
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
                _offers.isEmpty
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

    return Column(
      children: _filteredOffers.asMap().entries.map((entry) {
        final index = entry.key;
        final offer = entry.value;
        return _buildOfferListItem(offer)
            .animate()
            .fadeIn(duration: 500.ms, delay: (index * 100).ms)
            .slideY(begin: 0.5);
      }).toList(),
    );
  }

  Widget _buildOfferListItem(Offer offer) {
    final bool isActive = offer.isActiveAndValid;
    final bool isExpired = offer.isExpired;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showOfferDetails(offer),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.success.withOpacity(0.3)
                    : isExpired
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.borderLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
                if (isActive)
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.warmOrange.withOpacity(0.15),
                                      AppColors.warmOrange.withOpacity(0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.warmOrange.withOpacity(
                                      0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: AppColors.warmOrange,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      offer.instituteName,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      offer.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildModernInfoChip(
                                '${offer.courseOffers.length}',
                                'Courses',
                                Icons.school_rounded,
                                AppColors.info,
                              ),
                              const SizedBox(width: 12),
                              _buildModernInfoChip(
                                '${offer.tegaExamOffers.length}',
                                'Exams',
                                Icons.quiz_rounded,
                                AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              _buildModernInfoChip(
                                '${offer.studentCount}',
                                'Students',
                                Icons.people_rounded,
                                AppColors.success,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
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
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmOrange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '₹${offer.totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStatusBadge(isActive, isExpired),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.whiteShade2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Until ${offer.validUntil.day}/${offer.validUntil.month}/${offer.validUntil.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildModernActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: AppColors.info,
                          onPressed: () => _editOffer(offer),
                        ),
                        const SizedBox(width: 12),
                        _buildModernActionButton(
                          icon: offer.isActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          label: offer.isActive ? 'Deactivate' : 'Activate',
                          color: offer.isActive
                              ? AppColors.warning
                              : AppColors.success,
                          onPressed: () => _toggleOfferStatus(offer),
                        ),
                        const SizedBox(width: 12),
                        _buildModernActionButton(
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          color: AppColors.error,
                          onPressed: () => _deleteOffer(offer),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteShade2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${offer.totalOffers} Offers',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildStatusBadge(bool isActive, bool isExpired) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
