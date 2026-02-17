/// Manages user-configurable display settings (font zoom levels)
/// and persists them in [SharedPreferences].
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds Arabic and English font zoom factors with persistence.
///
/// Zoom values are clamped to the range [0.8, 1.8] where 1.0 is
/// the default (100%). Call [load] once at startup to restore the
/// saved values from disk.
class SettingsController extends ChangeNotifier {
  /// SharedPreferences keys for each zoom setting.
  static const _kArabicZoomKey = 'settings.arabicZoom';
  static const _kEnglishZoomKey = 'settings.englishZoom';

  double _arabicZoom = 1.0;
  double _englishZoom = 1.0;

  /// Current Arabic text zoom factor (1.0 = 100%).
  double get arabicZoom => _arabicZoom;

  /// Current English text zoom factor (1.0 = 100%).
  double get englishZoom => _englishZoom;

  /// Sets the Arabic zoom factor, clamped to [0.8, 1.8],
  /// persists the value, and notifies listeners.
  set arabicZoom(double value) {
    value = value.clamp(0.8, 1.8);
    if (value != _arabicZoom) {
      _arabicZoom = value;
      _persist(_kArabicZoomKey, value);
      notifyListeners();
    }
  }

  /// Sets the English zoom factor, clamped to [0.8, 1.8],
  /// persists the value, and notifies listeners.
  set englishZoom(double value) {
    value = value.clamp(0.8, 1.8);
    if (value != _englishZoom) {
      _englishZoom = value;
      _persist(_kEnglishZoomKey, value);
      notifyListeners();
    }
  }

  /// Restores saved zoom levels from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _arabicZoom = prefs.getDouble(_kArabicZoomKey) ?? 1.0;
    _englishZoom = prefs.getDouble(_kEnglishZoomKey) ?? 1.0;
    notifyListeners();
  }

  /// Writes a single zoom value to disk.
  Future<void> _persist(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }
}
