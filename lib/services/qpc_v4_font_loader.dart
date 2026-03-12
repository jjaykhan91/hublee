/// On-demand loading of QPC V4 Tajweed page fonts.
///
/// Each mushaf page (1–604) has its own font file. Fonts are loaded when
/// first needed and cached for the app session.
library;

import 'package:flutter/services.dart' show rootBundle, FontLoader;

import '../data/asset_paths.dart';

/// Family name used when registering a page font: QPCV4Page1 … QPCV4Page604.
String v4PageFontFamily(int page) =>
    'QPCV4Page${page.clamp(1, 604)}';

final Set<int> _v4LoadedPages = {};
final Map<int, Future<void>> _v4LoadFutures = {};

/// Ensures the QPC V4 Tajweed font for [page] is loaded.
/// Idempotent: safe to call multiple times for the same page.
Future<void> loadV4PageFont(int page) async {
  final p = page.clamp(1, 604);
  if (_v4LoadedPages.contains(p)) return;
  _v4LoadFutures[p] ??= _loadV4Page(p);
  await _v4LoadFutures[p];
}

Future<void> _loadV4Page(int page) async {
  if (_v4LoadedPages.contains(page)) return;
  try {
    final path = AssetPaths.quranV4TajweedFont(page);
    final family = v4PageFontFamily(page);
    final loader = FontLoader(family);
    loader.addFont(rootBundle.load(path));
    await loader.load();
    _v4LoadedPages.add(page);
  } catch (_) {
    // Asset missing or invalid; leave unloaded so UI can fall back.
  }
}

/// Ensures fonts for all [pages] are loaded. Completes when all are done.
Future<void> loadV4PageFonts(Set<int> pages) async {
  await Future.wait([
    for (final p in pages) loadV4PageFont(p),
  ]);
}

/// Returns whether the font for [page] has been loaded (for tests or UI).
bool isV4PageFontLoaded(int page) =>
    _v4LoadedPages.contains(page.clamp(1, 604));
