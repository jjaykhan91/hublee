/// Tests for the Modern Standard Arabic dictionary.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/arabic/grammar_course.dart';
import 'package:hublee/services/msa_dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(MsaDictionaryService.resetCache);

  test('English newspaper lookup returns Arabic', () async {
    const service = MsaDictionaryService();
    final hits = await service.search('newspaper');
    expect(hits, isNotEmpty);
    expect(hits.first.english.toLowerCase(), contains('newspaper'));
    expect(hits.first.arabic, isNotEmpty);
  });

  test('computer and water resolve', () async {
    const service = MsaDictionaryService();
    expect(await service.search('computer'), isNotEmpty);
    expect(await service.search('water'), isNotEmpty);
  });

  test('grammar course has roots and forms lessons', () {
    expect(grammarLessonById('roots'), isNotNull);
    expect(grammarLessonById('forms'), isNotNull);
    expect(grammarCourse, isNotEmpty);
  });
}
