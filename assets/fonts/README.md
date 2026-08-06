# Fonts

All Arabic faces are bundled. Nothing is fetched at runtime, so Arabic rendering never
depends on the network or on a platform font. Family names are declared in
`pubspec.yaml` and referenced through `AppFonts` in `lib/theme/app_tokens.dart`.

## Mushaf and display

- **KFGQPCQuranicFontHafsSmart_08.ttf** – Quranic Arabic, **PUA glyphs only**. Renders
  the `aya_text` field from `KFGQPCQuranMushaf_smart_v8.json`. It has *no* glyphs for
  standard Arabic Unicode, which is why styles using it declare
  `AppFonts.arabicFallback`. See the `font coverage` group in
  `test/arabic_rendering_test.dart`, which pins this behaviour.
- **surah-name-v4.ttf** – [Tarteel QUL Surah name font v4](https://qul.tarteel.ai/resources/font/457).
  Ligature-based: `surah001`–`surah114` render calligraphic Arabic surah names. Used in
  the reader header when the title is on the Arabic step. Because it is ligature-based it
  is unreadable to screen readers — always pair it with a `Semantics` label.

  To re-download: open the link above → **Download ttf** → save as `surah-name-v4.ttf` here.

## Standard-Unicode Arabic (SIL OFL 1.1)

These render `assets/quran/ar/<surahId>.json` (standard Uthmanic with full tashkeel),
which the reader uses whenever tajweed is enabled, and which the tajweed engine parses.

| File | Family | Source |
|---|---|---|
| `Amiri-Regular.ttf` | `Amiri` | [google/fonts `ofl/amiri`](https://github.com/google/fonts/tree/main/ofl/amiri) |
| `ScheherazadeNew-Regular.ttf` | `ScheherazadeNew` | [google/fonts `ofl/scheherazadenew`](https://github.com/google/fonts/tree/main/ofl/scheherazadenew) |
| `NotoNaskhArabic-Regular.ttf` | `NotoNaskhArabic` | [notofonts NotoNaskhArabic](https://github.com/notofonts/notofonts.github.io/tree/main/fonts/NotoNaskhArabic/hinted/ttf) |

**Amiri** additionally backs `AppFonts.arabicFallback`, so it is the face that renders
standard Uthmanic text when the user has the mushaf font selected with tajweed on, and
the face that renders Qur'anic symbols (ﷺ, ۩) inside otherwise-Latin styles.

Licences are alongside the fonts as `OFL-Amiri.txt`, `OFL-ScheherazadeNew.txt`, and
`OFL-NotoNaskhArabic.txt`. All three are SIL Open Font License 1.1, which permits
bundling and redistribution with attribution.

Only the Regular weight of each is bundled. `ArabicText` requests `FontWeight.w600`, so
heavier text is synthesised; add the real `-Bold.ttf` from the same source if that
becomes visible.
