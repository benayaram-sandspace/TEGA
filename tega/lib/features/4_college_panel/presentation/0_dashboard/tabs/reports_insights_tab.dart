import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/principal_dashboard_cache_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class ReportsInsightsPage extends StatefulWidget {
  const ReportsInsightsPage({super.key});

  @override
  State<ReportsInsightsPage> createState() => _ReportsInsightsPageState();
}

class _ReportsInsightsPageState extends State<ReportsInsightsPage> {
  final AuthService _authService = AuthService();
  final PrincipalDashboardCacheService _cacheService = PrincipalDashboardCacheService();
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _trendData = [];
  int _selectedPeriod = 30; // days
  double _maxY = 8.0;

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();
    
    // Try to load from cache first
    await _loadFromCache();
    
    // Then load fresh data
    await _loadTrendData();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _cacheService.getReportsInsightsData();
      if (cachedData != null && mounted) {
        setState(() {
          _isLoadingFromCache = true;
        });
        
        // Restore data from cache
        _trendData = List<Map<String, dynamic>>.from(
          cachedData['trendData'] as List? ?? []
        );
        _selectedPeriod = cachedData['selectedPeriod'] as int? ?? 30;
        _maxY = (cachedData['maxY'] as num?)?.toDouble() ?? 8.0;
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    } catch (e) {
      // Silently handle cache errors
      if (mounted) {
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    }
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  Future<void> _loadTrendData({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && !_isLoadingFromCache && _trendData.isNotEmpty) {
      _loadTrendDataInBackground();
      return;
    }

    if (!_isLoadingFromCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
          final calculatedMaxY = (maxValue * 1.2).ceil().toDouble();
          final finalMaxY = calculatedMaxY < 8 ? 8.0 : calculatedMaxY;

          if (mounted) {
            setState(() {
              _trendData = trendData;
              _maxY = finalMaxY;
              _isLoading = false;
              _isLoadingFromCache = false;
            });
            
            // Cache the reports/insights data
            await _cacheService.setReportsInsightsData({
              'trendData': trendData,
              'selectedPeriod': _selectedPeriod,
              'maxY': finalMaxY,
            });
            
            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoadingFromCache = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getReportsInsightsData();
        if (cachedData != null && mounted) {
          // Restore data from cache
          setState(() {
            _trendData = List<Map<String, dynamic>>.from(
              cachedData['trendData'] as List? ?? []
            );
            _selectedPeriod = cachedData['selectedPeriod'] as int? ?? 30;
            _maxY = (cachedData['maxY'] as num?)?.toDouble() ?? 8.0;
            _isLoading = false;
            _isLoadingFromCache = false;
            _errorMessage = null;
          });
          
          // Handle offline state
          _cacheService.handleOfflineState(context);
        } else {
          // No cache available
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = 'No internet connection';
            });
            
            // Handle offline state
            _cacheService.handleOfflineState(context);
          }
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _errorMessage = 'Error loading reports: $e';
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    }
  }

