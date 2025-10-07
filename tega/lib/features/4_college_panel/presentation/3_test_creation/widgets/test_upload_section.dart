import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'form_section_card.dart';

class TestUploadSection extends StatelessWidget {
  final String? fileName;
  final bool isFileUploading;
  // Enhancement: Add an error message parameter to handle different failure states
  final String? errorMessage;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onDownloadTemplate;

  const TestUploadSection({
    super.key,
    this.fileName,
    this.errorMessage, // Add to constructor
    required this.isFileUploading,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onDownloadTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      title: 'Question Paper',
      icon: Icons.upload_file_rounded,
      iconColor: const Color(0xFF43A047),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildCurrentState(context),
        ),
      ),
    );
  }

  // Logic is now updated to prioritize showing the error state
  Widget _buildCurrentState(BuildContext context) {
    if (errorMessage != null && !isFileUploading) {
      return _buildErrorState(errorMessage!, key: const ValueKey('error'));
    } else if (isFileUploading) {
      return _buildUploadingState(key: const ValueKey('uploading'));
    } else if (fileName != null) {
      return _buildFileUploadedState(key: const ValueKey('uploaded'));
    } else {
      return _buildFileUploadPrompt(context, key: const ValueKey('prompt'));
    }
  }

  // --- NEW: A dedicated UI for displaying errors ---
  Widget _buildErrorState(String message, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.red[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 36),
          const SizedBox(height: 12),
          Text(
            'Upload Failed',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[800], fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadedState({Key? key}) {
    // This widget remains the same as the previous refinement
    return Container(
      key: key,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF66BB6A), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.grid_on_rounded, color: Colors.green[800], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'Unknown File',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green[800],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'File ready for upload',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemoveFile,
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[700]),
              tooltip: 'Remove file',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState({Key? key}) {
    // This widget remains the same
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF43A047),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Uploading...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadPrompt(BuildContext context, {Key? key}) {
    // Reverted: Dotted border removed and replaced with a solid border container
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPickFile,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Click to upload Excel file',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: 'Don\'t have the format? '),
                        TextSpan(
                          text: 'Download Template',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = onDownloadTemplate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
