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
        primaryColor: AppColors.primaryWhiteColor,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: const Color(0xFFCADCF8),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: kPrimaryColor,
            shape: const StadiumBorder(),
            maximumSize: const Size(double.infinity, 56),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: kPrimaryLightColor,
          iconColor: kPrimaryColor,
          prefixIconColor: kPrimaryColor,
          contentPadding: EdgeInsets.symmetric(
              horizontal: defaultPadding, vertical: defaultPadding),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
            displayLarge: TextStyle(
                color: AppColors.headerTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 28),
            displayMedium:
                TextStyle(color: AppColors.headerTextColor, fontSize: 24),
            displaySmall: TextStyle(
                color: AppColors.primaryWhiteColor,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFCADCF8),
          elevation: 0,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
