import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';

class InternshipsPage extends StatefulWidget {
  const InternshipsPage({super.key});

  @override
  State<InternshipsPage> createState() => _InternshipsPageState();
}

class _InternshipsPageState extends State<InternshipsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allInternships = [];
  List<Map<String, dynamic>> _filteredInternships = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _activeInternships = 0;
  int _companies = 0;

  // Filter and sort states
  String _selectedCategory = 'All Categories';
  String _selectedSortBy = 'Most Recent';
  final List<String> _categories = [
    'All Categories',
    'Technology',
    'Marketing',
    'Finance',
    'Design',
    'Human Resources',
  ];
  final List<String> _sortOptions = [
    'Most Recent',
    'Oldest First',
    'Company A-Z',
    'Company Z-A',
  ];

  @override
  void initState() {
    super.initState();
    _loadInternshipData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInternshipData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final dashboardService = StudentDashboardService();

      // Fetch internships from backend
      final internships = await dashboardService.getInternships(headers);

      // Debug: Print what we got from backend
      print('Internships received from backend: ${internships.length}');
      if (internships.isNotEmpty) {
        print('First internship data: ${internships.first}');
      }

      // Transform backend data to match UI needs
      _allInternships = internships.map<Map<String, dynamic>>((internship) {
        // Extract category from field or tags
        String category = 'Technology';
        final categoryRaw = internship['category'] ?? internship['field'] ?? '';
        if (categoryRaw.toString().toLowerCase().contains('market')) {
          category = 'Marketing';
        } else if (categoryRaw.toString().toLowerCase().contains('finance')) {
          category = 'Finance';
        } else if (categoryRaw.toString().toLowerCase().contains('design')) {
          category = 'Design';
        } else if (categoryRaw.toString().toLowerCase().contains('hr') ||
            categoryRaw.toString().toLowerCase().contains('human')) {
          category = 'Human Resources';
        } else if (categoryRaw.toString().toLowerCase().contains('tech')) {
          category = 'Technology';
        }

        // Format stipend
        String stipend = internship['stipend']?.toString() ?? 'Unpaid';
        if (!stipend.contains('₹') &&
            stipend != 'Unpaid' &&
            stipend != 'Not specified') {
          stipend = '₹$stipend/month';
        }

        // Format posted date
        String postedDate = 'Recently';
        if (internship['createdAt'] != null) {
          try {
            final date = DateTime.parse(internship['createdAt']);
            final now = DateTime.now();
            final difference = now.difference(date);
            if (difference.inDays == 0) {
              postedDate = 'Today';
            } else if (difference.inDays == 1) {
              postedDate = '1 day ago';
            } else if (difference.inDays < 7) {
              postedDate = '${difference.inDays} days ago';
            } else if (difference.inDays < 30) {
              postedDate = '${(difference.inDays / 7).floor()} weeks ago';
            } else {
              postedDate = '${(difference.inDays / 30).floor()} months ago';
            }
          } catch (e) {
            postedDate = 'Recently';
          }
        }

        // Format duration
        String duration = internship['duration']?.toString() ?? '3 months';
        if (!duration.toLowerCase().contains('month') &&
            !duration.toLowerCase().contains('week')) {
          duration = '$duration months';
        }

        return {
          'id': internship['_id'] ?? internship['id'] ?? '',
          'title':
              internship['title'] ??
              internship['position'] ??
              'Untitled Internship',
          'company':
              internship['company'] ?? internship['companyName'] ?? 'Company',
          'location': internship['location'] ?? internship['city'] ?? 'Remote',
          'category': category,
          'stipend': stipend,
          'duration': duration,
          'description':
              internship['description'] ??
              internship['details'] ??
              'No description available',
          'postedDate': postedDate,
          'applicants':
              internship['applicants'] ?? internship['applicantCount'] ?? 0,
          'requirements': internship['requirements'] ?? [],
          'skills': internship['skills'] ?? [],
        };
      }).toList();

      // Calculate stats from actual data
      if (_allInternships.isNotEmpty) {
        _activeInternships = _allInternships.where((i) => i['id'] != '').length;
        _companies = _allInternships.map((i) => i['company']).toSet().length;
        print(
          'SUCCESS: Loaded ${_allInternships.length} internships from backend',
        );
      } else {
        print('INFO: No internships found in database - showing empty state');
        _activeInternships = 0;
        _companies = 0;
      }

      if (mounted) {
        setState(() {
          _filteredInternships = List.from(_allInternships);
          _applyFilters();
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading internships: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to load internships. Please try again. Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInternships = _allInternships.where((internship) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            internship['title'].toLowerCase().contains(searchQuery) ||
            internship['company'].toLowerCase().contains(searchQuery) ||
            internship['description'].toLowerCase().contains(searchQuery) ||
            internship['location'].toLowerCase().contains(searchQuery);

        // Category filter
        final matchesCategory =
            _selectedCategory == 'All Categories' ||
            internship['category'] == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Apply sorting
      switch (_selectedSortBy) {
        case 'Most Recent':
          // Already sorted by default (createdAt desc from backend)
          break;
        case 'Oldest First':
          _filteredInternships = _filteredInternships.reversed.toList();
          break;
        case 'Company A-Z':
          _filteredInternships.sort(
            (a, b) =>
                a['company'].toString().compareTo(b['company'].toString()),
          );
          break;
        case 'Company Z-A':
          _filteredInternships.sort(
            (a, b) =>
                b['company'].toString().compareTo(a['company'].toString()),
          );
          break;
      }
    });
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF6B5FFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(isDesktop, isTablet);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDesktop, isTablet),
          const SizedBox(height: 24),
          _buildStatsCards(isDesktop, isTablet),
          const SizedBox(height: 24),
          _buildSearchAndFilters(isDesktop, isTablet),
          const SizedBox(height: 16),
          _buildCategories(isDesktop, isTablet),
          const SizedBox(height: 16),
          _buildResultsCount(isDesktop),
          const SizedBox(height: 16),
          _filteredInternships.isEmpty
              ? _buildEmptyState(isDesktop, isTablet)
              : _buildInternshipsList(isDesktop, isTablet),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                color: Colors.white,
                size: isDesktop ? 32 : 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Internship Opportunities',
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Gain valuable experience and kickstart your career with exciting internship opportunities',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDesktop, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            value: '$_activeInternships',
            label: 'Active Internships',
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.business_rounded,
            value: '$_companies',
            label: 'Companies',
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B5FFF),
              size: isDesktop ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, company, or description...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _selectedSortBy,
              underline: const SizedBox(),
              icon: const Icon(Icons.unfold_more_rounded, size: 20),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(option, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSortBy = value;
                    _applyFilters();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Filters button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6B5FFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
              onPressed: _showFiltersDialog,
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _applyFilters();
                });
              },
              selectedColor: const Color(0xFF6B5FFF),
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCount(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Text(
        'Showing ${_filteredInternships.length} of ${_allInternships.length} internships',
        style: TextStyle(
          fontSize: isDesktop ? 15 : 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInternshipsList(bool isDesktop, bool isTablet) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredInternships.length,
      itemBuilder: (context, index) {
        final internship = _filteredInternships[index];
        return _buildInternshipCard(internship, isDesktop, isTablet);
      },
    );
  }

  Widget _buildInternshipCard(
    Map<String, dynamic> internship,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo placeholder
              Container(
                width: isDesktop ? 60 : 50,
                height: isDesktop ? 60 : 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    internship['company'][0].toUpperCase(),
                    style: TextStyle(
                      fontSize: isDesktop ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship['title'],
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      internship['company'],
                      style: TextStyle(
                        fontSize: isDesktop ? 15 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  internship['category'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B5FFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            internship['description'],
            style: TextStyle(
              fontSize: isDesktop ? 15 : 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Info chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.location_on_outlined,
                internship['location'],
                isDesktop,
              ),
              _buildInfoChip(
                Icons.access_time_rounded,
                internship['duration'],
                isDesktop,
              ),
              _buildInfoChip(
                Icons.payments_outlined,
                internship['stipend'],
                isDesktop,
              ),
              _buildInfoChip(
                Icons.people_outline_rounded,
                '${internship['applicants']} applicants',
                isDesktop,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Posted ${internship['postedDate']}',
                style: TextStyle(
                  fontSize: isDesktop ? 13 : 12,
                  color: Colors.grey[500],
                ),
              ),
              ElevatedButton(
                onPressed: () => _applyForInternship(internship['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 20,
                    vertical: isDesktop ? 12 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Now',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 16 : 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 13 : 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop, bool isTablet) {
    // Check if filters are active
    final hasActiveSearch = _searchController.text.isNotEmpty;
    final hasActiveFilters = _selectedCategory != 'All Categories';
    final isFilteredEmpty = hasActiveSearch || hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFilteredEmpty
                    ? Icons.search_off_rounded
                    : Icons.work_outline_rounded,
                size: isDesktop ? 64 : 56,
                color: const Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFilteredEmpty
                  ? 'No Internships Found'
                  : 'No Internships Available',
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isFilteredEmpty
                  ? 'Try adjusting your search or filter criteria to find more opportunities'
                  : 'There are currently no internship postings available. Check back soon for new opportunities!',
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            if (isFilteredEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'All Categories';
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.clear_all_rounded, size: 20),
                label: const Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 24,
                    vertical: isDesktop ? 16 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _loadInternshipData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5FFF),
                  side: const BorderSide(color: Color(0xFF6B5FFF), width: 1.5),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 24,
                    vertical: isDesktop ? 16 : 14,
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

  Widget _buildErrorState(bool isDesktop, bool isTablet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: isDesktop ? 64 : 56,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later',
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInternshipData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24,
                  vertical: isDesktop ? 16 : 14,
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

  Future<void> _applyForInternship(String internshipId) async {
    try {
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final dashboardService = StudentDashboardService();

      final result = await dashboardService.applyForInternship(
        internshipId,
        headers,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to apply'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
