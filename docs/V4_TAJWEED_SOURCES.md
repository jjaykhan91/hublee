# QPC V4 font-based tajweed — sources and status

## Status: not implemented

Hublee colours tajweed **in software**, via the rule engine in
`lib/ui/widgets/tajweed.dart`. There is no font-based tajweed in the app today.

This document exists because the alternative was explored on the
`TajweedWordbyWord/New` branch and the source information is genuinely hard to
rediscover. The branch has been retired; its full tree is preserved under the
tag [`archive/tajweed-wbw-v4`](#recovering-the-original-work).

## What the V4 approach is

quran.com renders tajweed by shipping **one font per mushaf page** (604 fonts)
whose glyphs are pre-coloured, paired with a script JSON that maps each word to
the right Private Use Area codepoints. Colouring becomes a typography concern
rather than a text-analysis one.

## Where the data actually comes from

The single most useful fact here, and the easiest to get wrong:

> The GitHub repo **`TarteelAI/quranic-universal-library` is the QUL backend/CMS
> — it is _not_ where the script or the fonts are downloaded from.** The data
> comes from the QUL website and Tarteel's CDN.

| Asset | Source |
|---|---|
| V4 script JSON | <https://qul.tarteel.ai/resources/quran-script/47> — "Download json", saved as `assets/quran/qpc-v4.json` |
| Page fonts `p1.ttf`–`p604.ttf` | `https://static-cdn.tarteel.ai/qul/fonts/quran_fonts/v4-tajweed/ttf` |

`tools/download_v4_tajweed.dart` automates the font download and prints the
manual steps for the script. It is kept in the repo purely so this option stays
open; nothing in the app calls it.

## Why it was not adopted

- **Bundle size.** The 604 fonts are **≈159 MB**, against roughly 1 MB for all
  currently bundled Arabic faces. That is a product decision about app size, not
  a technical blocker.
- **It replaces rather than complements.** The branch deleted the software
  tajweed engine and its 102 verified colour tests. The engine is checked
  letter-by-letter against quran.com's `uthmani_tajweed` API for 2:1–5.
- **It conflicts with word-by-word.** Word-by-word glosses are aligned against
  standard Uthmani text; V4 glyph text is PUA and segments differently (it
  aligned on 6,231 of 6,236 ayahs versus 6,235 for standard Uthmani).

## If it is revisited

Font-based tajweed and the software engine can coexist as a user preference, but
two things must hold:

1. **Do not delete the software engine.** It is the fallback for any font that
   is not bundled, and its tests are the only automated proof the colouring is
   correct.
2. **Gate rendering on font load.** The branch registered the page fonts
   fire-and-forget, so the reader could request a family before it existed and
   draw blank glyphs.

Also consider shipping the fonts as a downloadable pack rather than in the
bundle, which is what makes the 159 MB tolerable.

## Recovering the original work

```bash
git show archive/tajweed-wbw-v4:lib/quran/quran_v4_tajweed_repository.dart
git show archive/tajweed-wbw-v4:lib/services/qpc_v4_font_loader.dart
git checkout archive/tajweed-wbw-v4 -- assets/quran/qpc-v4.json
```
