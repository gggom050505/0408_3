import 'dart:async';

import 'package:flutter/material.dart';

/// 탭 전환 등 [AnimatedSwitcher]용 — 페이드 + 미세 슬라이드.
Widget tabSwitchChildTransition(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.028),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// 한 번만 재생되는 페이드 + 위로 스침 + 살짝 스케일.
class AppearAnimation extends StatefulWidget {
  const AppearAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 460),
    this.curve = Curves.easeOutCubic,
    this.slidePx = 22,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double slidePx;

  @override
  State<AppearAnimation> createState() => _AppearAnimationState();
}

class _AppearAnimationState extends State<AppearAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: widget.curve,
  );
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _c.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.slidePx * (1 - v)),
            child: Transform.scale(
              scale: 0.94 + v * 0.06,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 리스트·섹션 스태거 — [index]당 약 55ms 간격(상한 캡).
class StaggerItem extends StatelessWidget {
  const StaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.baseMs = 55,
    this.maxIndex = 18,
  });

  final int index;
  final Widget child;
  final int baseMs;
  final int maxIndex;

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, maxIndex);
    return AppearAnimation(
      delay: Duration(milliseconds: baseMs * i),
      duration: Duration(milliseconds: 380 + (i * 8).clamp(0, 120)),
      child: child,
    );
  }
}

/// 페이지 라우트용 짧은 페이드 + 아래에서 올라옴.
class GgomFadeUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const GgomFadeUpwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
