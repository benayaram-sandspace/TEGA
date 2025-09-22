import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/tabs/student_details_tab.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late List<Student> _allStudents;
  List<Student> _filteredStudents = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _allStudents = _generateDummyStudents();
    _filteredStudents = _allStudents;

    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
          _filterStudents();
        });
      }
    });

    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Student> _generateDummyStudents() {
    final names = [
      'Riya Sharma',
      'Amit Kumar',
      'Priya Singh',
      'Vikram Rathod',
      'Sneha Patil',
      'Arjun Verma',
      'Neha Gupta',
      'Rahul Desai',
      'Anjali Mehta',
      'Karan Joshi',
      'Sonia Reddy',
      'Raj Patel',
      'Pooja Chauhan',
      'Vivek Menon',
      'Deepika Nair',
    ];
    return List.generate(names.length, (index) {
      final statusMap = _getStatus(index);
      return Student(
        name: names[index],
        grade: 12 - (index % 5),
        gpa: (4.0 - (index % 8) * 0.15).clamp(2.5, 4.0),
        avatarUrl: 'https://i.pravatar.cc/150?img=${index + 1}',
        status: statusMap['text'] as String,
        statusColor: statusMap['color'] as Color,
      );
    });
  }

  void _filterStudents() {
    List<Student> results = _allStudents;
    if (_searchQuery.isNotEmpty) {
      results = results
          .where(
            (student) =>
                student.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedStatus != 'All') {
      results = results
          .where((student) => student.status == _selectedStatus)
          .toList();
    }
    setState(() {
      _filteredStudents = results;
    });
  }

  Map<String, dynamic> _getStatus(int index) {
    switch (index % 3) {
      case 0:
        return {'text': 'Excellent', 'color': DashboardStyles.accentGreen};
      case 1:
        return {'text': 'Good', 'color': DashboardStyles.accentOrange};
      default:
        return {'text': 'Average', 'color': DashboardStyles.primary};
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _filterStudents();
    });
    _searchFocusNode.unfocus();
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopSearch,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search students...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: DashboardStyles.textDark, fontSize: 16),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
      );
    } else {
      return AppBar(
        title: const Text(
          'Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          _buildFilterMenu(),
          IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _filteredStudents.isEmpty
            ? _buildEmptyState()
            : _buildStudentList(),
      ),
    );
  }

  Widget _buildFilterMenu() {
    final filterOptions = ['All', 'Excellent', 'Good', 'Average'];
    return Stack(
      alignment: Alignment.center,
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (String status) {
            setState(() {
              _selectedStatus = status;
              _filterStudents();
            });
          },
          itemBuilder: (BuildContext context) {
            return filterOptions.map((String choice) {
              return PopupMenuItem<String>(value: choice, child: Text(choice));
            }).toList();
          },
        ),
        if (_selectedStatus != 'All')
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: DashboardStyles.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      key: ValueKey(_filteredStudents.length),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final animation = CurvedAnimation(
          parent: _listAnimationController,
          curve: Interval(
            (0.1 * index).clamp(0.0, 1.0),
            (0.5 + 0.1 * index).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        return _buildAnimatedStudentTile(_filteredStudents[index], animation);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Students Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStudentTile(
    Student student,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: _buildStudentTile(student),
      ),
    );
  }

  Widget _buildStudentTile(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardStyles.cardBackground,
            Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.02)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(color: student.statusColor),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentDetailsPage(student: student),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: NetworkImage(student.avatarUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Grade: ${student.grade} | GPA: ${student.gpa.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: student.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              student.status,
                              style: TextStyle(
                                color: student.statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
