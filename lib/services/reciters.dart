/// Bundled Hafs reciter catalog for ayah audio.
///
/// Paths are from Quran.com's public recitation API
/// (`/recitations/{id}/by_chapter/1`) and EveryAyah folder names.
/// Warsh and translation tracks are omitted — Hublee displays Hafs.
library;

import 'package:flutter/foundation.dart';

/// One reciter Hublee can stream or download ayah-by-ayah.
@immutable
class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.shortName,
    this.style,
    this.cdnFolder,
    required this.everyAyahFolder,
  });

  /// Stable prefs key, e.g. `alafasy`.
  final String id;

  /// English display name.
  final String name;

  /// Compact name for the ayah play chip, e.g. `Alafasy`.
  final String shortName;

  /// Murattal / Mujawwad / Muallim when the same reciter has styles.
  final String? style;

  /// Quran.com CDN folder (`Alafasy`, `AbdulBaset/Mujawwad`), or null
  /// when that reciter is EveryAyah-only.
  final String? cdnFolder;

  /// EveryAyah directory under `https://everyayah.com/data/`.
  final String everyAyahFolder;

  /// Label shown in pickers.
  String get label {
    final styleName = style;
    if (styleName == null) return name;
    return '$name ($styleName)';
  }

  /// Reciter and style for the compact play control.
  String get chipLabel {
    final styleName = style;
    if (styleName == null) return shortName;
    return '$shortName · $styleName';
  }
}

/// Default reciter — matches the original Hublee stream.
const kDefaultReciterId = 'alafasy';

/// Reciters Hublee can play. Alafasy first; the rest follow Quran.com
/// ayah IDs, then extra EveryAyah Hafs voices.
const kReciters = <Reciter>[
  Reciter(
    id: 'alafasy',
    name: 'Mishary Rashid Alafasy',
    shortName: 'Alafasy',
    cdnFolder: 'Alafasy',
    everyAyahFolder: 'Alafasy_128kbps',
  ),
  Reciter(
    id: 'abdulbaset-mujawwad',
    name: 'AbdulBaset AbdulSamad',
    shortName: 'AbdulBaset',
    style: 'Mujawwad',
    cdnFolder: 'AbdulBaset/Mujawwad',
    everyAyahFolder: 'Abdul_Basit_Mujawwad_128kbps',
  ),
  Reciter(
    id: 'abdulbaset-murattal',
    name: 'AbdulBaset AbdulSamad',
    shortName: 'AbdulBaset',
    style: 'Murattal',
    cdnFolder: 'AbdulBaset/Murattal',
    everyAyahFolder: 'Abdul_Basit_Murattal_192kbps',
  ),
  Reciter(
    id: 'sudais',
    name: 'Abdur-Rahman as-Sudais',
    shortName: 'Sudais',
    cdnFolder: 'Sudais',
    everyAyahFolder: 'Abdurrahmaan_As-Sudais_192kbps',
  ),
  Reciter(
    id: 'shatri',
    name: 'Abu Bakr al-Shatri',
    shortName: 'Shatri',
    cdnFolder: 'Shatri',
    everyAyahFolder: 'Abu_Bakr_Ash-Shaatree_128kbps',
  ),
  Reciter(
    id: 'rifai',
    name: 'Hani ar-Rifai',
    shortName: 'Rifai',
    cdnFolder: 'Rifai',
    everyAyahFolder: 'Hani_Rifai_192kbps',
  ),
  Reciter(
    id: 'husary',
    name: 'Mahmoud Khalil Al-Husary',
    shortName: 'Husary',
    style: 'Murattal',
    everyAyahFolder: 'Husary_128kbps',
  ),
  Reciter(
    id: 'husary-muallim',
    name: 'Mahmoud Khalil Al-Husary',
    shortName: 'Husary',
    style: 'Muallim',
    everyAyahFolder: 'Husary_Muallim_128kbps',
  ),
  Reciter(
    id: 'minshawi-mujawwad',
    name: 'Mohamed Siddiq al-Minshawi',
    shortName: 'Minshawi',
    style: 'Mujawwad',
    cdnFolder: 'Minshawi/Mujawwad',
    everyAyahFolder: 'Minshawy_Mujawwad_192kbps',
  ),
  Reciter(
    id: 'minshawi-murattal',
    name: 'Mohamed Siddiq al-Minshawi',
    shortName: 'Minshawi',
    style: 'Murattal',
    cdnFolder: 'Minshawi/Murattal',
    everyAyahFolder: 'Minshawy_Murattal_128kbps',
  ),
  Reciter(
    id: 'shuraym',
    name: 'Saud ash-Shuraym',
    shortName: 'Shuraym',
    cdnFolder: 'Shuraym',
    everyAyahFolder: 'Saood_ash-Shuraym_128kbps',
  ),
  Reciter(
    id: 'tablawi',
    name: 'Mohamed al-Tablawi',
    shortName: 'Tablawi',
    everyAyahFolder: 'Mohammad_al_Tablaway_128kbps',
  ),
  Reciter(
    id: 'maher',
    name: 'Maher Al Muaiqly',
    shortName: 'Maher',
    everyAyahFolder: 'MaherAlMuaiqly128kbps',
  ),
  Reciter(
    id: 'ayyoub',
    name: 'Muhammad Ayyoub',
    shortName: 'Ayyoub',
    everyAyahFolder: 'Muhammad_Ayyoub_128kbps',
  ),
  Reciter(
    id: 'hudhaify',
    name: 'Ali al-Hudhaify',
    shortName: 'Hudhaify',
    everyAyahFolder: 'Hudhaify_128kbps',
  ),
  Reciter(
    id: 'yasser',
    name: 'Yasser ad-Dussary',
    shortName: 'Yasser',
    everyAyahFolder: 'Yasser_Ad-Dussary_128kbps',
  ),
  Reciter(
    id: 'qatami',
    name: 'Nasser Al-Qatami',
    shortName: 'Qatami',
    everyAyahFolder: 'Nasser_Alqatami_128kbps',
  ),
  Reciter(
    id: 'ajamy',
    name: 'Ahmed ibn Ali al-Ajamy',
    shortName: 'Ajamy',
    everyAyahFolder: 'ahmed_ibn_ali_al_ajamy_128kbps',
  ),
];

/// Looks up [id], falling back to Alafasy if unknown.
Reciter reciterById(String? id) {
  if (id == null) return kReciters.first;
  for (final reciter in kReciters) {
    if (reciter.id == id) return reciter;
  }
  return kReciters.first;
}

/// `{SSS}{AAA}` used by Quran.com and EveryAyah ayah files.
String recitationPaddedKey({required int surahId, required int ayah}) {
  final surah = surahId.toString().padLeft(3, '0');
  final verse = ayah.toString().padLeft(3, '0');
  return '$surah$verse';
}

/// Stream URLs to try in order until one plays or downloads.
List<String> recitationUrlsFor({
  required Reciter reciter,
  required int surahId,
  required int ayah,
}) {
  final padded = recitationPaddedKey(surahId: surahId, ayah: ayah);
  final urls = <String>[];
  final folder = reciter.cdnFolder;
  if (folder != null) {
    urls.add('https://audio.qurancdn.com/$folder/mp3/$padded.mp3');
    urls.add('https://verses.quran.com/$folder/mp3/$padded.mp3');
  }
  urls.add('https://everyayah.com/data/${reciter.everyAyahFolder}/$padded.mp3');
  urls.add(
    'https://mirrors.quranicaudio.com/everyayah/'
    '${reciter.everyAyahFolder}/$padded.mp3',
  );
  return urls;
}
