import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 💡 Import Provider
import 'package:car_pooling_app_frontend/core/constants.dart';
import 'package:car_pooling_app_frontend/providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlaBlaCar Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryTextColor,
          surface: kBackgroundColor,
        ),
        scaffoldBackgroundColor: kBackgroundColor,
      ),
      home: const SplashScreen(), // This is the screen that loads first
    );
  }
}
