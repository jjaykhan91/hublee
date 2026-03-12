/// Manages user-configurable display settings (font zoom levels,
/// V4 tajweed toggle, Arabic font family) and persists them in
/// [SharedPreferences].
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available Arabic font families for Quran/Hadith text.
enum ArabicFontOption {
  /// Bundled KFGQPC Uthmanic Hafs Smart font (default).
  uthmanic('Uthmanic Hafs', 'KFGQPCQuranicFontHafsSmart'),

  /// Amiri — classic Naskh typeface from Google Fonts.
  amiri('Amiri', 'Amiri'),

  /// Scheherazade New — elegant Arabic from Google Fonts.
  scheherazade('Scheherazade', 'Scheherazade New'),

  /// Noto Naskh Arabic — clean modern from Google Fonts.
  notoNaskh('Noto Naskh', 'Noto Naskh Arabic');

  /// Human-readable label.
  final String label;

  /// Font family identifier used by Flutter / Google Fonts.
  final String fontFamily;

  const ArabicFontOption(this.label, this.fontFamily);
}

/// Holds Arabic and English font zoom factors, tajweed preference,
/// and font selection with persistence.
///
/// Zoom values are clamped to the range [0.8, 1.8] where 1.0 is
/// the default (100%). Call [load] once at startup to restore the
/// saved values from disk.
class SettingsController extends ChangeNotifier {
  static const _kArabicZoomKey = 'settings.arabicZoom';
  static const _kEnglishZoomKey = 'settings.englishZoom';
  static const _kTajweedEnabledKey = 'settings.tajweedEnabled';
  static const _kArabicFontKey = 'settings.arabicFont';

  double _arabicZoom = 1.0;
  double _englishZoom = 1.0;
  bool _tajweedEnabled = true;
  ArabicFontOption _arabicFont = ArabicFontOption.uthmanic;

  /// Current Arabic text zoom factor (1.0 = 100%).
  double get arabicZoom => _arabicZoom;

  /// Current English text zoom factor (1.0 = 100%).
  double get englishZoom => _englishZoom;

  /// Whether V4 font-based tajweed is enabled for Quran text.
  bool get tajweedEnabled => _tajweedEnabled;

  /// Currently selected Arabic font family.
  ArabicFontOption get arabicFont => _arabicFont;

  set arabicFont(ArabicFontOption value) {
    if (value != _arabicFont) {
      _arabicFont = value;
      _persistString(_kArabicFontKey, value.name);
      notifyListeners();
    }
  }

  set arabicZoom(double value) {
    value = value.clamp(0.8, 1.8);
    if (value != _arabicZoom) {
      _arabicZoom = value;
      _persistDouble(_kArabicZoomKey, value);
      notifyListeners();
    }
  }

  set englishZoom(double value) {
    value = value.clamp(0.8, 1.8);
    if (value != _englishZoom) {
      _englishZoom = value;
      _persistDouble(_kEnglishZoomKey, value);
      notifyListeners();
    }
  }

  set tajweedEnabled(bool value) {
    if (value != _tajweedEnabled) {
      _tajweedEnabled = value;
      _persistBool(_kTajweedEnabledKey, value);
      notifyListeners();
    }
  }

  /// Restores saved settings from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _arabicZoom = prefs.getDouble(_kArabicZoomKey) ?? 1.0;
    _englishZoom = prefs.getDouble(_kEnglishZoomKey) ?? 1.0;
    _tajweedEnabled = prefs.getBool(_kTajweedEnabledKey) ?? true;
    final fontName = prefs.getString(_kArabicFontKey);
    if (fontName != null) {
      _arabicFont = ArabicFontOption.values.firstWhere(
        (f) => f.name == fontName,
        orElse: () => ArabicFontOption.uthmanic,
      );
    }
    notifyListeners();
  }

  Future<void> _persistDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _persistBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _persistString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
