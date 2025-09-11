import 'package:flutter/material.dart';
import 'dart:math' as math;

// Assuming you have a StudentHomePage defined
class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Home Page')),
      body: const Center(child: Text('Welcome to the Student Home Page!')),
    );
  }
}

// Data model for a Job
class Job {
  final String title;
  final String company;
  final String location;

  Job({required this.title, required this.company, required this.location});
}

// Main Page
class JobRecommendationScreen extends StatefulWidget {
  const JobRecommendationScreen({super.key});

  @override
  State<JobRecommendationScreen> createState() =>
      _JobRecommendationScreenState();
}

class _JobRecommendationScreenState extends State<JobRecommendationScreen>
    with SingleTickerProviderStateMixin {
  final List<Job> _jobs = [
    Job(
      title: 'Software Engineer\nIntern',
      company: 'Tech Solutions Inc.',
      location: 'San Francisco, CA',
    ),
    Job(
      title: 'UX/UI Designer',
      company: 'Creative Minds',
      location: 'New York, NY',
    ),
    Job(
      title: 'Data Analyst',
      company: 'Number Crunchers',
      location: 'Austin, TX',
    ),
    Job(title: 'Product Manager', company: 'Innovate Co.', location: 'Remote'),
    Job(
      title: 'Marketing Intern',
      company: 'Growth Hackers',
      location: 'Boston, MA',
    ),
  ];

  int _currentIndex = 0;
  late final AnimationController _animationController;
  final ValueNotifier<Offset> _cardOffsetNotifier = ValueNotifier(Offset.zero);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        _cardOffsetNotifier.value = Offset.zero;
        setState(() {
          _currentIndex = (_currentIndex + 1) % _jobs.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardOffsetNotifier.dispose();
    super.dispose();
  }

  void _runAnimation(Offset targetOffset) {
    final animation =
        Tween<Offset>(
          begin: _cardOffsetNotifier.value,
          end: targetOffset,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.decelerate,
          ),
        );

    animation.addListener(() {
      _cardOffsetNotifier.value = animation.value;
    });

    _animationController.forward();
  }

  void _swipe(Offset direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    _runAnimation(direction * screenWidth);
  }

  void _snapBack() {
    _runAnimation(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            children: [
              _buildAppBar(context),
              const SizedBox(height: 30),
              Expanded(child: _buildCardStack(screenWidth)),
              const SizedBox(height: 20),
              _buildMatchInfo(),
              const SizedBox(height: 30),
              _buildActionButtons(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Job Recommendations',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ],
            ),
            Image.asset(
              'assets/images/suitcase_icon.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.work_outline, size: 28);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildCardStack(double screenWidth) {
    Widget buildBackgroundCard(
      double angle,
      double verticalOffset,
      double horizontalOffset,
      double scale,
      Color color,
    ) {
      return Transform.translate(
        offset: Offset(horizontalOffset, verticalOffset),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Container(
              height: 200,
              width: screenWidth * 0.9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        buildBackgroundCard(
          -12 * (math.pi / 180),
          -45,
          -20,
          0.85,
          Colors.white.withOpacity(0.7),
        ),
        buildBackgroundCard(
          -8 * (math.pi / 180),
          -30,
          -10,
          0.9,
          Colors.white.withOpacity(0.8),
        ),
        buildBackgroundCard(
          -4 * (math.pi / 180),
          -15,
          0,
          0.95,
          Colors.white.withOpacity(0.9),
        ),
        GestureDetector(
          onPanUpdate: (details) {
            _cardOffsetNotifier.value += details.delta;
          },
          onPanEnd: (details) {
            final cardOffset = _cardOffsetNotifier.value;
            if (cardOffset.dx.abs() > screenWidth / 3) {
              _swipe(
                cardOffset.dx > 0 ? const Offset(2, 0) : const Offset(-2, 0),
              );
            } else {
              _snapBack();
            }
          },
          child: ValueListenableBuilder<Offset>(
            valueListenable: _cardOffsetNotifier,
            builder: (context, offset, _) {
              return Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: (offset.dx / screenWidth) * (math.pi / 20),
                  child: JobCard(
                    title: _jobs[_currentIndex].title,
                    company: _jobs[_currentIndex].company,
                    location: _jobs[_currentIndex].location,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 90,
          right: -40,
          child: Image.asset(
            'assets/images/robot.png',
            height: screenWidth * 0.4,
            width: screenWidth * 0.4,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.smart_toy_outlined, size: 80);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchInfo() {
    return Column(
      children: [
        PaginationDots(activeIndex: _currentIndex, count: _jobs.length),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Estimated 5 matches today',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF20C997),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text(
                'View All',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButton(
          label: 'Pass',
          color: const Color(0xFFEF5350),
          icon: Icons.close,
          onPressed: () => _swipe(const Offset(-2, 0)),
        ),
        ActionButton(
          label: 'Apply',
          color: const Color(0xFF20C997),
          icon: Icons.check,
          onPressed: () => _swipe(const Offset(2, 0)),
        ),
      ],
    );
  }
}

// Reusable Job Card
class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      width: screenWidth * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF5350),
                  shape: BoxShape.circle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2.0, right: 35.0),
                child: Row(
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            company,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            location,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Action Button
class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 45),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Pagination dots
class PaginationDots extends StatelessWidget {
  final int activeIndex;
  final int count;

  const PaginationDots({
    super.key,
    required this.activeIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? Colors.grey.shade600
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
