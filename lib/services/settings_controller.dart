/// Manages user-configurable display settings (font zoom levels,
/// tajweed toggle, word-by-word toggle, Arabic font family) and
/// persists them in [SharedPreferences].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available Arabic font families for Quran/Hadith text.
enum ArabicFontOption {
  /// Bundled KFGQPC Uthmanic Hafs Smart font (default).
  uthmanic('Uthmanic Hafs', 'KFGQPCQuranicFontHafsSmart'),

  /// Bundled Amiri — classic Naskh typeface (SIL OFL).
  amiri('Amiri', 'Amiri'),

  /// Bundled Scheherazade New — elegant Arabic (SIL OFL).
  scheherazade('Scheherazade', 'Scheherazade New'),

  /// Bundled Noto Naskh Arabic — clean modern face (SIL OFL).
  notoNaskh('Noto Naskh', 'Noto Naskh Arabic');

  /// Human-readable label.
  final String label;

  /// Font family identifier registered in [pubspec.yaml].
  final String fontFamily;

  const ArabicFontOption(this.label, this.fontFamily);
}

/// Holds Arabic and English font zoom factors, tajweed preference,
/// and font selection with persistence.
///
/// Zoom values are clamped to the range [0.8, 1.8] where 1.0 is
/// the default (100%). Call [load] once at startup to restore the
/// saved values from disk.
///
/// Zoom setters [notifyListeners] immediately for live preview, but
/// disk writes are debounced (~300 ms) so slider drags do not hammer
/// [SharedPreferences]. Call [dispose] to flush any pending write.
class SettingsController extends ChangeNotifier {
  static const _kArabicZoomKey = 'settings.arabicZoom';
  static const _kEnglishZoomKey = 'settings.englishZoom';
  static const _kTajweedEnabledKey = 'settings.tajweedEnabled';
  static const _kArabicFontKey = 'settings.arabicFont';
  static const _kWordByWordEnabledKey = 'settings.wordByWordEnabled';

  /// Delay before a zoom change is written to disk.
  @visibleForTesting
  static const persistDebounce = Duration(milliseconds: 300);

  double _arabicZoom = 1.0;
  double _englishZoom = 1.0;
  bool _tajweedEnabled = true;
  bool _wordByWordEnabled = false;
  ArabicFontOption _arabicFont = ArabicFontOption.uthmanic;

  Timer? _arabicZoomPersistTimer;
  Timer? _englishZoomPersistTimer;

  /// Current Arabic text zoom factor (1.0 = 100%).
  double get arabicZoom => _arabicZoom;

  /// Current English text zoom factor (1.0 = 100%).
  double get englishZoom => _englishZoom;

  /// Whether tajweed colour-coding is enabled for Quran text.
  bool get tajweedEnabled => _tajweedEnabled;

  /// Whether tapping a Qur'anic word reveals its English gloss.
  ///
  /// Off by default: it makes every word a tap target, which is what a learner
  /// wants but not what someone simply reading expects.
  bool get wordByWordEnabled => _wordByWordEnabled;

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
      notifyListeners();
      _scheduleZoomPersist(
        timer: _arabicZoomPersistTimer,
        assign: (t) => _arabicZoomPersistTimer = t,
        key: _kArabicZoomKey,
        value: value,
      );
    }
  }

  set englishZoom(double value) {
    value = value.clamp(0.8, 1.8);
    if (value != _englishZoom) {
      _englishZoom = value;
      notifyListeners();
      _scheduleZoomPersist(
        timer: _englishZoomPersistTimer,
        assign: (t) => _englishZoomPersistTimer = t,
        key: _kEnglishZoomKey,
        value: value,
      );
    }
  }

  set tajweedEnabled(bool value) {
    if (value != _tajweedEnabled) {
      _tajweedEnabled = value;
      _persistBool(_kTajweedEnabledKey, value);
      notifyListeners();
    }
  }

  set wordByWordEnabled(bool value) {
    if (value != _wordByWordEnabled) {
      _wordByWordEnabled = value;
      _persistBool(_kWordByWordEnabledKey, value);
      notifyListeners();
    }
  }

  /// Restores saved settings from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _arabicZoom = prefs.getDouble(_kArabicZoomKey) ?? 1.0;
    _englishZoom = prefs.getDouble(_kEnglishZoomKey) ?? 1.0;
    _tajweedEnabled = prefs.getBool(_kTajweedEnabledKey) ?? true;
    _wordByWordEnabled = prefs.getBool(_kWordByWordEnabledKey) ?? false;
    final fontName = prefs.getString(_kArabicFontKey);
    if (fontName != null) {
      _arabicFont = ArabicFontOption.values.firstWhere(
        (f) => f.name == fontName,
        orElse: () => ArabicFontOption.uthmanic,
      );
    }
    notifyListeners();
  }

  /// Cancels pending debounce timers and flushes the latest zoom values.
  @override
  void dispose() {
    _flushZoomPersist();
    super.dispose();
  }

  void _scheduleZoomPersist({
    required Timer? timer,
    required void Function(Timer?) assign,
    required String key,
    required double value,
  }) {
    timer?.cancel();
    assign(
      Timer(persistDebounce, () {
        assign(null);
        _persistDouble(key, value);
      }),
    );
  }

  void _flushZoomPersist() {
    final arabicPending = _arabicZoomPersistTimer != null;
    final englishPending = _englishZoomPersistTimer != null;
    _arabicZoomPersistTimer?.cancel();
    _englishZoomPersistTimer?.cancel();
    _arabicZoomPersistTimer = null;
    _englishZoomPersistTimer = null;
    if (arabicPending) {
      _persistDouble(_kArabicZoomKey, _arabicZoom);
    }
    if (englishPending) {
      _persistDouble(_kEnglishZoomKey, _englishZoom);
    }
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
