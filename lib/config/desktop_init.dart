import 'desktop_init_impl.dart' if (dart.library.html) 'desktop_init_stub.dart' as impl;

Future<void> initDesktopWindow() => impl.initDesktopWindow();
