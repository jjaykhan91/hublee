/// Tests for bookmark and last-read JSON that must not crash launch.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/services/bookmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skips corrupt bookmark rows and last-read maps', () async {
    SharedPreferences.setMockInitialValues({
      'bookmarks':
          '[{"type":"quran","surahId":1,"ayah":1,"surahName":"Al-Fatihah","createdAt":"not-a-date"},'
          '{"type":"quran","surahId":2,"ayah":255,"surahName":"Al-Baqarah","createdAt":"2024-01-01T00:00:00.000"},'
          '"oops"]',
      'last_read_quran': '{not json',
      'last_read_hadith': '[]',
      'quran_pins': '{not json',
    });

    final service = BookmarkService();
    await service.load();

    expect(service.bookmarks, hasLength(1));
    expect(service.bookmarks.single.ayah, 255);
    expect(service.lastReadQuran, isNull);
    expect(service.lastReadHadith, isNull);
    expect(service.quranPins, isEmpty);
  });

  test('persists hadith idInBook', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BookmarkService();
    await service.load();
    await service.toggleBookmark(
      Bookmark.hadith(
        collectionId: 'forties',
        bookFile: 'nawawi40.json',
        bookTitle: 'Nawawi 40',
        hadithIndex: 0,
        idInBook: 1,
      ),
    );

    final reloaded = BookmarkService();
    await reloaded.load();
    expect(reloaded.bookmarks.single.idInBook, 1);
    expect(reloaded.bookmarks.single.bookTitle, 'Nawawi 40');
  });

  test('one pin per surah; toggle clears; corrupt rows skipped', () async {
    SharedPreferences.setMockInitialValues({
      'quran_pins':
          '[{"surahId":2,"ayah":255,"surahName":"Al-Baqarah",'
          '"updatedAt":"2024-01-01T00:00:00.000"},'
          '{"surahId":0,"ayah":1,"surahName":"Bad","updatedAt":"2024-01-01T00:00:00.000"},'
          '"oops"]',
    });
    final service = BookmarkService();
    await service.load();
    expect(service.pinFor(2)?.ayah, 255);
    expect(service.isAyahPinned(2, 255), isTrue);
    expect(service.pinFor(1), isNull);

    expect(
      await service.toggleQuranPin(
        surahId: 2,
        ayah: 100,
        surahName: 'Al-Baqarah',
      ),
      QuranPinChange.moved,
    );
    expect(service.pinFor(2)?.ayah, 100);

    expect(
      await service.toggleQuranPin(
        surahId: 2,
        ayah: 100,
        surahName: 'Al-Baqarah',
      ),
      QuranPinChange.cleared,
    );
    expect(service.pinFor(2), isNull);

    expect(
      await service.toggleQuranPin(surahId: 18, ayah: 10, surahName: 'Al-Kahf'),
      QuranPinChange.pinned,
    );

    final reloaded = BookmarkService();
    await reloaded.load();
    expect(reloaded.pinFor(18)?.ayah, 10);
    expect(reloaded.pinFor(2), isNull);
  });

  test('quranOpenAyah prefers an explicit request over the pin', () {
    expect(quranOpenAyah(requestedAyah: 7, pinnedAyah: 50), 7);
    expect(quranOpenAyah(pinnedAyah: 50), 50);
    expect(quranOpenAyah(), isNull);
    expect(quranOpenAyah(requestedAyah: 0, pinnedAyah: 3), 3);
  });
}
