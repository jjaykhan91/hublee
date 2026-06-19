# Hublee

Offline-first Flutter app for reading the Quran and Hadith.

## Quick start

**New machine or fresh clone:**

```powershell
cd hublee
.\scripts\setup.ps1
flutter run -d chrome
```

**In Cursor / VS Code:** open this folder → install the **Dart** extension → **Run → Hublee (Chrome)** (F5).

Full setup, troubleshooting, and daily workflow: **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**

**GitHub (push/pull/PRs):** run `.\scripts\configure-github.ps1` once — see **[docs/GITHUB.md](docs/GITHUB.md)**

## Prerequisites (summary)

| Requirement | Required for |
|-------------|--------------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (Dart 3.4+) | Everything |
| **Developer Mode** (Windows) | `flutter pub get` / plugin symlinks |
| **Chrome** | `flutter run -d chrome` (easiest local target) |
| **Visual Studio** + C++ workload | `flutter run -d windows` only |
| **Android Studio** | Android emulator / device only |

Add Flutter to PATH (once per machine):

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  "$env:USERPROFILE\flutter\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"),
  "User"
)
```

Restart the terminal after updating PATH.

## Common commands

```powershell
flutter pub get          # after pubspec changes
flutter test             # unit tests
flutter run -d chrome    # run in browser
flutter analyze          # static analysis
dart format lib test     # format code
```

## Documentation

| Doc | Contents |
|-----|----------|
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Open project, load deps, run, test, troubleshoot |
| [docs/GITHUB.md](docs/GITHUB.md) | Git identity, SSH, `gh` CLI, push/PR workflow |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, navigation, adding pages & hadith collections |
| [.cursor/rules/](.cursor/rules/) | Quran/Hadith UI rules, theming, coding standards |
| [assets/fonts/README.md](assets/fonts/README.md) | Font files and re-download links |

## Runtime vs build tools

- **App runtime:** fully offline; all data in `assets/`. No `.env` needed.
- **Data regeneration:** optional `tools/` scripts use `.env` (see `.env.example`) and Quran Foundation API credentials.
