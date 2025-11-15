import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/repositories/offer_repository.dart';

class PackageOfferFormPage extends StatefulWidget {
  final Map<String, dynamic>? packageOffer;
  final bool isEdit;

  const PackageOfferFormPage({
    super.key,
    this.packageOffer,
    this.isEdit = false,
  });

  @override
  State<PackageOfferFormPage> createState() => _PackageOfferFormPageState();
}

class _PackageOfferFormPageState extends State<PackageOfferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _offerRepository = OfferRepository();
  final _cacheService = AdminDashboardCacheService();

  // Form controllers
  final _packageNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Form state
  String? _selectedInstitute;
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _isLoadingFromCache = false;

  // Available options
  List<Map<String, dynamic>> _availableCourses = [];
  List<Map<String, dynamic>> _availableTegaExams = [];
  List<String> _availableInstitutes = [];

  // Selected items
  List<Map<String, dynamic>> _selectedCourses = [];
  String? _selectedTegaExamId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.packageOffer != null) {
      _populateFormFromPackageOffer();
    }
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

      if (cachedCourses != null && cachedExams != null && cachedInstitutes != null) {
        // Deduplicate courses by ID
        final coursesList = List<Map<String, dynamic>>.from(cachedCourses);
        final seenCourseIds = <String>{};
        final deduplicatedCourses = <Map<String, dynamic>>[];
        for (final course in coursesList) {
          final courseId = course['_id']?.toString() ?? course['id']?.toString();
          if (courseId != null && !seenCourseIds.contains(courseId)) {
            seenCourseIds.add(courseId);
            deduplicatedCourses.add(course);
          }
        }

        setState(() {
          _availableCourses = deduplicatedCourses;
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

  void _populateFormFromPackageOffer() {
    final package = widget.packageOffer!;
    _packageNameController.text = package['packageName'] ?? '';
    _descriptionController.text = package['description'] ?? '';
    _priceController.text = (package['price'] ?? 0).toString();
    _selectedInstitute = package['instituteName'];
    
    if (package['validUntil'] != null) {
      _validUntil = DateTime.parse(package['validUntil']);
    }
    
    if (package['includedCourses'] != null) {
      _selectedCourses = List<Map<String, dynamic>>.from(
        package['includedCourses'].map((course) => {
          'courseId': course['courseId'] ?? course['_id'],
          'courseName': course['courseName'] ?? course['title'] ?? 'Unknown',
        }),
      );
    }
    
    _selectedTegaExamId = package['includedExam'];
  }

  Future<void> _loadAvailableOptions({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _availableCourses.isNotEmpty && 
        _availableTegaExams.isNotEmpty && _availableInstitutes.isNotEmpty) {
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

      // Deduplicate courses by ID
      final coursesList = List<Map<String, dynamic>>.from(results[0]);
      final seenCourseIds = <String>{};
      final deduplicatedCourses = <Map<String, dynamic>>[];
      for (final course in coursesList) {
        final courseId = course['_id']?.toString() ?? course['id']?.toString();
        if (courseId != null && !seenCourseIds.contains(courseId)) {
          seenCourseIds.add(courseId);
          deduplicatedCourses.add(course);
        }
      }

      setState(() {
        _availableCourses = deduplicatedCourses;
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

      // Deduplicate courses by ID
      final coursesList = List<Map<String, dynamic>>.from(results[0]);
      final seenCourseIds = <String>{};
      final deduplicatedCourses = <Map<String, dynamic>>[];
      for (final course in coursesList) {
        final courseId = course['_id']?.toString() ?? course['id']?.toString();
        if (courseId != null && !seenCourseIds.contains(courseId)) {
          seenCourseIds.add(courseId);
          deduplicatedCourses.add(course);
        }
      }

      if (mounted) {
        setState(() {
          _availableCourses = deduplicatedCourses;
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
    _packageNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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
                    padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPackageNameField(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildInstituteField(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildDescriptionField(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildCoursesSection(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildTegaExamField(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildPriceField(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildValidUntilField(isMobile, isTablet, isDesktop),
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
        left: isMobile ? 16 : isTablet ? 20 : 24,
        right: isMobile ? 16 : isTablet ? 20 : 24,
        top: isMobile ? 12 : 16,
        bottom: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.isEdit ? 'Edit Package Offer' : 'Create Package Offer',
            style: TextStyle(
              fontSize: isMobile ? 18 : isTablet ? 20 : 22,
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

  Widget _buildPackageNameField(bool isMobile, bool isTablet, bool isDesktop) {
    return TextFormField(
      controller: _packageNameController,
      style: TextStyle(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: 'Package Name *',
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isMobile ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 14,
          vertical: isMobile ? 14 : 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter package name';
        }
        return null;
      },
    );
  }

  Widget _buildInstituteField(bool isMobile, bool isTablet, bool isDesktop) {
    return DropdownButtonFormField<String>(
      value: _selectedInstitute,
      isExpanded: true,
      style: TextStyle(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: 'Institute Name *',
        hintText: 'Select Institute',
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isMobile ? 14 : 16,
        ),
        hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 14,
          vertical: isMobile ? 14 : 16,
        ),
      ),
      items: _availableInstitutes.map((institute) {
        return DropdownMenuItem<String>(
          value: institute,
          child: Text(
            institute,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: isMobile ? 14 : 16),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedInstitute = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an institute';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(bool isMobile, bool isTablet, bool isDesktop) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      style: TextStyle(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Package description...',
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isMobile ? 14 : 16,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: isMobile ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.all(isMobile ? 12 : 14),
      ),
    );
  }

  Widget _buildCoursesSection(bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Courses *',
          style: TextStyle(
            fontSize: isMobile ? 15 : isTablet ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 6),
        Text(
          '(Add courses one by one)',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 14),
        Builder(
          key: ValueKey('course_dropdown_${_selectedCourses.length}'),
          builder: (context) {
            // Get available courses (not already selected)
            final selectedIds = _selectedCourses
                .map((s) => s['courseId']?.toString() ?? s['_id']?.toString())
                .where((id) => id != null)
                .cast<String>()
                .toSet();

            // Filter and deduplicate in one pass
            final seenIds = <String>{};
            final items = <DropdownMenuItem<String>>[];
            
            for (final course in _availableCourses) {
              final courseId = course['_id']?.toString() ?? course['id']?.toString();
              if (courseId != null && 
                  !seenIds.contains(courseId) && 
                  !selectedIds.contains(courseId)) {
                seenIds.add(courseId);
                items.add(
                  DropdownMenuItem<String>(
                    value: courseId,
                    child: Text(
                      course['title'] ?? course['courseName'] ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  ),
                );
              }
            }

            return DropdownButtonFormField<String>(
              value: null,
              isExpanded: true,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: InputDecoration(
                hintText: 'Select a course to add...',
                hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isMobile ? 14 : 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 14,
                  vertical: isMobile ? 14 : 16,
                ),
              ),
              items: items,
              onChanged: (value) {
                if (value != null) {
                  final course = _availableCourses.firstWhere(
                    (c) {
                      final id = c['_id']?.toString() ?? c['id']?.toString();
                      return id == value;
                    },
                    orElse: () => <String, dynamic>{},
                  );
                  
                  if (course.isNotEmpty) {
                    setState(() {
                      _selectedCourses.add({
                        'courseId': value,
                        'courseName': course['title'] ?? course['courseName'] ?? 'Unknown',
                      });
                    });
                  }
                }
              },
            );
          },
        ),
        SizedBox(height: isMobile ? 12 : 14),
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedCourses.isEmpty
              ? Center(
                  child: Text(
                    'No courses selected. Please select at least one course.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._selectedCourses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final course = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                course['courseName'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: isMobile ? 18 : 20,
                              ),
                              color: AppColors.error,
                              padding: EdgeInsets.all(isMobile ? 4 : 8),
                              constraints: BoxConstraints(
                                minWidth: isMobile ? 32 : 40,
                                minHeight: isMobile ? 32 : 40,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedCourses.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
        if (_selectedCourses.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: isMobile ? 6 : 8),
            child: Text(
              'Please select at least one course',
              style: TextStyle(
                color: AppColors.error,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTegaExamField(bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TEGA Exam',
              style: TextStyle(
                fontSize: isMobile ? 15 : isTablet ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              '(Optional)',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 14),
        DropdownButtonFormField<String>(
          value: _selectedTegaExamId,
          isExpanded: true,
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          decoration: InputDecoration(
            hintText: 'No Exam',
            hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
            labelStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isMobile ? 14 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
              vertical: isMobile ? 14 : 16,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'No Exam',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
            ..._availableTegaExams.map((exam) {
              return DropdownMenuItem<String>(
                value: exam['_id']?.toString() ?? exam['id']?.toString(),
                child: Text(
                  exam['title'] ?? exam['examTitle'] ?? 'Unknown',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTegaExamId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceField(bool isMobile, bool isTablet, bool isDesktop) {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: 'Package Price (₹) *',
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isMobile ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 14,
          vertical: isMobile ? 14 : 16,
        ),
        prefixText: '₹ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter package price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      },
    );
  }

  Widget _buildValidUntilField(bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valid Until Date *',
          style: TextStyle(
            fontSize: isMobile ? 15 : isTablet ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 14),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'dd-mm-yyyy',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isMobile ? 14 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(
                Icons.calendar_today,
                color: AppColors.textSecondary,
                size: isMobile ? 20 : 24,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 14,
                vertical: isMobile ? 14 : 16,
              ),
            ),
            child: Text(
              '${_validUntil.day.toString().padLeft(2, '0')}-${_validUntil.month.toString().padLeft(2, '0')}-${_validUntil.year}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 4 : 6),
        Text(
          'Select the expiry date for this package',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
    );

    if (picked != null && picked != _validUntil) {
      setState(() {
        _validUntil = picked;
      });
    }
  }

  Widget _buildActionButtons(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _createPackageOffer,
              icon: Icon(
                widget.isEdit ? Icons.save_outlined : Icons.inventory_2_outlined,
                size: isMobile ? 18 : 20,
              ),
              label: Text(
                widget.isEdit ? 'Update Package' : 'Create Package',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 24,
                  vertical: isMobile ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 24,
                  vertical: isMobile ? 14 : 16,
                ),
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
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 24,
              vertical: isTablet ? 14 : 16,
            ),
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
        SizedBox(width: isTablet ? 12 : 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createPackageOffer,
          icon: Icon(
            widget.isEdit ? Icons.save_outlined : Icons.inventory_2_outlined,
            size: isTablet ? 18 : 20,
          ),
          label: Text(
            widget.isEdit ? 'Update Package' : 'Create Package',
            style: TextStyle(fontSize: isTablet ? 15 : 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmOrange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 24,
              vertical: isTablet ? 14 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 8 : 10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createPackageOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one course'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final packageData = {
        'packageName': _packageNameController.text,
        'instituteName': _selectedInstitute,
        'description': _descriptionController.text,
        'includedCourses': _selectedCourses,
        'price': double.parse(_priceController.text),
        'validUntil': _validUntil.toIso8601String(),
        if (_selectedTegaExamId != null)
          'includedExam': {
            'examId': _selectedTegaExamId,
            'examTitle': _availableTegaExams
                .firstWhere(
                  (e) =>
                      (e['_id']?.toString() ?? e['id']?.toString()) ==
                      _selectedTegaExamId,
                )['title'] ??
                'Unknown',
          },
      };

      if (widget.isEdit && widget.packageOffer != null) {
        final packageId = widget.packageOffer!['_id'] ?? widget.packageOffer!['packageId'];
        await _offerRepository.updatePackageOffer(packageId.toString(), packageData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package offer updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        await _offerRepository.createPackageOffer(packageData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package offer created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create package offer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

