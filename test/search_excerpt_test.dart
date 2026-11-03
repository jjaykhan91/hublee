/// Tests that search snippets are cut at word boundaries.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/search_match.dart';

String _excerptFor(String text, String query) =>
    searchExcerpt(text, text.indexOf(query), query.length);

void main() {
  const ayah =
      'Allah does not require of any soul more than what it can afford. '
      'All good will be for its own benefit, and all evil will be to its own '
      'loss. Pardon us, forgive us, and have mercy on us. You are our only '
      'Guardian. So grant us victory over the disbelieving people.';

  test('never starts or ends inside a word', () {
    final excerpt = _excerptFor(ayah, 'mercy');

    expect(excerpt, startsWith('…'));
    expect(excerpt, endsWith('…'));
    final words = excerpt.replaceAll('…', '').trim().split(' ');
    for (final word in [words.first, words.last]) {
      expect(ayah.split(RegExp(r'\s+')), contains(word));
    }
    expect(excerpt, contains('mercy'));
  });

  test('drops punctuation left at the cut', () {
    const text =
        'Then you turned away after that, and were it not for this. '
        'Had it not been for Allah’s grace and mercy upon you.';
    final excerpt = searchExcerpt(text, text.indexOf('mercy'), 5, before: 47);

    expect(excerpt, isNot(startsWith('….')));
    expect(excerpt, isNot(startsWith('… ')));
  });

  test('short text is returned whole without ellipses', () {
    expect(_excerptFor('Have mercy on us.', 'mercy'), 'Have mercy on us.');
  });
}
