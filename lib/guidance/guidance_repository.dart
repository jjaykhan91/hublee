/// Loads bundled Allah, Prophet, and dua guides from JSON assets.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import 'guidance_models.dart';

/// Repository for the Home-tab guides. Futures are cached per session.
class GuidanceRepository {
  const GuidanceRepository();

  static Future<AllahGuide>? _allah;
  static Future<ProphetGuide>? _prophet;
  static Future<DuaCatalog>? _duas;

  /// Clears session caches. Tests only.
  @visibleForTesting
  static void resetCache() {
    _allah = null;
    _prophet = null;
    _duas = null;
  }

  /// Allah guide: tawhid sections, key ayahs, and the 99 names.
  Future<AllahGuide> loadAllah({bool force = false}) {
    if (force) _allah = null;
    return _allah ??= _loadMap(AssetPaths.guidanceAllah, AllahGuide.fromJson);
  }

  /// Seerah orientation for Prophet Muhammad (peace be upon him).
  Future<ProphetGuide> loadProphet({bool force = false}) {
    if (force) _prophet = null;
    return _prophet ??= _loadMap(
      AssetPaths.guidanceProphet,
      ProphetGuide.fromJson,
    );
  }

  /// Quranic du'as plus Hisn al-Muslim categories.
  Future<DuaCatalog> loadDuas({bool force = false}) {
    if (force) _duas = null;
    return _duas ??= _loadMap(AssetPaths.guidanceDuas, DuaCatalog.fromJson);
  }

  Future<T> _loadMap<T>(
    String path,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Expected a JSON object in $path');
    }
    return parse(Map<String, dynamic>.from(decoded));
  }
}
