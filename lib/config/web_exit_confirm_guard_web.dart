import 'dart:async';

import 'package:web/web.dart' as web;

StreamSubscription<web.BeforeUnloadEvent>? _beforeUnloadSub;
var _temporarilyAllowLeaving = false;

void installWebExitConfirmGuard() {
  _beforeUnloadSub ??=
      web.EventStreamProviders.beforeUnloadEvent.forTarget(web.window).listen(
    (web.BeforeUnloadEvent event) {
      if (_temporarilyAllowLeaving) {
        return;
      }
      event.preventDefault();
      // 대부분 브라우저는 고정 문구만 표시합니다.
      event.returnValue = '';
    },
  );
}

void uninstallWebExitConfirmGuard() {
  _beforeUnloadSub?.cancel();
  _beforeUnloadSub = null;
}

void allowSingleNavigationWithoutConfirm([Duration? duration]) {
  _temporarilyAllowLeaving = true;
  // OAuth 이동 시작 시 네트워크 지연으로 3초를 넘는 경우가 있어 충분히 여유를 둔다.
  Timer(duration ?? const Duration(seconds: 3), () {
    _temporarilyAllowLeaving = false;
  });
}
