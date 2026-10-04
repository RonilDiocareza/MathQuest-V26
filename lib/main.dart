import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAj_7-oW2itTWEKQS2r5jJCyleCKEscnR4',
          authDomain: 'mathquest-4dd85.firebaseapp.com',
          appId: '1:827434338158:web:006f9247cfacd47b9ee37f',
          messagingSenderId: '827434338158',
          projectId: 'mathquest-4dd85',
          storageBucket: 'mathquest-4dd85.firebasestorage.app',
          measurementId: 'G-Z8G4B28KHH',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (error) {
    startupError = error;
    debugPrint('Firebase initialization failed: $error');
  }

  runApp(MyApp(startupError: startupError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: startupError == null
          ? const LoginScreen()
          : const StartupErrorScreen(),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Text(
            'MathQuest is temporarily unavailable. Please try again later.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
