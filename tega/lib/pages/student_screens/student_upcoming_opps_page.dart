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
  });
}

class AllOpportunitiesScreen extends StatefulWidget {
  const AllOpportunitiesScreen({super.key});

  @override
  State<AllOpportunitiesScreen> createState() => _AllOpportunitiesScreenState();
}

class _AllOpportunitiesScreenState extends State<AllOpportunitiesScreen>
    with SingleTickerProviderStateMixin {
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
      description: 'Meet 50+ top recruiters from various industries',
      applicants: 234,
      company: 'CareerConnect AP',
      status: 'upcoming',
      deadline: DateTime(2025, 9, 18),
      requirements: ['Resume', 'ID Proof', 'Degree Certificate'],
      type: 'in-person',
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
      description: 'Direct placement opportunity for freshers',
      applicants: 567,
      company: 'Tata Consultancy Services',
      status: 'upcoming',
      deadline: DateTime(2025, 9, 23),
      type: 'virtual',
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
      description: 'Learn to create ATS-friendly resumes',
      applicants: 89,
      company: 'SkillBridge',
      status: 'ongoing',
      deadline: DateTime(2025, 7, 17),
      type: 'virtual',
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
      description: 'Practice with industry experts',
      applicants: 45,
      company: 'InterviewPro',
      status: 'upcoming',
      deadline: DateTime(2025, 9, 26),
      type: 'virtual',
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
      description: 'Hands-on training in Machine Learning basics',
      applicants: 78,
      company: 'TechEd Institute',
      status: 'upcoming',
      deadline: DateTime(2025, 10, 3),
      type: 'hybrid',
    ),
  ];

  late List<Opportunity> filteredOpportunities;
  String _selectedFilter = 'All';
  String _sortBy = 'Date'; // 'Date', 'Popularity', 'Deadline'
  String _searchQuery = '';
  bool _showOnlyBookmarked = false;
  late AnimationController _animationController;
  Set<String> bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    filteredOpportunities = allOpportunities;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            opp.location.toLowerCase().contains(_searchQuery.toLowerCase());

        // Bookmark filter
        bool bookmarkMatch =
            !_showOnlyBookmarked || bookmarkedIds.contains(opp.id);

        return categoryMatch && searchMatch && bookmarkMatch;
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
    }
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (bookmarkedIds.contains(id)) {
        bookmarkedIds.remove(id);
      } else {
        bookmarkedIds.add(id);
      }
      if (_showOnlyBookmarked) {
        _filterOpportunities();
      }
    });
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
            // Navigate back to StudentHomePage
            Navigator.pop(context);
            // If you have a named route:
            // Navigator.pushReplacementNamed(context, '/studentHomePage');
          },
        ),
        title: const Text(
          'All Opportunities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
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
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            // Refresh data here
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      '${allOpportunities.length}',
                      Icons.list,
                    ),
                    _buildStatItem('Applied', '3', Icons.check_circle),
                    _buildStatItem(
                      'Saved',
                      '${bookmarkedIds.length}',
                      Icons.bookmark,
                    ),
                    _buildStatItem(
                      'Upcoming',
                      '${allOpportunities.where((o) => o.status == 'upcoming').length}',
                      Icons.access_time,
                    ),
                  ],
                ),
              ),
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

              // Search Bar with advanced features
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterOpportunities();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search opportunities, companies, locations...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _filterOpportunities();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Results count and filter info
              if (filteredOpportunities.isNotEmpty)
                Padding(
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
                      if (_showOnlyBookmarked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Bookmarked',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Opportunities List
              if (filteredOpportunities.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No opportunities found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters or search',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
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
                        onBookmarkToggle: () => _toggleBookmark(opportunity.id),
                      );
                    }
                    return EnhancedOpportunityCard(
                      opportunity: opportunity,
                      isBookmarked: bookmarkedIds.contains(opportunity.id),
                      onBookmarkToggle: () => _toggleBookmark(opportunity.id),
                      statusColor: _getStatusColor(opportunity.status),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      // Floating Action Button for quick actions
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showFilterBottomSheet(context);
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.filter_list),
        label: const Text('Filters'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Opportunity Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('In-Person'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  ChoiceChip(
                    label: const Text('Virtual'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  ChoiceChip(
                    label: const Text('Hybrid'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Status'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Upcoming'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  ChoiceChip(
                    label: const Text('Ongoing'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  ChoiceChip(
                    label: const Text('Expired'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Enhanced opportunity card with more features
class EnhancedOpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final Color statusColor;

  const EnhancedOpportunityCard({
    super.key,
    required this.opportunity,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: opportunity.cardColor,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: opportunity.iconBackgroundColor,
                radius: 20,
                child: Icon(opportunity.icon, color: Colors.black54, size: 20),
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
                    Text(
                      opportunity.date,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
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
                          Text(
                            opportunity.company,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (opportunity.applicants > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${opportunity.applicants} applicants',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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
          if (opportunity.type.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  opportunity.type == 'virtual'
                      ? Icons.video_call
                      : opportunity.type == 'hybrid'
                      ? Icons.sync
                      : Icons.location_on,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  opportunity.type == 'virtual'
                      ? 'Virtual Event'
                      : opportunity.type == 'hybrid'
                      ? 'Hybrid Event'
                      : opportunity.location,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Enhanced detailed card
class DetailedOpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const DetailedOpportunityCard({
    super.key,
    required this.opportunity,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    Text(
                      opportunity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to details page
                  },
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
                  onPressed: () {
                    // Set reminder
                  },
                  icon: const Icon(Icons.alarm_add, size: 18),
                  label: const Text('Set Reminder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3F2FD),
                    foregroundColor: Colors.blue.shade700,
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
    );
  }
}

// Filter chip widget remains the same
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
