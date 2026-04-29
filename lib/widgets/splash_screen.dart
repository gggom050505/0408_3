import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/opening_assets.dart';
import '../config/gggom_offline_landing.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

/// 오프닝: `assets/opening/` 이미지가 있으면 순서대로 표시 후 종료. 없으면 기본 splash 1프레임.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  var _completed = false;
  var _loaded = false;
  List<String> _openingPaths = [];
  var _carouselIndex = 0;
  PageController? _pageController;
  Timer? _carouselTimer;

  late final AnimationController _shineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  void _goNext() {
    if (_completed || !mounted) return;
    _completed = true;
    _carouselTimer?.cancel();
    _shineController.stop();
    widget.onComplete();
  }

  @override
  void initState() {
    super.initState();
    _shineController.repeat();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final paths = await loadOpeningImageAssetPaths();
    if (!mounted) return;
    setState(() {
      _openingPaths = paths;
      _loaded = true;
      if (paths.isNotEmpty) {
        _pageController = PageController();
      }
    });
    if (paths.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _armCarouselStep());
    }
  }

  /// 현재 페이지 기준으로 잠시 뒤 다음 페이지 또는 종료.
  void _armCarouselStep() {
    _carouselTimer?.cancel();
    if (_completed || !mounted || _openingPaths.isEmpty) return;
    _carouselTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _completed) return;
      final pc = _pageController;
      if (pc == null || !pc.hasClients) {
        _armCarouselStep();
        return;
      }
      final i = pc.page?.round() ?? 0;
      if (i >= _openingPaths.length - 1) {
        _goNext();
      } else {
        pc.animateToPage(
          i + 1,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController?.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: kGggomSiteSplashGradientColors,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.accentPurple.withValues(alpha: 0.5), size: 40),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_openingPaths.isNotEmpty) {
      return Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goNext,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: kGggomSiteSplashGradientColors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _carouselIndex = i);
                    _armCarouselStep();
                  },
                  itemCount: _openingPaths.length,
                  itemBuilder: (context, index) {
                    return _OpeningImagePage(
                      assetPath: _openingPaths[index],
                      shineAnimation: _shineController,
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 48,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_openingPaths.length, (i) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.4, end: 1),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOut,
                          builder: (context, v, child) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentPurple.withValues(
                                  alpha: 0.4 +
                                      (i == _carouselIndex ? 0.5 : 0) *
                                          (v % 1),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goNext,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: kGggomSiteSplashGradientColors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Image.asset(
                          kGggomSiteSplashPngAsset,
                          fit: BoxFit.contain,
                          semanticLabel: '$kGggomSiteBrowserTitle 오프닝 이미지',
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _shineController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _OpeningShinePainter(
                                  t: _shineController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: const Alignment(-0.85, -0.35),
                                end: const Alignment(0.85, 0.35),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                                stops: const [0.35, 0.5, 0.65],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 48,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(1, (i) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, v, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentPurple.withValues(
                                alpha: 0.4 + (i == 0 ? 0.5 : 0) * (v % 1),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpeningImagePage extends StatelessWidget {
  const _OpeningImagePage({
    required this.assetPath,
    required this.shineAnimation,
  });

  final String assetPath;
  final Animation<double> shineAnimation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AdaptiveNetworkOrAssetImage(
                src: assetPath,
                fit: BoxFit.contain,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: shineAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _OpeningShinePainter(
                        t: shineAnimation.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.85, -0.35),
                      end: const Alignment(0.85, 0.35),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 대각선 빛 띠가 좌→우로 지나가는 반사 느낌 (낮은 알파·넓은 밴드로 은은하게).
class _OpeningShinePainter extends CustomPainter {
  _OpeningShinePainter({required this.t});

  final double t;

  static const _tilt = -math.pi / 5.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final bandW = size.shortestSide * 0.58;
    final travel = size.width + bandW * 2.4;
    final x0 = -bandW * 1.2 + travel * Curves.easeInOut.transform(t);

    canvas.saveLayer(Offset.zero & size, Paint());

    canvas.save();
    canvas.translate(x0, size.height * 0.08);
    canvas.rotate(_tilt);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: bandW,
      height: size.height * 2.4,
    );

    final shimmer = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.03),
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.2),
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.03),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.24, 0.38, 0.5, 0.62, 0.76, 1.0],
    );

    final core = Paint()
      ..shader = shimmer.createShader(rect)
      ..blendMode = BlendMode.softLight;

    canvas.drawRect(rect, core);

    final glossRect = Rect.fromCenter(
      center: Offset(-bandW * 0.02, 0),
      width: bandW * 0.2,
      height: size.height * 2.2,
    );
    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(glossRect)
      ..blendMode = BlendMode.screen;

    canvas.drawRect(glossRect, gloss);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OpeningShinePainter oldDelegate) =>
      oldDelegate.t != t;
}
