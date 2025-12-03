import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tega/core/services/help_support_cache_service.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final HelpSupportCacheService _cacheService = HelpSupportCacheService();

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    // Future: Load categories and articles from API if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 24
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrowseByCategory(),
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 24,
            ),
            _buildPopularArticles(),
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 24,
            ),
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseByCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by Category',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(
          height: isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen
              ? 1
              : isTablet
              ? 2
              : isDesktop
              ? 3
              : isLargeDesktop
              ? 3
              : 2,
          mainAxisSpacing: isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
          crossAxisSpacing: isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
          childAspectRatio: isSmallScreen
              ? 2.5
              : isTablet
              ? 1.3
              : isDesktop
              ? 1.2
              : isLargeDesktop
              ? 1.15
              : 1.2,
          children: [
            _buildCategoryCard(
              icon: Icons.play_circle_outline,
              iconColor: const Color(0xFF3B82F6),
              title: 'Getting Started',
              description:
                  'Learn how to create an account, enroll in courses, and navigate the platform.',
            ),
            _buildCategoryCard(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF10B981),
              title: 'Account & Profile',
              description:
                  'Manage your account settings, update profile information, and change passwords.',
            ),
            _buildCategoryCard(
              icon: Icons.school_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Courses & Learning',
              description:
                  'Access course materials, submit assignments, and track your progress.',
            ),
            _buildCategoryCard(
              icon: Icons.payment_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'Payments & Refunds',
              description:
                  'Information about payment methods, refunds, and billing issues.',
            ),
            _buildCategoryCard(
              icon: Icons.support_agent,
              iconColor: const Color(0xFFEF4444),
              title: 'Technical Support',
              description:
                  'Troubleshoot technical issues with the platform and system requirements.',
            ),
            _buildCategoryCard(
              icon: Icons.verified_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: 'Certificates & Credentials',
              description:
                  'Access and verify your course completion certificates.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 14
            : 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 10
                  : isDesktop
                  ? 9
                  : isTablet
                  ? 8
                  : isSmallScreen
                  ? 7
                  : 8,
            ),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 7
                    : 8,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 26
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 22
                  : 24,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 17
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 15
                  : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 6
                : isDesktop
                ? 5
                : isTablet
                ? 4
                : isSmallScreen
                ? 3
                : 4,
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 13
                    : isTablet
                    ? 12
                    : isSmallScreen
                    ? 11
                    : 12,
              ),
              maxLines: isSmallScreen ? 4 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Articles',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(
          height: isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(
              isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.05),
                blurRadius: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 10,
                offset: Offset(
                  0,
                  isLargeDesktop
                      ? 3
                      : isDesktop
                      ? 2.5
                      : isTablet
                      ? 2
                      : isSmallScreen
                      ? 1.5
                      : 2,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildArticleItem('How to reset your password'),
              _buildDivider(),
              _buildArticleItem('System requirements for online learning'),
              _buildDivider(),
              _buildArticleItem('How to download course materials'),
              _buildDivider(),
              _buildArticleItem(
                'Understanding the course completion certificate',
              ),
              _buildDivider(),
              _buildArticleItem('Troubleshooting video playback issues'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArticleItem(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 14
            : 16,
        vertical: isLargeDesktop
            ? 16
            : isDesktop
            ? 14
            : isTablet
            ? 12
            : isSmallScreen
            ? 10
            : 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: Theme.of(context).disabledColor,
            size: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
          ),
          SizedBox(
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 13
                    : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Read →',
            style: TextStyle(
              color: const Color(0xFF3B82F6),
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 13
                  : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 14
            : 16,
      ),
      height: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 18
            : 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 14
              : isTablet
              ? 12
              : isSmallScreen
              ? 10
              : 12,
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Still need help?',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: isLargeDesktop
                  ? 22
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 19
                  : isSmallScreen
                  ? 17
                  : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 8,
          ),
          Text(
            'Our support team is available to help you with any questions or issues you might have.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 12
                  : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          isSmallScreen
              ? Column(
                  children: [
                    _buildSupportButton(
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      isPrimary: false,
                      onTap: () => _launchEmail(),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildSupportButton(
                      icon: Icons.phone_outlined,
                      title: 'Call Support',
                      isPrimary: true,
                      onTap: () => _launchPhone(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildSupportButton(
                        icon: Icons.email_outlined,
                        title: 'Email Support',
                        isPrimary: false,
                        onTap: () => _launchEmail(),
                      ),
                    ),
                    SizedBox(
                      width: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 14
                          : isTablet
                          ? 12
                          : 12,
                    ),
                    Expanded(
                      child: _buildSupportButton(
                        icon: Icons.phone_outlined,
                        title: 'Call Support',
                        isPrimary: true,
                        onTap: () => _launchPhone(),
                      ),
                    ),
                  ],
                ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).textTheme.bodySmall?.color,
                size: isLargeDesktop
                    ? 18
                    : isDesktop
                    ? 17
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 14
                    : 16,
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Flexible(
                child: Text(
                  'Available Monday to Friday, 9:00 AM to 6:00 PM IST',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 11
                        : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          foregroundColor: isPrimary
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(
            horizontal: isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 16
                : isSmallScreen
                ? 14
                : 16,
            vertical: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isLargeDesktop
                  ? 10
                  : isDesktop
                  ? 9
                  : isTablet
                  ? 8
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: const Color(0xFF3B82F6),
                    width: isLargeDesktop || isDesktop
                        ? 1.5
                        : isTablet
                        ? 1.2
                        : isSmallScreen
                        ? 0.8
                        : 1,
                  ),
          ),
          elevation: 0,
        ),
        icon: Icon(
          icon,
          size: isLargeDesktop
              ? 20
              : isDesktop
              ? 19
              : isTablet
              ? 18
              : isSmallScreen
              ? 16
              : 18,
        ),
        label: Text(
          title,
          style: TextStyle(
            fontSize: isLargeDesktop
                ? 17
                : isDesktop
                ? 16
                : isTablet
                ? 15
                : isSmallScreen
                ? 13
                : 14,
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@tega.com',
      query: 'subject=Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+91-9876543210');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}
