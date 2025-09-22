import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateTestAppBar extends StatefulWidget {
  const CreateTestAppBar({super.key});

  @override
  State<CreateTestAppBar> createState() => _CreateTestAppBarState();
}

class _CreateTestAppBarState extends State<CreateTestAppBar> {
  double _lastCollapseProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final top = constraints.biggest.height;
          final progress = (top - kToolbarHeight) / (120 - kToolbarHeight);
          final collapseProgress = (1 - progress).clamp(0.0, 1.0);

          if (_lastCollapseProgress != collapseProgress) {
            if (collapseProgress == 1.0 || collapseProgress == 0.0) {
              HapticFeedback.lightImpact();
            }
            _lastCollapseProgress = collapseProgress;
          }

          final double iconSize = 24 - (4 * collapseProgress);
          final double fontSize = 22 - (4 * collapseProgress);
          final double leftPadding = 36 + (20 * collapseProgress);

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_rounded, color: Colors.white, size: iconSize),
                const SizedBox(width: 8),
                Text(
                  'Create New Test',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Transform.translate(
                offset: Offset(0, top * 0.3),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 36,
                      bottom: 28,
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: Text(
                          'Add questions to get started',
                          style: GoogleFonts.lato(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
