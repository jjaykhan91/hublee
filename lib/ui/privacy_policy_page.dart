/// Full-screen privacy policy for Play Store and in-app Settings.
library;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Explains what Hublee stores on-device and when it uses the network.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      height: 1.5,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text('Last updated: 26 August 2026', style: muted),
          const SizedBox(height: 16),
          Text(
            'Hublee is an offline Quran and Hadith reader. There is no '
            'Hublee account, no Hublee server, and no advertising or '
            'analytics SDK.',
            style: muted,
          ),
          const SizedBox(height: 16),
          Text('What stays on your device', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Settings, bookmarks, last-read positions, first-run choices, '
            'optional Learn-tab study cards, and the text shown on Android '
            'home-screen widgets are saved in app storage on this device '
            '(SharedPreferences). If you download recitation, '
            'ayah audio files are stored in the app’s private support '
            'folder. Uninstalling Hublee removes that data. We cannot '
            'read it from another phone.',
            style: muted,
          ),
          const SizedBox(height: 16),
          Text(
            'When Hublee uses the internet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Quran and Hadith text is bundled in the app. Recitation is '
            'not. If you play or download an ayah, Hublee fetches MP3s '
            'from public hosts (Quran.com CDN, verses.quran.com, '
            'EveryAyah, and a Quranicaudio EveryAyah mirror). Share and '
            'copy use the Android share sheet or clipboard; that content '
            'goes only where you send it.',
            style: muted,
          ),
          const SizedBox(height: 16),
          Text('What we do not collect', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Hublee does not create an account, does not sell data, does '
            'not show ads, and does not send bookmarks, search queries, '
            'or reading history to us. Diagnostics (if you open that '
            'screen in a debug build) stay in memory on the device.',
            style: muted,
          ),
          const SizedBox(height: 16),
          Text('Children', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Hublee is a religious-text reader for a general audience. It '
            'is not directed at children under 13 and does not knowingly '
            'collect personal information from children.',
            style: muted,
          ),
          const SizedBox(height: 16),
          Text('Contact', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Questions about this policy: open an issue on the Hublee '
            'GitHub repository (jjaykhan91/hublee).',
            style: muted,
          ),
        ],
      ),
    );
  }
}
