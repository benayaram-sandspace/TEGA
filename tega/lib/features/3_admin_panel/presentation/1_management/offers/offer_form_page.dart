import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/models/offer_model.dart';
import 'package:tega/features/3_admin_panel/data/repositories/offer_repository.dart';

class OfferFormPage extends StatefulWidget {
  final Offer? offer; // null for create, existing offer for edit
  final bool isEdit;

  const OfferFormPage({super.key, this.offer, this.isEdit = false});

  @override
  State<OfferFormPage> createState() => _OfferFormPageState();
}

class _OfferFormPageState extends State<OfferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _offerRepository = OfferRepository();
  final _cacheService = AdminDashboardCacheService();

  // Form controllers
  final _instituteNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxStudentsController = TextEditingController();

  // Form state
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingFromCache = false;

  // Available options
  List<Map<String, dynamic>> _availableCourses = [];
  List<Map<String, dynamic>> _availableTegaExams = [];
  List<String> _availableInstitutes = [];

  // Selected offers
  List<CourseOffer> _selectedCourseOffers = [];
  List<TegaExamOffer> _selectedTegaExamOffers = [];

  // Inline input fields for adding offers
  String? _selectedCourseId;
  final _courseOriginalPriceController = TextEditingController();
  final _courseOfferPriceController = TextEditingController();

  String? _selectedTegaExamId;
  String? _selectedSlotId;
  final _examOriginalPriceController = TextEditingController();
  final _examOfferPriceController = TextEditingController();
  List<Map<String, dynamic>> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadAvailableOptions();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);

      final cachedCourses = await _cacheService.getAvailableCourses();
      final cachedExams = await _cacheService.getAvailableTegaExams();
      final cachedInstitutes = await _cacheService.getAvailableInstitutes();

      if (cachedCourses != null &&
          cachedExams != null &&
          cachedInstitutes != null) {
        setState(() {
          _availableCourses = List<Map<String, dynamic>>.from(cachedCourses);
          _availableTegaExams = List<Map<String, dynamic>>.from(cachedExams);
          _availableInstitutes = List<String>.from(cachedInstitutes);
          _isLoadingFromCache = false;
        });
      } else {
        setState(() => _isLoadingFromCache = false);
      }
    } catch (e) {
      setState(() => _isLoadingFromCache = false);
    }
  }

  void _initializeForm() {
    if (widget.isEdit && widget.offer != null) {
      final offer = widget.offer!;
      _instituteNameController.text = offer.instituteName;
      _descriptionController.text = offer.description;
      _maxStudentsController.text = offer.maxStudents?.toString() ?? '';
      _validFrom = offer.validFrom;
      _validUntil = offer.validUntil;
      _isActive = offer.isActive;
      _selectedCourseOffers = List.from(offer.courseOffers);
      _selectedTegaExamOffers = List.from(offer.tegaExamOffers);
    }
  }

  Future<void> _loadAvailableOptions({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh &&
        _availableCourses.isNotEmpty &&
        _availableTegaExams.isNotEmpty &&
        _availableInstitutes.isNotEmpty) {
      _loadAvailableOptionsInBackground();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _offerRepository.getAvailableCourses(),
        _offerRepository.getAvailableTegaExams(),
        _offerRepository.getAvailableInstitutes(),
      ]);

      setState(() {
        _availableCourses = List<Map<String, dynamic>>.from(results[0]);
        _availableTegaExams = List<Map<String, dynamic>>.from(results[1]);
        _availableInstitutes = List<String>.from(results[2]);
        _isLoading = false;
      });

      // Cache the results
      await _cacheService.setAvailableCourses(results[0]);
      await _cacheService.setAvailableTegaExams(results[1]);
      await _cacheService.setAvailableInstitutes(List<String>.from(results[2]));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load options: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableOptionsInBackground() async {
    try {
      final results = await Future.wait([
        _offerRepository.getAvailableCourses(),
        _offerRepository.getAvailableTegaExams(),
        _offerRepository.getAvailableInstitutes(),
      ]);

      if (mounted) {
        setState(() {
          _availableCourses = List<Map<String, dynamic>>.from(results[0]);
          _availableTegaExams = List<Map<String, dynamic>>.from(results[1]);
          _availableInstitutes = List<String>.from(results[2]);
        });
      }

      // Cache the results
      await _cacheService.setAvailableCourses(results[0]);
      await _cacheService.setAvailableTegaExams(results[1]);
      await _cacheService.setAvailableInstitutes(List<String>.from(results[2]));
    } catch (e) {
      // Silently fail in background
    }
  }

  @override
  void dispose() {
    _instituteNameController.dispose();
    _descriptionController.dispose();
    _maxStudentsController.dispose();
    _courseOriginalPriceController.dispose();
    _courseOfferPriceController.dispose();
    _examOriginalPriceController.dispose();
    _examOfferPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading && !_isLoadingFromCache) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmOrange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(isMobile, isTablet, isDesktop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile
                          ? 16
                          : isTablet
                          ? 20
                          : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOfferDetailsSection(
                          isMobile,
                          isTablet,
                          isDesktop,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildCourseOffersSection(
                          isMobile,
                          isTablet,
                          isDesktop,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildTegaExamOffersSection(
                          isMobile,
                          isTablet,
                          isDesktop,
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
                        _buildActionButtons(isMobile, isTablet, isDesktop),
                      ],
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

  Widget _buildHeader(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.only(
        left: isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
        right: isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
        top: isMobile ? 12 : 16,
        bottom: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            widget.isEdit ? 'Edit Offer' : 'Create Offer',
            style: TextStyle(
              fontSize: isMobile
                  ? 18
                  : isTablet
                  ? 20
                  : 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_isLoading && !_isLoadingFromCache)
            SizedBox(
              width: isMobile ? 18 : 20,
              height: isMobile ? 18 : 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmOrange),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.close, size: isMobile ? 20 : 24),
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildOfferDetailsSection(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offer Details',
            style: TextStyle(
              fontSize: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          // Institute Name
          DropdownButtonFormField<String>(
            value: _instituteNameController.text.isNotEmpty
                ? _instituteNameController.text
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Institute Name *',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.warmOrange,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            items: _availableInstitutes.map((institute) {
              return DropdownMenuItem<String>(
                value: institute,
                child: Text(institute, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _instituteNameController.text = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an institute';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Valid Until
          InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Valid Until *',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.warmOrange,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              child: Text(
                '${_validUntil.day.toString().padLeft(2, '0')}-${_validUntil.month.toString().padLeft(2, '0')}-${_validUntil.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.warmOrange,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          // Max Students
          TextFormField(
            controller: _maxStudentsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Students (Optional)',
              hintText: 'Leave empty for unlimited',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.warmOrange,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 20,
            0,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.warmOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_rounded,
                        color: AppColors.warmOrange,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                DropdownButtonFormField<String>(
                  value: _instituteNameController.text.isNotEmpty
                      ? _instituteNameController.text
                      : null,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Institute Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.warmOrange,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.school_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.whiteShade1,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  dropdownColor: AppColors.pureWhite,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  items: _availableInstitutes.map((institute) {
                    return DropdownMenuItem<String>(
                      value: institute,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          institute,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _instituteNameController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an institute';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.warmOrange,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.description_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.whiteShade1,
                  ),
                  maxLines: 3,
                  onTapOutside: (event) {
                    // Dismiss keyboard when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                TextFormField(
                  controller: _maxStudentsController,
                  decoration: InputDecoration(
                    labelText: 'Maximum Students (Optional)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.warmOrange,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.people_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.whiteShade1,
                  ),
                  keyboardType: TextInputType.number,
                  onTapOutside: (event) {
                    // Dismiss keyboard when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final maxStudents = int.tryParse(value);
                      if (maxStudents == null || maxStudents <= 0) {
                        return 'Please enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseOffersSection(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Offers',
            style: TextStyle(
              fontSize: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 16),
          // Inline input fields for adding course
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Stack vertically on small screens
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Course',
                        hintText: 'Select Course',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _availableCourses.map((course) {
                        return DropdownMenuItem<String>(
                          value:
                              course['_id']?.toString() ??
                              course['id']?.toString(),
                          child: Text(
                            course['title'] ??
                                course['courseName'] ??
                                'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                          // Auto-fill original price from course
                          if (value != null) {
                            final course = _availableCourses.firstWhere(
                              (c) =>
                                  (c['_id']?.toString() ??
                                      c['id']?.toString()) ==
                                  value,
                              orElse: () => {},
                            );
                            if (course.isNotEmpty) {
                              final price = course['price'] ?? 0;
                              _courseOriginalPriceController.text = price
                                  .toString();
                            }
                          } else {
                            _courseOriginalPriceController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _courseOriginalPriceController,
                            keyboardType: TextInputType.number,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Original Price',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _courseOfferPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Offer Price',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addCourseFromInline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                );
              } else {
                // Horizontal layout on larger screens
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Course',
                          hintText: 'Select Course',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: _availableCourses.map((course) {
                          return DropdownMenuItem<String>(
                            value:
                                course['_id']?.toString() ??
                                course['id']?.toString(),
                            child: Text(
                              course['title'] ??
                                  course['courseName'] ??
                                  'Unknown',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _courseOriginalPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Original Price',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _courseOfferPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Offer Price',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addCourseFromInline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: isMobile ? 16 : 20),
          // List of added course offers
          if (_selectedCourseOffers.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Text(
                  'No course offers added yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
            )
          else
            ..._selectedCourseOffers.asMap().entries.map((entry) {
              final index = entry.key;
              final offer = entry.value;
              return _buildCourseOfferItem(
                offer,
                index,
                isMobile,
                isTablet,
                isDesktop,
              );
            }),
        ],
      ),
    );
  }

  void _addCourseFromInline() {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a course')));
      return;
    }

    final originalPrice =
        double.tryParse(_courseOriginalPriceController.text) ?? 0;
    final offerPrice = double.tryParse(_courseOfferPriceController.text) ?? 0;

    if (originalPrice <= 0 || offerPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid prices')),
      );
      return;
    }

    final course = _availableCourses.firstWhere(
      (c) => (c['_id']?.toString() ?? c['id']?.toString()) == _selectedCourseId,
    );

    final discountPercentage = originalPrice > 0
        ? ((originalPrice - offerPrice) / originalPrice * 100).toDouble()
        : 0.0;

    setState(() {
      _selectedCourseOffers.add(
        CourseOffer(
          courseId: _selectedCourseId!,
          courseName: course['title'] ?? course['courseName'] ?? 'Unknown',
          originalPrice: originalPrice,
          offerPrice: offerPrice,
          discountPercentage: discountPercentage,
        ),
      );
      _selectedCourseId = null;
      _courseOriginalPriceController.clear();
      _courseOfferPriceController.clear();
    });
  }

  Widget _buildCourseOfferItem(
    CourseOffer offer,
    int index,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  offer.courseName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _removeCourseOffer(index),
                icon: Icon(Icons.delete, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Stack vertically on very small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original: ₹${offer.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offer: ₹${offer.offerPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discount: ${offer.discountPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              } else {
                // Side by side on larger screens
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Original: ₹${offer.originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Offer: ₹${offer.offerPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Discount: ${offer.discountPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildTegaExamOffersSection(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEGA Exam Offers',
            style: TextStyle(
              fontSize: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 16),
          // Inline input fields for adding TEGA exam
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                // Stack vertically on small screens
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedTegaExamId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'TEGA Exam',
                        hintText: 'Select TEGA Exam',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _availableTegaExams.map((exam) {
                        return DropdownMenuItem<String>(
                          value:
                              exam['_id']?.toString() ?? exam['id']?.toString(),
                          child: Text(
                            exam['title'] ?? exam['examTitle'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTegaExamId = value;
                          _selectedSlotId = null;
                          // Load slots for selected exam and auto-fill original price
                          if (value != null) {
                            final exam = _availableTegaExams.firstWhere(
                              (e) =>
                                  (e['_id']?.toString() ??
                                      e['id']?.toString()) ==
                                  value,
                              orElse: () => {},
                            );
                            if (exam.isNotEmpty) {
                              _availableSlots = List<Map<String, dynamic>>.from(
                                exam['slots'] ?? [],
                              );
                              // Auto-fill original price from exam
                              final price = exam['price'] ?? 0;
                              _examOriginalPriceController.text = price
                                  .toString();
                            }
                          } else {
                            _availableSlots = [];
                            _examOriginalPriceController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSlotId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Slot (Optional)',
                        hintText: 'All Slots',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Slots'),
                        ),
                        ..._availableSlots.map((slot) {
                          return DropdownMenuItem<String>(
                            value: slot['slotId']?.toString(),
                            child: Text(
                              '${slot['startTime'] ?? ''} - ${slot['endTime'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSlotId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _examOriginalPriceController,
                            keyboardType: TextInputType.number,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Original Price',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _examOfferPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Offer Price',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addTegaExamFromInline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                );
              } else {
                // Horizontal layout on larger screens
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTegaExamId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'TEGA Exam',
                          hintText: 'Select TEGA Exam',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: _availableTegaExams.map((exam) {
                          return DropdownMenuItem<String>(
                            value:
                                exam['_id']?.toString() ??
                                exam['id']?.toString(),
                            child: Text(
                              exam['title'] ?? exam['examTitle'] ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTegaExamId = value;
                            _selectedSlotId = null;
                            // Load slots for selected exam
                            if (value != null) {
                              final exam = _availableTegaExams.firstWhere(
                                (e) =>
                                    (e['_id']?.toString() ??
                                        e['id']?.toString()) ==
                                    value,
                              );
                              _availableSlots = List<Map<String, dynamic>>.from(
                                exam['slots'] ?? [],
                              );
                            } else {
                              _availableSlots = [];
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSlotId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Slot (Optional)',
                          hintText: 'All Slots',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Slots'),
                          ),
                          ..._availableSlots.map((slot) {
                            return DropdownMenuItem<String>(
                              value: slot['slotId']?.toString(),
                              child: Text(
                                '${slot['startTime'] ?? ''} - ${slot['endTime'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSlotId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _examOriginalPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Original Price',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _examOfferPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Offer Price',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addTegaExamFromInline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: isMobile ? 16 : 20),
          // List of added TEGA exam offers
          if (_selectedTegaExamOffers.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Text(
                  'No TEGA exam offers added yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
            )
          else
            ..._selectedTegaExamOffers.asMap().entries.map((entry) {
              final index = entry.key;
              final offer = entry.value;
              return _buildTegaExamOfferItem(
                offer,
                index,
                isMobile,
                isTablet,
                isDesktop,
              );
            }),
        ],
      ),
    );
  }

  void _addTegaExamFromInline() {
    if (_selectedTegaExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a TEGA exam')),
      );
      return;
    }

    final originalPrice =
        double.tryParse(_examOriginalPriceController.text) ?? 0;
    final offerPrice = double.tryParse(_examOfferPriceController.text) ?? 0;

    if (originalPrice <= 0 || offerPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid prices')),
      );
      return;
    }

    final exam = _availableTegaExams.firstWhere(
      (e) =>
          (e['_id']?.toString() ?? e['id']?.toString()) == _selectedTegaExamId,
    );

    final discountPercentage = originalPrice > 0
        ? ((originalPrice - offerPrice) / originalPrice * 100).toDouble()
        : 0.0;

    setState(() {
      _selectedTegaExamOffers.add(
        TegaExamOffer(
          examId: _selectedTegaExamId!,
          examTitle: exam['title'] ?? exam['examTitle'] ?? 'Unknown',
          slotId: _selectedSlotId,
          originalPrice: originalPrice,
          offerPrice: offerPrice,
          discountPercentage: discountPercentage,
        ),
      );
      _selectedTegaExamId = null;
      _selectedSlotId = null;
      _availableSlots = [];
      _examOriginalPriceController.clear();
      _examOfferPriceController.clear();
    });
  }

  Widget _buildTegaExamOfferItem(
    TegaExamOffer offer,
    int index,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  offer.examTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _removeTegaExamOffer(index),
                icon: Icon(Icons.delete, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Stack vertically on very small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original: ₹${offer.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offer: ₹${offer.offerPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discount: ${offer.discountPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              } else {
                // Side by side on larger screens
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Original: ₹${offer.originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Offer: ₹${offer.offerPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Discount: ${offer.discountPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildValiditySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 20,
            0,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: AppColors.success,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      'Validity Period',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Stack vertically on small screens
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Valid From',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.warmOrange,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.whiteShade1,
                                helperText: 'Cannot select past dates',
                                helperStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              child: Text(
                                '${_validFrom.day}/${_validFrom.month}/${_validFrom.year}',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Valid Until',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.warmOrange,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.whiteShade1,
                                helperText: 'Must be after Valid From date',
                                helperStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              child: Text(
                                '${_validUntil.day}/${_validUntil.month}/${_validUntil.year}',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Side by side on larger screens
                      return Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Valid From',
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.warmOrange,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.whiteShade1,
                                  helperText: 'Cannot select past dates',
                                  helperStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                child: Text(
                                  '${_validFrom.day}/${_validFrom.month}/${_validFrom.year}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Valid Until',
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.warmOrange,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.whiteShade1,
                                  helperText: 'Must be after Valid From date',
                                  helperStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                child: Text(
                                  '${_validUntil.day}/${_validUntil.month}/${_validUntil.year}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 20,
            0,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.warmOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.toggle_on_rounded,
                        color: AppColors.warmOrange,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Offer will be visible to students'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: AppColors.warmOrange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isMobile, bool isTablet, bool isDesktop) {
    return isMobile
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: isMobile ? 18 : 20,
                          height: isMobile ? 18 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.isEdit ? 'Update Offer' : 'Create Offer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 15 : 16,
                          ),
                        ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 15 : 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 15 : 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 8 : 10),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 15 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 14 : 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 15 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 8 : 10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: isTablet ? 18 : 20,
                          height: isTablet ? 18 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.isEdit ? 'Update Offer' : 'Create Offer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 15 : 16,
                          ),
                        ),
                ),
              ),
            ],
          );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _validFrom : _validUntil,
      firstDate: isFromDate
          ? today
          : _validFrom.add(
              const Duration(days: 1),
            ), // For Valid Until, cannot select before Valid From + 1 day
      lastDate: today.add(const Duration(days: 365)), // 1 year from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.warmOrange,
              onPrimary: AppColors.pureWhite,
              surface: AppColors.pureWhite,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warmOrange,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _validFrom = picked;
          // Ensure Valid Until is at least 1 day after Valid From
          if (_validUntil.isBefore(_validFrom.add(const Duration(days: 1)))) {
            _validUntil = _validFrom.add(const Duration(days: 30));
          }
        } else {
          // Ensure Valid Until is at least 1 day after Valid From
          if (picked.isBefore(_validFrom.add(const Duration(days: 1)))) {
            _validUntil = _validFrom.add(const Duration(days: 30));
          } else {
            _validUntil = picked;
          }
        }
      });
    }
  }

  void _removeCourseOffer(int index) {
    setState(() {
      _selectedCourseOffers.removeAt(index);
    });
  }

  void _removeTegaExamOffer(int index) {
    setState(() {
      _selectedTegaExamOffers.removeAt(index);
    });
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseOffers.isEmpty && _selectedTegaExamOffers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one course or exam offer'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final offerData = {
        'instituteName': _instituteNameController.text,
        'description': _descriptionController.text,
        'validFrom': _validFrom.toIso8601String(),
        'validUntil': _validUntil.toIso8601String(),
        'maxStudents': _maxStudentsController.text.isNotEmpty
            ? int.parse(_maxStudentsController.text)
            : null,
        'isActive': _isActive,
        'courseOffers': _selectedCourseOffers
            .map((offer) => offer.toJson())
            .toList(),
        'tegaExamOffers': _selectedTegaExamOffers
            .map((offer) => offer.toJson())
            .toList(),
      };

      if (widget.isEdit && widget.offer != null) {
        await _offerRepository.updateOffer(widget.offer!.id, offerData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await _offerRepository.createOffer(offerData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save offer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Course Offer Dialog
class _CourseOfferDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableCourses;
  final Function(CourseOffer) onAdd;

  const _CourseOfferDialog({
    required this.availableCourses,
    required this.onAdd,
  });

  @override
  State<_CourseOfferDialog> createState() => _CourseOfferDialogState();
}

class _CourseOfferDialogState extends State<_CourseOfferDialog> {
  String? selectedCourseId;
  double originalPrice = 0.0;
  double offerPrice = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.school_rounded,
                color: AppColors.info,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Course Offer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCourseId,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Select Course',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                filled: true,
                fillColor: AppColors.whiteShade1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              dropdownColor: AppColors.pureWhite,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              items: widget.availableCourses.map((course) {
                return DropdownMenuItem<String>(
                  value: course['_id'],
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      course['title'] ??
                          course['courseName'] ??
                          'Unknown Course',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCourseId = value;
                  if (value != null) {
                    final course = widget.availableCourses.firstWhere(
                      (c) => c['_id'] == value,
                    );
                    originalPrice = (course['price'] ?? 0).toDouble();
                    offerPrice = originalPrice;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Original Price',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.whiteShade1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
              initialValue: originalPrice.toString(),
              onTapOutside: (event) {
                // Dismiss keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              onChanged: (value) {
                originalPrice = double.tryParse(value) ?? 0.0;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Offer Price',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.whiteShade1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
              initialValue: offerPrice.toString(),
              onTapOutside: (event) {
                // Dismiss keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              onChanged: (value) {
                offerPrice = double.tryParse(value) ?? 0.0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: selectedCourseId != null ? _addOffer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmOrange,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Add Course',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _addOffer() {
    if (selectedCourseId == null) return;

    final course = widget.availableCourses.firstWhere(
      (c) => c['_id'] == selectedCourseId,
    );

    final discountPercentage = originalPrice > 0
        ? ((originalPrice - offerPrice) / originalPrice) * 100
        : 0.0;

    final offer = CourseOffer(
      courseId: selectedCourseId!,
      courseName: course['title'] ?? course['courseName'] ?? 'Unknown Course',
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      discountPercentage: discountPercentage,
      courseTitle: course['title'] ?? course['courseName'],
    );

    widget.onAdd(offer);
    Navigator.of(context).pop();
  }
}

// TEGA Exam Offer Dialog
class _TegaExamOfferDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableExams;
  final Function(TegaExamOffer) onAdd;

  const _TegaExamOfferDialog({
    required this.availableExams,
    required this.onAdd,
  });

  @override
  State<_TegaExamOfferDialog> createState() => _TegaExamOfferDialogState();
}

class _TegaExamOfferDialogState extends State<_TegaExamOfferDialog> {
  String? selectedExamId;
  double originalPrice = 0.0;
  double offerPrice = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.quiz_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add TEGA Exam Offer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedExamId,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Select Exam',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                filled: true,
                fillColor: AppColors.whiteShade1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              dropdownColor: AppColors.pureWhite,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              items: widget.availableExams.map((exam) {
                return DropdownMenuItem<String>(
                  value: exam['_id'],
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      exam['title'] ?? 'Unknown Exam',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedExamId = value;
                  if (value != null) {
                    final exam = widget.availableExams.firstWhere(
                      (e) => e['_id'] == value,
                    );
                    originalPrice =
                        (exam['price'] ?? exam['effectivePrice'] ?? 0)
                            .toDouble();
                    offerPrice = originalPrice;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Original Price',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.whiteShade1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
              initialValue: originalPrice.toString(),
              onTapOutside: (event) {
                // Dismiss keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              onChanged: (value) {
                originalPrice = double.tryParse(value) ?? 0.0;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Offer Price',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.whiteShade1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
              initialValue: offerPrice.toString(),
              onTapOutside: (event) {
                // Dismiss keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              onChanged: (value) {
                offerPrice = double.tryParse(value) ?? 0.0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: selectedExamId != null ? _addOffer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmOrange,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Add Exam',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _addOffer() {
    if (selectedExamId == null) return;

    final exam = widget.availableExams.firstWhere(
      (e) => e['_id'] == selectedExamId,
    );

    final discountPercentage = originalPrice > 0
        ? ((originalPrice - offerPrice) / originalPrice) * 100
        : 0.0;

    final offer = TegaExamOffer(
      examId: selectedExamId!,
      examTitle: exam['title'] ?? 'Unknown Exam',
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      discountPercentage: discountPercentage,
    );

    widget.onAdd(offer);
    Navigator.of(context).pop();
  }
}
