import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class CompanyQuizPage extends StatefulWidget {
  final String companyName;
  const CompanyQuizPage({super.key, required this.companyName});

  @override
  State<CompanyQuizPage> createState() => _CompanyQuizPageState();
}

class _CompanyQuizPageState extends State<CompanyQuizPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _questions = [];
  String? _error;
  bool _started = false;
  int _currentIndex = 0;
  int? _selectedIndex;
  late List<int?> _selections; // per-question selection
  int _score = 0;

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions().then((_) {
      if (mounted && _questions.isNotEmpty) {
        _startQuiz();
      }
    });
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final headers = AuthService().getAuthHeaders();
      final resp = await http.get(
        Uri.parse(ApiEndpoints.companyQuestions(widget.companyName)),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final list = (data['data'] ?? data['questions'] ?? []) as List<dynamic>;
        _questions = list.cast<Map<String, dynamic>>();
      } else {
        _error = 'Failed to load questions';
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        _error = 'No internet connection';
      } else {
        _error = e.toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startQuiz() async {
    try {
      final headers = AuthService().getAuthHeaders();
      await http.post(
        Uri.parse(ApiEndpoints.companyQuizStart),
        headers: headers,
        body: json.encode({'companyName': widget.companyName}),
      );
      if (mounted) {
        setState(() {
          _started = true;
          _currentIndex = 0;
          _selectedIndex = null;
          _selections = List<int?>.filled(_questions.length, null);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start quiz: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(widget.companyName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      floatingActionButton: null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B5FFF)))
          : _error != null
              ? _buildErrorState()
              : _questions.isEmpty
                  ? const Center(child: Text('No questions available'))
                  : (_started
                      ? _buildQuiz()
                      : const Center(child: CircularProgressIndicator(color: Color(0xFF6B5FFF)))),
    );
  }

  Widget _buildErrorState() {
    final isNoInternet = _error == 'No internet connection';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile ? 64 : isTablet ? 72 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 20 : isTablet ? 24 : 28),
            Text(
              isNoInternet ? 'No internet connection' : 'Something went wrong',
              style: TextStyle(
                fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (isNoInternet) ...[
              SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
              Text(
                'Please check your connection and try again',
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _loadQuestions().then((_) {
                  if (mounted && _questions.isNotEmpty) {
                    _startQuiz();
                  }
                });
              },
              icon: Icon(Icons.refresh, size: isMobile ? 18 : isTablet ? 20 : 22, color: Colors.white),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5FFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : isTablet ? 24 : 28,
                  vertical: isMobile ? 12 : isTablet ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    final questionText = _extractQuestionText(q);
    final options = _extractOptions(q);
    final difficulty = (q['difficulty'] ?? '').toString();
    final category = (q['category'] ?? '').toString();
    final points = q['points'] ?? q['score'] ?? q['marks'];
    final answeredCount = _selections.where((e) => e != null).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Text('Question ${_currentIndex + 1} of ${_questions.length}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            color: const Color(0xFF6B5FFF),
            backgroundColor: const Color(0xFFEAEAEA),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text('$answeredCount answered', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (category.isNotEmpty) _chip('Category', category),
              if (difficulty.isNotEmpty) _chip('Level', difficulty),
              if (points != null) _chip('Points', points.toString()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(options.length, (i) {
            final text = options[i];
            return _OptionTile(
              index: i,
              label: String.fromCharCode(65 + i),
              text: text,
              selected: _selectedIndex == i,
              onTap: () => setState(() => _selectedIndex = i),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _currentIndex == 0 ? null : _handlePrev,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6B5FFF)),
                    foregroundColor: const Color(0xFF6B5FFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedIndex == null && _selections[_currentIndex] == null ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5FFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(_currentIndex == _questions.length - 1 ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _handleNext() {
    // Persist current selection into the selections list
    if (_selectedIndex != null) {
      _selections[_currentIndex] = _selectedIndex;
    }
    // Recompute score from selections (so prev/next edits are reflected)
    int newScore = 0;
    for (int i = 0; i < _questions.length; i++) {
      final ops = _extractOptions(_questions[i]);
      final correct = _extractCorrectAnswer(_questions[i], ops);
      final sel = _selections[i];
      if (sel != null && sel >= 0 && sel < ops.length && ops[sel] == correct) {
        newScore += 1;
      }
    }
    _score = newScore;
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedIndex = _selections[_currentIndex];
      });
    } else {
      _showResult();
    }
  }

  void _handlePrev() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex -= 1;
      _selectedIndex = _selections[_currentIndex];
    });
  }

  String _extractCorrectAnswer(Map<String, dynamic> q, List<String> options) {
    final direct = (q['correctAnswer'] ?? q['answer'] ?? q['correct'] ?? '').toString();
    if (direct.isNotEmpty) return direct;
    final idx = q['correctOption'] ?? q['answerIndex'];
    if (idx is int && idx >= 0 && idx < options.length) return options[idx];
    return options.isNotEmpty ? options.first : '';
  }

  List<String> _extractOptions(Map<String, dynamic> q) {
    final raw = q['options'] ?? q['choices'] ?? q['answers'];
    if (raw is List) {
      // Allow list of strings OR list of maps with text field
      final texts = raw.map((e) {
        if (e is Map) {
          final t = (e['text'] ?? e['label'] ?? e['option'] ?? e['value'] ?? '').toString();
          return t;
        }
        return e.toString();
      }).where((s) => s.toString().trim().isNotEmpty).map((s) => s.toString()).toList();
      return texts.take(4).toList();
    }
    final candidates = [
      q['option1'], q['option2'], q['option3'], q['option4'],
      q['a'], q['b'], q['c'], q['d'],
    ];
    return candidates
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString())
        .take(4)
        .toList();
  }

  String _extractQuestionText(Map<String, dynamic> q) {
    final keys = ['questionText', 'question', 'text', 'title', 'prompt'];
    for (final k in keys) {
      final v = q[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return 'Question';
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final total = _questions.length;
        final percent = total > 0 ? ((_score / total) * 100).round() : 0;
        final isGood = percent >= 60;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B5FFF), Color(0xFF8B7FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quiz Result',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      // Score circle
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isGood ? const Color(0xFF27AE60) : const Color(0xFFE74C3C)).withOpacity(0.1),
                          border: Border.all(color: isGood ? const Color(0xFF27AE60) : const Color(0xFFE74C3C), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_score',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isGood ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                              ),
                            ),
                            Text(
                              '/$total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isGood ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$percent%',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isGood ? 'Great work! Keep it up.' : 'Good try! Review and attempt again.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chip('Correct', _score.toString()),
                          const SizedBox(width: 8),
                          _chip('Total', total.toString()),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // close dialog
                            Navigator.of(context).pop(); // go back to company list page
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6B5FFF)),
                            foregroundColor: const Color(0xFF6B5FFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _started = false;
                              _currentIndex = 0;
                              _selectedIndex = null;
                              _selections = List<int?>.filled(_questions.length, null);
                              _score = 0;
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5FFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5FFF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF6B5FFF).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0xFF6B5FFF), fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({required this.index, required this.label, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF6B5FFF) : const Color(0xFFE4E4E4);
    final fill = selected ? const Color(0xFF6B5FFF).withOpacity(0.06) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF6B5FFF) : const Color(0xFF6B5FFF).withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6B5FFF),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

