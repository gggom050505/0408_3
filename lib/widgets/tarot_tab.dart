import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'tarot_capture_download_stub.dart'
    if (dart.library.html) 'tarot_capture_download_web.dart'
    as tarot_download;
import 'tarot_share_non_web.dart'
    if (dart.library.html) 'tarot_share_non_web_stub.dart'
    as share_non_web;

import '../config/app_config.dart';
import '../data/card_themes.dart';
import '../data/deck_card_catalog.dart';
import '../data/mat_themes.dart';
import '../data/tarot_cards.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../standalone/local_json_store.dart';
import '../standalone/tarot_session_restore.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'oracle_modal.dart';
import 'post_capture_sheet.dart';
import 'result_modal.dart';
import 'tarot_capture_clipboard.dart';

const _totalSlots = 9;
const _deckN = 22;

/// 타로 보드 세로÷가로 비(값이 작을수록 같은 높이에서 보드가 가로로 더 넓어짐).
const _slotBoardAspect = 1.16;

/// 골드(아이보리) 링 — 작을수록 흰 슬롯이 패널에 더 꽉 참.
const _slotGridPadLr = 0.026;
const _slotGridPadTop = 0.022;
const _slotGridPadBottom = 0.028;

class TarotTab extends StatefulWidget {
  const TarotTab({
    super.key,
    this.userId,
    this.displayName = '나',
    this.avatarEmojiOrUrl = '🔮',
    this.equippedCardThemeId = 'default',
    this.equippedMatId = 'default-mint',
    this.equippedCardBackId = 'default-card-back',
    this.equippedCardBackImageSrc,
    this.equippedSlotId = 'slot-decor-1',
    this.emptySlotDecorationSrc,
    this.ownedOracleCardNumbers = const [],
    this.ownedKoreaMajorCardIds = const [],
    this.feedRepository,
    required this.onNeedLogin,
    this.onPostedToFeed,
    this.workspaceFlushSignal,
  });

  final String? userId;
  final String displayName;
  final String avatarEmojiOrUrl;
  final String equippedCardThemeId;
  final String equippedMatId;

  /// 가방 장착 ID — 타로 판 세션 복원 시 테마·매트와 함께 검증.
  final String equippedCardBackId;

  /// 장착한 `card_back` 상품 썸네일(또는 등록 이미지). 없으면 기본 보라 뒷면 그라데이션.
  final String? equippedCardBackImageSrc;

  /// 상점 `type: slot` 장착 ID.
  final String equippedSlotId;

  /// 빈 슬롯(미배치)에 깔 프레임 이미지. `null`이면 흰 칸+「슬롯」 문구.
  final String? emptySlotDecorationSrc;

  /// 가방에 있는 오라클 카드 번호(1~80). 뽑기는 이 목록에서만 랜덤.
  final List<int> ownedOracleCardNumbers;

  /// 보유한 한국전통 메이저 타로 카드 id (0~21). 일부 혼합 덱에서 사용.
  final List<int> ownedKoreaMajorCardIds;
  final FeedDataSource? feedRepository;
  final VoidCallback onNeedLogin;
  final VoidCallback? onPostedToFeed;

  /// 홈「저장하기」에서 증가시키면 타로 세션을 즉시 디스크에 씁니다.
  final ValueNotifier<int>? workspaceFlushSignal;

  @override
  State<TarotTab> createState() => _TarotTabState();
}

class _TarotTabState extends State<TarotTab> with WidgetsBindingObserver {
  final _capKeyOneRow = GlobalKey();
  final _capKeyTwoRows = GlobalKey();
  final _capKeyThreeRows = GlobalKey();
  late List<TarotCard> _deck22;
  final List<int?> _placed = List.filled(_totalSlots, null);
  final Set<int> _flipped = {};
  final Set<int> _used = {};
  bool _showCardDescriptionOnFlip = true;

  ValueNotifier<int>? _flushListenTarget;

  void _bindWorkspaceFlushSignal() {
    if (_flushListenTarget == widget.workspaceFlushSignal) {
      return;
    }
    _flushListenTarget?.removeListener(_onWorkspaceFlushSignal);
    _flushListenTarget = widget.workspaceFlushSignal;
    _flushListenTarget?.addListener(_onWorkspaceFlushSignal);
  }

