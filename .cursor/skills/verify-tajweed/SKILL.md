---
name: verify-tajweed
description: Verify Quran tajweed colouring against quran.com's reference markup before accepting a change. Use when changing tajweed rules, tajweed colours, the clustering or span engine in lib/ui/widgets/tajweed.dart, or when a letter appears to be coloured incorrectly.
---

# Verify tajweed colouring

Tajweed colouring is a correctness-critical feature: a wrong colour teaches a user to
recite incorrectly. Treat quran.com's Madani mushaf markup as the source of truth, never
your own reasoning about the rule.

## The reference

Quran.com's API returns per-letter tajweed markup as CSS class names:

```
https://api.quran.com/api/v4/quran/verses/uthmani_tajweed?chapter_number=2
```

The class-to-colour mapping used by this project:

| quran.com class | Colour | Constant |
|---|---|---|
| `ham_wasl`, `slnt`, `laam_shamsiyah`, `idgham_wo_ghunnah` | Grey | `kNotPronouncedColor(brightness)` |
| `madda_normal` | Pink | `kNormalMaadColor` |
| `madda_permissible` | Orange | `kMaadSukoonColor` |
| `madda_obligatory` | Dark pink | `kMaadConnectedColor` |
| `madda_necessary` | Red | `kMaadLongColor` |
| `ghunnah`, `ikhafa`, `idgham_ghunnah`, `iqlab` | Green | `kGhunnahColor` |
| `qalaqah` | Cyan | `kQalqalaColor` |
| (tafkhim — not a quran.com class) | Dark blue | `kTafkhimColor` |

Two-part rules (idgham, iqlab, ikhfa) colour **both** the source letter and the
receiving letter. Check both when verifying.

## Procedure

### 1. Establish the baseline

```bash
flutter test test/tajweed_baqarah_test.dart
```

All 107 tests must pass **before** you change anything. If they don't, fix that first —
you cannot tell a regression from a pre-existing failure otherwise.

### 2. Inspect the current output for the text in question

```bash
dart run tools/audit_baqarah_2_5.dart   # coloured cluster dump for 2:1–2:5
dart run tools/test_tajweed.dart        # targeted rule assertions
```

Use `tajweedColorAssignments(text)` for anything ad hoc — it returns
`List<TajweedClusterResult>` with `base`, `text`, `isLetter`, and `color`, and needs no
`BuildContext`.

### 3. Compare letter by letter against quran.com

Fetch the verse from the API and align the two, letter by letter. Do not spot-check —
a rule change usually shifts more positions than you expect, especially the receiving
letter of a two-part rule and the letter at the end of an ayah (waqf changes it).

### 4. Make the change

Constraints that must hold:

- **Never use `WidgetSpan`.** Each inline widget is shaped independently, which breaks
  Arabic cursive joining. Every span must be a `TextSpan` so the paragraph shaper can
  join letters across span boundaries. There is a test that enforces this.
- **Never drop characters.** U+0653 (maddah) and U+06DF (small high rounded zero) stay
  in the text and are rendered by the font. Tests assert their counts are preserved.
- **Never strip diacritics** to simplify detection.
- Keep the distinction between an *explicit* sukun (U+0652 / U+06E1) and a bare
  unmarked letter. `_hasExplicitSukun()` exists because a bare letter must not count as
  sakin for madd detection.
- Alef-wasla (U+0671) is not a maad letter and is skipped when looking at what follows a
  maad letter, because it is silent in continuous reading.

### 5. Add or update tests

Every rule change needs assertions in `test/tajweed_baqarah_test.dart`, in the group for
the affected verse:

```dart
test('ن (noon sakin before ف) — green (ikhafa)', () {
  expect(letters[31].color, _green);
});
```

Also update the "Colour summary counts" group for that verse — the per-colour totals are
what catch a change that fixes one letter and breaks another.

If the rule isn't exercised by 2:1–5, add a new group for a verse that does exercise it,
and cite the quran.com classes for it in a comment above the group, matching the
existing style.

### 6. Confirm

```bash
dart format lib test tools
flutter analyze
flutter test
```

Then render it. Colour assignment being correct in a unit test does not mean the text
renders correctly — open the surah reader and confirm the letters still join, the
diacritics are not clipped, and the colours are legible in **both** light and dark
themes. Regenerate the goldens if `ArabicText` rendering changed:

```bash
flutter test --update-goldens
```

## Also update

- `.cursor/rules/quran-guidelines.mdc` — the "Tajweed Coloring" section lists the
  implemented rules. Keep it in sync.
- `.cursor/rules/theming.mdc` — the colour table, if a colour constant changed.
- The tajweed legend in the surah reader and `tajweed_guide_page.dart`, plus
  `quran_reading_guide_sheet.dart`, if a rule was added or renamed.
