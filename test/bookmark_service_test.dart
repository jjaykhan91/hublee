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
    expect(service.positionFor(2), isNull);
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

  test('remembers where reading stopped in each surah', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BookmarkService();
    await service.load();
    await service.saveLastReadQuran(
      surahId: 2,
      ayah: 45,
      surahName: 'Al-Baqarah',
    );
    await service.saveLastReadQuran(
      surahId: 18,
      ayah: 10,
      surahName: 'Al-Kahf',
    );

    final reloaded = BookmarkService();
    await reloaded.load();
    expect(reloaded.positionFor(2), 45);
    expect(reloaded.positionFor(18), 10);
    expect(reloaded.positionFor(1), isNull);
    expect(reloaded.lastReadQuran?['surahId'], 18);
  });

  test('skips saved positions outside the Quran', () async {
    SharedPreferences.setMockInitialValues({
      'quran_positions': '{"2":45,"0":3,"x":1,"5":"a","6":0,"115":2}',
    });
    final service = BookmarkService();
    await service.load();
    expect(service.positionFor(2), 45);
    for (final surah in [0, 5, 6, 115]) {
      expect(service.positionFor(surah), isNull);
    }
  });

  test('old pins become bookmarks and positions, once', () async {
    SharedPreferences.setMockInitialValues({
      'bookmarks':
          '[{"type":"quran","surahId":18,"ayah":10,"surahName":"Al-Kahf",'
          '"createdAt":"2024-01-01T00:00:00.000"}]',
      'quran_positions': '{"18":30}',
      'quran_pins':
          '[{"surahId":2,"ayah":255,"surahName":"Al-Baqarah",'
          '"updatedAt":"2024-02-01T00:00:00.000"},'
          '{"surahId":18,"ayah":10,"surahName":"Al-Kahf",'
          '"updatedAt":"2024-02-01T00:00:00.000"},'
          '{"surahId":0,"ayah":1,"surahName":"Bad","updatedAt":"x"},'
          '"oops"]',
    });
    final service = BookmarkService();
    await service.load();

    expect(service.isBookmarked('quran:2:255'), isTrue);
    expect(service.isBookmarked('quran:18:10'), isTrue);
    expect(service.bookmarks, hasLength(2));
    expect(service.positionFor(2), 255);
    expect(service.positionFor(18), 30, reason: 'a saved position wins');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quran_pins'), isNull);

    final reloaded = BookmarkService();
    await reloaded.load();
    expect(reloaded.bookmarks, hasLength(2));
    expect(reloaded.positionFor(2), 255);
  });

  test('lists a surah\'s bookmarks in ayah order', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BookmarkService();
    await service.load();
    for (final ayah in [200, 3, 45]) {
      await service.toggleBookmark(
        Bookmark.quran(surahId: 2, ayah: ayah, surahName: 'Al-Baqarah'),
      );
    }
    await service.toggleBookmark(
      Bookmark.quran(surahId: 1, ayah: 1, surahName: 'Al-Fatihah'),
    );

    expect(service.quranBookmarksIn(2).map((b) => b.ayah), [3, 45, 200]);
    expect(service.quranBookmarksIn(3), isEmpty);
  });

  test('quranOpenAyah prefers an explicit request over the saved spot', () {
    expect(quranOpenAyah(requestedAyah: 7, savedAyah: 50), 7);
    expect(quranOpenAyah(savedAyah: 50), 50);
    expect(quranOpenAyah(), isNull);
    expect(quranOpenAyah(requestedAyah: 0, savedAyah: 3), 3);
  });

  group('reading notes', () {
    final ayah = Bookmark.quran(
      surahId: 2,
      ayah: 255,
      surahName: 'Al-Baqarah',
      snippet: 'Allah—there is no god except Him',
    );
    final hadith = Bookmark.hadith(
      collectionId: 'forties',
      bookFile: 'nawawi40.json',
      bookTitle: 'Nawawi 40',
      hadithIndex: 0,
      idInBook: 1,
    );

    test('saves, trims, reloads, and lists newest first', () async {
      SharedPreferences.setMockInitialValues({});
      final service = BookmarkService();
      await service.load();
      await service.saveNote(target: ayah, text: '  Before sleep  ');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await service.saveNote(target: hadith, text: 'Intentions first');

      final reloaded = BookmarkService();
      await reloaded.load();
      expect(reloaded.noteFor('quran:2:255')?.text, 'Before sleep');
      expect(reloaded.noteFor(hadith.id)?.target.bookTitle, 'Nawawi 40');
      expect(reloaded.notes.map((n) => n.id), [hadith.id, 'quran:2:255']);
      expect(
        reloaded.noteFor('quran:2:255')?.target.snippet,
        isNull,
        reason: 'the ayah text is not copied into the note',
      );
    });

    test('blank text deletes; restore puts it back', () async {
      SharedPreferences.setMockInitialValues({});
      final service = BookmarkService();
      await service.load();
      await service.saveNote(target: ayah, text: 'Keep');
      final note = service.noteFor(ayah.id)!;

      await service.saveNote(target: ayah, text: '   ');
      expect(service.noteFor(ayah.id), isNull);

      await service.restoreNote(note);
      expect(service.noteFor(ayah.id)?.text, 'Keep');
      await service.deleteNote(ayah.id);
      expect(service.notes, isEmpty);
    });

    test('skips corrupt note rows', () async {
      SharedPreferences.setMockInitialValues({
        'reading_notes':
            '[{"type":"quran","surahId":1,"ayah":1,"surahName":"Al-Fatihah",'
            '"createdAt":"2024-01-01T00:00:00.000","text":"ok",'
            '"updatedAt":"2024-01-02T00:00:00.000"},'
            '{"type":"quran","surahId":1,"ayah":2,"surahName":"Al-Fatihah",'
            '"createdAt":"2024-01-01T00:00:00.000","text":"  ",'
            '"updatedAt":"2024-01-02T00:00:00.000"},'
            '{"type":"hadith","collectionId":"x","bookTitle":"X",'
            '"createdAt":"2024-01-01T00:00:00.000","text":"no book",'
            '"updatedAt":"2024-01-02T00:00:00.000"},'
            '"oops"]',
      });
      final service = BookmarkService();
      await service.load();
      expect(service.notes.map((n) => n.id), ['quran:1:1']);
    });
  });
}
