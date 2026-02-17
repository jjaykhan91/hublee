/// [ThemeExtension] that provides colours for Tajweed recitation
/// rules.
///
/// Registered in both light and dark [ThemeData] so widgets can
/// access Tajweed colours via:
/// ```dart
/// final tj = Theme.of(context).extension<TajweedTheme>()!;
/// ```
library;

import 'package:flutter/material.dart';

/// Colour palette for the main Tajweed recitation rules.
///
/// Each field maps to a specific recitation rule:
/// - [ikhfa] — concealment (nasalization)
/// - [idgham] — merging
/// - [qalqalah] — echoing/bouncing
/// - [madd] — elongation
/// - [ghunnah] — nasalized noon/meem
/// - [iqlab] — conversion
/// - [ikhfaShafawi] — labial concealment
/// - [idghamMutajanisayn] — assimilation of similar letters
@immutable
class TajweedTheme extends ThemeExtension<TajweedTheme> {
  /// Ikhfa: concealment / nasalization.
  final Color ikhfa;

  /// Idgham: merging of letters.
  final Color idgham;

  /// Qalqalah: echoing / bouncing.
  final Color qalqalah;

  /// Madd: elongation of vowel sounds.
  final Color madd;

  /// Ghunnah: nasalization through the nose.
  final Color ghunnah;

  /// Iqlab: conversion of noon sakinah to meem.
  final Color iqlab;

  /// Ikhfa Shafawi: labial concealment.
  final Color ikhfaShafawi;

  /// Idgham Mutajanisayn: assimilation of similar articulation
  /// point letters.
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
  ThemeExtension<TajweedTheme> lerp(
    ThemeExtension<TajweedTheme>? other,
    double t,
  ) {
    if (other is! TajweedTheme) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return TajweedTheme(
      ikhfa: lerpColor(ikhfa, other.ikhfa),
      idgham: lerpColor(idgham, other.idgham),
      qalqalah: lerpColor(qalqalah, other.qalqalah),
      madd: lerpColor(madd, other.madd),
      ghunnah: lerpColor(ghunnah, other.ghunnah),
      iqlab: lerpColor(iqlab, other.iqlab),
      ikhfaShafawi: lerpColor(ikhfaShafawi, other.ikhfaShafawi),
      idghamMutajanisayn: lerpColor(
        idghamMutajanisayn,
        other.idghamMutajanisayn,
      ),
    );
  }

  // ── Preset palettes ──────────────────────────────────────────

  /// Tajweed colours optimised for light backgrounds.
  static const light = TajweedTheme(
    ikhfa: Color(0xFF006A6A),
    idgham: Color(0xFF8B5CF6),
    qalqalah: Color(0xFFB91C1C),
    madd: Color(0xFF0EA5E9),
    ghunnah: Color(0xFF16A34A),
    iqlab: Color(0xFFF59E0B),
    ikhfaShafawi: Color(0xFF7C3AED),
    idghamMutajanisayn: Color(0xFFEA580C),
  );

  /// Tajweed colours with higher brightness for dark / AMOLED
  /// backgrounds.
  static const dark = TajweedTheme(
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
