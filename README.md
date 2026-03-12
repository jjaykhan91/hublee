# Hublee

A cross-platform Flutter app for reading the Quran and Hadith. Offline-first, with V4 font-based tajweed, plain-English word-by-word translation, and bookmarks.

## Getting started

- **Flutter**: Install [Flutter](https://docs.flutter.dev/get-started/install) (3.4+).
- **Run**: `flutter pub get` then `flutter run`.
- **V4 tajweed**: Download the [V4 script](https://qul.tarteel.ai/resources/quran-script/47) (Save as `assets/quran/qpc-v4.json`) and run `dart run tools/download_v4_tajweed.dart` for fonts. See [docs/V4_TAJWEED_SOURCES.md](docs/V4_TAJWEED_SOURCES.md).
- **Word-by-word**: Add `assets/quran/english-wbw-translation.json` (keys like `2:2:6`). The reader shows one floating translation bar that updates to the selected word.

## Project layout

- `lib/` — app code (UI, Quran/Hadith repos, services, theme).
- `assets/quran/` — Quran text, translations, V4 script; `assets/hadith/` — hadith collections.
- `tools/` — scripts (e.g. download V4 fonts).
- `docs/` — architecture and V4 data sources.

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers, navigation, theming.
- [docs/V4_TAJWEED_SOURCES.md](docs/V4_TAJWEED_SOURCES.md) — where to get V4 script and fonts.
