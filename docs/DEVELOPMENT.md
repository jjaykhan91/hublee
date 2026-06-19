# Local development

How to open, load, run, and test Hublee on a developer machine. The app is **offline-first** — no backend, database, or `.env` file is required for normal development.

## First-time machine setup

### 1. Install Flutter

- [Flutter install guide (Windows)](https://docs.flutter.dev/get-started/install/windows)
- SDK requirement: **Dart 3.4+** (see `pubspec.yaml`)
- On this machine Flutter lives at `%USERPROFILE%\flutter` (e.g. `C:\Users\MightK\flutter`)

Add Flutter to your user PATH so `flutter` works in every terminal:

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  "$env:USERPROFILE\flutter\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"),
  "User"
)
```

Restart the terminal (or Cursor) after changing PATH.

Verify:

```powershell
flutter --version
flutter doctor
```

### 2. Enable Windows Developer Mode

Flutter plugins need **symlink support** on Windows. Without it, `flutter pub get` may warn:

> Building with plugins requires symlink support.

Enable: **Settings → System → For developers → Developer Mode**

Or open settings directly:

```powershell
start ms-settings:developers
```

### 3. Optional run targets

| Target | Command | Extra install |
|--------|---------|---------------|
| **Chrome (recommended)** | `flutter run -d chrome` | Google Chrome |
| **Windows desktop** | `flutter run -d windows` | [Visual Studio](https://visualstudio.microsoft.com/downloads/) with **Desktop development with C++** |
| **Android** | `flutter run` (with device/emulator) | Android Studio, SDK, accepted licenses (`flutter doctor --android-licenses`) |

For day-to-day UI work, **Chrome is the fastest path** — no Visual Studio or emulator required.

## Opening the project

### Cursor / VS Code

1. **File → Open Folder** → select the repo root (`hublee/`)
2. Install the [**Dart**](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code) extension (includes Flutter support)
3. The workspace already points at the Flutter SDK via `.vscode/settings.json`:

   ```json
   "dart.flutterSdkPath": "C:\\Users\\MightK\\flutter"
   ```

   If Flutter is installed elsewhere on a new machine, update this path or remove the key and rely on PATH.

4. Wait for Dart analysis to finish (status bar). The project should resolve `package:hublee/...` imports without errors.

### Run configurations

Pre-defined launch configs in `.vscode/launch.json`:

- **Hublee (Chrome)** — default for local dev
- **Hublee (Windows)** — native desktop (needs Visual Studio)

Use **Run and Debug** (F5) and pick a configuration from the dropdown.

## Loading dependencies (every clone / fresh checkout)

From the repo root:

```powershell
.\scripts\setup.ps1
```

This script:

1. Prepends `%USERPROFILE%\flutter\bin` to PATH for the session
2. Warns if Developer Mode is off
3. Runs `flutter pub get`
4. Runs `flutter test`
5. Prints `flutter doctor`

Manual equivalent:

```powershell
cd path\to\hublee
$env:Path = "$env:USERPROFILE\flutter\bin;" + $env:Path
flutter pub get
```

You only need `flutter pub get` again when `pubspec.yaml` or `pubspec.lock` changes.

## Running the app

```powershell
# Web (recommended)
flutter run -d chrome

# Fixed port (useful when testing deep links / bookmarks)
flutter run -d chrome --web-port=7357

# Windows desktop
flutter run -d windows

