import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mcprj/data/guesture_service.dart';
import 'package:mcprj/data/server_config.dart';
import 'package:mcprj/domain/guesture_model.dart';

class IsolatedSignsScreen extends StatefulWidget {
  @override
  _IsolatedSignsScreenState createState() => _IsolatedSignsScreenState();
}

class _IsolatedSignsScreenState extends State<IsolatedSignsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;

  GuestureService? _backendService;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _isFrontCamera = false;
  Timer? _detectionTimer;

  List<PhrasePrediction> _predictions = const [];
  String _statusText = 'Press Start to begin';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimation();
    _loadService();
  }

  Future<void> _loadService() async {
    final service = await GuestureService.create();
    if (mounted) setState(() => _backendService = service);
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  Future<void> _initializeCamera({bool front = false}) async {
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
      print('Camera init failed: $e');
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

  void _startDetection() {
    if (_isDetecting || _backendService == null || !_cameraController.value.isInitialized) return;
    setState(() {
      _isDetecting = true;
      _statusText = 'Detecting...';
      _predictions = const [];
    });

    _detectionTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (!_isDetecting) return;
      try {
        final XFile picture = await _cameraController.takePicture();
        final Uint8List bytes = await picture.readAsBytes();
        final r = await _backendService!.sendFrameToBackend(bytes, isFrontCamera: _isFrontCamera);
        if (!mounted) return;
        setState(() {
          if (r.phrasePredictions.isNotEmpty) {
            _predictions = r.phrasePredictions;
            _statusText = '';
          } else {
            _statusText = 'Hold a sign still for ~2 seconds...';
          }
        });
      } catch (_) {
        if (mounted) setState(() => _statusText = 'Could not reach server. Check the URL.');
      }
    });
  }

  void _stopDetection() {
    _detectionTimer?.cancel();
    if (mounted) {
      setState(() {
        _isDetecting = false;
        _statusText = 'Stopped';
      });
    }
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text), child: Text('Save')),
        ],
      ),
    );
    if (newUrl != null && newUrl.trim().isNotEmpty) {
      await ServerConfig.setServerUrl(newUrl);
      await _loadService();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Server URL updated.')));
      }
    }
  }

  Widget _buildResultPanel() {
    if (_predictions.isEmpty) {
      return Text(
        _statusText,
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(
            fontSize: 18,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
      );
    }

    final top = _predictions.first;
    final rest = _predictions.skip(1).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top prediction — large
        Text(
          top.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
        ),
        SizedBox(height: 6),
        // Confidence bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: top.confidence,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077B6)),
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${(top.confidence * 100).toStringAsFixed(1)}% confidence',
          style: GoogleFonts.roboto(fontSize: 13, color: Colors.white70),
        ),
        // Other predictions
        if (rest.isNotEmpty) ...[
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rest
                .map((p) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${p.label}  ${(p.confidence * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.montserrat(fontSize: 13, color: Colors.white),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
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
      label: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Welcome screen
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
                  child: Icon(Icons.waving_hand, size: 120, color: Color(0xFF0077B6)),
                ),
                SizedBox(height: 30),
                Text('Isolated Sign Recognition',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
                SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text('Recognise whole ASL words and phrases in real-time',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey.shade600)),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0077B6),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 3,
                  ),
                  onPressed: () => _animationController.forward(),
                  child: Text('Start',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                      ? CameraPreview(_cameraController)
                      : Container(
                          color: Colors.black,
                          child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF0077B6))),
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
                        colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                      ),
                    ),
                    padding: EdgeInsets.only(top: topPad + 4, left: 4, right: 4, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text('Sign Recognition',
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
                    top: topPad + 64,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8, height: 8,
                              decoration:
                                  BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
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

                // 4. Frosted result panel
                Positioned(
                  left: 16, right: 16, bottom: 96,
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
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        child: _buildResultPanel(),
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
                        colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
                      ),
                    ),
                    padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                            onPressed: _isDetecting ? null : _startDetection,
                            icon: Icons.play_arrow,
                            label: 'Start',
                            color: Colors.green),
                        _buildControlButton(
                            onPressed: _isDetecting ? _stopDetection : null,
                            icon: Icons.stop,
                            label: 'Stop',
                            color: Colors.red),
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
