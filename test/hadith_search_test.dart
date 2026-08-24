/// Tests that hadith search exposes catalog [Hadith.idInBook].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/hadith/hadith_repository.dart';
import 'package:hublee/services/search_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(HadithRepository.resetCache);

  test('Nawawi search tiles carry idInBook', () async {
    final result = await const HadithRepository().searchHadith(
      'niyyah',
      limit: 10,
    );
    expect(result.hits, isNotEmpty);
    final nawawi = result.hits.where((hit) => hit.bookFile == 'nawawi40.json');
    expect(nawawi, isNotEmpty);
    expect(nawawi.first.idInBook, isNotNull);
    expect(nawawi.first.numberLabel, startsWith('#'));
  });

  test('numberLabel falls back to the 1-based index', () {
    const hit = HadithSearchHit(
      collectionId: 'forties',
      bookFile: 'nawawi40.json',
      hadithIndex: 3,
    );
    expect(hit.numberLabel, 'Hadith 4');
  });
}
