/// Stub when `dart:io` is unavailable (web).
library;

import 'widget_look.dart';

/// Home-screen widgets exist only on Android.
abstract final class HomeWidgetSync {
  HomeWidgetSync._();

  static bool get isSupported => false;

  /// Lets [main] bind navigation. No-op here.
  static void bindNavigation({
    required String Function() currentLocation,
    required void Function(String path) openPath,
  }) {}

  /// Holds a cold-start widget tap. No-op here.
  static Future<void> captureLaunch() async {}

  /// Registers hourly refresh. No-op here.
  static Future<void> registerBackgroundWork() async {}

  /// Registers tap-through and background refresh. No-op here.
  static Future<void> bootstrap() async {}

  /// Writes today's content onto launcher widgets. No-op here.
  static Future<void> syncAll({bool force = false}) async {}

  /// Writes [look] onto [kind] without reloading daily text. No-op here.
  static Future<void> applyLook(HomeWidgetKind kind, WidgetLook look) async {}

  /// Asks the launcher to pin [kind]. No-op here.
  static Future<bool> requestPin(HomeWidgetKind kind) async => false;
}
