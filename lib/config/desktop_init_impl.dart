import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'window_geometry_store.dart';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

Future<void> initDesktopWindow() async {
  if (!_isDesktop) return;

  await windowManager.ensureInitialized();

  final saved = await WindowGeometryStore.load();
  const fallback = Size(1280, 720);
  final options = WindowOptions(
    size: saved != null ? Size(saved.width, saved.height) : fallback,
    center: saved == null,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: const Size(400, 500),
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (saved != null) {
      await windowManager.setBounds(saved);
    }
    await windowManager.show();
    await windowManager.focus();
  });

  await windowManager.setPreventClose(true);
  windowManager.addListener(_SaveBoundsOnClose());
}

class _SaveBoundsOnClose with WindowListener {
  @override
  void onWindowClose() {
    Future(() async {
      try {
        final rect = await windowManager.getBounds();
        await WindowGeometryStore.save(rect);
      } finally {
        await windowManager.destroy();
      }
    });
  }
}
