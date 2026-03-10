/// Tests for the typed route API [AppRoute].
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/router_paths.dart';

void main() {
  group('AppRoute', () {
    test('tab roots are constant', () {
      expect(AppRoute.home, '/home');
      expect(AppRoute.quran, '/quran');
      expect(AppRoute.hadith, '/hadith');
      expect(AppRoute.bookmarks, '/bookmarks');
      expect(AppRoute.settings, '/settings');
      expect(AppRoute.search, '/search');
      expect(AppRoute.tajweedGuide, '/tajweed-guide');
    });

    test('surah builds path without ayah', () {
      expect(AppRoute.surah(1), '/quran/1');
      expect(AppRoute.surah(114), '/quran/114');
    });

    test('surah builds path with ayah', () {
      expect(AppRoute.surah(2, ayah: 255), '/quran/2?ayah=255');
      expect(AppRoute.surah(1, ayah: 1), '/quran/1?ayah=1');
    });

    test('hadithBook builds path with required params', () {
      final path = AppRoute.hadithBook(
        collectionId: 'forties',
        bookFile: 'nawawi40.json',
        bookTitle: 'Nawawi 40',
      );
      expect(path, contains('/hadith/forties/nawawi40.json'));
      expect(path, contains('title='));
      expect(path, isNot(contains('index=')));
    });

    test('hadithBook builds path with index', () {
      final path = AppRoute.hadithBook(
        collectionId: 'forties',
        bookFile: 'nawawi40.json',
        bookTitle: 'Nawawi 40',
        index: 5,
      );
      expect(path, contains('index=5'));
    });
  });
}
