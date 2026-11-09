/// Cover art for each hadith book: its Arabic name, a cover colour, and
/// a geometric pattern, so every book is recognisable at a glance.
///
/// Drawn in code by [HadithBookCover] rather than shipped as images, so
/// covers stay sharp at any size and add nothing to the download.
library;

import 'package:flutter/painting.dart';

/// Geometric pattern pressed into a cover, like tooling on leather.
enum BookPattern { stars, lattice, diamonds }

/// How one cover looks. Used for hadith books and the Learn tools.
class BookArt {
  const BookArt({
    required this.arabicName,
    required this.arabicTitle,
    required this.dark,
    required this.light,
    required this.pattern,
  });

  /// Short name for small covers, e.g. البخاري.
  final String arabicName;

  /// Full title for large covers, e.g. صحيح البخاري.
  final String arabicTitle;

  /// Cover colours, spine to fore-edge.
  final Color dark;
  final Color light;

  final BookPattern pattern;
}

/// Gold used for the frame, pattern, and title on every cover.
const bookCoverGold = Color(0xFFD9B872);

const _art = <String, BookArt>{
  // The Nine Books
  'bukhari.json': BookArt(
    arabicName: 'البخاري',
    arabicTitle: 'صحيح البخاري',
    dark: Color(0xFF0B4A2E),
    light: Color(0xFF1C7A4D),
    pattern: BookPattern.stars,
  ),
  'muslim.json': BookArt(
    arabicName: 'مسلم',
    arabicTitle: 'صحيح مسلم',
    dark: Color(0xFF102F52),
    light: Color(0xFF1F5A8C),
    pattern: BookPattern.stars,
  ),
  'abudawud.json': BookArt(
    arabicName: 'أبو داود',
    arabicTitle: 'سنن أبي داود',
    dark: Color(0xFF55172A),
    light: Color(0xFF8A2E45),
    pattern: BookPattern.lattice,
  ),
  'tirmidhi.json': BookArt(
    arabicName: 'الترمذي',
    arabicTitle: 'جامع الترمذي',
    dark: Color(0xFF0C4547),
    light: Color(0xFF17777A),
    pattern: BookPattern.diamonds,
  ),
  'nasai.json': BookArt(
    arabicName: 'النسائي',
    arabicTitle: 'سنن النسائي',
    dark: Color(0xFF2A1C57),
    light: Color(0xFF4B3790),
    pattern: BookPattern.lattice,
  ),
  'ibnmajah.json': BookArt(
    arabicName: 'ابن ماجه',
    arabicTitle: 'سنن ابن ماجه',
    dark: Color(0xFF4F2E12),
    light: Color(0xFF8A5626),
    pattern: BookPattern.diamonds,
  ),
  'malik.json': BookArt(
    arabicName: 'الموطأ',
    arabicTitle: 'موطأ مالك',
    dark: Color(0xFF384217),
    light: Color(0xFF66762E),
    pattern: BookPattern.stars,
  ),
  'ahmed.json': BookArt(
    arabicName: 'المسند',
    arabicTitle: 'مسند أحمد',
    dark: Color(0xFF1B253D),
    light: Color(0xFF34466E),
    pattern: BookPattern.lattice,
  ),
  'darimi.json': BookArt(
    arabicName: 'الدارمي',
    arabicTitle: 'سنن الدارمي',
    dark: Color(0xFF42163B),
    light: Color(0xFF74305F),
    pattern: BookPattern.diamonds,
  ),
  // Forties
  'nawawi40.json': BookArt(
    arabicName: 'النووية',
    arabicTitle: 'الأربعون النووية',
    dark: Color(0xFF172544),
    light: Color(0xFF2F4A7D),
    pattern: BookPattern.stars,
  ),
  'qudsi40.json': BookArt(
    arabicName: 'القدسية',
    arabicTitle: 'الأحاديث القدسية',
    dark: Color(0xFF503B10),
    light: Color(0xFF8C6A22),
    pattern: BookPattern.lattice,
  ),
  'shahwaliullah40.json': BookArt(
    arabicName: 'ولي الله',
    arabicTitle: 'أربعون ولي الله',
    dark: Color(0xFF1A3D2A),
    light: Color(0xFF2F6A4A),
    pattern: BookPattern.diamonds,
  ),
  // Other books
  'riyad_assalihin.json': BookArt(
    arabicName: 'رياض',
    arabicTitle: 'رياض الصالحين',
    dark: Color(0xFF26461A),
    light: Color(0xFF467A31),
    pattern: BookPattern.stars,
  ),
  'aladab_almufrad.json': BookArt(
    arabicName: 'الأدب',
    arabicTitle: 'الأدب المفرد',
    dark: Color(0xFF551F2D),
    light: Color(0xFF8E3A50),
    pattern: BookPattern.diamonds,
  ),
  'bulugh_almaram.json': BookArt(
    arabicName: 'بلوغ',
    arabicTitle: 'بلوغ المرام',
    dark: Color(0xFF1E4548),
    light: Color(0xFF33767B),
    pattern: BookPattern.lattice,
  ),
  'mishkat_almasabih.json': BookArt(
    arabicName: 'مشكاة',
    arabicTitle: 'مشكاة المصابيح',
    dark: Color(0xFF55340C),
    light: Color(0xFF94601C),
    pattern: BookPattern.stars,
  ),
  'shamail_muhammadiyah.json': BookArt(
    arabicName: 'الشمائل',
    arabicTitle: 'الشمائل المحمدية',
    dark: Color(0xFF43251C),
    light: Color(0xFF7A4534),
    pattern: BookPattern.lattice,
  ),
};

const _fallbackColours = <(Color, Color)>[
  (Color(0xFF172544), Color(0xFF2F4A7D)),
  (Color(0xFF0B4A2E), Color(0xFF1C7A4D)),
  (Color(0xFF55172A), Color(0xFF8A2E45)),
  (Color(0xFF0C4547), Color(0xFF17777A)),
];

/// Cover art for the book in [file], or a plain cover for a new book.
BookArt hadithBookArt(String file) {
  final known = _art[file.toLowerCase()];
  if (known != null) return known;
  final (dark, light) =
      _fallbackColours[file.codeUnits.fold(0, (a, b) => a + b) %
          _fallbackColours.length];
  return BookArt(
    arabicName: 'حديث',
    arabicTitle: 'حديث',
    dark: dark,
    light: light,
    pattern: BookPattern.stars,
  );
}

/// Books that have their own cover, by file name.
Iterable<String> get hadithBooksWithArt => _art.keys;
