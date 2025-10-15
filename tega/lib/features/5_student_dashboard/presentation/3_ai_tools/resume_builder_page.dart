import 'package:flutter/material.dart';
import 'models/resume_template.dart';
import 'templates/template_registry.dart';
import 'widgets/template_gallery.dart';
import 'widgets/live_preview.dart';
import 'services/export_service.dart';
import '../shared/widgets/coming_soon_overlay.dart';

class ResumeBuilderPage extends StatefulWidget {
  const ResumeBuilderPage({super.key});

  @override
  State<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends State<ResumeBuilderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Personal Info Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _summaryController = TextEditingController();

  // Resume Data
  ResumeData _resumeData = ResumeData();
  final TemplateRegistry _templateRegistry = TemplateRegistry();
  TemplateMetadata? _selectedTemplate;
  bool _isLoading = false;
  bool _showPreview = false;
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _templateRegistry.initializeTemplates();
    _selectedTemplate = _templateRegistry.selectedTemplate;
    _loadResumeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _loadResumeData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _updateResumeData() {
    setState(() {
      _resumeData = _resumeData.copyWith(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        location: _locationController.text,
        linkedin: _linkedinController.text,
        summary: _summaryController.text,
        experiences: _resumeData.experiences,
        educations: _resumeData.educations,
        skills: _resumeData.skills,
        projects: _resumeData.projects,
        certifications: _resumeData.certifications,
        languages: _resumeData.languages,
      );
    });
  }

  int get completionPercentage => _resumeData.completionPercentage;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;
    final isTablet = size.width > 600 && size.width <= 1200;

