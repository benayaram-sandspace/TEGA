import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: DashboardStyles.cardBackground,
        foregroundColor: DashboardStyles.textDark,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=$index',
                ),
              ),
              title: Text('Student ${index + 1}'),
              subtitle: Text(
                'Grade: ${10 - index} | GPA: ${(4.0 - index * 0.2).toStringAsFixed(1)}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: index % 3 == 0
                      ? DashboardStyles.accentGreen.withOpacity(0.1)
                      : index % 3 == 1
                      ? DashboardStyles.accentOrange.withOpacity(0.1)
                      : DashboardStyles.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  index % 3 == 0
                      ? 'Excellent'
                      : index % 3 == 1
                      ? 'Good'
                      : 'Average',
                  style: TextStyle(
                    color: index % 3 == 0
                        ? DashboardStyles.accentGreen
                        : index % 3 == 1
                        ? DashboardStyles.accentOrange
                        : DashboardStyles.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: DashboardStyles.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
