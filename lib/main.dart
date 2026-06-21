import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DivineQueueApp());
}

class DivineQueueApp extends StatelessWidget {
  const DivineQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DivineQueue',
      theme: _buildDarkEtherealTheme(),
      home: const AuthWrapper(),
    );
  }

  ThemeData _buildDarkEtherealTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
        primary: const Color(0xFFA78BFA),
        secondary: const Color(0xFFF59E0B),
        surface: const Color(0xFF1E1B4B),
        background: const Color(0xFF0F0A1F),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0A1F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1B4B),
        foregroundColor: Color(0xFFA78BFA),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1B4B),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFFE9D5FF),
          fontWeight: FontWeight.bold,
          fontFamily: 'Georgia',
        ),
        bodyLarge: TextStyle(color: Color(0xFFC4B5FD)),
        bodyMedium: TextStyle(color: Color(0xFFA78BFA)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2E2A5C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: Color(0xFFA78BFA)),
      ),
    );
  }
}
