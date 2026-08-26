/// Android home-screen widget sync. No-op on other platforms.
library;

export 'home_widget_sync_stub.dart'
    if (dart.library.io) 'home_widget_sync_io.dart';
