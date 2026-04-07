import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../theme/app_colors.dart';
import 'app_motion.dart';

/// 별조각 광고 — [adVideoAssetPaths]를 순서대로 **한 번에 1편** 재생 후 「별조각 획득」 안내·별조각 지급,
/// [AppConfig.adRewardCooldownMinutes] 간격 제한. 진입: GNB·상점 배너.
class AdRewardSheet extends StatelessWidget {
  const AdRewardSheet({
    super.key,
    required this.userId,
    required this.shopRepo,
    required this.onBalanceRefresh,
    this.messengerKey,
  });

  final String userId;
  final ShopDataSource shopRepo;
  final Future<void> Function() onBalanceRefresh;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  /// `assets/advert/` 의 MP4. 매 시청마다 다음 인덱스로 순환(한 회차에 1편만 재생).
  /// 파일을 바꾸면 이 목록과 `pubspec.yaml`의 `assets/advert/` 항목을 맞춰 주세요.
  static const List<String> adVideoAssetPaths = <String>[
    'assets/advert/gdk15s.mp4',
    'assets/advert/wk15s.mp4',
  ];

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required ShopDataSource shopRepo,
    required Future<void> Function() onBalanceRefresh,
    GlobalKey<ScaffoldMessengerState>? messengerKey,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => AdRewardSheet(
        userId: userId,
        shopRepo: shopRepo,
        onBalanceRefresh: onBalanceRefresh,
        messengerKey: messengerKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (ctx, scrollController) => AppearAnimation(
        duration: const Duration(milliseconds: 400),
        slidePx: 28,
        child: Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: const Color(0xFFF7F2EC),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(ctx).bottom + 16,
              top: 12,
            ),
            child: _AdRewardActions(
              userId: userId,
              shopRepo: shopRepo,
              onBalanceRefresh: onBalanceRefresh,
              messengerKey: messengerKey,
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );
  }
}

/// `assets/advert/*.mp4`가 없거나(또는 코덱 문제로) 재생 실패할 때 1회 시도하는 짧은 데모 소스.
/// 실제 광고·프로모 영상은 `assets/advert/`에 MP4를 넣는 것을 권장합니다.
const String _kFallbackBetaAdVideoUrl =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

/// 전체 화면 광고 영상 1편. 재생 완료 시 `true`, 초기화·재생 실패 시 `false`.
class _AdRewardVideoDialog extends StatefulWidget {
  const _AdRewardVideoDialog({required this.assetPath});

  final String assetPath;

  @override
  State<_AdRewardVideoDialog> createState() => _AdRewardVideoDialogState();
}

class _AdRewardVideoDialogState extends State<_AdRewardVideoDialog> {
  VideoPlayerController? _controller;
  var _ended = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<VideoPlayerController?> _tryAttach(VideoPlayerController c) async {
    c.addListener(_onVideoUpdate);
    try {
      await c.initialize();
    } catch (e, st) {
      debugPrint('AdReward video init failed (${widget.assetPath}): $e\n$st');
      c.removeListener(_onVideoUpdate);
      await c.dispose();
      return null;
    }
    if (!mounted) {
      c.removeListener(_onVideoUpdate);
      await c.dispose();
      return null;
    }
    if (c.value.hasError) {
      c.removeListener(_onVideoUpdate);
      await c.dispose();
      return null;
    }
    return c;
  }

  Future<void> _init() async {
    VideoPlayerController? c = await _tryAttach(
      VideoPlayerController.asset(
        widget.assetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      ),
    );

    // `assets/advert/`에 MP4가 없거나 깨진 경우 등 — 데모 영상으로 1회 시도.
    c ??= await _tryAttach(
      VideoPlayerController.networkUrl(
        Uri.parse(_kFallbackBetaAdVideoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      ),
    );

    if (c == null) {
      if (mounted && !_ended) {
        _ended = true;
        Navigator.of(context).pop(false);
      }
      return;
    }

    _controller = c;
    if (!mounted) {
      return;
    }
    setState(() {});
    await c.play();
    if (!mounted) {
      return;
    }
    if (c.value.hasError && !_ended) {
      _ended = true;
      Navigator.of(context).pop(false);
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _ended) {
      return;
    }
    final c = _controller;
    if (c == null) {
      return;
    }
    final v = c.value;
    if (v.hasError) {
      _ended = true;
      Navigator.of(context).pop(false);
      return;
    }
    if (v.isCompleted) {
      _ended = true;
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onVideoUpdate);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: c == null || !c.value.isInitialized
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      '광고를 불러오는 중…',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              : AspectRatio(
                  aspectRatio: c.value.aspectRatio == 0
                      ? 16 / 9
                      : c.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
        ),
      ),
    );
  }
}

class _AdRewardActions extends StatefulWidget {
  const _AdRewardActions({
    required this.userId,
    required this.shopRepo,
    required this.onBalanceRefresh,
    required this.scrollController,
    this.messengerKey,
  });

  final String userId;
  final ShopDataSource shopRepo;
  final Future<void> Function() onBalanceRefresh;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  final ScrollController scrollController;

  @override
  State<_AdRewardActions> createState() => _AdRewardActionsState();
}

