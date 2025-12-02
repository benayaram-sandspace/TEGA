import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:tega/core/services/video_cache_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String courseTitle;
  final String instructorName;
  final List<dynamic> modules;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.courseTitle,
    required this.instructorName,
    this.modules = const [],
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isBuffering = false;

  // Gesture control variables
  bool _isDragging = false;
  double _dragStartX = 0;
  double _dragStartY = 0;
  double _currentVolume = 1.0;
  bool _isMuted = false;
  double _savedVolume = 1.0;
  double _currentBrightness = 1.0;
  double _seekPosition = 0;

  // Progress bar dragging
  bool _isDraggingProgress = false;
  double? _dragProgressPosition;
  bool _isHoveringProgress = false;
  bool _isSeeking = false;

  // Volume control
  bool _showVolumeSlider = false;

  // Settings menu
  bool _showSettingsMenu = false;

  // Video cache service
  final VideoCacheService _videoCacheService = VideoCacheService();

  // Animation controllers
  late AnimationController _controlsAnimationController;
  late AnimationController _gestureAnimationController;
  late Animation<double> _controlsAnimation;
  late Animation<double> _gestureAnimation;

  // Timer for auto-hiding controls
  Timer? _hideControlsTimer;

  // Gesture feedback
  String _gestureFeedback = '';
  bool _showGestureFeedback = false;
  IconData _gestureIcon = Icons.play_arrow;
  Color _gestureColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeVideoCache();
    _initializeVideo();
    _setupAnimations();
    _startHideControlsTimer();
  }

  Future<void> _initializeVideoCache() async {
    await _videoCacheService.initialize();
  }

  void _setupAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _gestureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _gestureAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gestureAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _initializeVideo() async {
    // Check cache first - if cached, use local file, otherwise use network URL
    String? cachedVideoPath = await _videoCacheService.getCachedVideoPath(
      widget.videoUrl,
    );

    if (cachedVideoPath != null && await File(cachedVideoPath).exists()) {
      // Use cached video file
      _controller = VideoPlayerController.file(
        File(cachedVideoPath),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    } else {
      // Use network URL and cache it in background
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Start caching video in background (don't await)
      _videoCacheService.cacheVideo(widget.videoUrl).catchError((_) {
        // Silently handle cache errors - video will still play from network
      });
    }

    _initializeVideoPlayerFuture = _controller
        .initialize()
        .then((_) {
          // Set video quality and buffering options for smooth playback
          _controller.setLooping(false);
          _controller.setVolume(1.0);
          setState(() {});
        })
        .catchError((error) {
          // Handle error silently
        });

    _controller.addListener(() {
      if (_controller.value.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }

      if (_controller.value.isBuffering != _isBuffering) {
        setState(() {
          _isBuffering = _controller.value.isBuffering;
        });
      }

      // Handle errors, but ignore transient seek errors
      if (_controller.value.hasError && !_isSeeking && !_isDraggingProgress) {
        final errorDescription = _controller.value.errorDescription ?? '';
        // Only show error if it's not a seek-related transient error
        if (!errorDescription.toLowerCase().contains('seek') &&
            !errorDescription.toLowerCase().contains('position')) {
          // Video error occurred - but don't show it as "failed to load course"
          // Just log it silently or show a non-fatal error
        }
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controlsAnimationController.dispose();
    _gestureAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
    _showControlsAndResetTimer();
  }

  void _toggleControls() {
    _showControlsAndResetTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
          _controlsAnimationController.reverse();
        }
      });
    }
  }

  void _showControlsAndResetTimer() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      _controlsAnimationController.forward();
    }
    _startHideControlsTimer();
  }

  void _showGestureFeedbackFunction(String text, IconData icon, Color color) {
    setState(() {
      _gestureFeedback = text;
      _gestureIcon = icon;
      _gestureColor = color;
      _showGestureFeedback = true;
    });

    _gestureAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _gestureAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showGestureFeedback = false;
              });
            }
          });
        }
      });
    });
  }

  Future<void> _safeSeekTo(Duration position) async {
    if (!_controller.value.isInitialized) {
      return;
    }

    final duration = _controller.value.duration;
    if (duration == Duration.zero || duration.inMilliseconds <= 0) {
      return;
    }

    try {
      // Ensure position is within valid range
      final clampedPosition = position < Duration.zero
          ? Duration.zero
          : (position > duration ? duration : position);

      // Don't seek if position is the same (within 1 second)
      final currentPos = _controller.value.position;
      if ((clampedPosition - currentPos).abs().inSeconds < 1) {
        return;
      }

      setState(() {
        _isSeeking = true;
      });

      await _controller.seekTo(clampedPosition);

      // Wait a bit for seek to complete
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isSeeking = false;
        });
      }
    } catch (e) {
      // Seek errors are not fatal - just continue
      // These are usually transient network issues or buffering problems
      if (mounted) {
        setState(() {
          _isSeeking = false;
        });
      }
    }
  }

  void _skipForward() async {
    final currentPosition = _controller.value.position;
    final duration = _controller.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (newPosition < duration) {
      await _safeSeekTo(newPosition);
      _showGestureFeedbackFunction('+10s', Icons.forward_10, Colors.white);
    }
    _showControlsAndResetTimer();
  }

  void _skipBackward() async {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      await _safeSeekTo(newPosition);
      _showGestureFeedbackFunction('-10s', Icons.replay_10, Colors.white);
    }
    _showControlsAndResetTimer();
  }

  void _handleDoubleTapLeft() {
    _skipBackward();
  }

  void _handleDoubleTapRight() {
    _skipForward();
  }

  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
    _seekPosition = _controller.value.position.inMilliseconds.toDouble();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final deltaX = details.globalPosition.dx - _dragStartX;
    final deltaY = details.globalPosition.dy - _dragStartY;

    // Determine gesture type based on initial position and movement
    if (details.globalPosition.dx < screenWidth * 0.3) {
      // Left side - Volume control
      _handleVolumeControl(deltaY, screenHeight);
    } else if (details.globalPosition.dx > screenWidth * 0.7) {
      // Right side - Brightness control
      _handleBrightnessControl(deltaY, screenHeight);
    } else {
      // Center - Seek control
      _handleSeekControl(deltaX, screenWidth);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDragging = false;
    _showGestureFeedback = false;
    _gestureAnimationController.reset();
  }

  void _handleVolumeControl(double deltaY, double screenHeight) {
    final volumeChange = -deltaY / (screenHeight * 0.5);
    final newVolume = (_currentVolume + volumeChange).clamp(0.0, 1.0);

    setState(() {
      _currentVolume = newVolume;
    });

    // Update system volume (this would require platform-specific implementation)
    _showGestureFeedbackFunction(
      '${(_currentVolume * 100).round()}%',
      _currentVolume > 0.5 ? Icons.volume_up : Icons.volume_down,
      Colors.white,
    );
  }

  void _handleBrightnessControl(double deltaY, double screenHeight) {
    final brightnessChange = -deltaY / (screenHeight * 0.5);
    final newBrightness = (_currentBrightness + brightnessChange).clamp(
      0.1,
      1.0,
    );

    setState(() {
      _currentBrightness = newBrightness;
    });

    // Update system brightness (this would require platform-specific implementation)
    _showGestureFeedbackFunction(
      '${(_currentBrightness * 100).round()}%',
      _currentBrightness > 0.5 ? Icons.brightness_7 : Icons.brightness_4,
      Colors.orange,
    );
  }

  void _handleSeekControl(double deltaX, double screenWidth) async {
    final duration = _controller.value.duration.inMilliseconds.toDouble();
    final seekChange = deltaX / (screenWidth * 0.5) * duration;
    final newPosition = (_seekPosition + seekChange).clamp(0.0, duration);

    await _safeSeekTo(Duration(milliseconds: newPosition.round()));

    final seekDirection = deltaX > 0 ? 'Forward' : 'Backward';
    _showGestureFeedbackFunction(
      seekDirection,
      deltaX > 0 ? Icons.fast_forward : Icons.fast_rewind,
      Colors.blue,
    );
  }

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        _isMuted = false;
        _currentVolume = _savedVolume;
      } else {
        _isMuted = true;
        _savedVolume = _currentVolume;
        _currentVolume = 0.0;
      }
    });
    _controller.setVolume(_currentVolume);
    _showControlsAndResetTimer();
  }

  void _changeVolume(double volume) {
    setState(() {
      _currentVolume = volume.clamp(0.0, 1.0);
      if (_currentVolume > 0) {
        _isMuted = false;
        _savedVolume = _currentVolume;
      }
    });
    _controller.setVolume(_currentVolume);
    _showControlsAndResetTimer();
  }

  void _changePlaybackSpeed() {
    final currentSpeed = _controller.value.playbackSpeed;
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(currentSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;

    _controller.setPlaybackSpeed(speeds[nextIndex]);
    _showGestureFeedbackFunction(
      '${speeds[nextIndex]}x',
      Icons.speed,
      Colors.green,
    );
    _showControlsAndResetTimer();
  }

  void _toggleSettingsMenu() {
    setState(() {
      _showSettingsMenu = !_showSettingsMenu;
    });
    _showControlsAndResetTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  Widget _buildDraggableProgressBar() {
    final duration = _controller.value.duration;
    final position = _isDraggingProgress && _dragProgressPosition != null
        ? Duration(milliseconds: _dragProgressPosition!.round())
        : _controller.value.position;
    final buffered = _controller.value.buffered;

    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHoveringProgress = true;
            });
          },
          onExit: (_) {
            if (!_isDraggingProgress) {
              setState(() {
                _isHoveringProgress = false;
              });
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              setState(() {
                _isDraggingProgress = true;
                _isHoveringProgress = true;
                _showControls = true;
              });
              _hideControlsTimer?.cancel();
            },
            onHorizontalDragUpdate: (details) {
              final localPosition = details.localPosition.dx;
              final newProgress = (localPosition / constraints.maxWidth).clamp(
                0.0,
                1.0,
              );

              setState(() {
                _dragProgressPosition = duration.inMilliseconds * newProgress;
              });
            },
            onHorizontalDragEnd: (details) async {
              if (_dragProgressPosition != null &&
                  duration.inMilliseconds > 0) {
                final seekPosition = Duration(
                  milliseconds: _dragProgressPosition!.round().clamp(
                    0,
                    duration.inMilliseconds,
                  ),
                );
                await _safeSeekTo(seekPosition);
              }
              setState(() {
                _isDraggingProgress = false;
                _dragProgressPosition = null;
              });
              _showControlsAndResetTimer();
            },
            onTapDown: (details) async {
              final localPosition = details.localPosition.dx;
              final newProgress = (localPosition / constraints.maxWidth).clamp(
                0.0,
                1.0,
              );
              final newPosition = Duration(
                milliseconds: (duration.inMilliseconds * newProgress)
                    .round()
                    .clamp(0, duration.inMilliseconds),
              );
              await _safeSeekTo(newPosition);
              _showControlsAndResetTimer();
            },
            child: Container(
              height: _isHoveringProgress || _isDraggingProgress ? 8 : 4,
              padding: EdgeInsets.symmetric(
                vertical: _isHoveringProgress || _isDraggingProgress ? 2 : 0,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background track - YouTube style (very thin)
                  Container(
                    height: _isHoveringProgress || _isDraggingProgress ? 4 : 3,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  // Buffered progress - YouTube style
                  if (buffered.isNotEmpty && duration.inMilliseconds > 0)
                    ...buffered.map((range) {
                      final bufferedStart =
                          range.start.inMilliseconds / duration.inMilliseconds;
                      final bufferedEnd =
                          range.end.inMilliseconds / duration.inMilliseconds;
                      return Positioned(
                        left: constraints.maxWidth * bufferedStart,
                        child: Container(
                          height: _isHoveringProgress || _isDraggingProgress
                              ? 4
                              : 3,
                          width:
                              constraints.maxWidth *
                              (bufferedEnd - bufferedStart),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      );
                    }),
                  // Played progress - YouTube red
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    height: _isHoveringProgress || _isDraggingProgress ? 4 : 3,
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626), // YouTube red
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  // Thumb - YouTube style (hidden by default, shows on hover/drag)
                  if (_isHoveringProgress ||
                      _isDraggingProgress ||
                      _showControls)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 50),
                      curve: Curves.easeOut,
                      left:
                          (constraints.maxWidth * progress.clamp(0.0, 1.0)) -
                          (_isDraggingProgress ? 10 : 8),
                      child: AnimatedScale(
                        scale: _isDraggingProgress ? 1.4 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        child: Container(
                          width: _isDraggingProgress ? 20 : 16,
                          height: _isDraggingProgress ? 20 : 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: _isDraggingProgress ? 8 : 6,
                              height: _isDraggingProgress ? 8 : 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626), // YouTube red center
                                shape: BoxShape.circle,
                              ),
                            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(
                widget.courseTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isFullscreen = !_isFullscreen;
                    });
                    if (_isFullscreen) {
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersive,
                      );
                    } else {
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                    }
                  },
                ),
              ],
            ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Video Player
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),

                // Gesture areas for double tap
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleControls,
                          onDoubleTap: _handleDoubleTapLeft,
                          onPanStart: _handlePanStart,
                          onPanUpdate: _handlePanUpdate,
                          onPanEnd: _handlePanEnd,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleControls,
                          onDoubleTap: _handleDoubleTapRight,
                          onPanStart: _handlePanStart,
                          onPanUpdate: _handlePanUpdate,
                          onPanEnd: _handlePanEnd,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),

                // Buffering indicator with modern design
                if (_isBuffering)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6B5FFF),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Buffering...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Gesture feedback overlay with modern design
                if (_showGestureFeedback)
                  Positioned.fill(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _gestureAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _gestureAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.85),
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _gestureColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _gestureColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _gestureColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _gestureIcon,
                                      color: _gestureColor,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _gestureFeedback,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Controls Overlay
                AnimatedBuilder(
                  animation: _controlsAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _showControls ? _controlsAnimation.value : 0.0,
                      child: _showControls
                          ? _buildControlsOverlay()
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            );
          } else {
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6B5FFF),
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading video...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Bottom Controls - YouTube Style
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildDraggableProgressBar(),
                    ),
                    // Controls Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Play/Pause Button
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _togglePlayPause,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Volume Control
                          GestureDetector(
                            onTap: _toggleMute,
                            onLongPress: () {
                              setState(() {
                                _showVolumeSlider = !_showVolumeSlider;
                              });
                            },
                            child: Icon(
                              _isMuted || _currentVolume == 0
                                  ? Icons.volume_off
                                  : _currentVolume < 0.5
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Volume Slider (shows on long press)
                          if (_showVolumeSlider)
                            SizedBox(
                              width: 100,
                              child: Slider(
                                value: _currentVolume,
                                onChanged: _changeVolume,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                min: 0.0,
                                max: 1.0,
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Time Display
                          Text(
                            '${_formatDuration(_isDraggingProgress && _dragProgressPosition != null ? Duration(milliseconds: _dragProgressPosition!.round()) : _controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Spacer(),
                          // Playback Speed Button
                          TextButton(
                            onPressed: _changePlaybackSpeed,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '${_controller.value.playbackSpeed}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Settings Button
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _toggleSettingsMenu,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Fullscreen Button
                          IconButton(
                            icon: Icon(
                              _isFullscreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFullscreen = !_isFullscreen;
                              });
                              if (_isFullscreen) {
                                SystemChrome.setEnabledSystemUIMode(
                                  SystemUiMode.immersive,
                                );
                              } else {
                                SystemChrome.setEnabledSystemUIMode(
                                  SystemUiMode.edgeToEdge,
                                );
                              }
                              _showControlsAndResetTimer();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
