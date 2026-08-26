# Hublee architecture

This document describes the main layers and conventions so the app stays easy to maintain and scale.

> **Getting the project running locally?** See [DEVELOPMENT.md](DEVELOPMENT.md) for Flutter setup, opening the repo in Cursor/VS Code, `flutter pub get`, run targets, and troubleshooting.

## Layers

- **UI** (`lib/ui/`): Pages and widgets only. No direct `rootBundle` or `SharedPreferences` usage. Navigation uses the typed [AppRoute](lib/router_paths.dart) API.
- **Services** (`lib/services/`): Application logic, state (e.g. `SettingsController`, `BookmarkService`), and orchestration (e.g. `QuranSearchService`, `HadithSearchService`, `DailyContentService`). They call into repositories and persist via `SharedPreferences` where needed.
- **Data** (`lib/quran/`, `lib/hadith/`, `lib/guidance/`, `lib/data/`): Repositories load and parse JSON assets; paths come from [AssetPaths](lib/data/asset_paths.dart). Models live next to their repositories.

## Navigation

All route paths are built via [AppRoute](lib/router_paths.dart). Use `AppRoute.surah(id, ayah: n)`, `AppRoute.hadithBook(...)`, `AppRoute.search`, etc., and pass the result to `context.go(...)` or `context.push(...)`. Do not hard-code path strings.

## Theming and design tokens

- Colours and base theme: [app_theme.dart](lib/theme/app_theme.dart).
- Layout and shadows: [app_tokens.dart](lib/theme/app_tokens.dart) — use `AppRadius`, `AppSpacing`, and `AppShadows` instead of inline values so changes apply from a single place.

## Shared UI

- [HubleeCard](lib/ui/widgets/hublee_card.dart): Standard card with optional tap and consistent padding.
- [SectionHeader](lib/ui/widgets/section_header.dart): Section titles with optional icon.
- [GradientTile](lib/ui/widgets/gradient_tile.dart): Explore-style tiles on the home page.

## Scopes and state

- `AppScope`: Theme toggle and app-level state.
- `SettingsScope`: Font zoom, tajweed, Arabic font — provided by `SettingsController`.
- `BookmarkScope`: Bookmarks and last-read positions — provided by `BookmarkService`.

Access via `XxxScope.of(context)`; do not pass controllers deep down by hand.

## Caching

Heavy assets are parsed **once per session** and held in static repository caches:

| Data | Source | Cache |
|------|--------|--------|
| Chapter list | `chapters.min.json` + `surah_metadata.json` + name files | `QuranChaptersRepository` static future |
| PUA / Imla'i ayahs | `KFGQPCQuranMushaf_smart_v8.json` | Shared mushaf-row future + per-surah maps in `QuranArabicRepository` |
| Standard Uthmanic | `assets/quran/ar/{id}.json` | Per-surah map cache in `QuranArabicRepository` |
| Surah info | `surah_info.json` | `SurahInfoRepository` static list |
| Word-by-word glosses | `assets/quran/en.wordbyword/{id}.json` | Per-surah future cache in `WordByWordRepository` |
| Allah / Prophet / duas | `assets/guidance/*.json` | `GuidanceRepository` static futures |
| Everyday dhikr | `lib/guidance/everyday_dhikr.dart` | Sync catalog; `DailyContentService.dhikrOfTheDay()` |
| Tajweed colours | rule engine in `tajweed.dart` | LRU (~300) of assignments keyed by `(brightness, text)` |

**Search** indexes `aya_text_emlaey` (`useGlyphText: false`), never PUA `aya_text`. Display still uses PUA or standard Uthmanic as before.

**Settings:** zoom sliders call `notifyListeners` immediately for live preview; `SharedPreferences` writes are debounced (~300 ms) and flushed on `dispose`.

**Bookmarks:** `isBookmarked` is O(1) via a `Set` kept in sync with the list. Per-surah Quran pins (`quran_pins`) are a separate resume marker: at most one ayah per surah.

## Word-by-word glossing

Tapping a word in the surah reader reveals its English meaning. The design
constraint is that this must **coexist with tajweed** rather than replace it, so
a selected word is marked with a background tint and every letter keeps its
tajweed colour.

The hard part is agreeing on what a "word" is. Three things disagree by default:
the gloss data numbers words from 1 and counts the ayah-number marker as a
word; quran.com's Uthmani text emits waqf signs and rosettes as standalone
tokens; and the tajweed engine strips presentation-only marks before analysis.

Rather than reconcile that per frame, alignment is settled once:

| Piece | Responsibility |
|---|---|
| `lib/quran/arabic_word_segmenter.dart` | The single definition of a word. Folds annotation-only tokens into a neighbour so no character is lost, and returns ranges that **tile the string** so any offset maps to exactly one word. |
| `tools/build_word_by_word.dart` | Runs that segmenter over all 6,236 ayahs and emits one gloss per word. Exits non-zero instead of shipping misaligned data. |
| `WordByWordRepository` | Loads a surah's glosses (~1 MB total across 114 files, so only the open surah is decoded) and resolves phrases via `glossPhraseAt`. |
| `WordByWordArabicText` | Segments the exact string being drawn — for the tajweed path, the one reconstructed from the engine's clusters — then maps clusters to words by offset. Recognizers live in `State` and are disposed. |

Two safety nets: the widget renders **untappable text** if gloss and word
counts ever disagree, because mislabelling a Qur'anic word is worse than not
offering the feature; and `test/word_by_word_test.dart` re-verifies the
alignment for every ayah on both rendering paths.

An empty gloss means "this word continues the previous phrase" (بَعْدَ مَا →
"after what"), and such words highlight together as one phrase.

Word-by-word requires standard Uthmani text, so enabling it opts out of the PUA
glyph column exactly as tajweed already does.

## Adding a new page

1. Create the page under `lib/ui/`.
2. Add the route in [router.dart](lib/router.dart) and a path helper in [router_paths.dart](lib/router_paths.dart) if needed.
3. Use `AppRoute` for any navigation to the new page.
4. Use design tokens and shared widgets where they fit.

## Android home-screen widgets

Four native launcher widgets (ayah, hadith, Quran word, MSA word) live in `android/app/src/main/kotlin/com/hublee/app/widgets/`. Dart writes today's strings and look into `home_widget` prefs via [HomeWidgetSync](lib/services/home_widget_sync.dart); Kotlin `RemoteViews` paint them. Looks are stored per kind in [WidgetLookStore](lib/services/widget_look.dart). Widgets are Android-only; other platforms show the Settings page with an explanation. Pin and look UI is [HomeWidgetsPage](lib/ui/home_widgets_page.dart) at `AppRoute.homeWidgets`.

## Adding a new hadith collection

1. Add assets under `assets/hadith/<collectionId>/` and register them in `pubspec.yaml`.
2. Ensure the collection is listed in the hadith manifest/index used by [HadithRepository](lib/hadith/hadith_repository.dart). Search and listing will pick it up via existing services.
