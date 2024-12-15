import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:async';
import 'backend_service.dart';

class TranslateSignToTextScreen extends StatefulWidget {
  @override
  _TranslateSignToTextScreenState createState() =>
      _TranslateSignToTextScreenState();
}

class _TranslateSignToTextScreenState extends State<TranslateSignToTextScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _translatedText = "Translation will appear here.";
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
      appBar: AppBar(
        title: Text(
          'Translate Sign to Text',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade300, Colors.pink.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera Preview with Rounded Borders
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController)
                      : Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),

          // Translated Text Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Translated Gesture',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink.shade400,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          _translatedText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Buttons Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _customButton(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  onPressed: _startDetection,
                  color: Colors.pink.shade300,
                ),
                _customButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  onPressed: _stopDetection,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom Button Widget
  Widget _customButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 3,
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _startDetection() {
    if (_isDetecting || !_cameraController.value.isInitialized) return;

    setState(() {
      _isDetecting = true;
      _translatedText = "Detecting...";
    });

    _detectionTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (!_isDetecting) return;

      try {
        final XFile picture = await _cameraController.takePicture();
        final Uint8List imageBytes = await picture.readAsBytes();

        // Simulate sending frame to backend
        String response = await sendFrameToBackend(imageBytes);

        setState(() {
          _translatedText = response;
        });
      } catch (e) {
        print('Error capturing frame: $e');
        setState(() {
          _translatedText = "Error processing frame.";
        });
      }
    });
  }

  void _stopDetection() {
    setState(() {
      _isDetecting = false;
      _detectionTimer?.cancel();
      _translatedText = "Detection stopped.";
    });
  }
}
