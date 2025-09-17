import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

// Helper class for event data, can be in its own file or shared.
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

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  static final List<EventInfo> _allEvents = [
    // September
    EventInfo(
      title: 'Parent-Teacher Meeting',
      date: 'Sep 18, 2025',
      time: '10:00 AM - 1:00 PM',
      icon: Icons.groups_rounded,
      color: DashboardStyles.primary,
      location: 'Main Auditorium',
      description:
          'A meeting to discuss student progress for the first quarter.',
    ),
    EventInfo(
      title: 'Guest Lecture: AI Ethics',
      date: 'Sep 25, 2025',
      time: '3:00 PM',
      icon: Icons.mic_external_on_rounded,
      color: DashboardStyles.accentPurple,
      location: 'Seminar Hall B',
      description: 'Special lecture by Dr. Anya Sharma on ethics in AI.',
    ),
    // October
    EventInfo(
      title: 'Science Fair',
      date: 'Oct 15, 2025',
      time: 'All Day',
      icon: Icons.science_rounded,
      color: DashboardStyles.accentGreen,
      location: 'College Grounds',
      description: 'Annual science fair showcasing student projects.',
    ),
    EventInfo(
      title: 'Mid-Term Exams Begin',
      date: 'Oct 20, 2025',
      time: '9:00 AM',
      icon: Icons.edit_note_rounded,
      color: DashboardStyles.accentOrange,
      location: 'Respective Classrooms',
      description: 'Mid-term examinations for all departments.',
    ),
    // November
    EventInfo(
      title: 'Annual Sports Day',
      date: 'Nov 12, 2025',
      time: '8:00 AM - 4:00 PM',
      icon: Icons.sports_kabaddi_rounded,
      color: DashboardStyles.accentRed,
      location: 'Sports Complex',
      description: 'A day of athletic events and friendly competition.',
    ),
    EventInfo(
      title: 'Diwali Vacation Starts',
      date: 'Nov 20, 2025',
      time: 'End of Day',
      icon: Icons.celebration_rounded,
      color: DashboardStyles.primary,
      location: 'Campus-wide',
      description: 'The college will be closed for the Diwali festival.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
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
      isScrollControlled: true, // Allows the sheet to be taller
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains the same as before)
    final Map<String, List<EventInfo>> groupedEvents = {};
    for (var event in _allEvents) {
      final month =
          "${event.date.split(' ')[0]} ${event.date.split(' ')[2]}"; // e.g., "Sep 2025"
      if (groupedEvents[month] == null) {
        groupedEvents[month] = [];
      }
      groupedEvents[month]!.add(event);
    }

    return Scaffold(
      backgroundColor: DashboardStyles.background,
      appBar: AppBar(
        title: const Text(
          'All Upcoming Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DashboardStyles.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: groupedEvents.keys.length,
        itemBuilder: (context, index) {
          String month = groupedEvents.keys.elementAt(index);
          List<EventInfo> events = groupedEvents[month]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    month.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              ...List.generate(events.length, (eventIndex) {
                final animation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (eventIndex * 0.15).clamp(0.0, 1.0),
                    ((eventIndex + 1) * 0.2).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: _buildFullEventTile(events[eventIndex]),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFullEventTile(EventInfo event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // MODIFICATION: onTap now calls the new method
        onTap: () => _showEventDetails(context, event),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ... (Date block remains the same)
              Container(
                width: 55,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      event.color.withOpacity(0.2),
                      event.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: event.color.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.date.split(' ')[0].toUpperCase(), // "SEP"
                      style: TextStyle(
                        color: event.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.date.split(' ')[1].replaceAll(',', ''), // "18"
                      style: TextStyle(
                        color: event.color.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // ... (Details block remains the same)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(event.icon, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          event.time,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MODIFICATION: New widget for the content of the bottom sheet
class _EventDetailsSheet extends StatelessWidget {
  final EventInfo event;
  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, // Start at 60% of the screen height
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
              // Drag handle
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
              // Header
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
              // Details section
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
              // Description
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
              // Action Button
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
