import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // 👈 1. Import your splash screen here

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ezze Score Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const SplashScreen(), // 👈 2. Set the splash screen as the home!
    );
  }
}