/// Android implementation: writes daily content into home_widget prefs.
library;

import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../router_paths.dart';
import 'daily_content_service.dart';
import 'widget_look.dart';
import 'widget_routes.dart';

const _kWorkName = 'hublee.widgets.sync';
const _kWorkTask = 'syncHomeWidgets';
const _kSyncDay = 'widget.sync.day';

/// Home-screen widgets exist only on Android.
abstract final class HomeWidgetSync {
  HomeWidgetSync._();

  static bool get isSupported => Platform.isAndroid;

  static bool _clicksBound = false;
  static bool _workBound = false;
  static String Function()? _currentLocation;
  static void Function(String path)? _openPath;

  /// Lets [main] bind navigation without importing the router here.
  static void bindNavigation({
    required String Function() currentLocation,
    required void Function(String path) openPath,
  }) {
    _currentLocation = currentLocation;
    _openPath = openPath;
  }

  /// Holds a cold-start widget tap and listens for later taps.
  ///
  /// This is cheap (one plugin call). Heavy Workmanager setup is
  /// [registerBackgroundWork], which must not delay first paint.
  static Future<void> captureLaunch() async {
    if (!isSupported || _clicksBound) return;
    _clicksBound = true;
    try {
      HomeWidget.widgetClicked.listen(_onClick);
      WidgetLaunch.hold(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } catch (_) {
      // Launcher widgets are best-effort; the app still works.
    }
  }

  /// Registers hourly refresh. Safe to call after the first frame.
  static Future<void> registerBackgroundWork() async {
    if (!isSupported || _workBound) return;
    _workBound = true;
    try {
      await Workmanager().initialize(_widgetWorkDispatcher);
      await Workmanager().registerPeriodicTask(
        _kWorkName,
        _kWorkTask,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    } catch (_) {
      // Hourly refresh is optional; opening the app still syncs.
    }
  }

  /// Registers tap-through and background refresh.
  static Future<void> bootstrap() async {
    await captureLaunch();
    await registerBackgroundWork();
  }

  /// Reloads today's ayah, hadith, and words onto every Hublee widget.
  ///
  /// Skips asset work when this calendar day was already written, so
  /// the hourly worker does not decode the mushaf in the background.
  static Future<void> syncAll({bool force = false}) async {
    if (!isSupported) return;
    try {
      final today = DailyContentService.dayIndex;
      final prefs = await SharedPreferences.getInstance();
      if (!force && prefs.getInt(_kSyncDay) == today) {
        final arabic = await HomeWidget.getWidgetData<String>('ayah_arabic');
        if (arabic != null && arabic.isNotEmpty) return;
      }
      await Future.wait([
        _syncAyah(),
        _syncHadith(),
        _syncQuranWord(),
        _syncArabicWord(),
      ]);
      await prefs.setInt(_kSyncDay, today);
    } catch (_) {
      // Launcher widgets are best-effort; the app still works.
    }
  }

  /// Writes [look] onto [kind] without reloading daily text.
  static Future<void> applyLook(HomeWidgetKind kind, WidgetLook look) async {
    if (!isSupported) return;
    try {
      final id = kind.id;
      await Future.wait([
        HomeWidget.saveWidgetData<String>('${id}_theme', look.theme.id),
        HomeWidget.saveWidgetData<String>('${id}_size', look.size.id),
        HomeWidget.saveWidgetData<bool>('${id}_show_tr', look.showTranslation),
      ]);
      await HomeWidget.updateWidget(
        name: kind.androidName,
        androidName: kind.androidName,
        qualifiedAndroidName: kind.androidClass,
      );
    } catch (_) {
      // Look changes still persist in SharedPreferences for the next sync.
    }
  }

  /// Asks the Android launcher to pin [kind] after a sync.
  static Future<bool> requestPin(HomeWidgetKind kind) async {
    if (!isSupported) return false;
    await syncAll();
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) return false;
    await HomeWidget.requestPinWidget(
      name: kind.androidName,
      androidName: kind.androidName,
      qualifiedAndroidName: kind.androidClass,
    );
    return true;
  }

  static void _onClick(Uri? uri) {
    if (uri == null) return;
    if (_openPath == null) {
      WidgetLaunch.hold(uri);
      return;
    }
    final location = _currentLocation?.call() ?? '';
    if (location == AppRoute.splash || location == AppRoute.onboarding) {
      WidgetLaunch.hold(uri);
      return;
    }
    _openUri(uri);
  }

  static Future<void> _syncAyah() async {
    final verse = await DailyContentService.loadVerseOfTheDay();
    final look = await WidgetLookStore.load(HomeWidgetKind.ayah);
    // Standard Uthmani only — PUA mushaf glyphs will not render in Amiri.
    final arabic = await DailyContentService.uthmaniFor(
      verse.surahId,
      verse.ayah,
    );
    await _write(HomeWidgetKind.ayah, look, (
      kicker: 'Ayah of the day',
      arabic: clipAtWord(arabic, 280),
      english: clipAtWord(verse.english, 220),
      ref: '${verse.surahName} ${verse.surahId}:${verse.ayah}',
      uri: 'hublee://ayah?surah=${verse.surahId}&ayah=${verse.ayah}',
    ));
  }

  static Future<void> _syncHadith() async {
    final hadith = await DailyContentService.loadHadithOfTheDay();
    final look = await WidgetLookStore.load(HomeWidgetKind.hadith);
    final narrator = (hadith.narrator ?? '').trim();
    final english = narrator.isEmpty
        ? hadith.english
        : '$narrator: ${hadith.english}';
    await _write(HomeWidgetKind.hadith, look, (
      kicker: 'Hadith of the day',
      arabic: clipAtWord(hadith.arabic, 280),
      english: clipAtWord(english, 220),
      ref: hadith.bookTitle,
      uri:
          'hublee://hadith?collection=${hadith.collectionId}'
          '&book=${Uri.encodeComponent(hadith.bookFile)}'
          '&title=${Uri.encodeComponent(hadith.bookTitle)}'
          '&index=${hadith.hadithIndex}',
    ));
  }

  static Future<void> _syncQuranWord() async {
    final word = await DailyContentService.loadQuranWordOfTheDay();
    final look = await WidgetLookStore.load(HomeWidgetKind.quranWord);
    await _write(HomeWidgetKind.quranWord, look, (
      kicker: 'Quran word',
      arabic: word.arabic,
      english: word.gloss,
      ref: '${word.surahName} ${word.surahId}:${word.ayah}',
      uri: 'hublee://ayah?surah=${word.surahId}&ayah=${word.ayah}',
    ));
  }

  static Future<void> _syncArabicWord() async {
    final word = await DailyContentService.loadArabicWordOfTheDay();
    final look = await WidgetLookStore.load(HomeWidgetKind.arabicWord);
    final pos = word.pos.trim();
    await _write(HomeWidgetKind.arabicWord, look, (
      kicker: 'Arabic word',
      arabic: word.arabic,
      english: word.english,
      ref: pos.isEmpty ? 'Modern Standard Arabic' : pos,
      uri: 'hublee://arabic',
    ));
  }

  static Future<void> _write(
    HomeWidgetKind kind,
    WidgetLook look,
    ({String kicker, String arabic, String english, String ref, String uri})
    payload,
  ) async {
    final id = kind.id;
    await Future.wait([
      HomeWidget.saveWidgetData<String>('${id}_kicker', payload.kicker),
      HomeWidget.saveWidgetData<String>('${id}_arabic', payload.arabic),
      HomeWidget.saveWidgetData<String>('${id}_english', payload.english),
      HomeWidget.saveWidgetData<String>('${id}_ref', payload.ref),
      HomeWidget.saveWidgetData<String>('${id}_uri', payload.uri),
      HomeWidget.saveWidgetData<String>('${id}_theme', look.theme.id),
      HomeWidget.saveWidgetData<String>('${id}_size', look.size.id),
      HomeWidget.saveWidgetData<bool>('${id}_show_tr', look.showTranslation),
    ]);
    await HomeWidget.updateWidget(
      name: kind.androidName,
      androidName: kind.androidName,
      qualifiedAndroidName: kind.androidClass,
    );
  }

  static void _openUri(Uri? uri) {
    if (uri == null) return;
    final path = pathForWidgetUri(uri);
    if (path == null) return;
    _openPath?.call(path);
  }
}

@pragma('vm:entry-point')
void _widgetWorkDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await HomeWidgetSync.syncAll();
    return true;
  });
}
