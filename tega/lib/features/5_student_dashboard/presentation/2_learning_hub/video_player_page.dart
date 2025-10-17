import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

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
  double _currentBrightness = 1.0;
  double _seekPosition = 0;

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
    _initializeVideo();
    _setupAnimations();
    _startHideControlsTimer();
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

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _initializeVideoPlayerFuture = _controller
        .initialize()
        .then((_) {
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
    _startHideControlsTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _controlsAnimationController.forward();
      _startHideControlsTimer();
    } else {
      _controlsAnimationController.reverse();
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
          _controlsAnimationController.reverse();
        }
      });
    }
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

  void _skipForward() {
    final currentPosition = _controller.value.position;
    final duration = _controller.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (newPosition < duration) {
      _controller.seekTo(newPosition);
      _showGestureFeedbackFunction('+10s', Icons.forward_10, Colors.white);
    }
  }

  void _skipBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      _controller.seekTo(newPosition);
      _showGestureFeedbackFunction('-10s', Icons.replay_10, Colors.white);
    }
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

  void _handleSeekControl(double deltaX, double screenWidth) {
    final duration = _controller.value.duration.inMilliseconds.toDouble();
    final seekChange = deltaX / (screenWidth * 0.5) * duration;
    final newPosition = (_seekPosition + seekChange).clamp(0.0, duration);

    _controller.seekTo(Duration(milliseconds: newPosition.round()));

    final seekDirection = deltaX > 0 ? 'Forward' : 'Backward';
    _showGestureFeedbackFunction(
      seekDirection,
      deltaX > 0 ? Icons.fast_forward : Icons.fast_rewind,
      Colors.blue,
    );
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

                // Buffering indicator
                if (_isBuffering)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6B5FFF),
                        ),
                      ),
                    ),
                  ),

                // Gesture feedback overlay
                if (_showGestureFeedback)
                  Positioned.fill(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _gestureAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _gestureAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _gestureIcon,
                                    color: _gestureColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _gestureFeedback,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
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
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Top Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courseTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${widget.instructorName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Playback speed button
                  IconButton(
                    icon: Text(
                      '${_controller.value.playbackSpeed}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _changePlaybackSpeed,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center Play/Pause Button
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Progress Bar
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF6B5FFF),
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time and Controls
                  Row(
                    children: [
                      Text(
                        _formatDuration(_controller.value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Skip buttons
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: _skipBackward,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: _skipForward,
                        iconSize: 20,
                      ),
                      Text(
                        _formatDuration(_controller.value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
