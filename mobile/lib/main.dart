import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/auth_cubit.dart';
import 'package:mobile/bloc/forum_detail_cubit.dart';
import 'package:mobile/bloc/forum_post_cubit.dart';
import 'package:mobile/bloc/reminder_cubit.dart';
import 'package:mobile/bloc/user_cubit.dart';
import 'package:mobile/constants/constants.dart';
import 'package:mobile/service/my_http_overrides.dart';
import 'package:mobile/views/splash.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  await initializeDateFormatting('tr_TR', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit()..checkAuthState(),
        ),
        BlocProvider(
          create: (context) => UserCubit(),
        ),
        BlocProvider(
          create: (context) => ForumPostCubit(),
        ),
        BlocProvider(
          create: (context) => ForumDetailCubit(),
        ),
        BlocProvider(
          create: (context) => ReminderCubit(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF6C9EFF),
            onPrimary: Colors.white,
            secondary: Color(0xFFB2D3FF),
            onSecondary: Color(0xFF1A2B4C),
            error: Color(0xFFFF6B6B),
            onError: Colors.white,
            surface: Color(0xFFF3F7FC),
            onSurface: Color(0xFF4B5C6B),
          ),
          primaryColor: Color(0xFF6C9EFF),
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Color(0xFFE7ECF5),
          cardColor: Color(0xFFF3F7FC),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF6C9EFF),
              shape: const StadiumBorder(),
              maximumSize: const Size(double.infinity, 56),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFF0F5FF),
            iconColor: Color(0xFF6D8EB0),
            prefixIconColor: Color(0xFF6D8EB0),
            contentPadding: EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
                color: Color(0xFF4B5C6B),
                fontWeight: FontWeight.bold,
                fontSize: 28),
            displayMedium: TextStyle(color: Color(0xFF4B5C6B), fontSize: 24),
            displaySmall: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE7ECF5),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(color: Colors.white,fontSize: 22),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
