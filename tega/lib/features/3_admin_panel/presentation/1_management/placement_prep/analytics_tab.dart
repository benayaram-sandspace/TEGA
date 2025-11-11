import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  bool _isLoading = true;
  final AuthService _auth = AuthService();
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminPlacementStats),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _stats = data['stats'] ?? {};
              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch stats');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch stats: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(int? minutes) {
    if (minutes == null || minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          : _stats == null
              ? _buildEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildPerformanceCard(),
                    const SizedBox(height: 20),
                    _buildDetailedAnalytics(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, color: AdminDashboardStyles.primary, size: 40),
          const SizedBox(height: 10),
          Text(
            'No analytics data available',
            style: TextStyle(fontWeight: FontWeight.w700, color: AdminDashboardStyles.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: [
          _buildStatItem(
            title: 'Total Questions',
            value: '${_stats!['totalQuestions'] ?? 0}',
            icon: Icons.description_rounded,
            color: const Color(0xFF3B82F6),
          ),
          _buildStatItem(
            title: 'Total Modules',
            value: '${_stats!['totalModules'] ?? 0}',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF10B981),
          ),
          _buildStatItem(
            title: 'Average Score',
            value: '${_stats!['averageScore'] ?? 0}%',
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF8B5CF6),
          ),
          _buildStatItem(
            title: 'Active Students',
            value: '${_stats!['activeStudents'] ?? 0}',
            icon: Icons.people_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: AdminDashboardStyles.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminDashboardStyles.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performance Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildPerformanceMetric(
                      icon: Icons.flag_rounded,
                      value: '${_stats!['completionRate'] ?? 0}%',
                      label: 'Students completing modules',
                      color: const Color(0xFF3B82F6),
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _buildPerformanceMetric(
                      icon: Icons.emoji_events_rounded,
                      value: '${_stats!['topScore'] ?? 0}%',
                      label: 'Highest score achieved',
                      color: const Color(0xFFF59E0B),
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _buildPerformanceMetric(
                      icon: Icons.access_time_rounded,
                      value: _formatTime(_stats!['averageTime']),
                      label: 'Time per assessment',
                      color: const Color(0xFF8B5CF6),
                    )),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPerformanceMetric(
                      icon: Icons.flag_rounded,
                      value: '${_stats!['completionRate'] ?? 0}%',
                      label: 'Students completing modules',
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceMetric(
                      icon: Icons.emoji_events_rounded,
                      value: '${_stats!['topScore'] ?? 0}%',
                      label: 'Highest score achieved',
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceMetric(
                      icon: Icons.access_time_rounded,
                      value: _formatTime(_stats!['averageTime']),
                      label: 'Time per assessment',
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalytics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCategoryCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildDifficultyCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildCategoryCard(),
              const SizedBox(height: 16),
              _buildDifficultyCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildCategoryCard() {
    final categories = _stats!['questionsByCategory'] as Map<String, dynamic>? ?? {};
    final categoryList = categories.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_rounded, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Questions by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (categoryList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No categories available',
                style: TextStyle(color: AdminDashboardStyles.textLight),
              ),
            )
          else
            ...categoryList.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _capitalizeFirst(entry.key),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminDashboardStyles.textDark,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard() {
    final difficulties = _stats!['questionsByDifficulty'] as Map<String, dynamic>? ?? {};
    final difficultyList = difficulties.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'hard':
          return const Color(0xFFEF4444);
        case 'medium':
          return const Color(0xFFF59E0B);
        case 'easy':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFF6B7280);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Questions by Difficulty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (difficultyList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No difficulty data available',
                style: TextStyle(color: AdminDashboardStyles.textLight),
              ),
            )
          else
            ...difficultyList.map((entry) {
              final color = getDifficultyColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _capitalizeFirst(entry.key),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminDashboardStyles.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
