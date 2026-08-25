/// Picks a [RecitationCache] for the current platform.
library;

import 'recitation_cache.dart';
import 'recitation_cache_stub.dart'
    if (dart.library.io) 'recitation_cache_io.dart';

/// Files on Android/iOS/desktop; no-op on web.
RecitationCache createRecitationCache() => createPlatformRecitationCache();
