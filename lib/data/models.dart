class Chapter {
  final int id;
  final String nameSimple;      // "Al-Fatihah"
  final String nameArabic;      // "الفاتحة"
  final String revelationPlace; // "makkah" | "madinah"
  final int versesCount;

  const Chapter({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.revelationPlace,
    required this.versesCount,
  });

  factory Chapter.fromJson(Map<String, dynamic> m) => Chapter(
        id: (m['id'] as num).toInt(),
        nameSimple: (m['name_simple'] ?? '').toString(),
        nameArabic: (m['name_arabic'] ?? '').toString(),
        revelationPlace: (m['revelation_place'] ?? '').toString(),
        versesCount: (m['verses_count'] as num).toInt(),
      );
}
