import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:mcprj/data/emotion_service.dart';
import 'package:mcprj/domain/emotion_model.dart';
import 'package:lottie/lottie.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:mcprj/presentation/builders/build_feature_cards.dart';

class EmotionDetectionScreen extends StatefulWidget {
  @override
  _EmotionDetectionScreenState createState() => _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  final EmotionService _backendService = EmotionService();
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _detectedEmotion = "Waiting to detect emotions...";
  double? _confidence;
  Map<String, dynamic>? _allEmotions;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
      );
      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Camera initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _stopDetection();
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _startDetection() {
    if (_isDetecting || !_cameraController.value.isInitialized) return;

    setState(() {
      _isDetecting = true;
      _detectedEmotion = "Detecting emotions...";
    });

    _detectionTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (!_isDetecting) return;

      try {
        final XFile picture = await _cameraController.takePicture();
        final Uint8List imageBytes = await picture.readAsBytes();

        final EmotionResponse response =
            await _backendService.sendFrameForEmotion(imageBytes);
        setState(() {
          if (response.error != null) {
            _detectedEmotion = "Error: ${response.error}";
            _confidence = null;
            _allEmotions = null;
          } else {
            _detectedEmotion = response.emotion ?? "No emotion detected";
            _confidence = response.confidence;
            _allEmotions = response.allEmotions;
          }
        });
      } catch (e) {
        setState(() {
          _detectedEmotion = "Error: $e";
          _confidence = null;
          _allEmotions = null;
        });
      }
    });
  }

  void _stopDetection() {
    _detectionTimer?.cancel();
    setState(() {
      _isDetecting = false;
      _detectedEmotion = "Detection stopped. Ready to start again.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Welcome Screen
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  child: Lottie.asset(
                    'assets/emotion.json', // Replace with your animation file path
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Emotion Detection',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Detect emotions in real-time',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0077B6),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Start Detection',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  onPressed: () => _animationController.forward(),
                ),
              ],
            ),
          ),
          // Detection Interface
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  // Custom AppBar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: Color(0xFF0077B6)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Emotion Detection',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0077B6),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline,
                              color: Color(0xFF0077B6)),
                          onPressed: () {/* Show help dialog */},
                        ),
                      ],
                    ),
                  ),
                  // Camera Preview
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFFB2D7F0),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _isCameraInitialized
                            ? Stack(
                                children: [
                                  CameraPreview(_cameraController),
                                  if (_isDetecting)
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Detecting',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0077B6),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Emotion Results
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFB2D7F0),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_emotions,
                                  color: Color(0xFF0077B6)),
                              SizedBox(width: 10),
                              Text(
                                'Detected Emotion',
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0077B6),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text(
                                      _detectedEmotion,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (_confidence != null) ...[
                                      SizedBox(height: 10),
                                      Text(
                                        'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Control Buttons
                  Padding(
                    padding: EdgeInsets.only(bottom: 30, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildControlButton(
                          onPressed: _isDetecting ? null : _startDetection,
                          icon: Icons.play_arrow,
                          label: 'Start',
                          color: Colors.green,
                        ),
                        buildControlButton(
                          onPressed: _isDetecting ? _stopDetection : null,
                          icon: Icons.stop,
                          label: 'Stop',
                          color: Colors.red,
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
}
