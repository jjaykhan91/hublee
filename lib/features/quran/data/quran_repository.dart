import '../../../core/cache.dart';
import 'quran_api.dart';

class QuranRepository {
  final QuranApi api;
  QuranRepository(this.api);

  Future<Map<String, dynamic>> chapters({bool forceRefresh = false}) async {
    const key = 'chapters';
    if (!forceRefresh) {
      final cached = JsonCache.getJson(key);
      if (cached != null) return cached;
    }
    final res = await api.getChapters();
    final data = res.data as Map<String, dynamic>;
    await JsonCache.putJson(key, data);
    return data;
  }

  Future<Map<String, dynamic>> versesByChapter(
    int chapter, {
    int page = 1,
    int perPage = 50,
    bool forceRefresh = false,
  }) async {
    final key = 'verses:$chapter:$page:$perPage:${DateTime.now().year}:131';
    if (!forceRefresh) {
      final cached = JsonCache.getJson(key);
      if (cached != null) return cached;
    }
    final res = await api.getVersesByChapter(chapter, page: page, perPage: perPage);
    final data = res.data as Map<String, dynamic>;
    await JsonCache.putJson(key, data);
    return data;
  }
}