  void _onWorkspaceFlushSignal() => unawaited(_persistSession());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindWorkspaceFlushSignal();
    _deck22 = _reshuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_tryRestoreSession());
      unawaited(_loadShowCardDescriptionOnFlipPref());
    });
  }

  Future<void> _loadShowCardDescriptionOnFlipPref() async {
    final v = await LocalAppPreferences.getShowCardDescriptionOnFlip(
      widget.userId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _showCardDescriptionOnFlip = v);
  }

  @override
  void dispose() {
    _flushListenTarget?.removeListener(_onWorkspaceFlushSignal);
    WidgetsBinding.instance.removeObserver(this);
    _persistSessionSnapshot();
    super.dispose();
  }

  @override
  void didUpdateWidget(TarotTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      unawaited(_loadShowCardDescriptionOnFlipPref());
    }
    if (oldWidget.workspaceFlushSignal != widget.workspaceFlushSignal) {
      _bindWorkspaceFlushSignal();
    }
    if (oldWidget.equippedCardThemeId != widget.equippedCardThemeId) {
      setState(() {
        _deck22 = _reshuffle();
        for (var i = 0; i < _totalSlots; i++) {
          _placed[i] = null;
        }
        _flipped.clear();
        _used.clear();
      });
      unawaited(_persistSession());
    } else if (oldWidget.equippedSlotId != widget.equippedSlotId) {
      unawaited(_persistSession());
    } else if (widget.equippedCardThemeId == koreaTraditionalMajorThemeId &&
        !listEquals(
          oldWidget.ownedKoreaMajorCardIds,
          widget.ownedKoreaMajorCardIds,
        )) {
      setState(() {
        _deck22 = _reshuffle();
        for (var i = 0; i < _totalSlots; i++) {
          _placed[i] = null;
        }
        _flipped.clear();
        _used.clear();
      });
      unawaited(_persistSession());
    } else if (widget.equippedCardThemeId ==
            mixedMinorKoreaTraditionalMajorThemeId &&
        !listEquals(
          oldWidget.ownedKoreaMajorCardIds,
          widget.ownedKoreaMajorCardIds,
        )) {
      setState(() {
        _deck22 = _reshuffle();
        for (var i = 0; i < _totalSlots; i++) {
          _placed[i] = null;
        }
        _flipped.clear();
        _used.clear();
      });
      unawaited(_persistSession());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistSessionSnapshot();
    }
  }

  /// [dispose] 이후에도 안전하도록 필드를 즉시 복사해 디스크에 씁니다.
  void _persistSessionSnapshot() {
    try {
      final name = _sessionFileName();
      final payload = _sessionPayload();
      unawaited(saveLocalJsonFile(name, jsonEncode(payload)));
    } catch (_) {}
  }

  String _sessionFileName() {
    final id = widget.userId ?? 'guest';
    final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'local_tarot_session_v1_$safe.json';
  }

  Map<String, dynamic> _sessionPayload() {
    final placed = List<int?>.generate(_totalSlots, (i) => _placed[i]);
    return {
      'version': 1,
      'equipped_card_theme': widget.equippedCardThemeId,
      'equipped_mat': widget.equippedMatId,
      'equipped_card_back': widget.equippedCardBackId,
      'equipped_slot': widget.equippedSlotId,
      'deck_card_ids': _deck22.map((c) => c.id).toList(),
      'placed': placed,
      'flipped': _flipped.toList()..sort(),
    };
  }

  Future<void> _persistSession() async {
    try {
      await saveLocalJsonFile(
        _sessionFileName(),
        jsonEncode(_sessionPayload()),
      );
    } catch (_) {}
  }

  Future<void> _tryRestoreSession() async {
    try {
      final raw = await loadLocalJsonFile(_sessionFileName());
      if (raw == null || raw.isEmpty || !mounted) {
        return;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final restored = tryRestoreTarotSessionV1FromMap(map);
      if (restored == null || !mounted) {
        return;
      }
      // 매트·뒷면·덱 테마는 상점에서 바뀔 수 있음. 카드 id·배치는 그대로 복원하고
      // 복원 직후 저장으로 메타만 현재 장착에 맞춘다.
      final byId = {for (final c in tarotDeck) c.id: c};
      final rebuilt = restored.deckCardIds.map((id) => byId[id]!).toList();
      final koreaMajor =
          widget.equippedCardThemeId == koreaTraditionalMajorThemeId;
      final mixedMinorKorea =
          widget.equippedCardThemeId == mixedMinorKoreaTraditionalMajorThemeId;
      final allowedKorea = widget.ownedKoreaMajorCardIds.toSet();
      if (koreaMajor &&
          rebuilt.any(
            (c) => !tarotCardAllowedInKoreaTraditionalMajorFullPool(c),
          )) {
        if (!mounted) return;
        setState(() {
          _deck22 = _reshuffle();
          for (var i = 0; i < _totalSlots; i++) {
            _placed[i] = null;
          }
          _flipped.clear();
          _used.clear();
        });
        unawaited(_persistSession());
        return;
      }
      if (mixedMinorKorea &&
          rebuilt.any(
            (c) => !tarotCardAllowedInMixedMinorKoreaPool(c, allowedKorea),
          )) {
        if (!mounted) return;
        setState(() {
          _deck22 = _reshuffle();
          for (var i = 0; i < _totalSlots; i++) {
            _placed[i] = null;
          }
          _flipped.clear();
          _used.clear();
        });
        unawaited(_persistSession());
        return;
      }
      final usedIdx = {
        for (var i = 0; i < tarotSessionSlotCount; i++)
          if (restored.placedDeckIndices[i] != null)
            restored.placedDeckIndices[i]!,
      };
      setState(() {
        _deck22 = rebuilt;
        for (var i = 0; i < _totalSlots; i++) {
          _placed[i] = restored.placedDeckIndices[i];
        }
        _used
          ..clear()
          ..addAll(usedIdx);
        _flipped
          ..clear()
          ..addAll(restored.flippedSlots);
      });
      unawaited(_persistSession());
    } catch (_) {}
  }

  List<TarotCard> _reshuffle() {
    List<TarotCard> source;
    if (widget.equippedCardThemeId == koreaTraditionalMajorThemeId) {
      source = buildMinorClayAndKoreaTraditionalFullDrawPool();
    } else if (widget.equippedCardThemeId ==
        mixedMinorKoreaTraditionalMajorThemeId) {
      source = buildMixedMinorAndKoreaTraditionalDrawPool(
        ownedKoreaMajorIds: widget.ownedKoreaMajorCardIds.toSet(),
      );
    } else {
      source = tarotDeck;
    }
    final s = shuffleDeck(List<TarotCard>.from(source));
    final n = math.min(_deckN, s.length);
    return s.take(n).toList();
  }

  void _reset() {
    setState(() {
      _deck22 = _reshuffle();
      for (var i = 0; i < _totalSlots; i++) {
        _placed[i] = null;
      }
      _flipped.clear();
      _used.clear();
    });
    unawaited(_persistSession());
  }

  void _place(int deckIdx, int slotIdx) {
    if (_placed[slotIdx] != null) return;
    setState(() {
      _placed[slotIdx] = deckIdx;
      _used.add(deckIdx);
    });
    unawaited(_persistSession());
  }

  String _themeIdForCardFront(TarotCard card) {
    if (widget.equippedCardThemeId == koreaTraditionalMajorThemeId) {
      return resolveFrontThemeForKoreaTraditionalDeckCard(card);
    }
    if (widget.equippedCardThemeId == majorClayThemeId) {
      return resolveFrontThemeForMajorClayDeckCard(card);
    }
    if (widget.equippedCardThemeId == mixedMinorKoreaTraditionalMajorThemeId) {
      if (card.id >= 0 && card.id <= 21 && card.arcana == 'major') {
        return koreaTraditionalMajorThemeId;
      }
      return defaultThemeId;
    }
    return widget.equippedCardThemeId;
  }

  String? _cardFrontImageSrc(TarotCard card) {
    final themeId = _themeIdForCardFront(card);
    return getCardImageUrl(
          themeId: themeId,
          cardId: card.id,
          assetOrigin: AppConfig.assetOrigin,
        ) ??
        getBundledSiteCardAssetPath(themeId: themeId, cardId: card.id);
  }

  Future<void> _onSlotTap(int slotIdx) async {
    final d = _placed[slotIdx];
    if (d == null) return;
    final card = _deck22[d];
    final img = _cardFrontImageSrc(card);

    if (_flipped.contains(slotIdx)) {
      if (!_showCardDescriptionOnFlip) {
        return;
      }
      await showResultModal(
        context,
        cardName: card.nameKo,
        meaning: card.meaning,
        advice: card.advice,
        cardImageSrc: img,
      );
      return;
    }

    setState(() => _flipped.add(slotIdx));
    unawaited(_persistSession());
    if (!_showCardDescriptionOnFlip) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await showResultModal(
      context,
      cardName: card.nameKo,
      meaning: card.meaning,
      advice: card.advice,
      cardImageSrc: img,
    );
  }

  Future<bool> _tryCopyCaptureClipboard(Uint8List bytes) async {
    try {
      return await copyTarotCapturePngToClipboard(bytes);
    } catch (e, st) {
      debugPrint('Tarot clipboard: $e\n$st');
      return false;
    }
  }

  Future<void> _shareCaptureBytes(
    Uint8List bytes, {
    bool copiedToClipboard = false,
  }) async {
    try {
      const typePng = XTypeGroup(label: 'PNG', extensions: ['png']);
      final suggested =
          'gggom_taro_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        try {
          tarot_download.tryDownloadPngInBrowser(bytes, suggested);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('이미지 저장에 실패했어요: $e')));
          }
          return;
        }
        if (mounted) {
          final clip = copiedToClipboard
              ? ' 클립보드에도 복사했어요. 카톡 웹 등에서 붙여넣기를 시도해 보세요.'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PNG 다운로드를 시작했어요.$clip '
                '반응이 없으면 브라우저의 다운로드·팝업 차단을 허용해 주세요.',
              ),
            ),
          );
        }
        return;
      }

      await share_non_web.shareCaptureNonWeb(
        context: context,
        bytes: bytes,
        suggested: suggested,
        typePng: typePng,
        copiedToClipboard: copiedToClipboard,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장·공유를 완료하지 못했어요: $e')));
      }
    }
  }

  /// 놓인 카드가 있는 **가장 아래 줄**(1-based: 1~3). 카드가 없으면 `null`.
  int? _spreadRowCountToCapture() {
    var deepest = -1;
    for (var slot = 0; slot < _totalSlots; slot++) {
      if (_placed[slot] != null) {
        final row = slot ~/ 3;
        if (row > deepest) deepest = row;
      }
    }
    if (deepest < 0) {
      return null;
    }
    return deepest + 1;
  }

  Future<Uint8List?> _captureToPng({required int rowCount}) async {
    assert(rowCount >= 1 && rowCount <= 3);
    try {
      final GlobalKey capKey = switch (rowCount) {
        1 => _capKeyOneRow,
        2 => _capKeyTwoRows,
        _ => _capKeyThreeRows,
      };
      final ctx = capKey.currentContext;
      if (ctx == null) {
        debugPrint('Tarot capture: RepaintBoundary context null');
        return null;
      }
      final ro = ctx.findRenderObject();
      if (ro is! RenderRepaintBoundary) {
        debugPrint(
          'Tarot capture: expected RenderRepaintBoundary, got ${ro.runtimeType}',
        );
        return null;
      }
      if (!ro.hasSize) {
        debugPrint('Tarot capture: RepaintBoundary has no size');
        return null;
      }

      for (var i = 0; i < 2; i++) {
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
      }
      await Future<void>.delayed(Duration(milliseconds: kIsWeb ? 160 : 80));

      var pixelRatio = 2.0;
      if (ctx.mounted) {
        final mq = MediaQuery.maybeOf(ctx);
        if (mq != null) {
          pixelRatio = mq.devicePixelRatio;
        }
      }
      pixelRatio = rowCount <= 2
          ? pixelRatio.clamp(1.0, 2.5)
          : pixelRatio.clamp(1.0, 2.0);

      for (var attempt = 0; attempt < 2; attempt++) {
        ui.Image? img;
        try {
          img = await ro.toImage(pixelRatio: pixelRatio);
          final bd = await img.toByteData(format: ui.ImageByteFormat.png);
          if (bd == null) {
            debugPrint('Tarot capture: toByteData returned null');
            return null;
          }
          return bd.buffer.asUint8List();
        } catch (e, st) {
          debugPrint('Tarot capture attempt $attempt: $e\n$st');
          if (attempt == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 120));
            continue;
          }
          return null;
        } finally {
          img?.dispose();
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('Tarot capture failed: $e\n$st');
      return null;
    }
  }

  bool _allowsFeedPost(FeedDataSource? feed) {
    if (feed == null || widget.userId == null) {
      return false;
    }
    return true;
  }

  String _spreadCaptionForPost(int rowCount) {
    return switch (rowCount) {
      1 => '🔮 타로 스프레드 (1열)',
      2 => '🔮 타로 스프레드 (2열)',
      _ => '🔮 타로 스프레드 (3열)',
    };
  }

  Future<void> _captureSpread() async {
    final rows = _spreadRowCountToCapture();
    if (rows == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캡처할 카드가 없어요. 먼저 슬롯에 카드를 놓아 주세요.')),
        );
      }
      return;
    }

    final bytes = await _captureToPng(rowCount: rows);
    if (!mounted) {
      return;
    }
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캡처에 실패했어요. 카드를 놓은 뒤 잠시 후 다시 눌러 주세요.')),
      );
      return;
    }

    final clipboardOk = await _tryCopyCaptureClipboard(bytes);
    if (!mounted) {
      return;
    }

    final feed = widget.feedRepository;
    final canPostFeed = _allowsFeedPost(feed);

    if (!canPostFeed) {
      if (widget.feedRepository != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '게시물에 올리려면 구글 로그인이 필요해요. '
              '상단 로그아웃 후 다시 로그인해 주세요. 지금은 이미지 저장·공유만 이어갈게요.',
            ),
          ),
        );
      }
      await _shareCaptureBytes(bytes, copiedToClipboard: clipboardOk);
      return;
    }

    if (clipboardOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 클립보드에 복사했어요. 카톡·다른 앱 채팅에 붙여넣기 할 수 있어요.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      constraints: kIsWeb
          ? BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            )
          : null,
      builder: (c) => PostCaptureSheet(
        pngBytes: Uint8List.fromList(bytes),
        feed: feed!,
        userId: widget.userId,
        username: widget.displayName,
        avatar: widget.avatarEmojiOrUrl,
        initialContent: _spreadCaptionForPost(rows),
        onPosted: () => widget.onPostedToFeed?.call(),
      ),
    );
  }

  /// 탭 메뉴 바로 아래까지 보드를 올리기 위한 얇은 간격.
  double _topInsetApprox2cm(BuildContext context) {
    final view = View.maybeOf(context);
    if (view == null) return 8;
    return (7.0 * view.devicePixelRatio / 3.0).clamp(4.0, 12.0);
  }

  Widget _slotTileInGrid(
    int slot,
    MatThemeData mat,
    String? cardFrontImageSrc,
    String? cardBackImageSrc,
    BoxConstraints bounds,
  ) {
    var w = bounds.maxWidth * 0.995;
    var h = w * 116 / 80;
    if (h > bounds.maxHeight * 0.98) {
      h = bounds.maxHeight * 0.98;
      w = h * 80 / 116;
    }
    return Center(
      child: _SlotCell(
        width: w,
        height: h,
        mat: mat,
        deckIndex: _placed[slot],
        card: _placed[slot] != null ? _deck22[_placed[slot]!] : null,
        flipped: _flipped.contains(slot),
        cardFrontImageSrc: cardFrontImageSrc,
        cardBackImageSrc: cardBackImageSrc,
        whitePlaceholder: true,
        emptySlotDecorationSrc: widget.emptySlotDecorationSrc,
        onTap: () => _onSlotTap(slot),
        onDrop: (d) => _place(d, slot),
      ),
    );
  }

  /// 골드 패널 + 3×3 슬롯. [boardW]·[boardH]는 부모가 준 실측(화면에 맞춤).
  Widget _buildNineSlotBoard({
    required double boardW,
    required double boardH,
    required MatThemeData mat,
    required String? cardBackImageSrc,
  }) {
    Widget rowSlots(int row) {
      return Row(
        children: List.generate(3, (c) {
          final slot = row * 3 + c;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              child: LayoutBuilder(
                builder: (ctx, bc) {
                  final card =
                      _placed[slot] != null ? _deck22[_placed[slot]!] : null;
                  final frontSrc =
                      card != null ? _cardFrontImageSrc(card) : null;
                  return _slotTileInGrid(
                    slot,
                    mat,
                    frontSrc,
                    cardBackImageSrc,
                    bc,
                  );
                },
              ),
            ),
          );
        }),
      );
    }

    return Container(
      width: boardW,
      height: boardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E4C8), Color(0xFFE2D4A4), Color(0xFFD2C085)],
        ),
        border: Border.all(
          color: const Color(0xFFC9A227).withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: boardW * _slotGridPadLr,
            top: boardH * _slotGridPadTop,
            width: boardW * (1 - 2 * _slotGridPadLr),
            height: boardH * (1 - _slotGridPadTop - _slotGridPadBottom),
            child: RepaintBoundary(
              key: _capKeyThreeRows,
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: RepaintBoundary(
                      key: _capKeyTwoRows,
                      child: Column(
                        children: [
                          Expanded(
                            child: RepaintBoundary(
                              key: _capKeyOneRow,
                              child: rowSlots(0),
                            ),
                          ),
                          Expanded(child: rowSlots(1)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(flex: 1, child: rowSlots(2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mat = matById(widget.equippedMatId);
    final filled = _placed.whereType<int>().length;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: mat.background),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: _topInsetApprox2cm(context)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      const edge = 6.0;
                      final availW = (c.maxWidth - edge * 2).clamp(
                        200.0,
                        double.infinity,
                      );
                      final availH = (c.maxHeight - 2).clamp(
                        160.0,
                        double.infinity,
                      );
                      var bw = availW;
                      var bh = bw * _slotBoardAspect;
                      if (bh > availH) {
                        bh = availH;
                        bw = bh / _slotBoardAspect;
                      }
                      return Center(
                        child: _buildNineSlotBoard(
                          boardW: bw,
                          boardH: bh,
                          mat: mat,
                          cardBackImageSrc: widget.equippedCardBackImageSrc,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '카드 설명 보기',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Switch(
                            value: _showCardDescriptionOnFlip,
                            onChanged: (v) {
                              setState(() => _showCardDescriptionOnFlip = v);
                              unawaited(
                                LocalAppPreferences.setShowCardDescriptionOnFlip(
                                  widget.userId,
                                  v,
                                ),
                              );
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _ClayButton(
                              label: '📸 스프레드 캡처',
                              onPressed: _captureSpread,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ClayButton(
                              label: '🔮 오라클 카드 뽑기',
                              purple: true,
                              onPressed: () => showOracleOverlay(
                                context,
                                ownedOracleCardNumbers:
                                    widget.ownedOracleCardNumbers,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ClayButton(
                              label: '다시 뽑기 🔄',
                              onPressed: filled > 0 ? _reset : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 스프레드(팬 덱): 화면 하단 작은 부채 덱.
        SizedBox(
          height: 108,
          width: double.infinity,
          child: Container(
            color: mat.deckAreaColor,
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: _buildFanDeck(c.maxWidth),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 하단 스프레드(팬 덱): 겹쳐 펼친 미사용 카드. 긴 부채꼴(넓은 호) + 가운데가 위로 오도록 겹침 순서.
  List<Widget> _buildFanDeck(double stackWidth) {
    final visible = List<int>.generate(
      _deckN,
      (i) => i,
    ).where((i) => !_used.contains(i)).toList();
    final n = visible.length;
    const fanW = 40.0;
    const fanH = 60.0;
    final halfW = fanW / 2;
    const spreadRad = 88 * math.pi / 180;
    final arcR = (stackWidth * 0.32).clamp(92.0, 132.0);

    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final ca = (a - (n - 1) / 2).abs();
        final cb = (b - (n - 1) / 2).abs();
        if (ca != cb) {
          return cb.compareTo(ca);
        }
        return a.compareTo(b);
      });

    return indices.map((vi) {
      final deckIdx = visible[vi];
      final t = n > 1 ? vi / (n - 1) : 0.5;
      final ang = -spreadRad / 2 + t * spreadRad;
      final dx = arcR * math.sin(ang);
      final lift = arcR * (1 - math.cos(ang)) * 0.26;
      return Positioned(
        left: stackWidth / 2 - halfW + dx,
        bottom: (10 - lift).clamp(0.0, 34.0),
        child: Transform.rotate(
          angle: ang,
          alignment: Alignment.bottomCenter,
          child: _HoverLiftFanCard(
            deckIdx: deckIdx,
            width: fanW,
            height: fanH,
            imageSrc: widget.equippedCardBackImageSrc,
          ),
        ),
      );
    }).toList();
  }
}

/// 데스크톱·웹: 마우스 호버 시 카드가 살짝 위로(hover lift / 호버 피드백).
class _HoverLiftFanCard extends StatefulWidget {
  const _HoverLiftFanCard({
    required this.deckIdx,
    required this.width,
    required this.height,
    required this.imageSrc,
  });

  final int deckIdx;
  final double width;
  final double height;
  final String? imageSrc;

  @override
  State<_HoverLiftFanCard> createState() => _HoverLiftFanCardState();
}

class _HoverLiftFanCardState extends State<_HoverLiftFanCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        offset: _hover ? const Offset(0, -0.14) : Offset.zero,
        child: Draggable<int>(
          data: widget.deckIdx,
          feedback: Material(
            color: Colors.transparent,
            child: _DeckCardFace(
              width: widget.width,
              height: widget.height,
              elevated: true,
              imageSrc: widget.imageSrc,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _DeckCardFace(
              width: widget.width,
              height: widget.height,
              imageSrc: widget.imageSrc,
            ),
          ),
          child: _DeckCardFace(
            width: widget.width,
            height: widget.height,
            imageSrc: widget.imageSrc,
          ),
        ),
      ),
    );
  }
}

class _DeckCardFace extends StatelessWidget {
  const _DeckCardFace({
    required this.width,
    required this.height,
    this.elevated = false,
    this.imageSrc,
  });

  final double width;
  final double height;
  final bool elevated;
  final String? imageSrc;

  @override
  Widget build(BuildContext context) {
    final img = imageSrc;
    final shadow = [
      if (elevated)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
    ];
    if (img != null && img.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB8A0D4), width: 2),
          boxShadow: shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: AdaptiveNetworkOrAssetImage(
          src: img,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _deckGradientFace(width, height, elevated: elevated),
        ),
      );
    }
    return _deckGradientFace(width, height, elevated: elevated);
  }
}

Widget _deckGradientFace(
  double width,
  double height, {
  required bool elevated,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(
        colors: [Color(0xFFC4B0E0), Color(0xFFA892C9), Color(0xFF9580B8)],
      ),
      border: Border.all(color: const Color(0xFFB8A0D4), width: 2),
      boxShadow: [
        if (elevated)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
      ],
    ),
    alignment: Alignment.center,
    child: const Text(
      '✦',
      style: TextStyle(fontSize: 10, color: Colors.black26),
    ),
  );
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.width,
    required this.height,
    required this.mat,
    required this.deckIndex,
    required this.card,
    required this.flipped,
    required this.cardFrontImageSrc,
    required this.cardBackImageSrc,
    this.whitePlaceholder = false,
    this.emptySlotDecorationSrc,
    required this.onTap,
    required this.onDrop,
  });

  final double width;
  final double height;
  final MatThemeData mat;
  final int? deckIndex;
  final TarotCard? card;
  final bool flipped;
  /// [_TarotTabState._cardFrontImageSrc]와 동일 규칙(장착 덱·카드별 테마).
  final String? cardFrontImageSrc;
  final String? cardBackImageSrc;

  /// 골드 보드 3×3: 빈 칸을 흰 카드 + 「슬롯」 문구로 표시.
  final bool whitePlaceholder;

  /// 장착한 카드 슬롯 프레임 PNG 등. 없으면 [whitePlaceholder]만 쓸 때와 동일하게 흰 칸.
  final String? emptySlotDecorationSrc;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    final filled = deckIndex != null;
    final img = cardFrontImageSrc;

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => deckIndex == null,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, cand, _) {
        final hover = cand.isNotEmpty;
        return GestureDetector(
          onTap: filled ? onTap : null,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: flipped ? 1 : 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) {
              final ang = v * 3.141592653589793;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(ang),
                child: ang < 1.57
                    ? _SlotBack(
                        width: width,
                        height: height,
                        mat: mat,
                        filled: filled,
                        hover: hover,
                        cardBackImageSrc: cardBackImageSrc,
                        whitePlaceholder: whitePlaceholder,
                        emptySlotDecorationSrc: emptySlotDecorationSrc,
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateY(3.141592653589793),
                        child: _SlotFront(
                          width: width,
                          height: height,
                          bottomRow: height < 100,
                          emoji: card?.emoji ?? '✦',
                          nameKo: card?.nameKo ?? '',
                          imageSrc: img,
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SlotBack extends StatelessWidget {
  const _SlotBack({
    required this.width,
    required this.height,
    required this.mat,
    required this.filled,
    required this.hover,
    this.cardBackImageSrc,
    this.whitePlaceholder = false,
    this.emptySlotDecorationSrc,
  });

  final double width;
  final double height;
  final MatThemeData mat;
  final bool filled;
  final bool hover;
  final String? cardBackImageSrc;
  final bool whitePlaceholder;
  final String? emptySlotDecorationSrc;

  BoxDecoration _emptySlotChrome() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: hover
            ? const Color(0xFF6B4FB8).withValues(alpha: 0.55)
            : const Color(0x28000000),
        width: hover ? 2.2 : 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: hover ? 0.16 : 0.10),
          blurRadius: hover ? 8 : 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _emptySlotLabel() {
    return Text(
      '슬롯',
      style: TextStyle(
        fontSize: (width * 0.17).clamp(12.0, 17.0),
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: hover ? 0.65 : 0.82),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!filled && whitePlaceholder) {
      final deco = emptySlotDecorationSrc?.trim();
      if (deco != null && deco.isNotEmpty) {
        return Container(
          width: width,
          height: height,
          decoration: _emptySlotChrome(),
          clipBehavior: Clip.antiAlias,
          child: AdaptiveNetworkOrAssetImage(
            src: deco,
            fit: BoxFit.cover,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: _emptySlotLabel(),
            ),
          ),
        );
      }
      return Container(
        width: width,
        height: height,
        decoration: _emptySlotChrome().copyWith(color: Colors.white),
        alignment: Alignment.center,
        child: _emptySlotLabel(),
      );
    }
    final img = cardBackImageSrc;
    if (filled && img != null && img.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB8A0D4), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AdaptiveNetworkOrAssetImage(
          src: img,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _slotBackGradientBody(
            width: width,
            height: height,
            mat: mat,
            filled: filled,
            hover: hover,
          ),
        ),
      );
    }
    return _slotBackGradientBody(
      width: width,
      height: height,
      mat: mat,
      filled: filled,
      hover: hover,
    );
  }
}

Widget _slotBackGradientBody({
  required double width,
  required double height,
  required MatThemeData mat,
  required bool filled,
  required bool hover,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: filled
          ? const LinearGradient(colors: [Color(0xFFC4B0E0), Color(0xFFA892C9)])
          : null,
      color: filled
          ? null
          : hover
          ? const Color(0x4DB89CD4)
          : Colors.white.withValues(alpha: 0.15),
      border: Border.all(
        color: filled
            ? const Color(0xFFB8A0D4)
            : hover
            ? mat.slotBorderHighlight
            : mat.slotBorder,
        width: 2.5,
      ),
      boxShadow: filled
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
              ),
            ]
          : hover
          ? mat.slotGlow
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
    ),
    alignment: Alignment.center,
    child: Text(
      filled
          ? '✦'
          : hover
          ? '✦'
          : '+',
      style: TextStyle(
        fontSize: height < 100 ? 16 : 22,
        color: Colors.black.withValues(alpha: filled ? 0.45 : 0.12),
      ),
    ),
  );
}

class _SlotFront extends StatelessWidget {
  const _SlotFront({
    required this.width,
    required this.height,
    required this.bottomRow,
    required this.emoji,
    required this.nameKo,
    required this.imageSrc,
  });

  final double width;
  final double height;
  final bool bottomRow;
  final String emoji;
  final String nameKo;
  final String? imageSrc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFD4C8A8), Color(0xFFC2B48E)],
        ),
        border: Border.all(color: AppColors.cardBorder, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageSrc == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: width * 0.8,
                  height: height * 0.55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [AppColors.cardInner, Color(0xFF98BFAA)],
                    ),
                    border: Border.all(
                      color: AppColors.cardBorder.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: bottomRow ? 20 : 28),
                  ),
                ),
                if (!bottomRow && nameKo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      nameKo,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cardBorder,
                      ),
                    ),
                  ),
              ],
            )
          : AdaptiveNetworkOrAssetImage(
              src: imageSrc!,
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: bottomRow ? 24 : 32),
                ),
              ),
            ),
    );
  }
}

class _ClayButton extends StatelessWidget {
  const _ClayButton({
    required this.label,
    required this.onPressed,
    this.purple = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool purple;

  @override
  Widget build(BuildContext context) {
    Widget btn;
    if (purple) {
      btn = FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7C5BB8),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x66C9B8E0)),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      btn = FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB89CD4),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFC9B8E0)),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
    return btn;
  }
}
