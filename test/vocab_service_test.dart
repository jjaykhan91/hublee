/// Tests for [VocabService].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/services/vocab_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('toggle saves and removes the same word from different ayahs', () async {
    final service = VocabService();
    await service.load();

    final first = VocabEntry.fromReader(
      arabic: 'ٱللَّهِ',
      gloss: '(of) Allah',
      surahId: 1,
      ayah: 1,
      surahName: 'Al-Fatihah',
    );
    await service.toggle(first);
    expect(service.entries, hasLength(1));

    final again = VocabEntry.fromReader(
      arabic: 'ٱللَّهِ',
      gloss: '(of) Allah',
      surahId: 1,
      ayah: 2,
      surahName: 'Al-Fatihah',
    );
    expect(again.id, first.id);
    await service.toggle(again);
    expect(service.entries, isEmpty);
  });
}
