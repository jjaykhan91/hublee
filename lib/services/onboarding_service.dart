/// Remembers whether the first-run intro has been finished.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router_paths.dart';

/// One-shot first-run flag stored in [SharedPreferences].
abstract final class OnboardingService {
  OnboardingService._();

  static const prefKey = 'onboarding.completed';

  static bool? _completed;

  /// Drops the in-memory flag. Tests only.
  @visibleForTesting
  static void resetCache() => _completed = null;

  /// Whether the user has finished or skipped the intro.
  static Future<bool> isCompleted() async {
    if (_completed != null) return _completed!;
    final prefs = await SharedPreferences.getInstance();
    return _completed = prefs.getBool(prefKey) ?? false;
  }

  /// Marks the intro done so splash goes straight to Home next launch.
  static Future<void> complete() async {
    _completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }

  /// [AppRoute.home] after the intro, otherwise [AppRoute.onboarding].
  static Future<String> nextRoute() async {
    return await isCompleted() ? AppRoute.home : AppRoute.onboarding;
  }
}
