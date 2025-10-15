import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/resume_template.dart';

enum ExportFormat { pdf, png, jpg, docx }

class ExportService {
  static Future<String?> exportResume({
    required ResumeData resumeData,
    required TemplateMetadata template,
    required GlobalKey previewKey,
    required ExportFormat format,
    String? fileName,
    double? quality,
  }) async {
    try {
      switch (format) {
        case ExportFormat.pdf:
          return await _exportAsPDF(
            resumeData: resumeData,
            template: template,
            previewKey: previewKey,
            fileName: fileName,
          );
        case ExportFormat.png:
          return await _exportAsImage(
            previewKey: previewKey,
            fileName: fileName,
            format: 'png',
            quality: quality ?? 1.0,
          );
        case ExportFormat.jpg:
          return await _exportAsImage(
            previewKey: previewKey,
            fileName: fileName,
            format: 'jpg',
            quality: quality ?? 0.9,
          );
        case ExportFormat.docx:
          return await _exportAsDocx(
            resumeData: resumeData,
            template: template,
            fileName: fileName,
          );
      }
    } catch (e) {
      debugPrint('Error exporting resume: $e');
      return null;
    }
  }

  static Future<String?> _exportAsPDF({
    required ResumeData resumeData,
    required TemplateMetadata template,
    required GlobalKey previewKey,
    String? fileName,
  }) async {
    try {
      // Capture the widget as an image
      final image = await _captureWidget(previewKey);
      if (image == null) return null;

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final finalFileName =
          fileName ?? 'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$finalFileName';

      // Create PDF file (simplified - in real implementation, use pdf package)
      final file = File(filePath);
      await file.writeAsBytes(image);

      return filePath;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }

  static Future<String?> _exportAsImage({
    required GlobalKey previewKey,
    String? fileName,
    required String format,
    required double quality,
  }) async {
    try {
      final image = await _captureWidget(previewKey);
      if (image == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final finalFileName =
          fileName ?? 'resume_${DateTime.now().millisecondsSinceEpoch}.$format';
      final filePath = '${directory.path}/$finalFileName';

      final file = File(filePath);
      await file.writeAsBytes(image);

      return filePath;
    } catch (e) {
      debugPrint('Error generating image: $e');
      return null;
    }
  }

  static Future<String?> _exportAsDocx({
    required ResumeData resumeData,
    required TemplateMetadata template,
    String? fileName,
  }) async {
    try {
      // Generate DOCX content (simplified - in real implementation, use docx package)
      final content = _generateDocxContent(resumeData, template);

      final directory = await getApplicationDocumentsDirectory();
      final finalFileName =
          fileName ?? 'resume_${DateTime.now().millisecondsSinceEpoch}.docx';
      final filePath = '${directory.path}/$finalFileName';

      final file = File(filePath);
      await file.writeAsString(content);

      return filePath;
    } catch (e) {
      debugPrint('Error generating DOCX: $e');
      return null;
    }
  }

  static Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  static String _generateDocxContent(
    ResumeData resumeData,
    TemplateMetadata template,
  ) {
    // Simplified DOCX content generation
    // In a real implementation, you would use a proper DOCX library
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln(
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">',
    );
    buffer.writeln('<w:body>');

    // Header
    if (resumeData.fullName.isNotEmpty) {
      buffer.writeln(
        '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>${resumeData.fullName}</w:t></w:r></w:p>',
      );
    }

    // Contact info
    if (resumeData.email.isNotEmpty || resumeData.phone.isNotEmpty) {
      buffer.writeln('<w:p>');
      if (resumeData.email.isNotEmpty) {
        buffer.writeln('<w:r><w:t>${resumeData.email}</w:t></w:r>');
      }
      if (resumeData.phone.isNotEmpty) {
        buffer.writeln('<w:r><w:t> | ${resumeData.phone}</w:t></w:r>');
      }
      buffer.writeln('</w:p>');
    }

    // Summary
    if (resumeData.summary.isNotEmpty) {
      buffer.writeln(
        '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Professional Summary</w:t></w:r></w:p>',
      );
      buffer.writeln('<w:p><w:r><w:t>${resumeData.summary}</w:t></w:r></w:p>');
    }

    // Experience
    if (resumeData.experiences.isNotEmpty) {
      buffer.writeln(
        '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Work Experience</w:t></w:r></w:p>',
      );
      for (final exp in resumeData.experiences) {
        buffer.writeln(
          '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>${exp.position}</w:t></w:r></w:p>',
        );
        buffer.writeln(
          '<w:p><w:r><w:t>${exp.company} | ${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}</w:t></w:r></w:p>',
        );
        if (exp.description.isNotEmpty) {
          buffer.writeln('<w:p><w:r><w:t>${exp.description}</w:t></w:r></w:p>');
        }
      }
    }

    // Education
    if (resumeData.educations.isNotEmpty) {
      buffer.writeln(
        '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Education</w:t></w:r></w:p>',
      );
      for (final edu in resumeData.educations) {
        buffer.writeln(
          '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>${edu.degree}</w:t></w:r></w:p>',
        );
        buffer.writeln('<w:p><w:r><w:t>${edu.institution}</w:t></w:r></w:p>');
      }
    }

    // Skills
    if (resumeData.skills.isNotEmpty) {
      buffer.writeln(
        '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Skills</w:t></w:r></w:p>',
      );
      buffer.writeln(
        '<w:p><w:r><w:t>${resumeData.skills.join(', ')}</w:t></w:r></w:p>',
      );
    }

    buffer.writeln('</w:body>');
    buffer.writeln('</w:document>');

    return buffer.toString();
  }

  static Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'My Resume');
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  static Future<bool> saveToDownloads(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final fileName = filePath.split('/').last;
          final newPath = '${downloadsDir.path}/$fileName';
          final file = File(filePath);
          await file.copy(newPath);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error saving to downloads: $e');
      return false;
    }
  }
}

