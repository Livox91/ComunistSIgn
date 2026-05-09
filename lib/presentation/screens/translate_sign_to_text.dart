import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mcprj/data/guesture_service.dart';
import 'package:mcprj/data/server_config.dart';

class TranslateSignToTextScreen extends StatefulWidget {
  @override
  _TranslateSignToTextScreenState createState() =>
      _TranslateSignToTextScreenState();
}

class _TranslateSignToTextScreenState extends State<TranslateSignToTextScreen>
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

  // Word-building state
  String _currentWord = '';
  String _completedSentence = '';
  String _statusText = 'Press Start to begin';

  // Debounce: don't append the same letter again until the hand changes
  String _lastAppended = '';
  DateTime _lastAppendTime = DateTime(0);


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
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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

  /// Apply a single classifier label to the current word.
  /// Letters append; SPACE finalizes the word; DELETE removes the last char.
  void _applyGesture(String gesture) {
    if (gesture.isEmpty || gesture == 'Unknown' || gesture == 'NOTHING') return;

    final now = DateTime.now();

    if (gesture == 'DELETE') {
      if (_currentWord.isNotEmpty) {
        _currentWord = _currentWord.substring(0, _currentWord.length - 1);
      }
      _lastAppended = '';
      return;
    }
    if (gesture == 'SPACE') {
      if (_currentWord.isNotEmpty) {
        _completedSentence = '$_completedSentence$_currentWord ';
        _currentWord = '';
      }
      _lastAppended = '';
      return;
    }

    // Different letter: 1300ms so the hand has time to finish moving between shapes.
    // Same letter: 2300ms to allow deliberate repetition (e.g. "LL").
    final cooldown = gesture == _lastAppended ? 2300 : 1300;
    if (now.difference(_lastAppendTime).inMilliseconds < cooldown) {
      return;
    }

    _currentWord = '$_currentWord$gesture';
    _lastAppended = gesture;
    _lastAppendTime = now;
  }

  void _startDetection() {
    if (_isDetecting ||
        _backendService == null ||
        !_cameraController.value.isInitialized) return;

    setState(() {
      _isDetecting = true;
      _statusText = 'Detecting...';
    });

    _detectionTimer = Timer.periodic(Duration(milliseconds: 1000), (_) async {
      if (!_isDetecting) return;
      try {
        final XFile picture = await _cameraController.takePicture();
        final Uint8List bytes = await picture.readAsBytes();

        final r = await _backendService!.sendFrameToBackend(bytes, isFrontCamera: _isFrontCamera);
        if (!mounted) return;

        setState(() {
          // Word building from per-frame letters (latest gesture wins per frame).
          if (r.gestures.isNotEmpty) {
            for (final g in r.gestures) {
              _applyGesture(g);
            }
          }

          if (r.gestures.isEmpty) {
            _statusText = 'Detecting...';
          } else {
            _statusText = 'Last: ${r.gestures.join(' ')}';
          }
        });
      } catch (e) {
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

  void _clearText() {
    setState(() {
      _currentWord = '';
      _completedSentence = '';
      _statusText = 'Cleared';
    });
  }

  /// In-app dialog to set the server URL (so a physical phone can hit your laptop).
  Future<void> _editServerUrl() async {
    final current = await ServerConfig.getServerUrl();
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

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool compact = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 18 : 22),
      label: Text(label,
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey.shade600 : color,
        foregroundColor: Colors.white,
        padding: compact
            ? EdgeInsets.symmetric(horizontal: 14, vertical: 9)
            : EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final fullText = '$_completedSentence$_currentWord'.trim();
    final displayText = fullText.isEmpty ? _statusText : fullText;
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
                  child: Icon(Icons.sign_language, size: 120, color: Color(0xFF0077B6)),
                ),
                SizedBox(height: 30),
                Text('Sign Language Translator',
                    style: GoogleFonts.montserrat(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
                SizedBox(height: 15),
                Text('Start translating sign language in real-time',
                    style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey.shade600)),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0077B6),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 3,
                  ),
                  onPressed: () => _animationController.forward(),
                  child: Text('Start Translating',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),

          // Full-screen translation interface
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
                          child: Text('Sign to Text',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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
                              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          SizedBox(width: 6),
                          Text('REC',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // 4. Frosted glass translation panel
                Positioned(
                  left: 16, right: 16, bottom: 158,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        constraints: BoxConstraints(maxHeight: 190),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(displayText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                            ],
                          ),
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
                        colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
                      ),
                    ),
                    padding: EdgeInsets.only(
                        left: 16, right: 16, top: 10,
                        bottom: MediaQuery.of(context).padding.bottom + 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                                onPressed: _isDetecting ? null : _startDetection,
                                icon: Icons.play_arrow, label: 'Start', color: Colors.green),
                            _buildControlButton(
                                onPressed: _isDetecting ? _stopDetection : null,
                                icon: Icons.stop, label: 'Stop', color: Colors.red),
                            _buildControlButton(
                                onPressed: _clearText,
                                icon: Icons.delete_sweep, label: 'Clear', color: Color(0xFF0077B6)),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Text-editing controls — compact, full width split 50/50
                        Row(
                          children: [
                            Expanded(
                              child: _buildControlButton(
                                  onPressed: () => setState(() {
                                    if (_currentWord.isNotEmpty) {
                                      _completedSentence = '$_completedSentence$_currentWord ';
                                      _currentWord = '';
                                    }
                                    _lastAppended = '';
                                  }),
                                  icon: Icons.space_bar, label: 'Space',
                                  color: Colors.blueGrey, compact: true),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildControlButton(
                                  onPressed: () => setState(() {
                                    if (_currentWord.isNotEmpty) {
                                      _currentWord = _currentWord.substring(0, _currentWord.length - 1);
                                    } else if (_completedSentence.isNotEmpty) {
                                      _completedSentence = _completedSentence.trimRight();
                                      final lastSpace = _completedSentence.lastIndexOf(' ');
                                      if (lastSpace >= 0) {
                                        _currentWord = _completedSentence.substring(lastSpace + 1);
                                        _completedSentence = _completedSentence.substring(0, lastSpace + 1);
                                      } else {
                                        _currentWord = _completedSentence;
                                        _completedSentence = '';
                                      }
                                    }
                                    _lastAppended = '';
                                  }),
                                  icon: Icons.backspace, label: 'Delete',
                                  color: Colors.orange, compact: true),
                            ),
                          ],
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
