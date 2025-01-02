import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mcprj/data/shared_preference.dart';
import 'package:mcprj/presentation/blocs/first_time_bloc/first_time_bloc.dart';
import 'package:mcprj/presentation/screens/first_time.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcprj/presentation/blocs/auth_bloc/user_auth_bloc.dart';
import 'package:mcprj/presentation/screens/login.dart';
import 'presentation/screens/main_dashboard.dart';
import 'presentation/screens/translate_sign_to_text.dart';
import 'presentation/screens/emotion_detection.dart';
import 'presentation/screens/settings_page.dart';
import 'presentation/screens/splash_screen.dart'; // Import the file where the MainDashboard is defined

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAuth.instance;
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
        '/': (context) => Authentication(),
        '/signToText': (context) => TranslateSignToTextScreen(),
        '/textToSign': (context) => PlaceholderScreen('Text to Sign Language'),
        '/settings': (context) => SettingsPage(),
        '/emotionDetection': (context) => EmotionDetectionScreen(),
        '/Login': (context) => Authentication(),
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
      create: (context) => UserAuthBloc(FirebaseAuth.instance),
      child: BlocConsumer<UserAuthBloc, UserAuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return LoginPage();
          } else if (state is AuthLoading) {
            return SplashScreen();
          } else if (state is AuthError) {
            return Text("Error: ${state.message}");
          } else if (state is AuthAuthenticated) {
            return BlocProvider(
                create: (context) => FirstTimeSetupBloc(),
                child: FirstTimeWidget());
          } else {
            return Text("Unknown state: $state");
          }
        },
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
      ),
    );
  }
}

class FirstTimeWidget extends StatelessWidget {
  const FirstTimeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final FirstTimeSetupBloc setupBloc =
        BlocProvider.of<FirstTimeSetupBloc>(context);
    return Center(
      child: BlocBuilder<FirstTimeSetupBloc, SetupState>(
        builder: (context, state) {
          if (state == SetupState.initial) {
            setupBloc.add(SetupEvent.startSetup);
          }
          if (state == SetupState.inProgress) {
            return OnboardingFlow();
          } else if (state == SetupState.completed) {
            return MainDashboard();
          }
          return Container();
        },
      ),
    );
  }
}
