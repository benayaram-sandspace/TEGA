import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';

// A simple data model for an active course
class ActiveCourse {
  final String title;
  final String subtitle;
  final String instructor;
  final String imageUrl;
  final double progress;
  final String duration;
  final Color startColor;
  final Color endColor;

  ActiveCourse({
    required this.title,
    required this.subtitle,
    required this.instructor,
    required this.imageUrl,
    required this.progress,
    required this.duration,
    required this.startColor,
    required this.endColor,
  });
}

// A simple data model for a subscribed course
class SubscribedCourse {
  final String title;
  final String category;
  final String duration;
  final Color backgroundColor;
  final IconData icon;

  SubscribedCourse({
    required this.title,
    required this.category,
    required this.duration,
    required this.backgroundColor,
    required this.icon,
  });
}

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  // Dummy data inspired by the image
  final List<ActiveCourse> _activeCourses = [
    ActiveCourse(
      title:
          'Mastering React Hooks and State Management in Modern Web Apps', // Longer title
      subtitle: 'Deep Learning',
      instructor: 'Liso Lesow',
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=774&q=80',
      progress: 0.75,
      duration: '7 min',
      startColor: const Color(0xFF6B4BFF),
      endColor: const Color(0xFFB83BFF),
    ),
    ActiveCourse(
      title: 'Core Fundamentals with',
      subtitle: 'Reinforcement Learning',
      instructor: 'Nico Robin The Archaeologist', // Longer instructor name
      imageUrl:
          'https://images.unsplash.com/photo-1527980965255-d3b416303d12?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1160&q=80',
      progress: 0.50,
      duration: '28 min',
      startColor: const Color(0xFFFC547C),
      endColor: const Color(0xFFFD8C5E),
    ),
  ];

  final List<SubscribedCourse> _subscribedCourses = [
    SubscribedCourse(
      title: 'Advanced & little tin React. Hooks',
      category: 'Checklast',
      duration: '7 min',
      backgroundColor: const Color(0xFFE6E3FF),
      icon: Icons.code,
    ),
    SubscribedCourse(
      title: 'Advanced Python for Data Science',
      category: 'Sloeskl',
      duration: '15 min',
      backgroundColor: const Color(0xFFD7F3E4),
      icon: Icons.analytics_outlined,
    ),
    SubscribedCourse(
      title: 'Cotaped Favars Data Structstals',
      category: 'Disdricarte',
      duration: '6 min',
      backgroundColor: const Color(0xFFD4EFFF),
      icon: Icons.data_usage,
    ),
    SubscribedCourse(
      title: 'Advanced Pythonff Im Data Science',
      category: 'Checklast',
      duration: '32 min',
      backgroundColor: const Color(0xFFE6E3FF),
      icon: Icons.science_outlined,
    ),
    SubscribedCourse(
      title: 'UI/X Design fun Fundamentals',
      category: 'Style Skill',
      duration: '23 min',
      backgroundColor: const Color(0xFFCFF3E9),
      icon: Icons.draw_outlined,
    ),
    SubscribedCourse(
      title: 'UI/X Design with AWS Router Fiesis',
      category: 'Dribbblard',
      duration: '72 min',
      backgroundColor: const Color(0xFFFFE4E4),
      icon: Icons.design_services_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // FIX: Set status bar icons to dark for light background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      // FIX: Changed background color to light grey
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // FIX: Changed AppBar color and added elevation for a light theme
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 2.0,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          // FIX: Changed icon color to be visible on a light background
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => StudentHomePage()),
            );
          },
        ),
        title: Text(
          'My Courses',
          // FIX: Changed text color for light theme
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            // FIX: Changed icon color for light theme
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              // Handle filter action
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildSectionHeader('Currently Active Modules'),
          const SizedBox(height: 16),
          _buildActiveCoursesList(),
          const SizedBox(height: 24),
          _buildSectionHeader('Subscribed Courses'),
          const SizedBox(height: 16),
          _buildSubscribedCoursesGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    // FIX: Restyled for light theme
    return TextField(
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: TextStyle(color: Theme.of(context).hintColor),
        prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      // FIX: Changed text color for light theme
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActiveCoursesList() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activeCourses.length,
        itemBuilder: (context, index) {
          final course = _activeCourses[index];
          return _buildActiveCourseCard(course);
        },
      ),
    );
  }

  Widget _buildActiveCourseCard(ActiveCourse course) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [course.startColor, course.endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Stage Alive',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              course.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: CachedNetworkImageProvider(
                          course.imageUrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lesson ${course.duration} left',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: course.progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(course.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          course.instructor,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.videocam_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lideo',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribedCoursesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subscribedCourses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final course = _subscribedCourses[index];
        return _buildSubscribedCourseCard(course);
      },
    );
  }

  Widget _buildSubscribedCourseCard(SubscribedCourse course) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      surfaceTintColor: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: course.backgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    course.icon,
                    size: 40,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                course.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                course.duration,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
