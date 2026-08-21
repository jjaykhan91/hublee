/// In-session performance and UI-change log for debug/profile builds.
///
/// Nothing is sent off-device. Release builds still record timings in
/// memory (cheap) but the HUD and Diagnostics page are hidden.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Kind of [MetricEvent].
enum MetricKind { timing, navigation, ui }

/// One recorded sample.
@immutable
class MetricEvent {
  const MetricEvent({
    required this.name,
    required this.kind,
    required this.at,
    this.duration,
    this.detail = const {},
  });

  final String name;
  final MetricKind kind;
  final DateTime at;
  final Duration? duration;
  final Map<String, String> detail;

  /// Duration in milliseconds, or `null` for non-timing events.
  int? get milliseconds => duration?.inMilliseconds;
}

/// Session metrics: operation timings, route changes, and frame jank.
class AppMetrics extends ChangeNotifier {
  AppMetrics._();

  /// Process-wide singleton. Tests call [reset].
  static final AppMetrics instance = AppMetrics._();

  static const int _maxEvents = 80;

  /// Frames slower than this count as jank at 60 Hz.
  static const Duration jankThreshold = Duration(milliseconds: 16);

  final List<MetricEvent> _events = [];
  bool _overlayEnabled = false;
  bool _listeningFrames = false;

  int frameCount = 0;
  int jankCount = 0;
  Duration lastBuild = Duration.zero;
  Duration lastRaster = Duration.zero;

  /// Recent events, newest first.
  List<MetricEvent> get events => List.unmodifiable(_events);

  bool get overlayEnabled => _overlayEnabled;

  /// Last timing event, if any.
  MetricEvent? get lastTiming {
    for (final event in _events) {
      if (event.kind == MetricKind.timing) return event;
    }
    return null;
  }

  /// Share of frames that missed 16 ms, 0–100.
  double get jankPercent {
    if (frameCount == 0) return 0;
    return 100 * jankCount / frameCount;
  }

  /// Shows or hides Flutter's performance overlay.
  set overlayEnabled(bool value) {
    if (_overlayEnabled == value) return;
    _overlayEnabled = value;
    notifyListeners();
  }

  /// Times an async [action] and records [name].
  Future<T> time<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? detail,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      recordTiming(name, stopwatch.elapsed, detail: detail);
    }
  }

  /// Records a completed operation.
  void recordTiming(
    String name,
    Duration duration, {
    Map<String, String>? detail,
  }) {
    _push(
      MetricEvent(
        name: name,
        kind: MetricKind.timing,
        at: DateTime.now(),
        duration: duration,
        detail: detail ?? const {},
      ),
    );
  }

  /// Records a route change (for "what did I just open?").
  void recordNav(String location) {
    if (location.isEmpty) return;
    for (final event in _events) {
      if (event.kind != MetricKind.navigation) continue;
      if (event.name == location) return;
      break;
    }
    _push(
      MetricEvent(
        name: location,
        kind: MetricKind.navigation,
        at: DateTime.now(),
      ),
    );
  }

  /// Records a user-visible UI change (theme, font, overlay).
  void recordUi(String name, {Map<String, String>? detail}) {
    _push(
      MetricEvent(
        name: name,
        kind: MetricKind.ui,
        at: DateTime.now(),
        detail: detail ?? const {},
      ),
    );
  }

  /// Starts listening for [FrameTiming]s. Safe to call more than once.
  void attachFrameTiming() {
    if (_listeningFrames) return;
    _listeningFrames = true;
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Clears timings and frame counters.
  void clear() {
    _events.clear();
    frameCount = 0;
    jankCount = 0;
    lastBuild = Duration.zero;
    lastRaster = Duration.zero;
    notifyListeners();
  }

  /// Tests only — also turns the overlay off.
  @visibleForTesting
  void reset() {
    _overlayEnabled = false;
    clear();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      frameCount++;
      lastBuild = timing.buildDuration;
      lastRaster = timing.rasterDuration;
      if (timing.totalSpan > jankThreshold) {
        jankCount++;
      }
    }
  }

  void _push(MetricEvent event) {
    _events.insert(0, event);
    if (_events.length > _maxEvents) {
      _events.removeLast();
    }
    notifyListeners();
  }
}
