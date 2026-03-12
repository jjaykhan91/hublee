/// Tests for tajweed colour constants (Tajweed Guide legend).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/widgets/tajweed.dart';

void main() {
  group('Tajweed colours', () {
    test('all rule colours are valid non-null colours', () {
      expect(kQalqalaColor, isNotNull);
      expect(kGhunnahColor, isNotNull);
      expect(kIdghamGhunnahColor, isNotNull);
      expect(kIkhfaColor, isNotNull);
      expect(kIqlabColor, isNotNull);
      expect(kMeemIkhfaColor, isNotNull);
      expect(kMeemIdghamColor, isNotNull);
      expect(kNormalMaadColor, isNotNull);
      expect(kMaadSukoonColor, isNotNull);
      expect(kMaadConnectedColor, isNotNull);
      expect(kMaadLongColor, isNotNull);
      expect(kTafkhimColor, isNotNull);
    });

    test('green group (ghunnah/ikhfa/iqlab/meem) share same hex', () {
      const greenHex = 0xFF43A047;
      expect(kGhunnahColor.value, greenHex);
      expect(kIdghamGhunnahColor.value, greenHex);
      expect(kIkhfaColor.value, greenHex);
      expect(kIqlabColor.value, greenHex);
      expect(kMeemIkhfaColor.value, greenHex);
      expect(kMeemIdghamColor.value, greenHex);
    });

    test('kNotPronouncedColor returns different grey for dark vs light', () {
      final dark = kNotPronouncedColor(Brightness.dark);
      final light = kNotPronouncedColor(Brightness.light);
      expect(dark, isNotNull);
      expect(light, isNotNull);
      expect(dark.value, isNot(equals(light.value)));
    });

    test('madd colours are distinct', () {
      expect(kNormalMaadColor.value, isNot(equals(kMaadSukoonColor.value)));
      expect(kMaadSukoonColor.value, isNot(equals(kMaadConnectedColor.value)));
      expect(kMaadConnectedColor.value, isNot(equals(kMaadLongColor.value)));
    });
  });
}
