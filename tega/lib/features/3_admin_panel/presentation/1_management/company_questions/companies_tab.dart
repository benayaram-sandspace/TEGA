import 'package:flutter/material.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class CompaniesTab extends StatefulWidget {
  const CompaniesTab({super.key});

  @override
  State<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<CompaniesTab> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _auth.getAuthHeaders();
      final res = await http.get(
        Uri.parse(ApiEndpoints.adminCompanyList),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final companies = (data['companies'] ?? data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _companies = companies.map((c) {
                if (c is Map<String, dynamic>) {
                  return c;
                }
                return {'name': c.toString(), 'questionCount': 0};
              }).toList();
              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch companies');
        }
      } else {
        final errorData = json.decode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch companies: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading companies: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          : _companies.isEmpty
              ? _buildEmptyState()
              : _buildCompaniesGrid(),
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
          Icon(Icons.business_rounded, color: AdminDashboardStyles.primary, size: 40),
          const SizedBox(height: 10),
          Text(
            'No companies found',
            style: TextStyle(fontWeight: FontWeight.w700, color: AdminDashboardStyles.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload PDFs or add questions to see companies here',
            style: AdminDashboardStyles.statTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final spacing = 16.0;
        final runSpacing = 16.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 2.5,
          ),
          itemCount: _companies.length,
          itemBuilder: (context, index) {
            return _buildCompanyCard(_companies[index]);
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final companyName = (company['name'] ?? company['companyName'] ?? 'Unknown').toString();
    final questionCount = company['questionCount'] ?? 0;

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$questionCount ${questionCount == 1 ? 'question' : 'questions'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 14,
                  color: AdminDashboardStyles.textLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'Questions available for practice',
                  style: TextStyle(
                    fontSize: 11,
                    color: AdminDashboardStyles.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
