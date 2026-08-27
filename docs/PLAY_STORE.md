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

Read with tajweed colouring and optional word-by-word English. Search Quran and Hadith on the device. Bookmark ayahs and hadiths. A Learn tab includes a Quranic glossary and Modern Arabic study cards. On Android you can pin ayah of the day, hadith of the day, a Quranic word, or an Arabic word to the home screen.

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
| Permissions | `INTERNET` (recitation). Home-screen widgets add `RECEIVE_BOOT_COMPLETED` so today’s ayah/hadith can refresh when the app is closed. Foreground-service permissions from Workmanager are stripped; Hublee does not run a foreground service. No microphone, camera, contacts, or SMS. |

If Play’s form forces a “collected” row for files: **App functionality**, **ephemeral / on-device**, not sold, not optional-account.

## Release track

1. **Testing → Internal testing** → create a release → upload `app-release.aab` → add your Gmail as a tester → install from the opt-in link (or Play Console’s install).
2. When that build is healthy, **Promote** to Production (or create a Production release with the same AAB).

First production review is often a few days. Fix any policy email before resubmitting.

A **closed testing** release must contain **one** version code for a given device config. If Console says a bundle is “completely shadowed”, you uploaded two AABs (for example `1.0.0+1` and `1.0.1+2`) into the same release. Remove the lower version from **New app bundles** and keep only the newest. The same AAB can sit on Internal testing and Closed testing; you do not need both files in one release.

## Upload from the repo (Play API)

Play has no email/password API login. **Setup → API access** was removed from Play Console. Auth is a Google Cloud **service account** JSON that you invite under **Users and permissions**.

You must be the Play developer **account owner** (or have Admin) to invite users. Do this from the **account** home, not inside the Hublee app — click **All apps** first if the left nav only shows Test and release.

1. [Create a Google Cloud project](https://console.cloud.google.com/projectcreate) (name it e.g. `hublee-play`).
2. [Enable Google Play Android Developer API](https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com) on that project → **Enable**.
3. [Create a service account](https://console.cloud.google.com/iam-admin/serviceaccounts): **Create service account** → name `hublee-play` → **Create and continue** → skip Cloud roles → **Done**. Open it → **Keys** → **Add key** → **Create new key** → **JSON**. Save as `android/play-service-account.json` (gitignored). Copy `client_email` from the JSON (`…@….iam.gserviceaccount.com`).
4. [Play Console → Users and permissions](https://play.google.com/console/users-and-permissions) → **Invite new users**. Paste that email (not your Gmail). **App permissions** → **Add app** → Hublee. Enable **View app information (read-only)**, **Release apps to testing tracks**, and **Manage testing tracks and edit tester lists**. **Invite user**. Status becomes Active immediately (no email to accept).
5. Wait a few minutes, then run the upload command below.

Official walkthrough: [Getting started with the Google Play Developer API](https://developers.google.com/android-publisher/getting_started).

Then:

```powershell
flutter build appbundle --release
dart pub get -C tools/play_release
Set-Location tools/play_release
dart run bin/upload.dart --tracks internal,closed --notes "Your what's new text"
```

`closed` is the default closed-testing track (`alpha`). Use `--skip-upload --version-code 2` to attach a bundle that is already on Play. `--dry-run` prints the plan without calling the API. `--help` reprints the setup steps.

Do not commit the JSON. Losing it is fine (mint a new key); leaking it lets anyone ship as Hublee.

## After each update

1. Bump `version:` in `pubspec.yaml` (name + **+build**, e.g. `1.0.1+2`).
2. `flutter build appbundle --release`
3. New Play release with the new AAB.

## Automated closed testing (GitHub Actions)

Cloud agents cannot sign or upload from the VM: the upload keystore is gitignored and lives on your PC. After the secrets below are in GitHub, **Deploy Play** builds a signed AAB and uploads it to Closed testing (`alpha` in the Play API).

Ask the cloud agent to deploy, or push a `v*` tag, or run **Actions → Deploy Play → Run workflow**.

### 1. Play Developer API service account (once)

Manual Play Console uploads do **not** replace this. The workflow talks to the API as a service account.

1. In [Google Cloud Console](https://console.cloud.google.com/) (same Google account as Play), create or pick a project.
2. **APIs & Services → Library** → enable **Google Play Android Developer API**.
3. **IAM & Admin → Service Accounts → Create service account**. Name it e.g. `hublee-play-upload`. Skip Cloud IAM roles.
4. Open the account → **Keys → Add key → Create new key → JSON**. Save the file off-repo.
5. In [Play Console](https://play.google.com/console) → **Users and permissions → Invite new users**.
6. Email = `client_email` from the JSON (ends with `.iam.gserviceaccount.com`).
7. App **Hublee** (`com.hublee.app`). Permissions:
   - **Release apps to testing tracks**
   - **View app information** (read)
8. **Invite user**. Wait up to 24 hours if the first API call returns a permission error.

### 2. GitHub Actions secrets (once)

On the PC that already has the keystore:

```powershell
.\scripts\prep-play-github-secrets.ps1
```

Add repository secrets at [github.com/jjaykhan91/hublee/settings/secrets/actions](https://github.com/jjaykhan91/hublee/settings/secrets/actions):

| Secret | Value |
|---|---|
| `PLAY_KEYSTORE_BASE64` | Output of the script (clipboard) |
| `PLAY_STORE_PASSWORD` | `storePassword` in `android/key.properties` |
| `PLAY_KEY_PASSWORD` | `keyPassword` in `android/key.properties` |
| `PLAY_KEY_ALIAS` | `keyAlias` (usually `upload`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | Entire service-account JSON file |

Do not commit the `.jks`, `key.properties`, or JSON key.

### 3. Deploy

Each Play upload needs a **new** `version:` in `pubspec.yaml` (higher `+build`). Then either:

- Tag `v1.0.2` (or whatever matches that version) and push the tag → uploads to **Closed testing** (`alpha`), status `completed`.
- **Actions → Deploy Play → Run workflow** and optionally change track (`internal`, `alpha`, `beta`, `production`) or upload as `draft`.

The workflow file is `.github/workflows/deploy-play.yml`. It must be on `master` before a tag on `master` will use it.

## If `flutter build appbundle` complains about debug symbols

Gradle may still have written `build\app\outputs\bundle\release\app-release.aab`. Flutter’s post-check needs Android **cmdline-tools** (`apkanalyzer`). Install them in Android Studio: **SDK Manager → SDK Tools → Android SDK Command-line Tools**, then `flutter doctor` until the Android toolchain is clean.
