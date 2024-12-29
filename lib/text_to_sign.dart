import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class TextToSignScreen extends StatefulWidget {
  @override
  _TextToSignScreenState createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen> {
  VideoPlayerController? _controller;
  String? _selectedWord;
  bool _isPlaying = false;

  // Sample word categories and their associated words
  final Map<String, List<String>> wordCategories = {
    'Common Phrases': ['Hello', 'Thank you', 'Please', 'Sorry', 'Good morning'],
    'Emotions': ['Happy', 'Sad', 'Angry', 'Excited', 'Tired'],
    'Numbers': ['One', 'Two', 'Three', 'Four', 'Five'],
    'Colors': ['Red', 'Blue', 'Green', 'Yellow', 'Purple'],
    'Family': ['Mother', 'Father', 'Sister', 'Brother', 'Family'],
  };

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _playVideo(String word) {
    // Here you would normally load the video file for the selected word
    // For demonstration, we'll just print the selected word
    setState(() {
      _selectedWord = word;
      _isPlaying = true;
    });
    
    // Example of how to implement video playing:
    // _controller = VideoPlayerController.asset('assets/videos/$word.mp4')
    //   ..initialize().then((_) {
    //     setState(() {});
    //     _controller?.play();
    //   });
  }

  Widget _buildCategorySection(String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            category,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 15),
            itemCount: wordCategories[category]?.length ?? 0,
            itemBuilder: (context, index) {
              final word = wordCategories[category]![index];
              return _buildWordCard(word);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(String word) {
    final isSelected = _selectedWord == word;
    
    return GestureDetector(
      onTap: () => _playVideo(word),
      child: Container(
        width: 150,
        margin: EdgeInsets.all(5),
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
            word,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 300,
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFB2D7F0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: _selectedWord == null
            ? Text(
                'Select a word to see its sign',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sign_language,
                    size: 80,
                    color: Color(0xFF0077B6),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Playing: $_selectedWord',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF0077B6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Text to Sign',
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
              children: wordCategories.keys
                  .map((category) => _buildCategorySection(category))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}