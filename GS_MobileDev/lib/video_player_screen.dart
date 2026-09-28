import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _lastPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load last position from shared preferences
      await _loadLastPosition();

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.url),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
        // Disable advanced features as requested
        showOptions: false,
        optionsTranslation: OptionsTranslation(
          playbackSpeedButtonText: '',
          subtitlesButtonText: '',
          cancelButtonText: 'Cancel',
        ),
        additionalOptions: (context) {
          return <OptionItem>[];
        },
      );

      // Resume from last position if available
      if (_lastPosition > 0) {
        _videoPlayerController!.seekTo(Duration(seconds: _lastPosition));
      }

      // Listen for position changes to save progress
      _videoPlayerController!.addListener(_onVideoPlayerUpdate);

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _onVideoPlayerUpdate() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      final position = _videoPlayerController!.value.position.inSeconds;
      if (position != _lastPosition && position % 5 == 0) {
        _saveLastPosition(position);
        _lastPosition = position;
      }
    }
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_position_${widget.video.url.hashCode}';
    _lastPosition = prefs.getInt(key) ?? 0;
  }

  Future<void> _saveLastPosition(int position) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_position_${widget.video.url.hashCode}';
    await prefs.setInt(key, position);
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryVideo() {
    _disposeControllers();
    _initializePlayer();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Retrying video...'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'Cancel',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _disposeControllers() {
    _videoPlayerController?.removeListener(_onVideoPlayerUpdate);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(widget.video.title, style: const TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF0F1115),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Video player area
          Container(
            width: double.infinity,
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1115), Color(0xFF12151B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _buildVideoPlayer(),
          ),
          // Video information
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.video.duration,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.signal_cellular_4_bar,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Adaptive streaming',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Video progress is automatically saved. The player will resume from where you left off.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Course-related description beneath the title
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About this lecture',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A concise, practical explanation aligned with the course topic. This lecture introduces the key ideas and demonstrates core techniques with examples.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
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
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorWidget(_errorMessage);
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Optimizing for your connection',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Video player not initialized',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}