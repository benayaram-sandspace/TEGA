import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
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

  // Form controllers
  final _instituteNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxStudentsController = TextEditingController();

  // Form state
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isLoading = false;

  // Available options
  List<Map<String, dynamic>> _availableCourses = [];
  List<Map<String, dynamic>> _availableTegaExams = [];
  List<String> _availableInstitutes = [];

  // Selected offers
  List<CourseOffer> _selectedCourseOffers = [];
  List<TegaExamOffer> _selectedTegaExamOffers = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadAvailableOptions();
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

  Future<void> _loadAvailableOptions() async {
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

  @override
  void dispose() {
    _instituteNameController.dispose();
    _descriptionController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Offer' : 'Create Offer'),
        backgroundColor: AppColors.warmOrange,
        elevation: 0,
        foregroundColor: AppColors.pureWhite,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping outside input fields
                FocusScope.of(context).unfocus();
              },
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildCourseOffersSection(),
                      const SizedBox(height: 24),
                      _buildTegaExamOffersSection(),
                      const SizedBox(height: 24),
                      _buildValiditySection(),
                      const SizedBox(height: 24),
                      _buildStatusSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
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

  Widget _buildCourseOffersSection() {
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Stack vertically on small screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                'Course Offers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addCourseOffer,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Course'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                                foregroundColor: AppColors.pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Side by side on larger screens
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
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
                                Flexible(
                                  child: Text(
                                    'Course Offers',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addCourseOffer,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Course'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info,
                              foregroundColor: AppColors.pureWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedCourseOffers.isEmpty)
                  Center(
                    child: Text(
                      'No course offers added yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ..._selectedCourseOffers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final offer = entry.value;
                    return _buildCourseOfferItem(offer, index);
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseOfferItem(CourseOffer offer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildTegaExamOffersSection() {
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Stack vertically on small screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                'TEGA Exam Offers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addTegaExamOffer,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Exam'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: AppColors.pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Side by side on larger screens
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
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
                                Flexible(
                                  child: Text(
                                    'TEGA Exam Offers',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addTegaExamOffer,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Exam'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: AppColors.pureWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedTegaExamOffers.isEmpty)
                  Center(
                    child: Text(
                      'No TEGA exam offers added yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ..._selectedTegaExamOffers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final offer = entry.value;
                    return _buildTegaExamOfferItem(offer, index);
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTegaExamOfferItem(TegaExamOffer offer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 20,
            0,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 16 : 20,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                    side: BorderSide(color: AppColors.warmOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.warmOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmOrange,
                    foregroundColor: AppColors.pureWhite,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.pureWhite,
                            ),
                          ),
                        )
                      : Text(
                          widget.isEdit ? 'Update Offer' : 'Create Offer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
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

  void _addCourseOffer() {
    showDialog(
      context: context,
      builder: (context) => _CourseOfferDialog(
        availableCourses: _availableCourses,
        onAdd: (offer) {
          setState(() {
            _selectedCourseOffers.add(offer);
          });
        },
      ),
    );
  }

  void _removeCourseOffer(int index) {
    setState(() {
      _selectedCourseOffers.removeAt(index);
    });
  }

  void _addTegaExamOffer() {
    showDialog(
      context: context,
      builder: (context) => _TegaExamOfferDialog(
        availableExams: _availableTegaExams,
        onAdd: (offer) {
          setState(() {
            _selectedTegaExamOffers.add(offer);
          });
        },
      ),
    );
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
