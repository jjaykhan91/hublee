/// Full-screen splash shown at app launch.
///
/// Displays the Hublee background for 3 seconds, then navigates to the home tab.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash screen: background image + centered logo, waits 3 seconds then goes to home.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.asset(
        'assets/images/HubleeBackground.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
