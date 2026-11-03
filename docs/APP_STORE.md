# Apple App Store listing (Hublee)

The iOS bundle id is **`com.hublee.app`** (same as Android). Do not change it after the first App Store Connect upload.

You **cannot** upload an iOS build from this Windows PC. Apple requires Xcode on a Mac (or a cloud Mac such as Codemagic / GitHub Actions `macos-latest`).

## What you need

1. [Apple Developer Program](https://developer.apple.com/programs/) — **$99 / year** (the same Apple ID you will use in App Store Connect).
2. A **Mac** with the latest Xcode (or a CI Mac).
3. This repo on that Mac, Flutter installed, `flutter doctor` showing a check for Xcode.

Home-screen widgets stay **Android-only**. Do not mention them on the iOS listing.

## Create the app in App Store Connect

1. Open [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**.
2. Platforms: **iOS**. Name: **Hublee**. Primary language: English (US).
3. Bundle ID: register **`com.hublee.app`** in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) if it is not already there, then select it.
4. SKU: e.g. `hublee-ios` (internal; users never see it).
5. User Access: Full Access.

**Price:** Paid or Free is an App Store Connect setting, not in the IPA. A paid App Store app can be made free later; a free app **cannot** be made paid later. Match Play if you want ($0.49 now, raise later). TestFlight installs are **free** even when the store listing is paid.

Complete **Paid Applications** (and banking/tax) under **Business** if the app is paid.

## Build and upload (on a Mac)

```bash
cd path/to/hublee
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode:

1. Select the **Runner** target → **Signing & Capabilities**.
2. Team: your Apple Developer team. Automatic signing is fine.
3. Confirm Bundle Identifier is `com.hublee.app`.
4. Product → Destination → **Any iOS Device (arm64)**.
5. **Product → Archive**. When the Organizer opens, **Distribute App** → **App Store Connect** → Upload.

Or from the terminal (after signing is set in Xcode once):

```bash
flutter build ipa --release
```

Then upload `build/ios/ipa/*.ipa` with **Transporter** or `xcrun altool` / `xcrun notarytool` is for Mac apps — for iOS use Transporter or Xcode Organizer.

Version comes from `pubspec.yaml` (`1.0.5+7` → marketing `1.0.5`, build `7`). Bump both before each new upload, same as Play.

## TestFlight (Apple’s closed test)

After the build processes (often 10–60 minutes):

1. App Store Connect → Hublee → **TestFlight**.
2. Add **Internal testers** (App Store Connect users on your team) — fastest, no review.
3. **External testers** need a short Beta App Review the first time, then you send an invite link. Testers install **TestFlight** from the App Store and redeem the invite. They do **not** pay.

External TestFlight is the analogue of Play closed testing, but it does **not** replace Apple’s production review.

## Store listing (paste)

**Subtitle** (max 30 characters):

```
Quran and Hadith, offline
```

**Description:**

```
Hublee is an offline Quran and Hadith reader. The Arabic text, English translation (ClearQuran), and Hadith collections are bundled in the app. There is no account, no ads, and no tracking SDK.

Read with tajweed colouring and optional word-by-word English. Search Quran and Hadith on the device. Bookmark ayahs and hadiths. A Learn tab includes a Quranic glossary and Modern Arabic study cards.

Recitation is optional and not bundled. Choose a Hafs reciter from the play control on any ayah. Stream over the network, or download a surah (or the full Quran for that reciter) to this device for offline playback.

Sources: ClearQuran; KFGQPC Hafs and Uthmani Arabic; word-by-word glossary by Dr. Shehnaz Shaikh and Ms. Kausar Khatri; recitation from Quran.com CDN and EveryAyah.
```

**Keywords** (comma-separated, 100 characters max, no spaces after commas if you need the room):

```
quran,hadith,islam,tajweed,muslim,quranic,dua,salah,dhikr,arabic
```

**Support URL:** `https://github.com/jjaykhan91/hublee`

**Privacy policy URL:**

`https://github.com/jjaykhan91/hublee/blob/master/docs/privacy-policy.md`

**Category:** Books (primary). Reference as secondary if asked.

**Age rating:** complete the questionnaire. Religious text, no violence, no user-generated chat. Not made for kids.

## App Privacy (nutrition labels)

Hublee does **not** collect data for the developer. Choose **Data Not Collected**. Recitation MP3s are fetched only when the user plays or downloads; you do not receive those requests.

Export compliance: the IPA sets `ITSAppUsesNonExemptEncryption` to `NO` (HTTPS only). In App Store Connect you can answer that the app only uses exempt encryption.

## Screenshots

Required sizes change with Xcode; App Store Connect shows what’s missing. Typical:

- iPhone 6.7" (e.g. 15 Pro Max) — at least one
- iPhone 6.5" or the other required slot if listed
- iPad 13" if you check iPad

Take them on a simulator on the Mac (`flutter run` then Cmd+S) or a device. Use Hublee’s dark teal, not the Android widget screens.

## Review notes (optional but useful)

```
Hublee is an offline religious reader. There is no login. Optional recitation streams or downloads public MP3s over HTTPS when the user taps play. No ads, no analytics SDK, no account.
```

## Production

TestFlight → when you are happy, in the iOS app version click **Add for Review** → **Submit**. First review is often 1–3 days. Reply on Resolution Center if they ask.

Do not submit a Mac (macOS) build unless you intend a separate Mac App Store listing. This file is **iPhone / iPad** only. The macOS target in the repo still uses a different bundle id and is not prepared for the Mac App Store.