class _AdRewardActionsState extends State<_AdRewardActions> {
  var _busy = false;
  Duration _cooldownLeft = Duration.zero;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_reloadCooldown());
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_reloadCooldown());
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<Duration> _remainingCooldown() async {
    final last = await LocalAppPreferences.getAdRewardLastCompletedUtc(
      widget.userId,
    );
    if (last == null) {
      return Duration.zero;
    }
    final next = last.add(Duration(minutes: AppConfig.adRewardCooldownMinutes));
    final left = next.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _reloadCooldown() async {
    final d = await _remainingCooldown();
    if (!mounted) {
      return;
    }
    setState(() => _cooldownLeft = d);
  }

  String _formatCooldown(Duration d) {
    if (d <= Duration.zero) {
      return '';
    }
    final totalSec = d.inSeconds;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showAdVideoThenGrant() async {
    if (_busy) {
      return;
    }
    final left = await _remainingCooldown();
    if (left > Duration.zero) {
      widget.messengerKey?.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '다음 광고까지 ${_formatCooldown(left)} 남았어요. (${AppConfig.adRewardCooldownMinutes}분 간격)',
          ),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _busy = true);

    final paths = AdRewardSheet.adVideoAssetPaths;
    if (paths.isEmpty) {
      if (mounted) {
        setState(() => _busy = false);
        widget.messengerKey?.currentState?.showSnackBar(
          const SnackBar(content: Text('등록된 광고 영상이 없어요.')),
        );
      }
      return;
    }

    final rawIdx = await LocalAppPreferences.getAdRewardNextPromoAssetIndex(
      widget.userId,
    );
    if (!mounted) {
      return;
    }
    final n = paths.length;
    final videoIdx = n <= 0 ? 0 : rawIdx % n;
    final assetPath = paths[videoIdx];

    final watched = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: _AdRewardVideoDialog(assetPath: assetPath),
      ),
    );

    if (!mounted) {
      return;
    }

    if (watched != true) {
      setState(() => _busy = false);
      if (watched == false && mounted) {
        widget.messengerKey?.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '광고 영상을 재생하지 못했어요.\n'
              '`assets/advert/`에 gdk15s.mp4·wk15s.mp4 등을 넣었는지 확인해 주세요. '
              '웹 빌드에서 폴백 재생 시 인터넷이 필요할 수 있어요.',
            ),
          ),
        );
      }
      return;
    }

    final profile = await widget.shopRepo.grantAdRewardStars(
      widget.userId,
      amount: AppConfig.adRewardStarAmount,
    );

    if (!mounted) {
      return;
    }

    if (profile != null) {
      await LocalAppPreferences.setAdRewardLastCompletedUtc(
        widget.userId,
        DateTime.now().toUtc(),
      );
      final nextIdx = (videoIdx + 1) % paths.length;
      await LocalAppPreferences.setAdRewardNextPromoAssetIndex(
        widget.userId,
        nextIdx,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() => _busy = false);

    if (profile != null) {
      await widget.onBalanceRefresh();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('별조각 획득'),
          content: Text(
            '광고 시청을 완료해 별조각 ${AppConfig.adRewardStarAmount}개를 드렸어요.\n\n'
            '현재 보유: ${profile.starFragments}개',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      widget.messengerKey?.currentState?.showSnackBar(
        const SnackBar(content: Text('보상 지급에 실패했어요.')),
      );
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCooldown = _cooldownLeft > Duration.zero;
    final cdLabel = onCooldown ? _formatCooldown(_cooldownLeft) : '';

    return ListView(
      controller: widget.scrollController,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          '⭐ 별조각 광고',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '「광고 시청」을 누르면 영상 1편이 재생돼요. 끝까지 보면 별조각 ${AppConfig.adRewardStarAmount}개를 드리며, '
          '확인 창에 「별조각 획득」으로 알려 드려요. '
          '같은 계정으로는 ${AppConfig.adRewardCooldownMinutes}분에 한 번 시청할 수 있고, '
          '볼 때마다 gdk15s → wk15s 순으로 돌아가며 다른 영상이 나와요.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.38),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.accentPurple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '쿨타임 안내',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• 별조각을 받은 직후부터 ${AppConfig.adRewardCooldownMinutes}분 동안은 같은 계정으로 광고를 다시 볼 수 없어요.\n'
                '• 남은 대기 시간은 아래에 분·초(MM:SS)로 표시돼요.\n'
                '• 광고 영상은 `assets/advert/`의 MP4를 써요 (예: gdk15s.mp4, wk15s.mp4).\n'
                '• 파일이 없거나 재생이 안 되면 짧은 데모 영상(웹에서는 인터넷 필요)으로 대체돼요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (onCooldown) ...[
          const SizedBox(height: 10),
          Text(
            '다음 광고까지 $cdLabel',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.accentPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentLilac.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안내',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPurple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '앱에 넣은 MP4를 ${AppConfig.adRewardCooldownMinutes}분 간격으로 재생한 뒤 '
                '별조각 ${AppConfig.adRewardStarAmount}개를 지급해요.\n'
                '상단 · 상점의 「별조각 광고」와 같은 메뉴예요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: (_busy || onCooldown) ? null : _showAdVideoThenGrant,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentPurple,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.smart_display_outlined),
          label: Text(
            _busy
                ? '처리 중…'
                : onCooldown
                ? '다음 광고까지 $cdLabel'
                : '광고 시청 (⭐ ${AppConfig.adRewardStarAmount}개)',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            AppConfig.adInquiryContactLine,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