# List devices
flutter devices
```

While running: **r** = hot reload, **R** = hot restart, **q** = quit.

### Release build (sanity check)

```powershell
flutter build web
# Output: build/web/
```

## Testing & analysis

```powershell
flutter test                  # unit tests (router paths, tajweed engine)
flutter analyze               # static analysis
dart format lib test          # format before committing
```

Key test files:

- `test/tajweed_baqarah_test.dart` — tajweed colours vs quran.com for Al-Baqarah 2:1–5
- `test/router_paths_test.dart` — typed `AppRoute` paths

## Project layout (quick reference)

```
hublee/
├── lib/
│   ├── main.dart              # App entry
│   ├── router.dart            # go_router routes
│   ├── router_paths.dart      # AppRoute — use for all navigation
│   ├── ui/                    # Pages and widgets
│   ├── services/              # Settings, bookmarks, search, daily content
│   ├── quran/                 # Quran repositories & models
│   ├── hadith/                # Hadith repository & models
│   ├── data/asset_paths.dart  # Asset path helpers
│   └── theme/                 # Light/dark themes, design tokens
├── assets/
│   ├── quran/                 # Arabic text, translations, metadata
│   ├── hadith/                # Collection JSON files
│   ├── fonts/                 # KFGQPC + surah name fonts
│   └── images/
├── tools/                     # Build-time data scripts (not runtime)
├── test/
├── scripts/setup.ps1          # First-load helper
└── docs/
    ├── DEVELOPMENT.md         # This file
    └── ARCHITECTURE.md        # Layer boundaries & conventions
```

## Data & credentials

**Running the app:** all Quran and Hadith content is bundled under `assets/`. No network calls at runtime.

**Regenerating data** (optional, only when updating bundled JSON):

1. Copy `.env.example` → `.env`
2. Add [Quran Foundation](https://quran.foundation) API credentials
3. Run scripts in `tools/` (e.g. `dart run tools/build_arabic_and_chapters.dart`)

See `.env.example` for variable names. `.env` is gitignored.

## Fonts

Bundled in `assets/fonts/`:

- `KFGQPCQuranicFontHafsSmart_08.ttf` — PUA Quranic glyphs (default Uthmanic font)
- `surah-name-v4.ttf` — calligraphic surah names (download instructions in `assets/fonts/README.md`)

Both are registered in `pubspec.yaml`. If missing after clone, check LFS or re-download per `assets/fonts/README.md`.

## Troubleshooting

### `flutter` / `dart` not recognized

Flutter is not on PATH. Either add `%USERPROFILE%\flutter\bin` permanently (see above) or prefix each session:

```powershell
$env:Path = "$env:USERPROFILE\flutter\bin;" + $env:Path
```

### Symlink / Developer Mode warning on `pub get`

Enable Developer Mode (see [§2](#2-enable-windows-developer-mode)). Then re-run `flutter pub get`.

### Dart extension cannot find Flutter SDK

Update `dart.flutterSdkPath` in `.vscode/settings.json` to your local Flutter install, or ensure Flutter is on PATH and remove that setting.

### `flutter run -d windows` fails — Visual Studio not found

Install Visual Studio with the **Desktop development with C++** workload, then run `flutter doctor` again.

### Android licenses / cmdline-tools

```powershell
flutter doctor --android-licenses
```

Install missing SDK components via Android Studio → SDK Manager.

### Web build errors after theme changes

`CupertinoPageTransitionsBuilder` requires `package:flutter/cupertino.dart` in `lib/theme/app_theme.dart`. Material-only imports are not enough.

### Hot reload not picking up asset changes

Stop the app and run again, or run `flutter clean` then `flutter pub get` if assets were added/renamed in `pubspec.yaml`.

## GitHub

Account: **jjaykhan91** · email: **jjaykhan91@gmail.com** · repo: [github.com/jjaykhan91/hublee](https://github.com/jjaykhan91/hublee)

One-time setup (git identity, SSH, `gh` login):

```powershell
.\scripts\configure-github.ps1
```

Full details, manual steps, and troubleshooting: **[GITHUB.md](GITHUB.md)**

## Further reading

- [GITHUB.md](GITHUB.md) — GitHub CLI, SSH, push/PR workflow
- [ARCHITECTURE.md](ARCHITECTURE.md) — layers, navigation, how to add pages
- [.cursor/rules/](../.cursor/rules/) — UI patterns, Quran/Hadith display rules, theming
- [Flutter docs](https://docs.flutter.dev/)
