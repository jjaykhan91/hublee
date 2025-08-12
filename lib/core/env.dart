class Env {
  // OAuth / Foundation
  static const clientId     = String.fromEnvironment('QF_CLIENT_ID');
  static const clientSecret = String.fromEnvironment('QF_CLIENT_SECRET');
  static const oauthBase    = String.fromEnvironment('QF_OAUTH_BASE');
  static const scope        = String.fromEnvironment('QF_SCOPE', defaultValue: 'content');
  static const contentHostOverride = String.fromEnvironment('QF_CONTENT_HOST', defaultValue: '');

  // Try more possible content base paths (preprod can differ)
  static const contentPathCandidates = <String>[
    '/content/api/v4',
    '/quran/api/v4',
    '/api/v4',
    '/content/v4',
    '/quran/v4'
  ];

  // If discovery fails, optionally use the public API so the app still runs
  static const fallbackToPublic = bool.fromEnvironment('QF_FALLBACK_PUBLIC', defaultValue: true);

  // Public API (fallback)
  static const publicBase = 'https://api.quran.com';
  static const publicContent = '/api/v4';

  // Clear Quran translation id
  static const clearQuranResId = 131;
}
