/// Chapter lookup helpers for hadith books.
library;

import 'hadith_repository.dart';

/// Book indices of every hadith in [chapterId], in list order.
///
/// When [chapterId] is `null`, returns every index (the full book).
List<int> hadithIndicesForChapter(List<Hadith> hadiths, int? chapterId) {
  if (chapterId == null) {
    return [for (var i = 0; i < hadiths.length; i++) i];
  }
  final indices = <int>[];
  for (var i = 0; i < hadiths.length; i++) {
    if (hadiths[i].chapterId == chapterId) indices.add(i);
  }
  return indices;
}

/// Index of the first hadith in [hadiths] whose [Hadith.chapterId]
/// matches [chapterId], or `null` if none.
int? firstHadithIndexForChapter(List<Hadith> hadiths, int? chapterId) {
  if (chapterId == null) return null;
  for (var i = 0; i < hadiths.length; i++) {
    if (hadiths[i].chapterId == chapterId) return i;
  }
  return null;
}

/// Chapter whose [HadithChapter.id] equals [id].
HadithChapter? chapterById(List<HadithChapter> chapters, int? id) {
  if (id == null) return null;
  for (final chapter in chapters) {
    if (chapter.id == id) return chapter;
  }
  return null;
}

/// Whether [index] is the first hadith of its chapter in [hadiths].
bool isChapterStart(List<Hadith> hadiths, int index) {
  if (index < 0 || index >= hadiths.length) return false;
  final id = hadiths[index].chapterId;
  if (id == null) return false;
  if (index == 0) return true;
  return hadiths[index - 1].chapterId != id;
}

/// How many hadiths in [hadiths] belong to [chapterId].
int hadithCountForChapter(List<Hadith> hadiths, int? chapterId) {
  if (chapterId == null) return 0;
  var count = 0;
  for (final hadith in hadiths) {
    if (hadith.chapterId == chapterId) count++;
  }
  return count;
}
