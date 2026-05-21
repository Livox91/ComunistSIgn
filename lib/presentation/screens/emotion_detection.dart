import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:mcprj/data/emotion_service.dart';
import 'package:mcprj/data/server_config.dart';
import 'package:mcprj/domain/emotion_model.dart';
import 'package:lottie/lottie.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

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
  EmotionService? _backendService;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _isFrontCamera = true;
  String _detectedEmotion = "Waiting to detect emotions...";
  double? _confidence;
  Map<String, dynamic>? _allEmotions;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera(front: true);
    _setupAnimation();
    _loadService();
  }

  Future<void> _loadService() async {
    final service = await EmotionService.create();
    if (mounted) setState(() => _backendService = service);
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

  Future<void> _initializeCamera({bool front = true}) async {
    try {
      _cameras = await availableCameras();
      final selected = _cameras.firstWhere(
        (c) => c.lensDirection ==
            (front ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => _cameras.first,
      );
      _cameraController = CameraController(selected, ResolutionPreset.medium);
      await _cameraController.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      print('Camera initialization failed: $e');
    }
  }

  Future<void> _switchCamera() async {
    final wasDetecting = _isDetecting;
    _stopDetection();
    setState(() => _isCameraInitialized = false);
    await _cameraController.dispose();
    _isFrontCamera = !_isFrontCamera;
    await _initializeCamera(front: _isFrontCamera);
    if (wasDetecting) _startDetection();
  }

  @override
  void dispose() {
    _stopDetection();
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _editServerUrl() async {
    final current = await ServerConfig.getServerUrl();
    if (!mounted) return;
    final controller = TextEditingController(text: current);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Server URL', style: GoogleFonts.montserrat()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'http://192.168.1.42:5000',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (newUrl != null && newUrl.trim().isNotEmpty) {
      await ServerConfig.setServerUrl(newUrl);
      await _loadService();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server URL updated.')),
        );
      }
    }
  }

  void _startDetection() {
    if (_isDetecting || _backendService == null || !_cameraController.value.isInitialized) return;

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
            await _backendService!.sendFrameForEmotion(imageBytes, isFrontCamera: _isFrontCamera);
        setState(() {
          if (response.error != null) {
            _detectedEmotion = "No face detected";
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
          _detectedEmotion = "Could not reach server. Check the URL.";
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
          // Full-screen detection interface
          SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // 1. Full-screen camera
                Positioned.fill(
                  child: _isCameraInitialized
                      ? Transform.scale(
                          scaleX: Platform.isAndroid && _isFrontCamera ? -1 : 1,
                          alignment: Alignment.center,
                          child: CameraPreview(_cameraController),
                        )
                      : Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF0077B6)),
                          ),
                        ),
                ),

                // 2. Top gradient bar
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 4,
                      left: 4, right: 4, bottom: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text('Emotion Detection',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        IconButton(
                          icon: Icon(Icons.flip_camera_android, color: Colors.white),
                          tooltip: 'Switch camera',
                          onPressed: _isCameraInitialized ? _switchCamera : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.dns, color: Colors.white),
                          tooltip: 'Set server URL',
                          onPressed: _editServerUrl,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. REC indicator
                if (_isDetecting)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 64,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 6),
                          Text('REC',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // 4. Frosted glass emotion panel
                Positioned(
                  left: 16, right: 16, bottom: 88,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_detectedEmotion,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                            if (_confidence != null) ...[
                              SizedBox(height: 8),
                              Text(
                                '${(_confidence! * 100).toStringAsFixed(1)}% confidence',
                                style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Bottom gradient + controls
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 20, right: 20, top: 12,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
