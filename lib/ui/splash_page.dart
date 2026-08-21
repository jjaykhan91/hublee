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
      backgroundColor: const Color(
        0xFF0D3B3B,
      ), // Dark teal to match artwork letterboxing
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Show full image without cropping; letterboxing uses scaffold background.
            Image.asset(
              'assets/images/HubleeBackground.png',
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
