import 'package:flutter/material.dart';

// Enhanced data model for an opportunity
class Opportunity {
  final String id;
  final String title;
  final String date;
  final String location;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color cardColor;
  final String category;
  final String description;
  final int applicants;
  final String company;
  final bool isBookmarked;
  final String status; // 'upcoming', 'ongoing', 'expired'
  final DateTime deadline;
  final List<String> requirements;
  final String type; // 'in-person', 'virtual', 'hybrid'
  final double matchPercentage;
  final List<String> skills;
  final String salary;
  final String duration;
  final String eligibility;
  final bool isVerified;
  final int viewCount;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final Map<String, dynamic> contactInfo;

  Opportunity({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.icon,
    required this.iconBackgroundColor,
    required this.cardColor,
    required this.category,
    this.description = '',
    this.applicants = 0,
    this.company = '',
    this.isBookmarked = false,
    this.status = 'upcoming',
    required this.deadline,
    this.requirements = const [],
    this.type = 'in-person',
    this.matchPercentage = 0.0,
    this.skills = const [],
    this.salary = '',
    this.duration = '',
    this.eligibility = '',
    this.isVerified = false,
    this.viewCount = 0,
    this.difficulty = 'Medium',
    this.contactInfo = const {},
  });
}

class AllOpportunitiesScreen extends StatefulWidget {
  const AllOpportunitiesScreen({super.key});

  @override
  State<AllOpportunitiesScreen> createState() => _AllOpportunitiesScreenState();
}

