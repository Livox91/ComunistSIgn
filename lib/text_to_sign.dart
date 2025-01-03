import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

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

  final Map<String, String> phraseVideos = {
    'Hello': 'assets/hello.mp4',
    'Thank you': 'assets/thank_you.mp4',
    'Please': 'assets/please.mp4',
    'Sorry': 'assets/sorry.mp4',
    'Good morning': 'assets/good_morning.mp4',
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
      // Dispose of previous controller
      await _controller?.dispose();

      final videoPath = phraseVideos[phrase];
      if (videoPath == null) {
        throw Exception('Video path not found for phrase: $phrase');
      }

      _controller = VideoPlayerController.asset(
        videoPath,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Add error listener before initialization
      _controller!.addListener(() {
        final error = _controller!.value.errorDescription;
        if (error != null && error.isNotEmpty) {
          print('Video player error: $error');
          setState(() {
            _errorMessage = 'Error playing video: $error';
            _isLoading = false;
          });
        }
      });

      // Initialize with error catching
      await _controller!.initialize().catchError((error) {
        print('Initialization error: $error');
        setState(() {
          _errorMessage = 'Could not load video. Please check asset files.';
          _isLoading = false;
        });
        return;
      });

      setState(() {
        _selectedPhrase = phrase;
        _isPlaying = true;
        _isLoading = false;
      });

      await _controller!.play();
    } catch (error) {
      print('Error in _playVideo: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video. Please check assets and paths.';
      });
    }
  }

  Widget _buildPhraseCard(String phrase) {
    final isSelected = _selectedPhrase == phrase;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: GestureDetector(
        onTap: () => _playVideo(phrase),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF0077B6) : Color(0xFFB2D7F0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              phrase,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        Container(
          height: 300,
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFB2D7F0),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0077B6),
                    ),
                  ),
                if (!_isLoading &&
                    (_controller == null || !_controller!.value.isInitialized))
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sign_language,
                          size: 80,
                          color: Color(0xFF0077B6),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _selectedPhrase == null
                              ? 'Select a phrase to see its sign'
                              : 'Loading video for: $_selectedPhrase',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF0077B6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Common Phrases',
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
          Expanded(
            child: ListView(
              children: phraseVideos.keys
                  .map((phrase) => _buildPhraseCard(phrase))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
