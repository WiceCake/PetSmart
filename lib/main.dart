import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:pet_smart/auth/auth.dart'; // or your main screen
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jgqxknwrcxxhwylnrpfr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpncXhrbndyY3h4aHd5bG5ycGZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5NzI1MTcsImV4cCI6MjA2MzU0ODUxN30.uRz08HtNPGD57dHNBSVAL7Txq4_O4JzJvlU7q7UVLjg',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        splash: 'assets/petsmart_word.png', // Your logo path
        nextScreen: const AuthScreen(),   // The screen to show after splash
        splashTransition: SplashTransition.fadeTransition,
        backgroundColor: Colors.white,
        duration: 2000, // Duration in milliseconds
      ),
    );
  }
}