    return ComingSoonOverlay(
      featureName: 'Resume Builder',
      description:
          'Create professional resumes with our AI-powered builder. Choose from multiple templates and export to PDF.',
      icon: Icons.description_rounded,
      primaryColor: const Color(0xFF4CAF50),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            _buildTopBar(isDesktop, isTablet),
            Expanded(
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          flex: _showPreview ? 5 : 1,
                          child: _buildMainContent(isDesktop, isTablet),
                        ),
                        if (_showPreview)
                          Expanded(
                            flex: 4,
                            child: _buildLivePreview(isDesktop),
                          ),
                      ],
                    )
                  : _showPreview
                  ? _buildLivePreview(isDesktop)
                  : _buildMainContent(isDesktop, isTablet),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _exportPDF(),
          backgroundColor: const Color(0xFF6B5FFF),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text(
            'Export PDF',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Professional Resume Builder',
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create ATS-friendly resumes with professional templates',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop || isTablet) ...[
                const SizedBox(width: 24),
                Column(
                  children: [
                    _buildActionButton(
                      'Templates',
                      Icons.palette_outlined,
                      () => _showTemplateSelector(),
                      const Color(0xFF6B5FFF),
                      false,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      _showPreview ? 'Hide Preview' : 'Live Preview',
                      _showPreview ? Icons.visibility_off : Icons.visibility,
                      () => setState(() => _showPreview = !_showPreview),
                      const Color(0xFF6B5FFF),
                      false,
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (!isDesktop && !isTablet) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Templates',
                        Icons.palette_outlined,
                        () => _showTemplateSelector(),
                        const Color(0xFF6B5FFF),
                        false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        _showPreview ? 'Edit' : 'Preview',
                        _showPreview ? Icons.edit : Icons.visibility,
                        () => setState(() => _showPreview = !_showPreview),
                        const Color(0xFF6B5FFF),
                        false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$completionPercentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: completionPercentage == 100
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6B5FFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: completionPercentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(
              completionPercentage == 100
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B5FFF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    Color color,
    bool isLoading,
  ) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop, bool isTablet) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          _buildQuickTips(isDesktop, isTablet),
          const SizedBox(height: 4),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(isDesktop, isTablet),
                _buildExperienceTab(isDesktop, isTablet),
                _buildEducationTab(isDesktop, isTablet),
                _buildSkillsTab(isDesktop, isTablet),
                _buildExtrasTab(isDesktop, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips(bool isDesktop, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B5FFF).withOpacity(0.1),
            const Color(0xFF8B7FFF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B5FFF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF6B5FFF),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Fill all sections to increase your completion score',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5FFF).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(6),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 18),
                SizedBox(width: 6),
                Text('Personal Info'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work_outline, size: 18),
                SizedBox(width: 6),
                Text('Experience'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 18),
                SizedBox(width: 6),
                Text('Education'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_outlined, size: 18),
                SizedBox(width: 6),
                Text('Skills'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 18),
                SizedBox(width: 6),
                Text('Extras'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Personal Info Tab
  Widget _buildPersonalInfoTab(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16 : 8,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Basic details that will appear on your resume',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'John Doe',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'john@example.com',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+1 (555) 000-0000',
                    icon: Icons.phone_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'City, State, Country',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _linkedinController,
              label: 'LinkedIn Profile (Optional)',
              hint: 'linkedin.com/in/johndoe',
              icon: Icons.link,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Professional Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A brief overview of your professional background and goals',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _summaryController,
              label: 'Summary',
              hint:
                  'Write a compelling summary of your skills, experience, and career objectives...',
              icon: Icons.description_outlined,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  // Experience Tab
  Widget _buildExperienceTab(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16 : 8,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            color: const Color(0xFF6B5FFF),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Work Experience',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: Text(
                          'Add your professional work history',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addExperience(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_resumeData.experiences.isEmpty)
              _buildEmptyState(
                'No work experience added yet',
                'Add your professional experience to build a strong resume',
                Icons.work_outline,
              )
            else
              ..._resumeData.experiences.asMap().entries.map((entry) {
                return _buildExperienceCard(entry.value, entry.key);
              }),
          ],
        ),
      ),
    );
  }

  // Education Tab
  Widget _buildEducationTab(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16 : 8,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: const Color(0xFF10B981),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Education',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: Text(
                          'Add your educational background',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addEducation(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_resumeData.educations.isEmpty)
              _buildEmptyState(
                'No education added yet',
                'Add your academic qualifications to complete your resume',
                Icons.school_outlined,
              )
            else
              ..._resumeData.educations.asMap().entries.map((entry) {
                return _buildEducationCard(entry.value, entry.key);
              }),
          ],
        ),
      ),
    );
  }

  // Skills Tab
  Widget _buildSkillsTab(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16 : 8,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars_outlined,
                            color: const Color(0xFFF59E0B),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Skills',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: Text(
                          'List your technical and soft skills',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addSkill(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_resumeData.skills.isEmpty)
              _buildEmptyState(
                'No skills added yet',
                'Add at least 5-7 skills to showcase your expertise',
                Icons.star_outline,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _resumeData.skills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _resumeData.skills.remove(skill));
                    },
                    backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIconColor: const Color(0xFF92400E),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Extras Tab
  Widget _buildExtrasTab(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16 : 8,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
        isDesktop ? 20 : 12,
      ),
      child: Column(
        children: [
          // Projects
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.code_outlined,
                            color: const Color(0xFFEC4899),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Projects',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _addProject(),
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFFEC4899),
                        size: 28,
                      ),
                    ),
                  ],
                ),
                if (_resumeData.projects.isEmpty)
                  const SizedBox()
                else
                  ..._resumeData.projects.asMap().entries.map((entry) {
                    return _buildProjectCard(entry.value, entry.key);
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Certifications
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: const Color(0xFF6B5FFF),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Certifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _addCertification(),
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF6B5FFF),
                        size: 28,
                      ),
                    ),
                  ],
                ),
                if (_resumeData.certifications.isEmpty)
                  const SizedBox()
                else
                  ..._resumeData.certifications.asMap().entries.map((entry) {
                    return _buildCertificationCard(entry.value, entry.key);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: const Color(0xFF6B5FFF)),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (_) {
              setState(() {});
              _updateResumeData();
            },
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6B5FFF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(WorkExperience exp, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          exp.position,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(exp.company),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editExperience(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {
                setState(() => _resumeData.experiences.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCard(Education edu, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          edu.degree,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(edu.institution),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editEducation(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {
                setState(() => _resumeData.educations.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          project.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: () {
            setState(() => _resumeData.projects.removeAt(index));
          },
        ),
      ),
    );
  }

  Widget _buildCertificationCard(Certification cert, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          cert.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(cert.issuer),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: () {
            setState(() => _resumeData.certifications.removeAt(index));
          },
        ),
      ),
    );
  }

  Widget _buildLivePreview(bool isDesktop) {
    if (_selectedTemplate == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.palette_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Select a template to see preview',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LivePreview(
      resumeData: _resumeData,
      template: _selectedTemplate!,
      isVisible: true,
      onClose: () => setState(() => _showPreview = false),
    );
  }

  // Dialog Methods
  void _showTemplateSelector() {
    showDialog(
      context: context,
      builder: (context) => TemplateGallery(
        selectedTemplateId: _selectedTemplate?.id,
        onTemplateSelected: (templateId) {
          setState(() {
            _templateRegistry.selectTemplate(templateId);
            _selectedTemplate = _templateRegistry.selectedTemplate;
          });
        },
      ),
    );
  }

  void _addExperience() {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Experience'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resumeData.experiences.add(
                  WorkExperience(
                    company: companyController.text,
                    position: titleController.text,
                    location: '',
                    startDate: '',
                    endDate: '',
                    description: descController.text,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editExperience(int index) {
    final exp = _resumeData.experiences[index];
    final titleController = TextEditingController(text: exp.position);
    final companyController = TextEditingController(text: exp.company);
    final descController = TextEditingController(text: exp.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Experience'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resumeData.experiences[index] = WorkExperience(
                  company: companyController.text,
                  position: titleController.text,
                  location: exp.location,
                  startDate: exp.startDate,
                  endDate: exp.endDate,
                  description: descController.text,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addEducation() {
    final degreeController = TextEditingController();
    final institutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Education'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: degreeController,
                decoration: const InputDecoration(labelText: 'Degree'),
              ),
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resumeData.educations.add(
                  Education(
                    degree: degreeController.text,
                    institution: institutionController.text,
                    location: '',
                    startDate: '',
                    endDate: '',
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editEducation(int index) {
    final edu = _resumeData.educations[index];
    final degreeController = TextEditingController(text: edu.degree);
    final institutionController = TextEditingController(text: edu.institution);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Education'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: degreeController,
                decoration: const InputDecoration(labelText: 'Degree'),
              ),
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resumeData.educations[index] = Education(
                  degree: degreeController.text,
                  institution: institutionController.text,
                  location: edu.location,
                  startDate: edu.startDate,
                  endDate: edu.endDate,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSkill() {
    final skillController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          controller: skillController,
          decoration: const InputDecoration(
            labelText: 'Skill Name',
            hintText: 'e.g. Flutter, Python, Leadership',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (skillController.text.isNotEmpty) {
                setState(() => _resumeData.skills.add(skillController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addProject() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Project Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resumeData.projects.add(
                  Project(
                    name: titleController.text,
                    description: descController.text,
                    technologies: '',
                    startDate: '',
                    endDate: '',
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCertification() {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Certification'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Certification Name',
                ),
              ),
              TextField(
                controller: issuerController,
                decoration: const InputDecoration(
                  labelText: 'Issuing Organization',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resumeData.certifications.add(
                  Certification(
                    name: nameController.text,
                    issuer: issuerController.text,
                    date: '',
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _exportPDF() {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template first!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _updateResumeData();

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        resumeData: _resumeData,
        template: _selectedTemplate!,
        previewKey: _previewKey,
      ),
    );
  }
}
