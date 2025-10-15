import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/resume_template.dart';
import '../templates/template_renderer.dart';

class PDFGenerator {
  static Future<String?> generatePDF({
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

      // Create PDF file
      final file = File(filePath);
      await file.writeAsBytes(image);

      return filePath;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
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

  static Future<void> sharePDF(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'My Resume');
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  static Future<bool> saveToDownloads(String filePath) async {
    try {
      // For Android, we can save to Downloads directory
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

class ResumePreviewWidget extends StatelessWidget {
  final ResumeData resumeData;
  final TemplateMetadata template;
  final GlobalKey previewKey;

  const ResumePreviewWidget({
    super.key,
    required this.resumeData,
    required this.template,
    required this.previewKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: previewKey,
      child: Container(
        width: 595, // A4 width in points
        height: 842, // A4 height in points
        color: Colors.white,
        child: TemplateRenderer(
          resumeData: resumeData,
          template: template,
          isPreview: false,
        ),
      ),
    );
  }
}

class PDFExportDialog extends StatefulWidget {
  final ResumeData resumeData;
  final TemplateMetadata template;
  final GlobalKey previewKey;

  const PDFExportDialog({
    super.key,
    required this.resumeData,
    required this.template,
    required this.previewKey,
  });

  @override
  State<PDFExportDialog> createState() => _PDFExportDialogState();
}

class _PDFExportDialogState extends State<PDFExportDialog> {
  bool _isGenerating = false;
  String _fileName = '';
  PDFQuality _selectedQuality = PDFQuality.high;

  @override
  void initState() {
    super.initState();
    _fileName = '${widget.resumeData.fullName.replaceAll(' ', '_')}_Resume.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
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
                    Icons.picture_as_pdf,
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
                        'Generate and download your resume as PDF',
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

            // Quality selection
            const Text(
              'PDF Quality',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            ...PDFQuality.values.map(
              (quality) => RadioListTile<PDFQuality>(
                value: quality,
                groupValue: _selectedQuality,
                onChanged: (value) {
                  setState(() {
                    _selectedQuality = value!;
                  });
                },
                title: Text(quality.displayName),
                subtitle: Text(quality.description),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6B5FFF),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isGenerating
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
                    onPressed: _isGenerating ? null : _generatePDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Generate PDF',
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

  Future<void> _generatePDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final filePath = await PDFGenerator.generatePDF(
        resumeData: widget.resumeData,
        template: widget.template,
        previewKey: widget.previewKey,
        fileName: _fileName.endsWith('.pdf') ? _fileName : '$_fileName.pdf',
      );

      if (filePath != null) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog(filePath);
        }
      } else {
        if (mounted) {
          _showErrorDialog('Failed to generate PDF. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error generating PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
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
            Text('PDF Generated Successfully'),
          ],
        ),
        content: const Text('Your resume has been generated and saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PDFGenerator.sharePDF(filePath);
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
            Text('Error'),
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

enum PDFQuality {
  standard,
  high,
  ultra;

  String get displayName {
    switch (this) {
      case PDFQuality.standard:
        return 'Standard';
      case PDFQuality.high:
        return 'High Quality';
      case PDFQuality.ultra:
        return 'Ultra High';
    }
  }

  String get description {
    switch (this) {
      case PDFQuality.standard:
        return 'Good quality, smaller file size';
      case PDFQuality.high:
        return 'High quality, balanced file size';
      case PDFQuality.ultra:
        return 'Best quality, larger file size';
    }
  }

  double get pixelRatio {
    switch (this) {
      case PDFQuality.standard:
        return 2.0;
      case PDFQuality.high:
        return 3.0;
      case PDFQuality.ultra:
        return 4.0;
    }
  }
}
