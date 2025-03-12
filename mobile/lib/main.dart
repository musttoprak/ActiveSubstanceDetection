import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/constants/constants.dart';
import 'package:mobile/service/my_http_overrides.dart';
import 'package:mobile/views/splash.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue.withOpacity(0.1),
        // Soft pastel blue
        scaffoldBackgroundColor: Colors.white,
        // Keep background white for clean look
        canvasColor: const Color(0xFFE7ECF5),
        // Soft light blue
        cardColor: Color(0xFFF3F7FC),
        // Soft pastel light blue for all Cards
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue.withOpacity(0.1),
            // Soft muted blue
            shape: const StadiumBorder(),
            maximumSize: const Size(double.infinity, 56),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF0F5FF),
          // Light pastel blue
          iconColor: Color(0xFF6D8EB0),
          // Muted blue
          prefixIconColor: Color(0xFF6D8EB0),
          // Muted blue
          contentPadding: EdgeInsets.symmetric(
              horizontal: defaultPadding, vertical: defaultPadding),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
            displayLarge: TextStyle(
                color: Color(0xFF4B5C6B), // Soft dark gray for headers
                fontWeight: FontWeight.bold,
                fontSize: 28),
            displayMedium: TextStyle(
                color: Color(0xFF4B5C6B), // Soft dark gray
                fontSize: 24),
            displaySmall: TextStyle(
                color: Colors.white, // Keeping header text white for contrast
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE7ECF5), // Soft light blue
          elevation: 0,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
