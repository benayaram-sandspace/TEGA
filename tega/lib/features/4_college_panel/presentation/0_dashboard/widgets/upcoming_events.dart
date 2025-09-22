import 'package:flutter/material.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

import 'package:visibility_detector/visibility_detector.dart';
import 'all_events_page.dart'; // This import is still needed for navigation

// MODIFICATION: The EventInfo class now includes location and description for the details panel
class EventInfo {
  final String title;
  final String date;
  final String time;
  final IconData icon;
  final Color color;
  final String location;
  final String description;

  const EventInfo({
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
    required this.color,
    required this.location,
    required this.description,
  });
}

class UpcomingEvents extends StatefulWidget {
  const UpcomingEvents({super.key});

  @override
  State<UpcomingEvents> createState() => _UpcomingEventsState();
}

class _UpcomingEventsState extends State<UpcomingEvents>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _animationStarted = false;

  // MODIFICATION: Added location and description data for each event
  final List<EventInfo> _events = [
    EventInfo(
      title: 'Parent-Teacher Meeting',
      date: 'Sep 18, 2025',
      time: 'Tomorrow, 10:00 AM',
      icon: Icons.groups_outlined,
      color: DashboardStyles.primary,
      location: 'Main Auditorium',
      description:
          'A meeting to discuss student progress for the first quarter.',
    ),
    EventInfo(
      title: 'Science Fair',
      date: 'Oct 15, 2025',
      time: 'In 4 weeks',
      icon: Icons.science_outlined,
      color: DashboardStyles.accentGreen,
      location: 'College Grounds',
      description: 'Annual science fair showcasing student projects.',
    ),
    EventInfo(
      title: 'Mid-Term Exams Begin',
      date: 'Oct 20, 2025',
      time: 'In 5 weeks',
      icon: Icons.edit_note_outlined,
      color: DashboardStyles.accentOrange,
      location: 'Respective Classrooms',
      description: 'Mid-term examinations for all departments.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // MODIFICATION: New method to show the details panel
  void _showEventDetails(BuildContext context, EventInfo event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains the same)
    return VisibilityDetector(
      key: const Key('upcoming-events-card'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_animationStarted) {
          setState(() {
            _animationStarted = true;
            _animationController.forward();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DashboardStyles.cardBackground,
              Color.lerp(DashboardStyles.cardBackground, Colors.black, 0.04)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Events',
                  style: DashboardStyles.sectionTitle,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllEventsPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: DashboardStyles.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_events.length, (index) {
              return _buildAnimatedEventItem(
                event: _events[index],
                index: index,
                isLast: index == _events.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedEventItem({
    required EventInfo event,
    required int index,
    required bool isLast,
  }) {
    // ... (Animation logic remains the same)
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2 * index, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation),
        child: _buildEventItem(event, isLast),
      ),
    );
  }

  Widget _buildEventItem(EventInfo event, bool isLast) {
    // MODIFICATION: The Row is now wrapped in an InkWell to make it tappable
    return InkWell(
      onTap: () => _showEventDetails(context, event),
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Timeline column remains the same)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(event.icon, color: event.color, size: 22),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade200),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // ... (Details column remains the same)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.time,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MODIFICATION: The details sheet widget is now included here as well.
class _EventDetailsSheet extends StatelessWidget {
  final EventInfo event;
  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: DashboardStyles.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.color.withOpacity(0.1),
                    ),
                    child: Icon(event.icon, color: event.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                'Date',
                event.date,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.access_time_outlined, 'Time', event.time),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.location_on_outlined,
                'Location',
                event.location,
              ),
              const SizedBox(height: 24),
              Text(
                'About Event',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_alert_outlined, color: Colors.white),
                label: const Text(
                  'Add to Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: event.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }
}
