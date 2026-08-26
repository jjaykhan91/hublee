/// Models for the bundled Allah, Prophet, and dua guides.
library;

/// A Quran range shown as a tappable chip on a guide page.
class GuidanceAyahRef {
  const GuidanceAyahRef({
    required this.surahId,
    required this.ayah,
    this.ayahEnd,
    this.title,
    this.why,
  });

  final int surahId;
  final int ayah;
  final int? ayahEnd;
  final String? title;
  final String? why;

  factory GuidanceAyahRef.fromJson(Map<String, dynamic> json) {
    return GuidanceAyahRef(
      surahId: json['surahId'] as int,
      ayah: json['ayah'] as int,
      ayahEnd: json['ayahEnd'] as int?,
      title: json['title'] as String?,
      why: json['why'] as String?,
    );
  }

  String get label {
    final named = title?.trim();
    final range = ayahEnd == null || ayahEnd == ayah
        ? '$surahId:$ayah'
        : '$surahId:$ayah–$ayahEnd';
    if (named == null || named.isEmpty) return range;
    return '$named · $range';
  }
}

/// A headed list of short items inside a guide section.
class GuidanceGroup {
  const GuidanceGroup({required this.heading, required this.items});

  final String heading;
  final List<String> items;

  factory GuidanceGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return GuidanceGroup(
      heading: json['heading'] as String? ?? '',
      items: raw is List
          ? raw.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}

/// One dated event on the seerah timeline.
class GuidanceTimelineItem {
  const GuidanceTimelineItem({
    required this.when,
    required this.title,
    required this.body,
  });

  final String when;
  final String title;
  final String body;

  factory GuidanceTimelineItem.fromJson(Map<String, dynamic> json) {
    return GuidanceTimelineItem(
      when: json['when'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

/// A navigable chapter of a guide (who He is, family, timeline…).
class GuidanceSection {
  const GuidanceSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.paragraphs = const [],
    this.groups = const [],
    this.timeline = const [],
    this.ayahs = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<String> paragraphs;
  final List<GuidanceGroup> groups;
  final List<GuidanceTimelineItem> timeline;
  final List<GuidanceAyahRef> ayahs;

  factory GuidanceSection.fromJson(Map<String, dynamic> json) {
    return GuidanceSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      paragraphs: _stringList(json['paragraphs']),
      groups: _mapList(json['groups'], GuidanceGroup.fromJson),
      timeline: _mapList(json['timeline'], GuidanceTimelineItem.fromJson),
      ayahs: _mapList(json['ayahs'], GuidanceAyahRef.fromJson),
    );
  }
}

/// One of the ninety-nine names as commonly taught.
class AllahName {
  const AllahName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    this.surahId,
    this.ayah,
  });

  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;
  final int? surahId;
  final int? ayah;

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      number: json['number'] as int? ?? 0,
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      surahId: json['surahId'] as int?,
      ayah: json['ayah'] as int?,
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return transliteration.toLowerCase().contains(q) ||
        meaning.toLowerCase().contains(q) ||
        '$number'.contains(q) ||
        arabic.contains(query.trim());
  }
}

/// Bundled guide to Allah: tawhid orientation, key ayahs, and names.
class AllahGuide {
  const AllahGuide({
    required this.arabicName,
    required this.englishName,
    required this.intro,
    required this.namesNote,
    required this.sections,
    required this.ayahs,
    required this.names,
  });

  final String arabicName;
  final String englishName;
  final String intro;
  final String namesNote;
  final List<GuidanceSection> sections;
  final List<GuidanceAyahRef> ayahs;
  final List<AllahName> names;

  factory AllahGuide.fromJson(Map<String, dynamic> json) {
    return AllahGuide(
      arabicName: json['arabicName'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      namesNote: json['namesNote'] as String? ?? '',
      sections: _mapList(json['sections'], GuidanceSection.fromJson),
      ayahs: _mapList(json['ayahs'], GuidanceAyahRef.fromJson),
      names: _mapList(json['names'], AllahName.fromJson),
    );
  }

  GuidanceSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }
}

/// Bundled seerah orientation for Prophet Muhammad (peace be upon him).
class ProphetGuide {
  const ProphetGuide({
    required this.arabicName,
    required this.englishName,
    required this.honorific,
    required this.intro,
    required this.sections,
  });

  final String arabicName;
  final String englishName;
  final String honorific;
  final String intro;
  final List<GuidanceSection> sections;

  factory ProphetGuide.fromJson(Map<String, dynamic> json) {
    return ProphetGuide(
      arabicName: json['arabicName'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      honorific: json['honorific'] as String? ?? 'peace be upon him',
      intro: json['intro'] as String? ?? '',
      sections: _mapList(json['sections'], GuidanceSection.fromJson),
    );
  }

  GuidanceSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }
}

/// One du'a: Arabic, English, and a source line.
class DuaEntry {
  const DuaEntry({
    required this.id,
    required this.arabic,
    required this.english,
    required this.source,
    this.title,
    this.transliteration,
    this.note,
    this.surahId,
    this.ayah,
    this.ayahEnd,
  });

  final String id;
  final String arabic;
  final String english;
  final String source;
  final String? title;
  final String? transliteration;
  final String? note;
  final int? surahId;
  final int? ayah;
  final int? ayahEnd;

  factory DuaEntry.fromJson(Map<String, dynamic> json) {
    return DuaEntry(
      id: json['id'] as String? ?? '',
      arabic: json['arabic'] as String? ?? '',
      english: json['english'] as String? ?? '',
      source: json['source'] as String? ?? '',
      title: json['title'] as String?,
      transliteration: json['transliteration'] as String?,
      note: json['note'] as String?,
      surahId: json['surahId'] as int?,
      ayah: json['ayah'] as int?,
      ayahEnd: json['ayahEnd'] as int?,
    );
  }
}

/// A headed cluster of du'as inside a category.
class DuaGroup {
  const DuaGroup({required this.title, required this.duas});

  final String title;
  final List<DuaEntry> duas;

  factory DuaGroup.fromJson(Map<String, dynamic> json) {
    return DuaGroup(
      title: json['title'] as String? ?? '',
      duas: _mapList(json['duas'], DuaEntry.fromJson),
    );
  }
}

/// A tappable category on the dua hub (Quran, morning, travel…).
class DuaCategory {
  const DuaCategory({
    required this.id,
    required this.title,
    required this.kind,
    required this.count,
    required this.groups,
    this.subtitle,
  });

  final String id;
  final String title;
  final String kind;
  final int count;
  final String? subtitle;
  final List<DuaGroup> groups;

  bool get isQuran => kind == 'quran';

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      kind: json['kind'] as String? ?? 'sunnah',
      count: json['count'] as int? ?? 0,
      subtitle: json['subtitle'] as String?,
      groups: _mapList(json['groups'], DuaGroup.fromJson),
    );
  }
}

/// Full dua catalog: Quranic set plus Hisn al-Muslim categories.
class DuaCatalog {
  const DuaCatalog({required this.sourceNote, required this.categories});

  final String sourceNote;
  final List<DuaCategory> categories;

  factory DuaCatalog.fromJson(Map<String, dynamic> json) {
    return DuaCatalog(
      sourceNote: json['sourceNote'] as String? ?? '',
      categories: _mapList(json['categories'], DuaCategory.fromJson),
    );
  }

  DuaCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList(growable: false);
}

List<T> _mapList<T>(Object? raw, T Function(Map<String, dynamic> json) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((row) => parse(Map<String, dynamic>.from(row)))
      .toList(growable: false);
}
