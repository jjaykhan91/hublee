# Google Play listing (Hublee)

The Android application id is **`com.hublee.app`**. Do not change it after the first Play upload.

Release signing uses `android/key.properties` and `android/upload-keystore.jks`. Those files are gitignored. **Back them up** (password manager + offline copy). Losing the upload key means you cannot ship updates under this listing.

## Build the upload

```powershell
flutter build appbundle --release
```

File: `build\app\outputs\bundle\release\app-release.aab`

Play accepts an **AAB**, not the APK you sideload for personal testing.

## Create the app

1. Open [Google Play Console](https://play.google.com/console) with the developer account ($25 one-time).
2. **Create app** → name **Hublee** → default language → **App** → free or paid.
3. Accept the declarations.

## Store listing (paste)

**Short description** (max 80 characters):

```
Offline Quran and Hadith reader. Tajweed, word-by-word, optional recitation.
```

**Full description:**

```
Hublee is an offline Quran and Hadith reader. The Arabic text, English translation (ClearQuran), and Hadith collections are bundled in the app. There is no account, no ads, and no tracking SDK.

Read with tajweed colouring and optional word-by-word English. Search Quran and Hadith on the device. Bookmark ayahs and hadiths. A Learn tab includes a Quranic glossary and Modern Arabic study cards.

Recitation is optional and not bundled. Choose a Hafs reciter from the play control on any ayah. Stream over the network, or download a surah (or the full Quran for that reciter) to this device for offline playback.

Sources: ClearQuran; KFGQPC Hafs and Uthmani Arabic; word-by-word glossary by Dr. Shehnaz Shaikh and Ms. Kausar Khatri; recitation from Quran.com CDN and EveryAyah.
```

**Privacy policy URL** (must be a public page, not only in-app):

After this file is on `master`:

`https://github.com/jjaykhan91/hublee/blob/master/docs/privacy-policy.md`

**Graphics:** Play icon 512×512 PNG (use `assets/images/HubleeAppLogo.png` exported at that size), feature graphic 1024×500, at least two phone screenshots (you take those on a device or emulator).

**App category:** Books & Reference (or Lifestyle). **Tags:** books, islam, education as they fit.

## App content questionnaires

- **Ads:** No.
- **Target audience:** not primarily children. Age 13+ or “18 and up” if you prefer not to complete the Designed for Families flow. This is a religious text app, not a kids’ product.
- **News app / COVID / government:** No.
- **Data safety:** see below.
- **Content rating:** complete the IARC questionnaire. Hublee is a religious reader (no violence, no user-generated chat).

## Data safety (answer from the code)

Hublee has **no backend**. Declare only what the APK actually does.

| Question | Answer |
|---|---|
| Collects user data? | **No** collection to the developer. Optional network for recitation only. |
| Account / name / email / location | **Not collected** |
| Analytics / advertising / crash SDK | **Not collected** (no Firebase, no ads) |
| Approximate location | **No** |
| App activity (search, bookmarks) | Stays **on device**; not sent to us |
| Files / audio on device | User-initiated **downloaded ayah MP3s** in app-private storage |
| Encryption in transit | Recitation uses **HTTPS** |
| Users can request deletion | N/A — we never receive an account or cloud copy |
| Data shared with third parties | Recitation hosts receive a normal HTTPS request for an MP3 when the user plays or downloads. We do not sell data. |
| Permissions | `INTERNET` (recitation). No microphone, camera, contacts, or SMS. |

If Play’s form forces a “collected” row for files: **App functionality**, **ephemeral / on-device**, not sold, not optional-account.

## Release track

1. **Testing → Internal testing** → create a release → upload `app-release.aab` → add your Gmail as a tester → install from the opt-in link (or Play Console’s install).
2. When that build is healthy, **Promote** to Production (or create a Production release with the same AAB).

First production review is often a few days. Fix any policy email before resubmitting.

## After each update

1. Bump `version:` in `pubspec.yaml` (name + **+build**, e.g. `1.0.1+2`).
2. `flutter build appbundle --release`
3. New Play release with the new AAB.

## If `flutter build appbundle` complains about debug symbols

Gradle may still have written `build\app\outputs\bundle\release\app-release.aab`. Flutter’s post-check needs Android **cmdline-tools** (`apkanalyzer`). Install them in Android Studio: **SDK Manager → SDK Tools → Android SDK Command-line Tools**, then `flutter doctor` until the Android toolchain is clean.
