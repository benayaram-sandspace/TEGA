import 'package:flutter/material.dart';
import '../models/resume_template.dart';

class TemplateRegistry {
  static final TemplateRegistry _instance = TemplateRegistry._internal();
  factory TemplateRegistry() => _instance;
  TemplateRegistry._internal();

  final List<TemplateMetadata> _templates = [];
  String? _selectedTemplateId;

  List<TemplateMetadata> get templates => List.unmodifiable(_templates);
  String? get selectedTemplateId => _selectedTemplateId;

  TemplateMetadata? get selectedTemplate {
    if (_selectedTemplateId == null) return null;
    return _templates.firstWhere(
      (template) => template.id == _selectedTemplateId,
      orElse: () => _templates.first,
    );
  }

  void initializeTemplates() {
    _templates.clear();
    _templates.addAll(_generatePlaceholderTemplates());
    _selectedTemplateId = _templates.first.id;
  }

  void selectTemplate(String templateId) {
    if (_templates.any((template) => template.id == templateId)) {
      _selectedTemplateId = templateId;
    }
  }

  List<TemplateMetadata> getTemplatesByCategory(TemplateCategory category) {
    return _templates
        .where((template) => template.category == category)
        .toList();
  }

  List<TemplateMetadata> searchTemplates(String query) {
    if (query.isEmpty) return _templates;

    final lowercaseQuery = query.toLowerCase();
    return _templates.where((template) {
      return template.name.toLowerCase().contains(lowercaseQuery) ||
          template.description.toLowerCase().contains(lowercaseQuery) ||
          template.features.any(
            (feature) => feature.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  List<TemplateMetadata> getPopularTemplates() {
    final sortedTemplates = List<TemplateMetadata>.from(_templates);
    sortedTemplates.sort((a, b) => b.downloads.compareTo(a.downloads));
    return sortedTemplates.take(6).toList();
  }

  List<TemplateMetadata> getRecentTemplates() {
    // In a real app, this would track user's recently used templates
    return _templates.take(4).toList();
  }

  List<TemplateMetadata> _generatePlaceholderTemplates() {
    return [
      // ATS Templates
      TemplateMetadata(
        id: 'professional_1',
        name: 'ATS Classic',
        description: 'ATS-optimized template with clean, professional layout',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/ats_classic.png',
        features: ['ATS Friendly', 'Clean Layout', 'Professional Typography'],
        rating: 4.8,
        downloads: 1250,
      ),
      TemplateMetadata(
        id: 'professional_2',
        name: 'ATS Engineering',
        description: 'Perfect for engineering and technical roles',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/ats_engineering.png',
        features: ['Engineering Focus', 'Technical Skills', 'ATS Optimized'],
        rating: 4.6,
        downloads: 980,
      ),
      TemplateMetadata(
        id: 'professional_3',
        name: 'ATS IT',
        description: 'Designed for IT support and technical positions',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/ats_it.png',
        features: ['IT Focus', 'Technical Skills', 'ATS Friendly'],
        rating: 4.7,
        downloads: 1100,
      ),
      TemplateMetadata(
        id: 'professional_4',
        name: 'ATS Modern',
        description: 'Modern ATS template with contemporary design',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/ats_modern.png',
        features: ['Modern Design', 'ATS Optimized', 'Professional'],
        rating: 4.5,
        downloads: 950,
      ),
      TemplateMetadata(
        id: 'creative_1',
        name: 'ATS Professional',
        description: 'Professional ATS template with clean layout',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/ats_professional.png',
        features: ['Professional Style', 'ATS Friendly', 'Clean Design'],
        rating: 4.6,
        downloads: 920,
      ),
      TemplateMetadata(
        id: 'creative_2',
        name: 'ATS Simple',
        description: 'Simple and clean ATS-optimized template',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/ats_simple.png',
        features: ['Simple Design', 'ATS Optimized', 'Clean Layout'],
        rating: 4.4,
        downloads: 850,
      ),
      TemplateMetadata(
        id: 'modern_1',
        name: 'ATS Technical',
        description: 'Technical-focused ATS template',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/ats_technical.png',
        features: ['Technical Focus', 'ATS Friendly', 'Professional'],
        rating: 4.7,
        downloads: 1050,
      ),

      // Professional Templates
      TemplateMetadata(
        id: 'classic_1',
        name: 'Bold Template',
        description: 'Bold and impactful design with dark theme',
        category: TemplateCategory.creative,
        colorScheme: TemplateColorScheme.orange,
        previewImage: 'assets/templates/bold.png',
        features: ['Bold Design', 'Dark Theme', 'High Impact'],
        rating: 4.5,
        downloads: 750,
      ),
      TemplateMetadata(
        id: 'classic_2',
        name: 'CS Fresher',
        description: 'Perfect for computer science fresh graduates',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.green,
        previewImage: 'assets/templates/cs_fresher.png',
        features: ['Fresher Focus', 'CS Skills', 'Clean Design'],
        rating: 4.4,
        downloads: 680,
      ),
      TemplateMetadata(
        id: 'minimalist_1',
        name: 'Chronological',
        description: 'Traditional chronological resume layout',
        category: TemplateCategory.classic,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/chronological.png',
        features: ['Chronological Order', 'Traditional Layout', 'Professional'],
        rating: 4.3,
        downloads: 850,
      ),
      TemplateMetadata(
        id: 'minimalist_2',
        name: 'Classic Template',
        description: 'Classic and timeless professional design',
        category: TemplateCategory.classic,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/classic.png',
        features: ['Classic Design', 'Timeless Style', 'Professional'],
        rating: 4.6,
        downloads: 920,
      ),
      TemplateMetadata(
        id: 'executive_1',
        name: 'Clean Template',
        description: 'Clean and minimalist professional design',
        category: TemplateCategory.minimalist,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/clean.png',
        features: ['Clean Design', 'Minimalist', 'Professional'],
        rating: 4.7,
        downloads: 1050,
      ),
      TemplateMetadata(
        id: 'executive_2',
        name: 'Compact Template',
        description: 'Compact design for space-efficient resumes',
        category: TemplateCategory.minimalist,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/compact.png',
        features: ['Compact Layout', 'Space Efficient', 'Professional'],
        rating: 4.5,
        downloads: 890,
      ),
      TemplateMetadata(
        id: 'executive_3',
        name: 'Contemporary',
        description: 'Contemporary design with modern layout',
        category: TemplateCategory.modern,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/contemporary.png',
        features: ['Contemporary Style', 'Modern Layout', 'Professional'],
        rating: 4.6,
        downloads: 950,
      ),
      TemplateMetadata(
        id: 'creative_3',
        name: 'Creative Template',
        description: 'Creative design for artistic professionals',
        category: TemplateCategory.creative,
        colorScheme: TemplateColorScheme.purple,
        previewImage: 'assets/templates/creative.png',
        features: ['Creative Design', 'Artistic Style', 'Visual Appeal'],
        rating: 4.4,
        downloads: 780,
      ),
      TemplateMetadata(
        id: 'creative_4',
        name: 'Elegant Template',
        description: 'Elegant and sophisticated design',
        category: TemplateCategory.classic,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/elegant.png',
        features: ['Elegant Design', 'Sophisticated Style', 'Professional'],
        rating: 4.8,
        downloads: 1100,
      ),
      TemplateMetadata(
        id: 'executive_4',
        name: 'Executive Template',
        description: 'Executive-level design for senior positions',
        category: TemplateCategory.executive,
        colorScheme: TemplateColorScheme.black,
        previewImage: 'assets/templates/executive.png',
        features: ['Executive Style', 'Senior Level', 'Professional'],
        isPremium: true,
        rating: 4.9,
        downloads: 650,
      ),
      TemplateMetadata(
        id: 'functional_1',
        name: 'Functional Template',
        description: 'Functional resume layout for career changers',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/functional.png',
        features: ['Functional Layout', 'Career Change', 'Skills Focus'],
        rating: 4.3,
        downloads: 720,
      ),
      TemplateMetadata(
        id: 'it_fresher_1',
        name: 'IT Fresher',
        description: 'Perfect for IT fresh graduates',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.orange,
        previewImage: 'assets/templates/it_fresher.png',
        features: ['IT Focus', 'Fresher Design', 'Technical Skills'],
        rating: 4.5,
        downloads: 850,
      ),
      TemplateMetadata(
        id: 'minimalist_3',
        name: 'Minimal Template',
        description: 'Ultra-minimal design with clean layout',
        category: TemplateCategory.minimalist,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/minimal.png',
        features: ['Ultra Minimal', 'Clean Design', 'Simple Layout'],
        rating: 4.7,
        downloads: 1050,
      ),
      TemplateMetadata(
        id: 'modern_2',
        name: 'Modern Template',
        description: 'Modern design with sidebar layout',
        category: TemplateCategory.modern,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/modern.png',
        features: ['Modern Design', 'Sidebar Layout', 'Professional'],
        rating: 4.6,
        downloads: 950,
      ),
      TemplateMetadata(
        id: 'modern_3',
        name: 'Professional Template',
        description: 'Professional two-column layout',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/professional.png',
        features: ['Professional Style', 'Two Column', 'Clean Design'],
        rating: 4.5,
        downloads: 920,
      ),
      TemplateMetadata(
        id: 'simple_1',
        name: 'Simple Template',
        description: 'Simple and clean professional design',
        category: TemplateCategory.minimalist,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/simple.png',
        features: ['Simple Design', 'Clean Layout', 'Professional'],
        rating: 4.4,
        downloads: 850,
      ),
      TemplateMetadata(
        id: 'technical_fresher_1',
        name: 'Technical Fresher',
        description: 'Technical template for fresh graduates',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/technical_fresher.png',
        features: ['Technical Focus', 'Fresher Design', 'Skills Grid'],
        rating: 4.6,
        downloads: 900,
      ),
      TemplateMetadata(
        id: 'technical_2',
        name: 'Technical Template',
        description: 'Technical-focused design with monospace font',
        category: TemplateCategory.professional,
        colorScheme: TemplateColorScheme.blue,
        previewImage: 'assets/templates/technical.png',
        features: ['Technical Style', 'Monospace Font', 'Skills Tags'],
        rating: 4.7,
        downloads: 1000,
      ),
      TemplateMetadata(
        id: 'traditional_1',
        name: 'Traditional Template',
        description: 'Traditional academic design with serif typography',
        category: TemplateCategory.classic,
        colorScheme: TemplateColorScheme.gray,
        previewImage: 'assets/templates/traditional.png',
        features: ['Traditional Style', 'Serif Typography', 'Academic Design'],
        rating: 4.3,
        downloads: 750,
      ),
    ];
  }

  // Helper methods for template categories
  String getCategoryDisplayName(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.professional:
        return 'Professional';
      case TemplateCategory.creative:
        return 'Creative';
      case TemplateCategory.modern:
        return 'Modern';
      case TemplateCategory.classic:
        return 'Classic';
      case TemplateCategory.minimalist:
        return 'Minimalist';
      case TemplateCategory.executive:
        return 'Executive';
    }
  }

  Color getCategoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.professional:
        return const Color(0xFF3B82F6); // Blue
      case TemplateCategory.creative:
        return const Color(0xFFF59E0B); // Orange
      case TemplateCategory.modern:
        return const Color(0xFF10B981); // Green
      case TemplateCategory.classic:
        return const Color(0xFF6B7280); // Gray
      case TemplateCategory.minimalist:
        return const Color(0xFF1F2937); // Dark Gray
      case TemplateCategory.executive:
        return const Color(0xFF6B5FFF); // Purple
    }
  }

  IconData getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.professional:
        return Icons.business_center;
      case TemplateCategory.creative:
        return Icons.palette;
      case TemplateCategory.modern:
        return Icons.trending_up;
      case TemplateCategory.classic:
        return Icons.history_edu;
      case TemplateCategory.minimalist:
        return Icons.minimize;
      case TemplateCategory.executive:
        return Icons.work_outline;
    }
  }
}
