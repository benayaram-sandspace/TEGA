import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class ReportsInsightsPage extends StatefulWidget {
  const ReportsInsightsPage({super.key});

  @override
  State<ReportsInsightsPage> createState() => _ReportsInsightsPageState();
}

class _ReportsInsightsPageState extends State<ReportsInsightsPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _trendData = [];
  int _selectedPeriod = 30; // days
  double _maxY = 8.0;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.principalTrendAnalysis}?period=$_selectedPeriod'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['trendData'] != null) {
          final trendData = List<Map<String, dynamic>>.from(data['trendData']);
          
          // Calculate max Y value (with some padding)
          double maxValue = 0;
          for (var item in trendData) {
            final students = (item['students'] as num?)?.toDouble() ?? 0;
            final active = (item['active'] as num?)?.toDouble() ?? 0;
            final completed = (item['completed'] as num?)?.toDouble() ?? 0;
            maxValue = [maxValue, students, active, completed].reduce((a, b) => a > b ? a : b);
          }
          _maxY = (maxValue * 1.2).ceil().toDouble();
          if (_maxY < 8) _maxY = 8;

          setState(() {
            _trendData = trendData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trend Analysis Card
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildTrendAnalysisCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trend Analysis',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Student enrollment and performance trends',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Line Chart
          SizedBox(
            height: 300,
            child: _trendData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No trend data available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildLineChart(),
          ),
          const SizedBox(height: 20),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (_trendData.isEmpty) return const SizedBox.shrink();

    // Prepare data points
    final activeSpots = <FlSpot>[];
    final completedSpots = <FlSpot>[];
    final totalSpots = <FlSpot>[];

    for (int i = 0; i < _trendData.length; i++) {
      final item = _trendData[i];
      final active = (item['active'] as num?)?.toDouble() ?? 0;
      final completed = (item['completed'] as num?)?.toDouble() ?? 0;
      final students = (item['students'] as num?)?.toDouble() ?? 0;

      activeSpots.add(FlSpot(i.toDouble(), active));
      completedSpots.add(FlSpot(i.toDouble(), completed));
      totalSpots.add(FlSpot(i.toDouble(), students));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200.withOpacity(0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
          checkToShowHorizontalLine: (value) => value % 1 == 0,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _trendData.length) {
                  final date = _trendData[value.toInt()]['date'] as String? ?? '';
                  // Show every nth label to avoid crowding
                  final showEvery = _trendData.length > 20 ? 3 : (_trendData.length > 10 ? 2 : 1);
                  if (value.toInt() % showEvery == 0 || value.toInt() == _trendData.length - 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          date.length > 8 ? date.substring(0, 8) : date,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        minX: 0,
        maxX: (_trendData.length - 1).toDouble(),
        minY: 0,
        maxY: _maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => DashboardStyles.primary,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < _trendData.length) {
                  final item = _trendData[index];
                  String label = '';
                  if (spot.barIndex == 0) {
                    label = 'Active: ${item['active']}';
                  } else if (spot.barIndex == 1) {
                    label = 'Completed: ${item['completed']}';
                  } else if (spot.barIndex == 2) {
                    label = 'Total: ${item['students']}';
                  }
                  return LineTooltipItem(
                    label,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).where((item) => item != null).toList();
            },
          ),
        ),
        lineBarsData: [
          // Active Students (Green)
          LineChartBarData(
            spots: activeSpots,
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.3),
                  const Color(0xFF10B981).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Completed Courses (Purple)
          LineChartBarData(
            spots: completedSpots,
            isCurved: true,
            color: const Color(0xFF8B5CF6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.3),
                  const Color(0xFF8B5CF6).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Total Students (Blue)
          LineChartBarData(
            spots: totalSpots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  const Color(0xFF3B82F6).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildLegendItem(
          color: const Color(0xFF10B981),
          label: 'Active Students',
        ),
        _buildLegendItem(
          color: const Color(0xFF8B5CF6),
          label: 'Completed Courses',
        ),
        _buildLegendItem(
          color: const Color(0xFF3B82F6),
          label: 'Total Students',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '→ $label',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
