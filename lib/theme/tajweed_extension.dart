import 'package:flutter/material.dart';

@immutable
class TajweedTheme extends ThemeExtension<TajweedTheme> {
  final Color ikhfa;     // nasalization
  final Color idgham;    // merging
  final Color qalqalah;  // bounce
  final Color madd;      // elongation
  final Color ghunnah;   // nasalized noon/meem
  final Color iqlab;     // conversion
  final Color ikhfaShafawi;
  final Color idghamMutajanisayn;

  const TajweedTheme({
    required this.ikhfa,
    required this.idgham,
    required this.qalqalah,
    required this.madd,
    required this.ghunnah,
    required this.iqlab,
    required this.ikhfaShafawi,
    required this.idghamMutajanisayn,
  });

  @override
  TajweedTheme copyWith({
    Color? ikhfa,
    Color? idgham,
    Color? qalqalah,
    Color? madd,
    Color? ghunnah,
    Color? iqlab,
    Color? ikhfaShafawi,
    Color? idghamMutajanisayn,
  }) {
    return TajweedTheme(
      ikhfa: ikhfa ?? this.ikhfa,
      idgham: idgham ?? this.idgham,
      qalqalah: qalqalah ?? this.qalqalah,
      madd: madd ?? this.madd,
      ghunnah: ghunnah ?? this.ghunnah,
      iqlab: iqlab ?? this.iqlab,
      ikhfaShafawi: ikhfaShafawi ?? this.ikhfaShafawi,
      idghamMutajanisayn: idghamMutajanisayn ?? this.idghamMutajanisayn,
    );
  }

  @override
  ThemeExtension<TajweedTheme> lerp(ThemeExtension<TajweedTheme>? other, double t) {
    if (other is! TajweedTheme) return this;
    Color lerp(Color a, Color b) => Color.lerp(a, b, t)!;
    return TajweedTheme(
      ikhfa: lerp(ikhfa, other.ikhfa),
      idgham: lerp(idgham, other.idgham),
      qalqalah: lerp(qalqalah, other.qalqalah),
      madd: lerp(madd, other.madd),
      ghunnah: lerp(ghunnah, other.ghunnah),
      iqlab: lerp(iqlab, other.iqlab),
      ikhfaShafawi: lerp(ikhfaShafawi, other.ikhfaShafawi),
      idghamMutajanisayn: lerp(idghamMutajanisayn, other.idghamMutajanisayn),
    );
  }

  // Light palette (unchanged)
  static TajweedTheme light = const TajweedTheme(
    ikhfa: Color(0xFF006A6A),
    idgham: Color(0xFF8B5CF6),
    qalqalah: Color(0xFFB91C1C),
    madd: Color(0xFF0EA5E9),
    ghunnah: Color(0xFF16A34A),
    iqlab: Color(0xFFF59E0B),
    ikhfaShafawi: Color(0xFF7C3AED),
    idghamMutajanisayn: Color(0xFFEA580C),
  );

  // Tuned for true-dark backgrounds
  static TajweedTheme dark = const TajweedTheme(
    ikhfa: Color(0xFF8AF0FF),
    idgham: Color(0xFFE1D5FF),
    qalqalah: Color(0xFFFFB3B3),
    madd: Color(0xFFAED2FF),
    ghunnah: Color(0xFFA8F7BE),
    iqlab: Color(0xFFFFE694),
    ikhfaShafawi: Color(0xFFD8C9FF),
    idghamMutajanisayn: Color(0xFFFFCC66),
  );
}