  Future<void> _loadTrendDataInBackground() async {
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

      if (response.statusCode == 200 && mounted) {
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
          final calculatedMaxY = (maxValue * 1.2).ceil().toDouble();
          final finalMaxY = calculatedMaxY < 8 ? 8.0 : calculatedMaxY;

          if (mounted) {
            setState(() {
              _trendData = trendData;
              _maxY = finalMaxY;
            });
            
            // Cache the reports/insights data
            await _cacheService.setReportsInsightsData({
              'trendData': trendData,
              'selectedPeriod': _selectedPeriod,
              'maxY': finalMaxY,
            });
            
            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        }
      }
    } catch (e) {
      // Silently handle background errors
      if (_isNoInternetError(e)) {
        _cacheService.handleOfflineState(context);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 20.0;
    
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: SafeArea(
        child: _isLoading && !_isLoadingFromCache
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null && _trendData.isEmpty
                ? _buildErrorState(isMobile, isTablet)
                : SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTrendAnalysisCard(isMobile, isTablet),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24.0 : isTablet ? 32.0 : 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile ? 56 : isTablet ? 64 : 72,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'No internet connection',
              style: TextStyle(
                fontSize: isMobile ? 18 : isTablet ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            ElevatedButton.icon(
              onPressed: () => _loadTrendData(forceRefresh: true),
              icon: Icon(Icons.refresh, size: isMobile ? 18 : 20, color: Colors.white),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysisCard(bool isMobile, bool isTablet) {
    // Responsive values
    final padding = isMobile ? 16.0 : isTablet ? 20.0 : 24.0;
    final borderRadius = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    final titleFontSize = isMobile ? 15.0 : isTablet ? 16.0 : 17.0;
    final subtitleFontSize = isMobile ? 10.0 : isTablet ? 10.5 : 11.0;
    final chartHeight = isMobile ? 250.0 : isTablet ? 275.0 : 300.0;
    final chartSpacing = isMobile ? 18.0 : isTablet ? 20.0 : 24.0;
    final legendSpacing = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
    final emptyIconSize = isMobile ? 40.0 : isTablet ? 44.0 : 48.0;
    final emptyFontSize = isMobile ? 13.0 : isTablet ? 13.5 : 14.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isMobile ? 16 : isTablet ? 18 : 20,
            offset: Offset(0, isMobile ? 3 : isTablet ? 3.5 : 4),
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
              Text(
                'Trend Analysis',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: isMobile ? 3 : 4),
              Text(
                'Student enrollment and performance trends',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: chartSpacing),
          // Line Chart
          SizedBox(
            height: chartHeight,
            child: _trendData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: emptyIconSize,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: isMobile ? 10 : 12),
                        Text(
                          'No trend data available',
                          style: TextStyle(
                            fontSize: emptyFontSize,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildLineChart(isMobile, isTablet),
          ),
          SizedBox(height: legendSpacing),
          // Legend
          _buildLegend(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildLineChart(bool isMobile, bool isTablet) {
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
              reservedSize: isMobile ? 35 : isTablet ? 38 : 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _trendData.length) {
                  final date = _trendData[value.toInt()]['date'] as String? ?? '';
                  // Show every nth label to avoid crowding
                  final showEvery = _trendData.length > 20 ? 3 : (_trendData.length > 10 ? 2 : 1);
                  if (value.toInt() % showEvery == 0 || value.toInt() == _trendData.length - 1) {
                    return Padding(
                      padding: EdgeInsets.only(top: isMobile ? 6 : 8),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          date.length > (isMobile ? 6 : 8) ? date.substring(0, isMobile ? 6 : 8) : date,
                          style: TextStyle(
                            fontSize: isMobile ? 9 : isTablet ? 9.5 : 10,
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
              reservedSize: isMobile ? 35 : isTablet ? 38 : 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 10 : isTablet ? 10.5 : 11,
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
            tooltipPadding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
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
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 11 : isTablet ? 11.5 : 12,
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
            barWidth: isMobile ? 2.5 : isTablet ? 2.75 : 3,
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
            barWidth: isMobile ? 2.5 : isTablet ? 2.75 : 3,
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
            barWidth: isMobile ? 2.5 : isTablet ? 2.75 : 3,
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

  Widget _buildLegend(bool isMobile, bool isTablet) {
    final spacing = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    final runSpacing = isMobile ? 10.0 : isTablet ? 11.0 : 12.0;
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        _buildLegendItem(
          color: const Color(0xFF10B981),
          label: 'Active Students',
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _buildLegendItem(
          color: const Color(0xFF8B5CF6),
          label: 'Completed Courses',
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _buildLegendItem(
          color: const Color(0xFF3B82F6),
          label: 'Total Students',
          isMobile: isMobile,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isMobile,
    required bool isTablet,
  }) {
    final lineWidth = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;
    final lineHeight = isMobile ? 2.5 : 3.0;
    final fontSize = isMobile ? 10.0 : isTablet ? 10.5 : 11.0;
    final spacing = isMobile ? 5.0 : 6.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: lineWidth,
          height: lineHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            '→ $label',
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF1F2937),
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
