/// Look options for Android home-screen widgets.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// One of the four Hublee launcher widgets.
enum HomeWidgetKind { ayah, hadith, quranWord, arabicWord }

/// Visual theme for a widget. [accent] uses the indigo / emerald / teal
/// card colours from Home.
enum WidgetLookTheme { light, dark, paper, accent }

/// Type size on the launcher widget.
enum WidgetLookSize { compact, comfortable, large }

/// Per-kind look stored on device.
class WidgetLook {
  const WidgetLook({
    required this.theme,
    required this.size,
    required this.showTranslation,
  });

  final WidgetLookTheme theme;
  final WidgetLookSize size;
  final bool showTranslation;

  WidgetLook copyWith({
    WidgetLookTheme? theme,
    WidgetLookSize? size,
    bool? showTranslation,
  }) {
    return WidgetLook(
      theme: theme ?? this.theme,
      size: size ?? this.size,
      showTranslation: showTranslation ?? this.showTranslation,
    );
  }

  static WidgetLook defaultsFor(HomeWidgetKind _) {
    return const WidgetLook(
      theme: WidgetLookTheme.accent,
      size: WidgetLookSize.comfortable,
      showTranslation: true,
    );
  }
}

extension HomeWidgetKindX on HomeWidgetKind {
  String get id => switch (this) {
    HomeWidgetKind.ayah => 'ayah',
    HomeWidgetKind.hadith => 'hadith',
    HomeWidgetKind.quranWord => 'qword',
    HomeWidgetKind.arabicWord => 'aword',
  };

  String get title => switch (this) {
    HomeWidgetKind.ayah => 'Ayah of the day',
    HomeWidgetKind.hadith => 'Hadith of the day',
    HomeWidgetKind.quranWord => 'Quran word of the day',
    HomeWidgetKind.arabicWord => 'Arabic word of the day',
  };

  String get subtitle => switch (this) {
    HomeWidgetKind.ayah => 'A verse from the Quran, new each day',
    HomeWidgetKind.hadith => 'From Nawawi 40, new each day',
    HomeWidgetKind.quranWord => 'A Quranic word and its English gloss',
    HomeWidgetKind.arabicWord => 'A Modern Standard Arabic word',
  };

  /// Fully-qualified Android AppWidgetProvider class.
  String get androidClass => switch (this) {
    HomeWidgetKind.ayah => 'com.hublee.app.widgets.AyahWidgetProvider',
    HomeWidgetKind.hadith => 'com.hublee.app.widgets.HadithWidgetProvider',
    HomeWidgetKind.quranWord =>
      'com.hublee.app.widgets.QuranWordWidgetProvider',
    HomeWidgetKind.arabicWord =>
      'com.hublee.app.widgets.ArabicWordWidgetProvider',
  };

  String get androidName => switch (this) {
    HomeWidgetKind.ayah => 'AyahWidgetProvider',
    HomeWidgetKind.hadith => 'HadithWidgetProvider',
    HomeWidgetKind.quranWord => 'QuranWordWidgetProvider',
    HomeWidgetKind.arabicWord => 'ArabicWordWidgetProvider',
  };
}

extension WidgetLookThemeX on WidgetLookTheme {
  String get id => name;

  String get label => switch (this) {
    WidgetLookTheme.light => 'Light',
    WidgetLookTheme.dark => 'Dark',
    WidgetLookTheme.paper => 'Paper',
    WidgetLookTheme.accent => 'Accent',
  };
}

extension WidgetLookSizeX on WidgetLookSize {
  String get id => name;

  String get label => switch (this) {
    WidgetLookSize.compact => 'Compact',
    WidgetLookSize.comfortable => 'Comfortable',
    WidgetLookSize.large => 'Large',
  };
}

/// Loads and saves [WidgetLook] per [HomeWidgetKind].
class WidgetLookStore {
  WidgetLookStore._();

  static const _prefix = 'widget.look.';

  static String _key(HomeWidgetKind kind) => '$_prefix${kind.id}';

  /// Reads the look for [kind], or the default if nothing is saved.
  static Future<WidgetLook> load(HomeWidgetKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(kind));
    if (raw == null || raw.isEmpty) {
      return WidgetLook.defaultsFor(kind);
    }
    return decode(kind, raw);
  }

  /// Persists [look] for [kind].
  static Future<void> save(HomeWidgetKind kind, WidgetLook look) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(kind), encode(look));
  }

  /// Encodes [look] as `theme|size|0or1`.
  static String encode(WidgetLook look) {
    final flag = look.showTranslation ? '1' : '0';
    return '${look.theme.id}|${look.size.id}|$flag';
  }

  /// Parses [raw] from [encode].
  static WidgetLook decode(HomeWidgetKind kind, String raw) {
    final parts = raw.split('|');
    final defaults = WidgetLook.defaultsFor(kind);
    if (parts.length < 3) return defaults;
    final theme = WidgetLookTheme.values.where((t) => t.id == parts[0]);
    final size = WidgetLookSize.values.where((s) => s.id == parts[1]);
    return WidgetLook(
      theme: theme.isEmpty ? defaults.theme : theme.first,
      size: size.isEmpty ? defaults.size : size.first,
      showTranslation: parts[2] != '0',
    );
  }
}

/// Clips [text] at a word boundary so Arabic is never cut mid-word.
String clipAtWord(String text, int maxChars) {
  final trimmed = text.trim();
  if (trimmed.length <= maxChars) return trimmed;
  final cut = trimmed.substring(0, maxChars);
  final space = cut.lastIndexOf(' ');
  if (space > 0) return '${cut.substring(0, space)}...';
  final firstSpace = trimmed.indexOf(' ');
  if (firstSpace <= 0) return trimmed;
  return '${trimmed.substring(0, firstSpace)}...';
}
