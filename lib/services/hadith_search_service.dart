/// Orchestrates full-text search across all Hadith collections.
///
/// Delegates to [HadithRepository.searchHadith] so search logic
/// stays in one place and can be swapped or extended later.
library;

import '../hadith/hadith_repository.dart';
import 'search_models.dart';

/// Service that searches Hadith books by Arabic or English text.
class HadithSearchService {
  const HadithSearchService({HadithRepository? repo})
    : _repo = repo ?? const HadithRepository();

  final HadithRepository _repo;

  /// Builds the hadith search index if needed.
  Future<void> warmIndex() => _repo.warmSearchIndex();

  /// Searches all hadith collections for [query]. Returns up to [limit] hits.
  Future<List<HadithSearchHit>> search(String query, {int limit = 100}) async {
    return _repo.searchHadith(query, limit: limit);
  }
}
