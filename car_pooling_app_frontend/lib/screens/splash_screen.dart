import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_pooling_app_frontend/providers/auth_provider.dart';
import 'package:car_pooling_app_frontend/screens/auth/login_screen.dart';
import 'package:car_pooling_app_frontend/screens/main_navigation_screen.dart';
import 'package:car_pooling_app_frontend/core/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthenticationStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(child: CircularProgressIndicator(color: kAccentColor)),
    );
  }
}