class ExportFormatInfo {
  final ExportFormat format;
  final String name;
  final String description;
  final IconData icon;
  final String extension;

  const ExportFormatInfo({
    required this.format,
    required this.name,
    required this.description,
    required this.icon,
    required this.extension,
  });

  static const List<ExportFormatInfo> formats = [
    ExportFormatInfo(
      format: ExportFormat.pdf,
      name: 'PDF',
      description: 'Portable Document Format',
      icon: Icons.picture_as_pdf,
      extension: 'pdf',
    ),
    ExportFormatInfo(
      format: ExportFormat.png,
      name: 'PNG',
      description: 'High quality image',
      icon: Icons.image,
      extension: 'png',
    ),
    ExportFormatInfo(
      format: ExportFormat.jpg,
      name: 'JPG',
      description: 'Compressed image',
      icon: Icons.image,
      extension: 'jpg',
    ),
    ExportFormatInfo(
      format: ExportFormat.docx,
      name: 'DOCX',
      description: 'Microsoft Word document',
      icon: Icons.description,
      extension: 'docx',
    ),
  ];
}

class ExportDialog extends StatefulWidget {
  final ResumeData resumeData;
  final TemplateMetadata template;
  final GlobalKey previewKey;

  const ExportDialog({
    super.key,
    required this.resumeData,
    required this.template,
    required this.previewKey,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExporting = false;
  String _fileName = '';
  ExportFormat _selectedFormat = ExportFormat.pdf;
  double _imageQuality = 0.9;

  @override
  void initState() {
    super.initState();
    _fileName = '${widget.resumeData.fullName.replaceAll(' ', '_')}_Resume';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Resume',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose format and export your resume',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // File name input
            const Text(
              'File Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _fileName),
              onChanged: (value) => _fileName = value,
              decoration: InputDecoration(
                hintText: 'Enter file name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B5FFF),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Format selection
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            ...ExportFormatInfo.formats.map(
              (formatInfo) => RadioListTile<ExportFormat>(
                value: formatInfo.format,
                groupValue: _selectedFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(
                      formatInfo.icon,
                      size: 20,
                      color: const Color(0xFF6B5FFF),
                    ),
                    const SizedBox(width: 12),
                    Text(formatInfo.name),
                  ],
                ),
                subtitle: Text(formatInfo.description),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6B5FFF),
              ),
            ),

            // Image quality slider for image formats
            if (_selectedFormat == ExportFormat.jpg ||
                _selectedFormat == ExportFormat.png) ...[
              const SizedBox(height: 16),
              const Text(
                'Image Quality',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _imageQuality,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: const Color(0xFF6B5FFF),
                      onChanged: (value) {
                        setState(() {
                          _imageQuality = value;
                        });
                      },
                    ),
                  ),
                  Text(
                    '${(_imageQuality * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isExporting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _exportResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Export',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportResume() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final formatInfo = ExportFormatInfo.formats.firstWhere(
        (info) => info.format == _selectedFormat,
      );

      final fileName = '$_fileName.${formatInfo.extension}';

      final filePath = await ExportService.exportResume(
        resumeData: widget.resumeData,
        template: widget.template,
        previewKey: widget.previewKey,
        format: _selectedFormat,
        fileName: fileName,
        quality: _imageQuality,
      );

      if (filePath != null) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog(filePath);
        }
      } else {
        if (mounted) {
          _showErrorDialog('Failed to export resume. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error exporting resume: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text('Export Successful'),
          ],
        ),
        content: const Text('Your resume has been exported successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ExportService.shareFile(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text('Export Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
