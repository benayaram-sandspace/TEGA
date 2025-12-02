import 'package:flutter/material.dart';
import 'form_section_card.dart';

class TestSettingsSection extends StatelessWidget {
  final bool isAutoGraded;
  final ValueChanged<bool> onAutoGradedChanged;
  final bool shuffleQuestions;
  final ValueChanged<bool> onShuffleChanged;
  final bool showResults;
  final ValueChanged<bool> onShowResultsChanged;
  final bool allowRetake;
  final ValueChanged<bool> onAllowRetakeChanged;
  final int retakeAttempts;
  final VoidCallback onIncrementAttempts;
  final VoidCallback onDecrementAttempts;
  final TextEditingController instructionsController;

  const TestSettingsSection({
    super.key,
    required this.isAutoGraded,
    required this.onAutoGradedChanged,
    required this.shuffleQuestions,
    required this.onShuffleChanged,
    required this.showResults,
    required this.onShowResultsChanged,
    required this.allowRetake,
    required this.onAllowRetakeChanged,
    required this.retakeAttempts,
    required this.onIncrementAttempts,
    required this.onDecrementAttempts,
    required this.instructionsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSectionCard(
          title: 'Test Settings',
          icon: Icons.tune_rounded,
          iconColor: const Color(0xFF7B1FA2),
          child: Column(
            children: [
              _buildSettingTile(
                title: 'Auto-graded Test',
                subtitle: 'Automatically calculate scores',
                icon: Icons.auto_awesome_rounded,
                value: isAutoGraded,
                onChanged: onAutoGradedChanged,
              ),
              const Divider(height: 24),
              _buildSettingTile(
                title: 'Shuffle Questions',
                subtitle: 'Randomize question order',
                icon: Icons.shuffle_rounded,
                value: shuffleQuestions,
                onChanged: onShuffleChanged,
              ),
              const Divider(height: 24),
              _buildSettingTile(
                title: 'Show Results Immediately',
                subtitle: 'Display scores after submission',
                icon: Icons.visibility_rounded,
                value: showResults,
                onChanged: onShowResultsChanged,
              ),
              const Divider(height: 24),
              _buildSettingTile(
                title: 'Allow Retake',
                subtitle: 'Students can attempt multiple times',
                icon: Icons.refresh_rounded,
                value: allowRetake,
                onChanged: onAllowRetakeChanged,
              ),
              if (allowRetake) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maximum Attempts',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: retakeAttempts > 1
                                ? onDecrementAttempts
                                : null,
                            color: Colors.blue[700],
                          ),
                          Text(
                            '$retakeAttempts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: onIncrementAttempts,
                            color: Colors.blue[700],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        FormSectionCard(
          title: 'Instructions',
          icon: Icons.rule_rounded,
          iconColor: const Color(0xFF00ACC1),
          child: TextFormField(
            controller: instructionsController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter any special instructions or rules...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final activeColor = const Color(0xFF2E7D32);
    return Row(
      children: [
        Icon(icon, size: 20, color: value ? activeColor : Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
        ),
      ],
    );
  }
}
