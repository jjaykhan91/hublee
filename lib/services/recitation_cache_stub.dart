/// Web / non-IO recitation cache factory.
library;

import 'recitation_cache.dart';

/// Returns a cache that never writes files.
RecitationCache createPlatformRecitationCache() {
  return const NoopRecitationCache();
}
