/// Tests for [AssetPaths] path builders and constants.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/data/asset_paths.dart';

void main() {
  group('AssetPaths', () {
    test('quran root and script paths are non-empty', () {
      expect(AssetPaths.quranRoot, isNotEmpty);
      expect(AssetPaths.quranV4TajweedScript, isNotEmpty);
      expect(AssetPaths.quranV4TajweedScript, contains('qpc-v4.json'));
    });

    test('quranV4TajweedFont clamps page to 1-604', () {
      expect(AssetPaths.quranV4TajweedFont(0), contains('p1.ttf'));
      expect(AssetPaths.quranV4TajweedFont(1), contains('p1.ttf'));
      expect(AssetPaths.quranV4TajweedFont(604), contains('p604.ttf'));
      expect(AssetPaths.quranV4TajweedFont(605), contains('p604.ttf'));
      expect(AssetPaths.quranV4TajweedFont(100), contains('p100.ttf'));
    });

    test('quranUthmaniStandard and quranClearQuran use surah id', () {
      expect(AssetPaths.quranUthmaniStandard(1), contains('ar/1.json'));
      expect(AssetPaths.quranUthmaniStandard(114), contains('ar/114.json'));
      expect(AssetPaths.quranClearQuran(1), contains('en.clearquran/1.json'));
    });

    test('hadith path builds collection and file', () {
      final path = AssetPaths.hadith('forties', 'nawawi40.json');
      expect(path, contains('hadith'));
      expect(path, contains('forties'));
      expect(path, contains('nawawi40.json'));
    });

    test('word-by-word and KFGQPC paths are set', () {
      expect(AssetPaths.quranWordByWordTranslation, isNotEmpty);
      expect(AssetPaths.quranWordByWordTranslation, contains('english-wbw-translation.json'));
      expect(AssetPaths.kfgqpcQuranMushafSmartV8, isNotEmpty);
    });
  });
}
