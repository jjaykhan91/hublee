/// Pins the tajweed rule colours to the Madani mushaf scheme.
///
/// These constants are the contract between the rule engine, the Tajweed Guide
/// legend, and `.cursor/rules/theming.mdc`. A silent edit to one of them would
/// leave the legend describing colours the reader never sees, so the exact hex
/// values are asserted here rather than merely checked for existence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/widgets/tajweed.dart';

/// The documented scheme, matching quran.com's Madani colouring.
const _expected = <String, (Color, int)>{
  'qalqala': (kQalqalaColor, 0xFF00BCD4),
  'ghunnah': (kGhunnahColor, 0xFF43A047),
  'idghamGhunnah': (kIdghamGhunnahColor, 0xFF43A047),
  'ikhfa': (kIkhfaColor, 0xFF43A047),
  'iqlab': (kIqlabColor, 0xFF43A047),
  'meemIkhfa': (kMeemIkhfaColor, 0xFF43A047),
  'meemIdgham': (kMeemIdghamColor, 0xFF43A047),
  'normalMaad': (kNormalMaadColor, 0xFFE91E8C),
  'maadSukoon': (kMaadSukoonColor, 0xFFFB8C00),
  'maadConnected': (kMaadConnectedColor, 0xFFD81B60),
  'maadLong': (kMaadLongColor, 0xFFF44336),
  'tafkhim': (kTafkhimColor, 0xFF1565C0),
};

void main() {
  group('Tajweed colours', () {
    test('every rule colour matches the documented Madani hex', () {
      for (final entry in _expected.entries) {
        final (colour, expectedHex) = entry.value;
        expect(
          colour.toARGB32(),
          expectedHex,
          reason:
              '${entry.key} drifted from the documented scheme — update '
              'theming.mdc and the Tajweed Guide together, or revert',
        );
      }
    });

    test(
      'the green group shares one hex so the legend can show one swatch',
      () {
        const green = 0xFF43A047;
        for (final key in [
          'ghunnah',
          'idghamGhunnah',
          'ikhfa',
          'iqlab',
          'meemIkhfa',
          'meemIdgham',
        ]) {
          expect(_expected[key]!.$1.toARGB32(), green, reason: key);
        }
      },
    );

    test('the four madd colours stay visually distinct', () {
      final maddHexes = {
        kNormalMaadColor.toARGB32(),
        kMaadSukoonColor.toARGB32(),
        kMaadConnectedColor.toARGB32(),
        kMaadLongColor.toARGB32(),
      };
      expect(
        maddHexes,
        hasLength(4),
        reason: 'two madd rules would be indistinguishable to the reader',
      );
    });

    test('the silent-letter grey adapts to brightness for legibility', () {
      final dark = kNotPronouncedColor(Brightness.dark);
      final light = kNotPronouncedColor(Brightness.light);
      expect(dark.toARGB32(), 0xFF9E9E9E);
      expect(light.toARGB32(), 0xFFBDBDBD);
      expect(dark.toARGB32(), isNot(light.toARGB32()));
    });
  });
}
