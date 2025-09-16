import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds user-facing settings (Arabic/English font zoom) with persistence.
class SettingsController extends ChangeNotifier {
  static const _kArabicZoomKey  = 'settings.arabicZoom';
  static const _kEnglishZoomKey = 'settings.englishZoom';

  /// Zoom factors (1.0 = 100%). Reasonable range: 0.8 – 1.6
  double _arabicZoom  = 1.0;
  double _englishZoom = 1.0;

  double get arabicZoom  => _arabicZoom;
  double get englishZoom => _englishZoom;

  set arabicZoom(double v) {
    v = v.clamp(0.8, 1.8);
    if (v != _arabicZoom) {
      _arabicZoom = v;
      _save(_kArabicZoomKey, v);
      notifyListeners();
    }
  }

  set englishZoom(double v) {
    v = v.clamp(0.8, 1.8);
    if (v != _englishZoom) {
      _englishZoom = v;
      _save(_kEnglishZoomKey, v);
      notifyListeners();
    }
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _arabicZoom  = sp.getDouble(_kArabicZoomKey)  ?? 1.0;
    _englishZoom = sp.getDouble(_kEnglishZoomKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> _save(String key, double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(key, v);
  }
}
