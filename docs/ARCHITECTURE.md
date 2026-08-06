# Hublee architecture

This document describes the main layers and conventions so the app stays easy to maintain and scale.

> **Getting the project running locally?** See [DEVELOPMENT.md](DEVELOPMENT.md) for Flutter setup, opening the repo in Cursor/VS Code, `flutter pub get`, run targets, and troubleshooting.

## Layers

- **UI** (`lib/ui/`): Pages and widgets only. No direct `rootBundle` or `SharedPreferences` usage. Navigation uses the typed [AppRoute](lib/router_paths.dart) API.
- **Services** (`lib/services/`): Application logic, state (e.g. `SettingsController`, `BookmarkService`), and orchestration (e.g. `QuranSearchService`, `HadithSearchService`, `DailyContentService`). They call into repositories and persist via `SharedPreferences` where needed.
- **Data** (`lib/quran/`, `lib/hadith/`, `lib/data/`): Repositories load and parse JSON assets; paths come from [AssetPaths](lib/data/asset_paths.dart). Models live next to their repositories.

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
| Tajweed colours | rule engine in `tajweed.dart` | LRU (~300) of assignments keyed by `(brightness, text)` |

**Search** indexes `aya_text_emlaey` (`useGlyphText: false`), never PUA `aya_text`. Display still uses PUA or standard Uthmanic as before.

**Settings:** zoom sliders call `notifyListeners` immediately for live preview; `SharedPreferences` writes are debounced (~300 ms) and flushed on `dispose`.

**Bookmarks:** `isBookmarked` is O(1) via a `Set` kept in sync with the list.

## Adding a new page

1. Create the page under `lib/ui/`.
2. Add the route in [router.dart](lib/router.dart) and a path helper in [router_paths.dart](lib/router_paths.dart) if needed.
3. Use `AppRoute` for any navigation to the new page.
4. Use design tokens and shared widgets where they fit.

## Adding a new hadith collection

1. Add assets under `assets/hadith/<collectionId>/` and register them in `pubspec.yaml`.
2. Ensure the collection is listed in the hadith manifest/index used by [HadithRepository](lib/hadith/hadith_repository.dart). Search and listing will pick it up via existing services.
