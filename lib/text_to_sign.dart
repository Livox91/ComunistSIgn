import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TextToSignScreen extends StatefulWidget {
  @override
  _TextToSignScreenState createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen> {
  VideoPlayerController? _controller;
  String? _selectedPhrase;
  bool _isPlaying = false;
  bool _isLoading = false;
  String _errorMessage = '';
  
  final Map<String, Map<String, String>> phraseData = {
    'Hello': {
      'video': 'https://example.com/videos/hello.mp4',
      'thumbnail': 'https://example.com/thumbnails/hello.jpg',
      'description': 'Wave your hand in greeting',
    },
    'Thank you': {
      'video': 'https://example.com/videos/thank_you.mp4',
      'thumbnail': 'https://example.com/thumbnails/thank_you.jpg',
      'description': 'Touch your chin and extend hand forward',
    },
    'Please': {
      'video': 'https://example.com/videos/please.mp4',
      'thumbnail': 'https://example.com/thumbnails/please.jpg',
      'description': 'Rub your chest in circular motion',
    },
    'Sorry': {
      'video': 'https://example.com/videos/sorry.mp4',
      'thumbnail': 'https://example.com/thumbnails/sorry.jpg',
      'description': 'Make a fist and rub it in circular motion',
    },
    'Good morning': {
      'video': 'https://example.com/videos/good_morning.mp4',
      'thumbnail': 'https://example.com/thumbnails/good_morning.jpg',
      'description': 'Combine signs for good and morning',
    },
  };

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _playVideo(String phrase) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _controller?.dispose();
      
      final videoUrl = phraseData[phrase]?['video'];
      if (videoUrl == null) {
        throw Exception('Video URL not found for phrase: $phrase');
      }

      _controller = VideoPlayerController.network(
        videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          setState(() {
            _errorMessage = 'Error playing video: ${_controller!.value.errorDescription}';
            _isLoading = false;
          });
        }
      });

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _selectedPhrase = phrase;
          _isPlaying = true;
          _isLoading = false;
        });
        
        await _controller!.play();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video. Please check your internet connection.';
        });
      }
    }
  }

  Widget _buildPhraseCard(String phrase) {
    final isSelected = _selectedPhrase == phrase;
    final description = phraseData[phrase]?['description'] ?? '';
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: isSelected ? Color(0xFF0077B6) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _playVideo(phrase),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.white : Color(0xFF0077B6),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: CachedNetworkImage(
                      imageUrl: phraseData[phrase]?['thumbnail'] ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Color(0xFFB2D7F0),
                        child: Icon(
                          Icons.sign_language,
                          color: Color(0xFF0077B6),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.sign_language,
                        color: Color(0xFF0077B6),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: isSelected ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_outline,
                  color: isSelected ? Colors.white : Color(0xFF0077B6),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 350,
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            if (!_isLoading && (_controller == null || !_controller!.value.isInitialized))
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sign_language,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        _selectedPhrase == null
                            ? 'Select a phrase to see its sign'
                            : 'Loading video for: $_selectedPhrase',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF0077B6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Learn Sign Language',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0077B6),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildVideoPlayer(),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 8, bottom: 20),
              children: phraseData.keys
                  .map((phrase) => _buildPhraseCard(phrase))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}