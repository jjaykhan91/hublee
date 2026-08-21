/// Full-screen splash shown at app launch.
///
/// Warms launch caches, keeps the logo on screen for a short minimum,
/// then navigates to home. A hung load cannot trap the user past
/// [SplashPage.maxWait], and a tap skips the wait.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/launch_preload.dart';

/// Splash screen: background image, preload, then [AppRoute.home].
class SplashPage extends StatefulWidget {
  /// Work to finish before leaving splash. Defaults to [warmLaunchCaches].
  final Future<void> Function()? preload;

  /// Shortest time the logo stays visible so launch is not a flicker.
  final Duration minDisplay;

  /// Hard cap so a stuck preload still reaches home.
  final Duration maxWait;

  const SplashPage({
    super.key,
    this.preload,
    this.minDisplay = const Duration(milliseconds: 400),
    this.maxWait = const Duration(seconds: 8),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _minTimer;
  Timer? _maxTimer;
  bool _left = false;
  bool _minElapsed = false;
  bool _preloadDone = false;

  @override
  void initState() {
    super.initState();
    _minTimer = Timer(widget.minDisplay, () {
      _minElapsed = true;
      _leaveIfReady();
    });
    _maxTimer = Timer(widget.maxWait, _goHome);
    _runPreload();
  }

  Future<void> _runPreload() async {
    try {
      await (widget.preload ?? warmLaunchCaches)();
    } catch (_) {
      // Home has its own error UI for failed daily content.
    }
    _preloadDone = true;
    _leaveIfReady();
  }

  void _leaveIfReady() {
    if (_minElapsed && _preloadDone) _goHome();
  }

  void _goHome() {
    if (_left || !mounted) return;
    _left = true;
    _minTimer?.cancel();
    _maxTimer?.cancel();
    context.go(AppRoute.home);
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D3B3B,
      ), // Dark teal to match artwork letterboxing
      body: Semantics(
        button: true,
        label: 'Continue',
        child: GestureDetector(
          onTap: _goHome,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                // Show full image without cropping; letterboxing uses
                // scaffold background.
                Image.asset(
                  'assets/images/HubleeBackground.png',
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
