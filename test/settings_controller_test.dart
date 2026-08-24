/// Unit tests for [SettingsController] zoom debounce behaviour.
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/services/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('zoom setters notify immediately but debounce disk writes', () {
    fakeAsync((async) {
      final controller = SettingsController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // load() is async; flush so prefs are ready before assertions.
      controller.load();
      async.flushMicrotasks();
      notifications = 0;

      controller.arabicZoom = 1.1;
      controller.arabicZoom = 1.2;
      controller.arabicZoom = 1.3;

      expect(controller.arabicZoom, 1.3);
      expect(notifications, 3);

      // Still inside the debounce window — nothing on disk yet.
      async.elapse(const Duration(milliseconds: 299));
      async.flushMicrotasks();

      SharedPreferences.getInstance().then((prefs) {
        expect(prefs.getDouble('settings.arabicZoom'), isNull);
      });
      async.flushMicrotasks();

      // After the debounce, a single write of the latest value.
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();

      SharedPreferences.getInstance().then((prefs) {
        expect(prefs.getDouble('settings.arabicZoom'), 1.3);
      });
      async.flushMicrotasks();

      controller.dispose();
    });
  });

  test('dispose flushes a pending zoom write', () {
    fakeAsync((async) {
      final controller = SettingsController();
      controller.load();
      async.flushMicrotasks();

      controller.englishZoom = 1.5;
      // Dispose before the debounce fires.
      controller.dispose();
      async.flushMicrotasks();

      SharedPreferences.getInstance().then((prefs) {
        expect(prefs.getDouble('settings.englishZoom'), 1.5);
      });
      async.flushMicrotasks();
    });
  });

  test('tajweed toggle persists immediately', () {
    fakeAsync((async) {
      final controller = SettingsController();
      controller.load();
      async.flushMicrotasks();

      controller.tajweedEnabled = false;
      async.flushMicrotasks();

      SharedPreferences.getInstance().then((prefs) {
        expect(prefs.getBool('settings.tajweedEnabled'), isFalse);
      });
      async.flushMicrotasks();

      controller.dispose();
    });
  });

  test('showTranslation defaults on and persists', () {
    fakeAsync((async) {
      final controller = SettingsController();
      controller.load();
      async.flushMicrotasks();

      expect(controller.showTranslation, isTrue);
      controller.showTranslation = false;
      async.flushMicrotasks();

      SharedPreferences.getInstance().then((prefs) {
        expect(prefs.getBool('settings.showTranslation'), isFalse);
      });
      async.flushMicrotasks();

      controller.dispose();
    });
  });
}
