/// Thin wrappers around [HapticFeedback] for consistent tactile cues.
///
/// Safe to call on every platform — web and desktop no-op when the
/// engine has no haptic device. Centralising call sites here lets us
/// later honour reduce-motion / `disableAnimations` in one place.
library;

import 'package:flutter/services.dart';

/// Named haptic helpers used across Hublee UI.
abstract final class AppHaptics {
  AppHaptics._();

  /// Tab switches, toggles, chips, and scrubber index steps.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Bookmark add/remove and other discrete "commit" actions.
  static Future<void> lightImpact() => HapticFeedback.lightImpact();
}
