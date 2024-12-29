import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:async';
import 'backend_service.dart';

class TranslateSignToTextScreen extends StatefulWidget {
  @override
  _TranslateSignToTextScreenState createState() => _TranslateSignToTextScreenState();
}

class _TranslateSignToTextScreenState extends State<TranslateSignToTextScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  final BackendService _backendService = BackendService();
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _translatedText = "Translation will appear here.";
  Timer? _detectionTimer;
  List<String> _currentSequence = [];

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
      _translatedText = "Detecting...";
    });

    _detectionTimer = Timer.periodic(Duration(milliseconds: 1000), (_) async {  // Increased to 1 second
      if (!_isDetecting) return;

      try {
        final XFile picture = await _cameraController.takePicture();
        final Uint8List imageBytes = await picture.readAsBytes();
        
        // Process gestures
        final gestureResponse = await _backendService.sendFrameToBackend(imageBytes);
        
        setState(() {
          if (gestureResponse.error != null) {
            _translatedText = gestureResponse.error!;
          } else if (gestureResponse.phrase != null) {
            // When a phrase is detected, pause detection for a moment
            _isDetecting = false;
            _translatedText = gestureResponse.phrase!;  // Show the actual phrase
            _currentSequence = [];
            
            // Resume detection after 3 seconds
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _isDetecting = true;
                  _translatedText = "Detecting...";
                });
              }
            });
          } else if (gestureResponse.gestures.isNotEmpty) {
            _currentSequence = gestureResponse.sequence;
            // Show both current gestures and accumulated sequence
            _translatedText = "Detected: ${gestureResponse.gestures.join('')}";
          } else {
            _translatedText = "No gestures detected";
          }
        });

      } catch (e) {
        setState(() {
          _translatedText = "Error: $e";
        });
      }
    });
}
  void _stopDetection() {
    _detectionTimer?.cancel();
    setState(() {
      _isDetecting = false;
      _translatedText = "Detection stopped. Ready to start again.";
    });
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
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
                  decoration: BoxDecoration(
                    color: Color(0xFFB2D7F0),
                    borderRadius: BorderRadius.circular(120),
                  ),
                  child: Icon(
                    Icons.sign_language,
                    size: 120,
                    color: Color(0xFF0077B6),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Sign Language Translator',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Start translating sign language in real-time',
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
                    'Start Translating',
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
          // Translation Interface
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
                          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF0077B6)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Sign to Text',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0077B6),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline, color: Color(0xFF0077B6)),
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
                                          borderRadius: BorderRadius.circular(20),
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
                                              'Recording',
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
                  // Translation Results
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
                              Icon(Icons.translate, color: Color(0xFF0077B6)),
                              SizedBox(width: 10),
                              Text(
                                'Translation',
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
                                child: Text(
                                  _translatedText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
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
                        _buildControlButton(
                          onPressed: _isDetecting ? null : _startDetection,
                          icon: Icons.play_arrow,
                          label: 'Start',
                          color: Colors.green,
                        ),
                        _buildControlButton(
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