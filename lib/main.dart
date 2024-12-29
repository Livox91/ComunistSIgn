import 'package:flutter/material.dart';
import 'main_dashboard.dart';
import 'translate_sign_to_text.dart';
import 'emotion_detection.dart';
import 'settings_page.dart';// Import the file where the MainDashboard is defined


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Communication Bridge',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainDashboard(),
        '/signToText': (context) => TranslateSignToTextScreen(),
        '/textToSign': (context) => PlaceholderScreen('Text to Sign Language'),
        '/settings': (context) => SettingsPage(),

        '/emotionDetection': (context) => EmotionDetectionScreen(),
      },
    );
  }
}

// Placeholder screens for navigation
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// Exit screen
class ExitScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Thank you for using Communication Bridge!',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}