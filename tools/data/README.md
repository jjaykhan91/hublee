# Build-time source data

Files here are **inputs to `tools/` scripts**, not app assets. They are not
listed in `pubspec.yaml` and never ship in the app bundle.

They are committed rather than downloaded on demand so that regenerating a
Qur'anic asset is reproducible offline and produces byte-identical output. For
sacred text that matters more than the few megabytes.

## `english-wbw-translation.json`

Flat map of `"surah:ayah:word"` to an English gloss, 83,665 entries covering all
6,236 ayahs.

- **Provenance:** derived from _The Glorious Qur'an: Word-for-Word Translation
  to Facilitate Learning of Qur'anic Arabic_ (2007) compiled by
  Dr. Shehnaz Shaikh and Ms. Kausar Khatri, as distributed by the Quranic
  Arabic Corpus and the Quranic Universal Library (QUL).
- **Attributed in-app** under Settings → About → Sources.

Two quirks of the source, both handled by `tools/build_word_by_word.dart`:

1. The **last word position of every ayah is the ayah-number marker**, e.g.
   `"1:1:5"` is `"(1)"`. It is dropped, not glossed.
2. A **blank gloss is intentional**. Where the source glosses two Arabic words
   together — بَعْدَ مَا rendered once as "after what" — the second word's slot is
   empty. These are kept as empty strings, which the app reads as "this word
   continues the previous gloss" and highlights as one phrase.

### Regenerating the assets

```bash
dart run tools/build_word_by_word.dart
```

Writes `assets/quran/en.wordbyword/1.json` … `114.json`, one gloss array per
ayah. The script **fails rather than emitting misaligned data** if any ayah's
word count stops matching its gloss count, so a future data refresh cannot
silently attach the wrong meaning to a word. `test/word_by_word_test.dart`
re-checks the same invariant for all 6,236 ayahs on both the plain and the
tajweed rendering path.
