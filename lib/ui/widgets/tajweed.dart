/// Tajweed rule colours (Madani mushaf scheme).
///
/// Used by the Tajweed Guide page to show the same colour legend as
/// the QPC V4 font-based tajweed in the reader. The reader uses only
/// V4 for tajweed; no software colour engine.
library;

import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────
//  Tajweed rule colours (Madani mushaf scheme from quran.com / V4)
// ────────────────────────────────────────────────────────────────

const kQalqalaColor = Color(0xFF00BCD4); // cyan
const kGhunnahColor = Color(0xFF43A047); // green
const kIdghamGhunnahColor = Color(0xFF43A047); // green (receiving letter)
const kIkhfaColor = Color(0xFF43A047); // green
const kIqlabColor = Color(0xFF43A047); // green (receiving ba)
const kMeemIkhfaColor = Color(0xFF43A047); // green
const kMeemIdghamColor = Color(0xFF43A047); // green
const kNormalMaadColor = Color(0xFFE91E8C); // pink (Normal madd 2 counts)
const kMaadSukoonColor = Color(0xFFFB8C00); // orange (Separated / Aridh)
const kMaadConnectedColor = Color(0xFFD81B60); // dark pink (Connected madd)
const kMaadLongColor = Color(0xFFF44336); // red (Necessary madd 6 — Madd Lazim)

/// Tafkhim (heavy/thick articulation) — dark blue.
const kTafkhimColor = Color(0xFF1565C0);

/// "Not pronounced" colour for idgham & iqlab (silent letter).
Color kNotPronouncedColor(Brightness brightness) =>
    brightness == Brightness.dark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFFBDBDBD);