class _AllOpportunitiesScreenState extends State<AllOpportunitiesScreen>
    with TickerProviderStateMixin {
  // Enhanced placeholder data with categories
  final List<Opportunity> allOpportunities = [
    Opportunity(
      id: '1',
      title: 'Kakinada Job Fair',
      date: 'Friday, Sep 20, 2025',
      location: 'Kakinada, Andhra Pradesh',
      icon: Icons.work,
      iconBackgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
      cardColor: Colors.white,
      category: 'Job Fairs',
      description:
          'Meet 50+ top recruiters from various industries including IT, Finance, and Manufacturing',
      applicants: 234,
      company: 'CareerConnect AP',
      status: 'upcoming',
      deadline: DateTime(2025, 9, 18),
      requirements: [
        'Resume',
        'ID Proof',
        'Degree Certificate',
        'Formal Attire',
      ],
      type: 'in-person',
      matchPercentage: 92.5,
      skills: ['Communication', 'Teamwork', 'Problem Solving'],
      salary: '₹3-8 LPA',
      duration: 'Full Day (9 AM - 6 PM)',
      eligibility: 'Final year students & 2023-2025 graduates',
      isVerified: true,
      viewCount: 1542,
      difficulty: 'Easy',
      contactInfo: {
        'email': 'info@careerconnect.com',
        'phone': '+91 9876543210',
      },
    ),
    Opportunity(
      id: '2',
      title: 'TCS Campus Recruitment',
      date: 'Monday, Sep 25, 2025',
      location: 'Online',
      icon: Icons.business,
      iconBackgroundColor: const Color(0xFFE0F7FA),
      cardColor: const Color(0xFFE0F2FF),
      category: 'Job Fairs',
      description:
          'Direct placement opportunity for freshers in TCS Digital and TCS Ninja roles',
      applicants: 567,
      company: 'Tata Consultancy Services',
      status: 'upcoming',
      deadline: DateTime(2025, 9, 23),
      type: 'virtual',
      matchPercentage: 88.0,
      skills: ['Java', 'Python', 'SQL', 'Data Structures'],
      salary: '₹3.36-7 LPA',
      duration: '3 rounds over 2 days',
      eligibility: 'B.Tech/B.E. with 60% aggregate',
      isVerified: true,
      viewCount: 3421,
      difficulty: 'Medium',
      contactInfo: {'email': 'campus@tcs.com', 'website': 'tcs.com/careers'},
    ),
    Opportunity(
      id: '3',
      title: 'Resume Building Workshop',
      date: 'July 18, 2025',
      location: 'Online',
      icon: Icons.description,
      iconBackgroundColor: const Color(0xFFFFF3E0),
      cardColor: const Color(0xFFFFF3E0),
      category: 'Workshops',
      description: 'Learn to create ATS-friendly resumes with industry experts',
      applicants: 89,
      company: 'SkillBridge',
      status: 'ongoing',
      deadline: DateTime(2025, 7, 17),
      type: 'virtual',
      matchPercentage: 95.0,
      skills: ['Resume Writing', 'LinkedIn Optimization'],
      duration: '2 hours',
      eligibility: 'Open to all students',
      isVerified: false,
      viewCount: 892,
      difficulty: 'Easy',
    ),
    Opportunity(
      id: '4',
      title: 'Mock Interview Session',
      date: 'Sep 27, 2025',
      location: 'Virtual',
      icon: Icons.mic,
      iconBackgroundColor: const Color(0xFFE8F5E9),
      cardColor: const Color(0xFFE8F5E9),
      category: 'Mock Interviews',
      description: 'Practice with industry experts from top companies',
      applicants: 45,
      company: 'InterviewPro',
      status: 'upcoming',
      deadline: DateTime(2025, 9, 26),
      type: 'virtual',
      matchPercentage: 78.5,
      skills: ['Communication', 'Technical Skills', 'Problem Solving'],
      duration: '45 minutes per session',
      eligibility: 'Pre-final and final year students',
      isVerified: true,
      viewCount: 567,
      difficulty: 'Medium',
    ),
    Opportunity(
      id: '5',
      title: 'Google Mock Interview',
      date: 'Oct 2, 2025',
      location: 'Virtual',
      icon: Icons.video_call,
      iconBackgroundColor: const Color(0xFFE8F5E9),
      cardColor: const Color(0xFFE8F5E9),
      category: 'Mock Interviews',
      description: 'Technical interview preparation with Google engineers',
      applicants: 120,
      company: 'Google',
      status: 'upcoming',
      deadline: DateTime(2025, 10, 1),
      type: 'virtual',
      matchPercentage: 65.0,
      skills: ['DSA', 'System Design', 'Algorithms'],
      duration: '1 hour',
      eligibility: 'CS/IT students with strong programming skills',
      isVerified: true,
      viewCount: 2134,
      difficulty: 'Hard',
    ),
    Opportunity(
      id: '6',
      title: 'AI/ML Workshop',
      date: 'Oct 5, 2025',
      location: 'College Auditorium',
      icon: Icons.school,
      iconBackgroundColor: const Color(0xFFE3F2FD),
      cardColor: const Color(0xFFE3F2FD),
      category: 'Workshops',
      description:
          'Hands-on training in Machine Learning basics with real projects',
      applicants: 78,
      company: 'TechEd Institute',
      status: 'upcoming',
      deadline: DateTime(2025, 10, 3),
      type: 'hybrid',
      matchPercentage: 82.0,
      skills: ['Python', 'TensorFlow', 'Data Analysis'],
      duration: 'Full day workshop',
      eligibility: 'Basic Python knowledge required',
      isVerified: true,
      viewCount: 1023,
      difficulty: 'Medium',
    ),
  ];

  late List<Opportunity> filteredOpportunities;
  String _selectedFilter = 'All';
  String _sortBy = 'Date'; // 'Date', 'Popularity', 'Deadline', 'Match'
  String _searchQuery = '';
  bool _showOnlyBookmarked = false;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  Set<String> bookmarkedIds = {};
  Set<String> appliedIds = {};
  Set<String> viewedIds = {};

  // For advanced filters
  RangeValues _matchRange = const RangeValues(0, 100);
  String? _selectedType;
  String? _selectedDifficulty;
  bool _showOnlyVerified = false;

  // Tab controller for view modes
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    filteredOpportunities = allOpportunities;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _filterOpportunities() {
    setState(() {
      filteredOpportunities = allOpportunities.where((opp) {
        // Category filter
        bool categoryMatch =
            _selectedFilter == 'All' || opp.category == _selectedFilter;

        // Search filter
        bool searchMatch =
            _searchQuery.isEmpty ||
            opp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            opp.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            opp.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            opp.skills.any(
              (skill) =>
                  skill.toLowerCase().contains(_searchQuery.toLowerCase()),
            );

        // Bookmark filter
        bool bookmarkMatch =
            !_showOnlyBookmarked || bookmarkedIds.contains(opp.id);

        // Match percentage filter
        bool matchRangeMatch =
            opp.matchPercentage >= _matchRange.start &&
            opp.matchPercentage <= _matchRange.end;

        // Type filter
        bool typeMatch = _selectedType == null || opp.type == _selectedType;

        // Difficulty filter
        bool difficultyMatch =
            _selectedDifficulty == null ||
            opp.difficulty == _selectedDifficulty;

        // Verified filter
        bool verifiedMatch = !_showOnlyVerified || opp.isVerified;

        return categoryMatch &&
            searchMatch &&
            bookmarkMatch &&
            matchRangeMatch &&
            typeMatch &&
            difficultyMatch &&
            verifiedMatch;
      }).toList();

      // Apply sorting
      _sortOpportunities();
    });
  }

  void _sortOpportunities() {
    switch (_sortBy) {
      case 'Date':
        filteredOpportunities.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'Popularity':
        filteredOpportunities.sort(
          (a, b) => b.applicants.compareTo(a.applicants),
        );
        break;
      case 'Deadline':
        filteredOpportunities.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'Match':
        filteredOpportunities.sort(
          (a, b) => b.matchPercentage.compareTo(a.matchPercentage),
        );
        break;
    }
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (bookmarkedIds.contains(id)) {
        bookmarkedIds.remove(id);
        _showSnackBar('Removed from bookmarks', Colors.grey);
      } else {
        bookmarkedIds.add(id);
        _showSnackBar('Added to bookmarks', Colors.green);
      }
      if (_showOnlyBookmarked) {
        _filterOpportunities();
      }
    });
  }

  void _applyToOpportunity(String id) {
    setState(() {
      if (!appliedIds.contains(id)) {
        appliedIds.add(id);
        _showSnackBar('Successfully applied!', Colors.green);
      }
    });
  }

  void _markAsViewed(String id) {
    if (!viewedIds.contains(id)) {
      setState(() {
        viewedIds.add(id);
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.green;
      case 'ongoing':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'All Opportunities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.deepPurple,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
                Tab(icon: Icon(Icons.list), text: 'List'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
              ],
            ),
          ),
        ),
        actions: [
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black54,
                ),
                onPressed: () {
                  _showNotificationsSheet();
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // Bookmark filter toggle
          IconButton(
            icon: Icon(
              _showOnlyBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _showOnlyBookmarked ? Colors.deepPurple : Colors.black54,
            ),
            onPressed: () {
              setState(() {
                _showOnlyBookmarked = !_showOnlyBookmarked;
                _filterOpportunities();
              });
            },
          ),
          // Sort options
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black54),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _filterOpportunities();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
              const PopupMenuItem(
                value: 'Popularity',
                child: Text('Sort by Popularity'),
              ),
              const PopupMenuItem(
                value: 'Deadline',
                child: Text('Sort by Deadline'),
              ),
              const PopupMenuItem(
                value: 'Match',
                child: Text('Sort by Match %'),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Grid View
          _buildGridView(),
          // List View
          _buildListView(),
          // Calendar View
          _buildCalendarView(),
        ],
      ),
      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'ai',
              onPressed: () {
                _showAIRecommendations();
              },
              backgroundColor: Colors.purple,
              child: const Icon(Icons.auto_awesome, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              heroTag: 'filter',
              onPressed: () {
                _showFilterBottomSheet(context);
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interactive Stats Dashboard
            _buildInteractiveStatsDashboard(),
            const SizedBox(height: 20),

            // AI Insights Card
            _buildAIInsightsCard(),
            const SizedBox(height: 20),

            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChipWidget(
                    label: 'All',
                    isSelected: _selectedFilter == 'All',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _filterOpportunities();
                      });
                    },
                  ),
                  FilterChipWidget(
                    label: 'Job Fairs',
                    isSelected: _selectedFilter == 'Job Fairs',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Job Fairs';
                        _filterOpportunities();
                      });
                    },
                  ),
                  FilterChipWidget(
                    label: 'Mock Interviews',
                    isSelected: _selectedFilter == 'Mock Interviews',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Mock Interviews';
                        _filterOpportunities();
                      });
                    },
                  ),
                  FilterChipWidget(
                    label: 'Workshops',
                    isSelected: _selectedFilter == 'Workshops',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Workshops';
                        _filterOpportunities();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Enhanced Search Bar
            _buildEnhancedSearchBar(),
            const SizedBox(height: 20),

            // Results info
            _buildResultsInfo(),

            // Opportunities Grid/List
            if (filteredOpportunities.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredOpportunities.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final opportunity = filteredOpportunities[index];
                  if (index == 0 && _selectedFilter == 'All') {
                    return DetailedOpportunityCard(
                      opportunity: opportunity,
                      isBookmarked: bookmarkedIds.contains(opportunity.id),
                      isApplied: appliedIds.contains(opportunity.id),
                      onBookmarkToggle: () => _toggleBookmark(opportunity.id),
                      onApply: () => _applyToOpportunity(opportunity.id),
                      onTap: () {
                        _markAsViewed(opportunity.id);
                        _showOpportunityDetails(opportunity);
                      },
                    );
                  }
                  return EnhancedOpportunityCard(
                    opportunity: opportunity,
                    isBookmarked: bookmarkedIds.contains(opportunity.id),
                    isApplied: appliedIds.contains(opportunity.id),
                    isViewed: viewedIds.contains(opportunity.id),
                    onBookmarkToggle: () => _toggleBookmark(opportunity.id),
                    onApply: () => _applyToOpportunity(opportunity.id),
                    statusColor: _getStatusColor(opportunity.status),
                    onTap: () {
                      _markAsViewed(opportunity.id);
                      _showOpportunityDetails(opportunity);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOpportunities.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [_buildEnhancedSearchBar(), const SizedBox(height: 16)],
            );
          }
          final opportunity = filteredOpportunities[index - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: opportunity.iconBackgroundColor,
                child: Icon(opportunity.icon, color: Colors.black54, size: 20),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      opportunity.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (opportunity.isVerified)
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(opportunity.company),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opportunity.date,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(
                            opportunity.difficulty,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          opportunity.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getDifficultyColor(opportunity.difficulty),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opportunity.description),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: opportunity.skills
                            .map(
                              (skill) => Chip(
                                label: Text(
                                  skill,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.deepPurple.shade50,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: appliedIds.contains(opportunity.id)
                                  ? null
                                  : () => _applyToOpportunity(opportunity.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    appliedIds.contains(opportunity.id)
                                    ? Colors.grey
                                    : Colors.deepPurple,
                              ),
                              child: Text(
                                appliedIds.contains(opportunity.id)
                                    ? 'Applied'
                                    : 'Apply Now',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _toggleBookmark(opportunity.id),
                            icon: Icon(
                              bookmarkedIds.contains(opportunity.id)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: bookmarkedIds.contains(opportunity.id)
                                  ? Colors.deepPurple
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarView() {
    return CalendarView(
      opportunities: filteredOpportunities,
      onDateSelected: (date) {
        // Filter opportunities for selected date
      },
    );
  }

  Widget _buildInteractiveStatsDashboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAnimatedStatItem(
                'Total',
                '${allOpportunities.length}',
                Icons.list,
                0,
              ),
              _buildAnimatedStatItem(
                'Applied',
                '${appliedIds.length}',
                Icons.check_circle,
                1,
              ),
              _buildAnimatedStatItem(
                'Saved',
                '${bookmarkedIds.length}',
                Icons.bookmark,
                2,
              ),
              _buildAnimatedStatItem(
                'Viewed',
                '${viewedIds.length}',
                Icons.visibility,
                3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Completion: 75%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: 0.75,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatItem(
    String label,
    String value,
    IconData icon,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (delay * 100)),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                animValue == 1 ? value : '0',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.purple.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Recommendation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your profile, "TCS Campus Recruitment" has 88% match!',
                  style: TextStyle(fontSize: 12, color: Colors.purple.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showAIRecommendations(),
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterOpportunities();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search opportunities, companies, skills...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterOpportunities();
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.grey),
                onPressed: () {
                  // Voice search functionality
                },
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    if (filteredOpportunities.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${filteredOpportunities.length} opportunities found',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              if (_showOnlyBookmarked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Bookmarked',
                    style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                  ),
                ),
              if (_showOnlyVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified Only',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No opportunities found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _searchQuery = '';
                _showOnlyBookmarked = false;
                _showOnlyVerified = false;
                _selectedType = null;
                _selectedDifficulty = null;
                _matchRange = const RangeValues(0, 100);
                _filterOpportunities();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advanced Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Match Percentage Slider
                          const Text(
                            'Match Percentage',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          RangeSlider(
                            values: _matchRange,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: Colors.deepPurple,
                            labels: RangeLabels(
                              '${_matchRange.start.round()}%',
                              '${_matchRange.end.round()}%',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _matchRange = values;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Opportunity Type
                          const Text(
                            'Opportunity Type',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All Types'),
                                selected: _selectedType == null,
                                selectedColor: Colors.deepPurple.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedType = selected
                                        ? null
                                        : _selectedType;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('In-Person'),
                                selected: _selectedType == 'in-person',
                                selectedColor: Colors.deepPurple.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedType = selected
                                        ? 'in-person'
                                        : null;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Virtual'),
                                selected: _selectedType == 'virtual',
                                selectedColor: Colors.deepPurple.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedType = selected ? 'virtual' : null;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Hybrid'),
                                selected: _selectedType == 'hybrid',
                                selectedColor: Colors.deepPurple.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedType = selected ? 'hybrid' : null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Difficulty Level
                          const Text(
                            'Difficulty Level',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All Levels'),
                                selected: _selectedDifficulty == null,
                                selectedColor: Colors.deepPurple.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedDifficulty = selected
                                        ? null
                                        : _selectedDifficulty;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Easy'),
                                selected: _selectedDifficulty == 'Easy',
                                selectedColor: Colors.green.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedDifficulty = selected
                                        ? 'Easy'
                                        : null;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Medium'),
                                selected: _selectedDifficulty == 'Medium',
                                selectedColor: Colors.orange.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedDifficulty = selected
                                        ? 'Medium'
                                        : null;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Hard'),
                                selected: _selectedDifficulty == 'Hard',
                                selectedColor: Colors.red.shade100,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedDifficulty = selected
                                        ? 'Hard'
                                        : null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Additional Filters
                          SwitchListTile(
                            title: const Text('Verified Opportunities Only'),
                            subtitle: const Text(
                              'Show only verified companies',
                            ),
                            value: _showOnlyVerified,
                            activeThumbColor: Colors.deepPurple,
                            onChanged: (value) {
                              setModalState(() {
                                _showOnlyVerified = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = null;
                              _selectedDifficulty = null;
                              _showOnlyVerified = false;
                              _matchRange = const RangeValues(0, 100);
                              _filterOpportunities();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterOpportunities();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildNotificationItem(
                      'New opportunity matching your profile',
                      'Google Mock Interview is now open',
                      Icons.work,
                      Colors.blue,
                      '2 hours ago',
                    ),
                    _buildNotificationItem(
                      'Application deadline reminder',
                      'TCS Campus Recruitment closes in 2 days',
                      Icons.alarm,
                      Colors.orange,
                      '5 hours ago',
                    ),
                    _buildNotificationItem(
                      'Profile view',
                      'A recruiter from Microsoft viewed your profile',
                      Icons.visibility,
                      Colors.green,
                      '1 day ago',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showAIRecommendations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final recommendations =
            filteredOpportunities
                .where((opp) => opp.matchPercentage >= 70)
                .toList()
              ..sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.purple.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Recommendations for You',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your profile, skills, and preferences',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final opp = recommendations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: opp.iconBackgroundColor,
                              child: Icon(opp.icon, size: 20),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${opp.matchPercentage.round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          opp.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opp.company),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: opp.matchPercentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                opp.matchPercentage >= 85
                                    ? Colors.green
                                    : opp.matchPercentage >= 70
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.pop(context);
                            _showOpportunityDetails(opp);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOpportunityDetails(Opportunity opportunity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.85,
          child: OpportunityDetailsSheet(
            opportunity: opportunity,
            isBookmarked: bookmarkedIds.contains(opportunity.id),
            isApplied: appliedIds.contains(opportunity.id),
            onBookmarkToggle: () => _toggleBookmark(opportunity.id),
            onApply: () => _applyToOpportunity(opportunity.id),
          ),
        );
      },
    );
  }
}

// Enhanced opportunity card widget
class EnhancedOpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool isBookmarked;
  final bool isApplied;
  final bool isViewed;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onApply;
  final VoidCallback onTap;
  final Color statusColor;

  const EnhancedOpportunityCard({
    super.key,
    required this.opportunity,
    required this.isBookmarked,
    required this.isApplied,
    required this.isViewed,
    required this.onBookmarkToggle,
    required this.onApply,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isViewed ? Colors.grey.shade50 : opportunity.cardColor,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: opportunity.iconBackgroundColor,
                      radius: 20,
                      child: Icon(
                        opportunity.icon,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                    if (opportunity.matchPercentage >= 80)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              opportunity.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (opportunity.isVerified)
                            Icon(
                              Icons.verified,
                              color: Colors.blue.shade600,
                              size: 14,
                            ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              opportunity.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            opportunity.date,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (opportunity.company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                opportunity.company,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Colors.deepPurple : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onBookmarkToggle,
                    ),
                    if (isApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Applied',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Match percentage bar
            if (opportunity.matchPercentage > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: opportunity.matchPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        opportunity.matchPercentage >= 80
                            ? Colors.green
                            : opportunity.matchPercentage >= 60
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${opportunity.matchPercentage.round()}% match',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: opportunity.matchPercentage >= 80
                          ? Colors.green
                          : opportunity.matchPercentage >= 60
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Additional info chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (opportunity.type.isNotEmpty)
                  _buildInfoChip(
                    opportunity.type == 'virtual'
                        ? Icons.video_call
                        : opportunity.type == 'hybrid'
                        ? Icons.sync
                        : Icons.location_on,
                    opportunity.type == 'virtual'
                        ? 'Virtual'
                        : opportunity.type == 'hybrid'
                        ? 'Hybrid'
                        : 'In-Person',
                  ),
                if (opportunity.applicants > 0)
                  _buildInfoChip(
                    Icons.people,
                    '${opportunity.applicants} applied',
                  ),
                if (opportunity.viewCount > 0)
                  _buildInfoChip(
                    Icons.visibility,
                    '${opportunity.viewCount} views',
                  ),
                if (opportunity.difficulty.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        opportunity.difficulty,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      opportunity.difficulty,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getDifficultyColor(opportunity.difficulty),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// Enhanced detailed card
class DetailedOpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool isBookmarked;
  final bool isApplied;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onApply;
  final VoidCallback onTap;

  const DetailedOpportunityCard({
    super.key,
    required this.opportunity,
    required this.isBookmarked,
    required this.isApplied,
    required this.onBookmarkToggle,
    required this.onApply,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              spreadRadius: 4,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE3F2FD),
                  radius: 22,
                  child: Icon(
                    opportunity.icon,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              opportunity.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (opportunity.isVerified)
                            Icon(
                              Icons.verified,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opportunity.date,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.deepPurple : Colors.grey,
                  ),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
            if (opportunity.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                opportunity.description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            // Match percentage with visual indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Match Score: ${opportunity.matchPercentage}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: opportunity.matchPercentage / 100,
                          backgroundColor: Colors.purple.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (opportunity.location.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.location_on, size: 16),
                    label: Text(opportunity.location),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (opportunity.company.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.business, size: 16),
                    label: Text(opportunity.company),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (opportunity.applicants > 0)
                  Chip(
                    avatar: const Icon(Icons.people, size: 16),
                    label: Text('${opportunity.applicants} applied'),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (opportunity.salary.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.currency_rupee, size: 16),
                    label: Text(opportunity.salary),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isApplied ? null : onApply,
                    icon: Icon(isApplied ? Icons.check : Icons.send, size: 18),
                    label: Text(isApplied ? 'Applied' : 'Apply Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApplied
                          ? Colors.grey
                          : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Opportunity Details Sheet
class OpportunityDetailsSheet extends StatelessWidget {
  final Opportunity opportunity;
  final bool isBookmarked;
  final bool isApplied;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onApply;

  const OpportunityDetailsSheet({
    super.key,
    required this.opportunity,
    required this.isBookmarked,
    required this.isApplied,
    required this.onBookmarkToggle,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: opportunity.iconBackgroundColor,
                radius: 30,
                child: Icon(opportunity.icon, size: 30, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opportunity.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (opportunity.isVerified)
                          Icon(Icons.verified, color: Colors.blue.shade600),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opportunity.company,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isApplied ? null : onApply,
                  icon: Icon(isApplied ? Icons.check : Icons.send),
                  label: Text(isApplied ? 'Applied' : 'Apply Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApplied
                        ? Colors.grey
                        : Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onBookmarkToggle,
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.deepPurple : Colors.grey,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // Share functionality
                },
                icon: const Icon(Icons.share),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Match Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.purple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'AI Match Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${opportunity.matchPercentage}% Match',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: opportunity.matchPercentage / 100,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.purple.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            opportunity.matchPercentage >= 80
                                ? Icons.trending_up
                                : opportunity.matchPercentage >= 60
                                ? Icons.trending_flat
                                : Icons.trending_down,
                            color: opportunity.matchPercentage >= 80
                                ? Colors.green
                                : opportunity.matchPercentage >= 60
                                ? Colors.orange
                                : Colors.red,
                          ),
                          Text(
                            opportunity.matchPercentage >= 80
                                ? 'High'
                                : opportunity.matchPercentage >= 60
                                ? 'Medium'
                                : 'Low',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details Sections
          _buildSection('Description', opportunity.description),
          _buildSection('Eligibility', opportunity.eligibility),
          _buildSection('Duration', opportunity.duration),
          if (opportunity.salary.isNotEmpty)
            _buildSection('Compensation', opportunity.salary),

          // Requirements
          if (opportunity.requirements.isNotEmpty) ...[
            const Text(
              'Requirements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...opportunity.requirements.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(req),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Skills
          if (opportunity.skills.isNotEmpty) ...[
            const Text(
              'Required Skills',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opportunity.skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.deepPurple.shade50,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Contact Information
          if (opportunity.contactInfo.isNotEmpty) ...[
            const Text(
              'Contact Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...opportunity.contactInfo.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.key == 'email'
                          ? Icons.email
                          : entry.key == 'phone'
                          ? Icons.phone
                          : entry.key == 'website'
                          ? Icons.language
                          : Icons.info,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    if (content.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(content),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Calendar View Widget
class CalendarView extends StatelessWidget {
  final List<Opportunity> opportunities;
  final Function(DateTime) onDateSelected;

  const CalendarView({
    super.key,
    required this.opportunities,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Calendar view shows upcoming opportunities by date',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: opportunities.length,
              itemBuilder: (context, index) {
                final opp = opportunities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: opp.iconBackgroundColor,
                      child: Icon(opp.icon, size: 20),
                    ),
                    title: Text(opp.title),
                    subtitle: Text(opp.date),
                    trailing: Text(
                      '${opp.deadline.day}/${opp.deadline.month}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Filter chip widget
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.deepPurple : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
