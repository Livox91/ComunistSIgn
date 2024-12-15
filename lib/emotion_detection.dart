import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:async';
import 'backend_service.dart';

class EmotionDetectionScreen extends StatefulWidget {
  @override
  _EmotionDetectionScreenState createState() => _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _detectedEmotion = "Emotion will appear here.";
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: Text('Emotion Detection', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera Preview Section
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isCameraInitialized
                    ? CameraPreview(_cameraController)
                    : Center(
                        child: CircularProgressIndicator(
                          color: Colors.pinkAccent,
                        ),
                      ),
              ),
            ),
          ),

          // Detected Emotion Section
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Detected Emotion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _detectedEmotion,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startDetection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start'),
                ),
                ElevatedButton.icon(
                  onPressed: _stopDetection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(Icons.stop),
                  label: Text('Stop'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to start emotion detection
  void _startDetection() {
    if (_isDetecting || !_cameraController.value.isInitialized) return;

    setState(() {
      _isDetecting = true;
      _detectedEmotion = "Detecting emotion...";
    });

    _detectionTimer = Timer.periodic(Duration(milliseconds: 700), (_) async {
      if (!_isDetecting) return;

      try {
        final XFile picture = await _cameraController.takePicture();
        final Uint8List imageBytes = await picture.readAsBytes();

        // Send frame to backend
        String response = await sendFrameForEmotion(imageBytes);

        setState(() {
          _detectedEmotion = response;
        });
      } catch (e) {
        print('Error capturing frame: $e');
        setState(() {
          _detectedEmotion = "Error detecting emotion.";
        });
      }
    });
  }

  // Method to stop emotion detection
  void _stopDetection() {
    setState(() {
      _isDetecting = false;
      _detectionTimer?.cancel();
      _detectedEmotion = "Emotion detection stopped.";
    });
  }
}
