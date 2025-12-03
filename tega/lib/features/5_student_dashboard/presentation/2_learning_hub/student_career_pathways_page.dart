import 'package:flutter/material.dart';

// This is the main widget for the Career Pathways page.
// You can navigate to this widget from anywhere in your app.
class CareerPathwaysPage extends StatefulWidget {
  const CareerPathwaysPage({super.key});

  @override
  State<CareerPathwaysPage> createState() => _CareerPathwaysPageState();
}

class _CareerPathwaysPageState extends State<CareerPathwaysPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'All';
  bool showOnlyRecommended = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Career Pathways',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).iconTheme.color,
                ),
                if (showOnlyRecommended)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          // Notifications for career updates
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
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
            onPressed: () => _showNotifications(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Banner
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Career Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '12 skills mastered • 3 certifications earned',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Level 4 - Advanced',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context).disabledColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Explore'),
                Tab(text: 'My Path'),
                Tab(text: 'Learning'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Explore Tab
                _buildExploreTab(),
                // My Path Tab
                _buildMyPathTab(),
                // Learning Tab
                _buildLearningTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAICareerAssistant(context),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.psychology),
        label: const Text('AI Career Assistant'),
      ),
    );
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search with voice input
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search careers, skills, or companies...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).disabledColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 10,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trending Careers Section
            const SectionHeader(title: 'Trending Careers 🔥'),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  TrendingCareerCard(
                    title: 'AI Engineer',
                    growth: '+45%',
                    salary: '\$150K - \$250K',
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 12),
                  TrendingCareerCard(
                    title: 'Cybersecurity',
                    growth: '+38%',
                    salary: '\$130K - \$220K',
                    color: Color(0xFF00BCD4),
                  ),
                  SizedBox(width: 12),
                  TrendingCareerCard(
                    title: 'Data Scientist',
                    growth: '+35%',
                    salary: '\$140K - \$230K',
                    color: Color(0xFFFFA000),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Skills Categories
            const SectionHeader(title: 'Explore by Category'),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: const [
                SkillChip(
                  icon: Icons.code,
                  label: 'Software Engineer',
                  isSelected: true,
                ),
                SkillChip(icon: Icons.bar_chart, label: 'Data Science'),
                SkillChip(icon: Icons.design_services, label: 'UI/UX'),
                SkillChip(icon: Icons.cloud_queue, label: 'Cloud'),
                SkillChip(icon: Icons.security, label: 'Security'),
                SkillChip(icon: Icons.psychology, label: 'AI/ML'),
              ],
            ),
            const SizedBox(height: 30),

            // Company Spotlights
            const SectionHeader(title: 'Company Spotlights'),
            const SizedBox(height: 15),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  CompanySpotlightCard(
                    companyName: 'Google',
                    openPositions: 127,
                    rating: 4.5,
                    benefits: ['Remote', 'Health', 'Stock'],
                  ),
                  SizedBox(width: 12),
                  CompanySpotlightCard(
                    companyName: 'Microsoft',
                    openPositions: 98,
                    rating: 4.4,
                    benefits: ['Hybrid', 'Learning', 'Wellness'],
                  ),
                  SizedBox(width: 12),
                  CompanySpotlightCard(
                    companyName: 'Amazon',
                    openPositions: 156,
                    rating: 4.2,
                    benefits: ['Flexible', 'Growth', 'Benefits'],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Career Match Quiz
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Career Match Quiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Find your perfect career in 5 minutes',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                    ),
                    child: const Text('Start Quiz'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPathTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Role Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Role',
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Senior Software Engineer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Career Roadmap
          const SectionHeader(title: 'Your Career Roadmap'),
          const SizedBox(height: 15),
          const CareerRoadmapItem(
            title: 'Senior Software Engineer',
            status: 'Current',
            isCompleted: true,
            isCurrent: true,
          ),
          const CareerRoadmapItem(
            title: 'Tech Lead',
            status: '6-12 months',
            isCompleted: false,
            isCurrent: false,
          ),
          const CareerRoadmapItem(
            title: 'Engineering Manager',
            status: '2-3 years',
            isCompleted: false,
            isCurrent: false,
          ),
          const CareerRoadmapItem(
            title: 'Director of Engineering',
            status: '5+ years',
            isCompleted: false,
            isCurrent: false,
            isLast: true,
          ),
          const SizedBox(height: 30),

          // Skills Gap Analysis
          const SectionHeader(title: 'Skills Gap Analysis'),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: const [
                SkillProgressItem(
                  skill: 'Leadership',
                  currentLevel: 65,
                  requiredLevel: 90,
                ),
                SizedBox(height: 16),
                SkillProgressItem(
                  skill: 'System Design',
                  currentLevel: 80,
                  requiredLevel: 95,
                ),
                SizedBox(height: 16),
                SkillProgressItem(
                  skill: 'Team Management',
                  currentLevel: 45,
                  requiredLevel: 85,
                ),
                SizedBox(height: 16),
                SkillProgressItem(
                  skill: 'Strategic Planning',
                  currentLevel: 30,
                  requiredLevel: 80,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Mentorship Opportunities
          const SectionHeader(title: 'Recommended Mentors'),
          const SizedBox(height: 15),
          const MentorCard(
            name: 'Sarah Johnson',
            role: 'VP of Engineering at Meta',
            expertise: 'Leadership, Scale, Architecture',
            rating: 4.9,
            sessions: 127,
          ),
          const SizedBox(height: 12),
          const MentorCard(
            name: 'Michael Chen',
            role: 'CTO at Startup',
            expertise: 'Innovation, Product, Growth',
            rating: 4.8,
            sessions: 89,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Learning Streak
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF28A745), Color(0xFF34CE57)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '15 Day Streak! 🔥',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Keep learning daily to maintain your streak',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recommended Courses
          const SectionHeader(title: 'Recommended Courses'),
          const SizedBox(height: 15),
          const CourseCard(
            title: 'Advanced System Design',
            provider: 'Coursera',
            duration: '6 weeks',
            rating: 4.8,
            price: '\$49',
            difficulty: 'Advanced',
          ),
          const SizedBox(height: 12),
          const CourseCard(
            title: 'Leadership Excellence',
            provider: 'LinkedIn Learning',
            duration: '4 weeks',
            rating: 4.7,
            price: '\$29',
            difficulty: 'Intermediate',
          ),
          const SizedBox(height: 12),
          const CourseCard(
            title: 'Cloud Architecture Patterns',
            provider: 'Udemy',
            duration: '8 weeks',
            rating: 4.9,
            price: '\$79',
            difficulty: 'Advanced',
          ),
          const SizedBox(height: 30),

          // Certifications
          const SectionHeader(title: 'Trending Certifications'),
          const SizedBox(height: 15),
          const CertificationCard(
            title: 'AWS Solutions Architect',
            organization: 'Amazon',
            validityPeriod: '3 years',
            examFee: '\$300',
            popularity: 95,
          ),
          const SizedBox(height: 12),
          const CertificationCard(
            title: 'Google Cloud Professional',
            organization: 'Google',
            validityPeriod: '2 years',
            examFee: '\$200',
            popularity: 88,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Show only recommended'),
              value: showOnlyRecommended,
              onChanged: (value) {
                setState(() {
                  showOnlyRecommended = value;
                });
                Navigator.pop(context);
              },
            ),
            const ListTile(
              title: Text('Experience Level'),
              trailing: Text('Senior'),
            ),
            const ListTile(
              title: Text('Salary Range'),
              trailing: Text('\$100K - \$200K'),
            ),
            const ListTile(title: Text('Location'), trailing: Text('Remote')),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Career Updates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            NotificationItem(
              title: 'New Tech Lead position at Google',
              time: '2 hours ago',
              icon: Icons.work,
            ),
            Divider(),
            NotificationItem(
              title: 'Your skill assessment is ready',
              time: '5 hours ago',
              icon: Icons.assessment,
            ),
            Divider(),
            NotificationItem(
              title: 'Sarah accepted your mentorship request',
              time: '1 day ago',
              icon: Icons.person,
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

  void _showAICareerAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'AI Career Assistant',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  ChatBubble(
                    text: 'How can I help you with your career today?',
                    isUser: false,
                  ),
                  ChatBubble(
                    text: 'What skills do I need to become a Tech Lead?',
                    isUser: true,
                  ),
                  ChatBubble(
                    text:
                        'Based on your profile, here are the key skills you\'ll need:\n\n• Leadership & Team Management\n• System Architecture\n• Strategic Planning\n• Stakeholder Communication\n\nWould you like me to create a personalized learning plan?',
                    isUser: false,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ask about careers, skills, or growth...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Additional Widgets

class TrendingCareerCard extends StatelessWidget {
  final String title;
  final String growth;
  final String salary;
  final Color color;

  const TrendingCareerCard({
    super.key,
    required this.title,
    required this.growth,
    required this.salary,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                growth,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                salary,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompanySpotlightCard extends StatelessWidget {
  final String companyName;
  final int openPositions;
  final double rating;
  final List<String> benefits;

  const CompanySpotlightCard({
    super.key,
    required this.companyName,
    required this.openPositions,
    required this.rating,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
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
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    companyName[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(
                          ' $rating',
                          style: TextStyle(
                            color: Theme.of(context).disabledColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$openPositions open positions',
            style: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: benefits
                .map(
                  (benefit) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      benefit,
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class CareerRoadmapItem extends StatelessWidget {
  final String title;
  final String status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const CareerRoadmapItem({
    super.key,
    required this.title,
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Theme.of(context).primaryColor
                    : isCompleted
                    ? Colors.green
                    : Theme.of(context).disabledColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : isCurrent
                  ? const Icon(Icons.circle, size: 8, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted
                    ? Colors.green
                    : Theme.of(context).disabledColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCurrent
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SkillProgressItem extends StatelessWidget {
  final String skill;
  final int currentLevel;
  final int requiredLevel;

  const SkillProgressItem({
    super.key,
    required this.skill,
    required this.currentLevel,
    required this.requiredLevel,
  });

  @override
  Widget build(BuildContext context) {
    final gap = requiredLevel - currentLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skill,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              '$gap% gap',
              style: TextStyle(
                color: gap > 30 ? Colors.red : Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: currentLevel / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: requiredLevel / 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(width: 2, height: 12, color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current: $currentLevel%',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 11,
              ),
            ),
            Text(
              'Required: $requiredLevel%',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MentorCard extends StatelessWidget {
  final String name;
  final String role;
  final String expertise;
  final double rating;
  final int sessions;

  const MentorCard({
    super.key,
    required this.name,
    required this.role,
    required this.expertise,
    required this.rating,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              name.split(' ').map((e) => e[0]).join(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expertise,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(' $rating', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      '• $sessions sessions',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final String title;
  final String provider;
  final String duration;
  final double rating;
  final String price;
  final String difficulty;

  const CourseCard({
    super.key,
    required this.title,
    required this.provider,
    required this.duration,
    required this.rating,
    required this.price,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.play_circle_filled,
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      provider,
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $duration',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(' $rating', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: difficulty == 'Advanced'
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          fontSize: 11,
                          color: difficulty == 'Advanced'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: const Text('Enroll', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CertificationCard extends StatelessWidget {
  final String title;
  final String organization;
  final String validityPeriod;
  final String examFee;
  final int popularity;

  const CertificationCard({
    super.key,
    required this.title,
    required this.organization,
    required this.validityPeriod,
    required this.examFee,
    required this.popularity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'by $organization',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Validity',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    validityPeriod,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exam Fee',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    examFee,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popularity',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 4,
                        child: LinearProgressIndicator(
                          value: popularity / 100,
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$popularity%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;

  const NotificationItem({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6C63FF) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Keep original widgets from the original code
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const SkillChip({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD7F5E8) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? const Color(0xFF28A745) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? const Color(0xFF28A745) : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF28A745)
                  : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
