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

void allowSingleNavigationWithoutConfirm() {
  _temporarilyAllowLeaving = true;
  // OAuth 이동 직전 1회만 우회하고, 곧바로 원복한다.
  Timer(const Duration(seconds: 3), () {
    _temporarilyAllowLeaving = false;
  });
}
