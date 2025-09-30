import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';
import 'college_details_page.dart';
import 'add_college_page.dart';
import 'bulk_import_colleges_page.dart';

class CollegesListPage extends StatefulWidget {
  const CollegesListPage({super.key});

  @override
  State<CollegesListPage> createState() => _CollegesListPageState();
}

class _CollegesListPageState extends State<CollegesListPage>
    with TickerProviderStateMixin {
  final CollegeService _collegeService = CollegeService();
  final TextEditingController _searchController = TextEditingController();
  List<College> _colleges = [];
  List<College> _filteredColleges = [];
  bool _isLoading = true;

  // Animation controllers for enhanced animations
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadColleges();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      20, // Maximum expected colleges
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 50)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) => CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutBack,
          ),
        )
        .toList();

    _slideAnimations = _animationControllers
        .map(
          (controller) => Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutCubic,
          )),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadColleges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final colleges = await _collegeService.loadColleges();
      setState(() {
        _colleges = colleges;
        _filteredColleges = colleges;
        _isLoading = false;
      });
      // Start staggered animations once data is loaded
      _startStaggeredAnimations();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('Failed to load colleges: $e');
      }
    }
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _filteredColleges.length && i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  void _filterColleges(String query) {
    // Reset all animations
    for (var controller in _animationControllers) {
      controller.reset();
    }
    setState(() {
      if (query.isEmpty) {
        _filteredColleges = _colleges;
      } else {
        _filteredColleges = _collegeService.searchColleges(query);
      }
    });
    _startStaggeredAnimations(); // Animate filtered list
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardStyles.background,
      body: RefreshIndicator(
        onRefresh: _loadColleges,
        color: AdminDashboardStyles.primary,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AdminDashboardStyles.primary,
                        ),
                      ),
                    )
                  : _filteredColleges.isEmpty
                  ? _buildEmptyState()
                  : _buildCollegesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const BulkImportCollegesPage(),
                ),
              )
              .then((_) => _loadColleges());
        },
        backgroundColor: AdminDashboardStyles.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Bulk Import'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: TextField(
        controller: _searchController,
        onChanged: _filterColleges,
        decoration: InputDecoration(
          hintText: 'Search by name, city, or ID...',
          hintStyle: TextStyle(color: AdminDashboardStyles.textLight.withValues(alpha: 0.8)),
          prefixIcon: const Icon(
            Icons.search,
            color: AdminDashboardStyles.textLight,
            size: 22,
          ),
          filled: true,
          fillColor: AdminDashboardStyles.cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AdminDashboardStyles.primary, width: 2),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildCollegesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredColleges.length,
      itemBuilder: (context, index) {
        final college = _filteredColleges[index];
        if (index >= _animationControllers.length) return _buildCollegeCard(college, index);
        
        return AnimatedBuilder(
          animation: _scaleAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: SlideTransition(
                position: _slideAnimations[index],
                child: _buildCollegeCard(college, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCollegeCard(College college, int index) {
    // Generate a consistent, vibrant color from the college name
    final color = Colors
        .primaries[college.name.hashCode % Colors.primaries.length]
        .withOpacity(0.8);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: AdminDashboardStyles.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior:
          Clip.antiAlias, // Ensures content respects the border radius
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CollegeDetailsPage(college: college),
            ),
          );
        },
        splashColor: AdminDashboardStyles.primary.withValues(alpha: 0.1),
        highlightColor: AdminDashboardStyles.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color,
                child: Text(
                  college.name.isNotEmpty ? college.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AdminDashboardStyles.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 14,
                          color: AdminDashboardStyles.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          college.city,
                          style: const TextStyle(
                            color: AdminDashboardStyles.primary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${college.id} • ${college.totalStudents} students',
                      style: TextStyle(
                        color: AdminDashboardStyles.textLight,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AdminDashboardStyles.textLight),
                onSelected: (value) {
                  // Existing logic...
                },
                itemBuilder: (context) => [
                  // Existing PopupMenuItems...
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: AdminDashboardStyles.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Colleges Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AdminDashboardStyles.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Your college list is empty. Add a new college to get started.'
                  : 'Try adjusting your search terms to find what you\'re looking for.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AdminDashboardStyles.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
