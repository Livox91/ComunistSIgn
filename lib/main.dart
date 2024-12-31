import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcprj/presentation/blocs/bloc/user_auth_bloc.dart';
import 'presentation/screens/main_dashboard.dart';
import 'presentation/screens/translate_sign_to_text.dart';
import 'presentation/screens/emotion_detection.dart';
import 'presentation/screens/settings_page.dart'; // Import the file where the MainDashboard is defined

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
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// Exit screen
class ExitScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserAuthBloc(),
      child: AuthenticationView(),
    );
  }
}

class AuthenticationView extends StatelessWidget {
  const AuthenticationView({super.key});

  @override
  Widget build(BuildContext context) {
    final UserAuthBloc userAuthBloc = BlocProvider.of<UserAuthBloc>(context);

    return BlocBuilder(builder: builder);
  }
}
