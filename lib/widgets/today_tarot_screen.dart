import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../config/app_config.dart';
import '../config/gggom_site_public_catalog.dart';
import '../data/card_themes.dart'
    show normalizeFlutterBundledAssetKey, resolvePublicAssetUrl;
import '../data/feed_tags.dart';
import '../data/korea_traditional_major_assets.dart';
import '../data/major_clay_assets.dart';
import '../data/minor_clay_assets.dart';
import '../data/tarot_cards.dart';
import '../data/today_tarot_deck.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

const _pickCount = 10;
const _poolSize = 106;
const _slotCols = 5;
const _slotRows = 2;

/// 웹·와이드 화면에서 5×2 슬롯이 가로 전체로 늘어나 카드가 비정상적으로 커지는 것을 막습니다.
const double _kTodayTarotMaxContentWidth = 480;

/// 오늘의 타로 앞면 — `assets/…` 는 항상 번들 [Image.asset] 키로 두고, [resolvePublicAssetUrl]로
/// `http(s)://`·`/cards/…` 등만 오리진과 맞춥니다.
///
/// **주의:** 웹에서 `Uri.base.resolve('assets/…')` → `Image.network` 로 가면 정적 서버에 해당
/// 원본 경로가 없어 마이너·메이저·한국전통 앞면이 비는 경우가 많습니다. 번들 에셋은 `Image.asset` 이
/// AssetManifest 기준으로 올바른 URL을 씁니다.
String _todayTarotDisplaySrc(String assetPath) {
  final key = normalizeFlutterBundledAssetKey(assetPath);
  if (key.isEmpty) {
    return key;
  }
  // 마이너 카드는 웹에서 항상 온라인 원본(`/cards/minor_*`) 우선으로 로드한다.
  // (상대 오리진/프록시 영향으로 번들 경로가 깨지는 경우를 회피)
  if (key.startsWith('assets/cards/minor_number_clay/')) {
    final rest = key.substring('assets/cards/minor_number_clay/'.length);
    return '${GggomSitePublicCatalog.siteOrigin}/cards/minor_number_clay/$rest';
  }
  if (key.startsWith('assets/cards/minor_court_clay/')) {
    final rest = key.substring('assets/cards/minor_court_clay/'.length);
    return '${GggomSitePublicCatalog.siteOrigin}/cards/minor_court_clay/$rest';
  }
  // 번들 카드 에셋은 네트워크 URL로 바꾸지 않고 그대로 Image.asset 경로를 사용한다.
  // (외부 도메인/Supabase 프로젝트 URL을 ASSET_ORIGIN으로 쓸 때 404 방지)
  if (key.startsWith('assets/')) {
    return key;
  }
  return resolvePublicAssetUrl(key, AppConfig.assetOrigin) ?? key;
}

String? _todayTarotLocalFallbackAssetByTarotId(int tarotId) {
  final minorNumber = minorNumberClayAssetPathForTarotCardId(tarotId);
  if (minorNumber != null) {
    return minorNumber;
  }
  final minorCourt = minorCourtClayAssetPathForTarotCardId(tarotId);
  if (minorCourt != null) {
    return minorCourt;
  }
  final majorClay = majorClayAssetPathForTarotCardId(tarotId);
  if (majorClay != null) {
    return majorClay;
  }
  return koreaTraditionalMajorAssetPath(tarotId);
}

/// [showDialog] 등에 넣는 오늘의 타로 안내 본문.
const String kTodayTarotGuideBody = '''
이 화면은 매일 하나의 키워드를 떠올리며, 106장 덱에서 10장을 고르는 데일리 타로예요.

• 키워드 — 날짜마다 정해진 시드로 무작위로 하나가 뽑혀요. 같은 날에는 같은 단어가 유지됩니다.

• 덱 구성 — 숫자 40장, 궁정 20장, 클레이 메이저 24장, 한국전통 메이저 22장입니다.

• 뽑기 — 아래 부채 덱에서 카드를 누르면 빈 칸부터 차례로 깔리고, 길게 눌러 드래그하면 원하는 빈 슬롯(5×2 아무 칸)에 놓을 수 있어요.

• 뒤집기 — 슬롯의 카드 뒷면을 누르면 앞면이 공개되며, 이때 카드를 크게 보고 의미·조언 문구를 읽을 수 있어요. 10장을 모두 뒤집으면 같은 화면에서 게시 / 게시 안 함을 고를 수 있어요.

• 점수 — 마이너 1점 · 궁정 2점 · 메이저 3점 · 한국전통 메이저 4점. 합계와 점수순 정리를 볼 수 있어요.

• «오늘의 게시» — 피드가 연결된 빌드에서는 10장을 모두 뒤집은 뒤 «게시하기»·«게시 안함»으로 #오늘의타로 글을 올리거나 건너뛸 수 있어요. «게시 안함»은 그날 기록만 남고 피드에는 안 올라가요.

• 다시 뽑기 — 상단 «다시 뽑기」로 오늘 완료 기록을 지우고 처음부터 다시 진행할 수 있어요(같은 날의 키워드·덱 순서는 그대로예요).

• 터치·마우스 — 손가락·스타일러스·마우스를 올리거나 누르면 덱 카드가 살짝 들립니다.
''';

/// 후보 풀 — 날짜 시드로 그중 하나가 무작위로 선택됩니다.
const kTodayTarotKeywordsOrdered = <String>[
  '합격',
  '완성',
  '평화',
  '축복',
  '횡재',
  '풍요',
  '화합',
  '신뢰',
  '슬픔',
  '공포',
  '질병',
  '파괴',
  '구설수',
  '이별',
  '불합격',
  '미련',
  '전환점',
  '필연',
  '심판',
  '절제',
  '조화',
];

/// [d]의 **로컬 날짜** 기준: 같은 날에는 항상 같은 단어(시드 고정 난수).
String todayTarotKeywordForDate(DateTime d) {
  final dayLocal = DateTime(d.year, d.month, d.day);
  final seed = dayLocal.year * 10000 + dayLocal.month * 100 + dayLocal.day;
  final rnd = math.Random(seed);
  return kTodayTarotKeywordsOrdered[rnd.nextInt(
    kTodayTarotKeywordsOrdered.length,
  )];
}

class TodayTarotScreen extends StatefulWidget {
  const TodayTarotScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.avatarEmojiOrUrl,
    this.cardBackImageSrc,
    this.emptySlotImageSrc,
    this.feed,
    this.onPosted,

    /// GNB 탭 본문으로 넣을 때 — 결과·차단 화면에서 `Navigator.pop` 대신 탭 전환을 씁니다.
    this.embeddedInHomeShell = false,
    @visibleForTesting this.skipDailyCompletionLock = false,

    /// 위젯 테스트: prefs 없이 즉시 «오늘은 이미 완료» 화면을 띄움.
    @visibleForTesting this.debugForceBlockedGateForTest = false,
  });

  final String userId;
  final String displayName;
  final String avatarEmojiOrUrl;
  final String? cardBackImageSrc;
  final String? emptySlotImageSrc;
  final FeedDataSource? feed;
  final VoidCallback? onPosted;

  /// 홈 하단 탭에 넣은 경우 `true`.
  final bool embeddedInHomeShell;

  /// `true`이면 «오늘 이미 완료» 로컬 조회를 하지 않습니다(VM 위젯 테스트·서포트 경로 미초기화 대비).
  @visibleForTesting
  final bool skipDailyCompletionLock;

  @visibleForTesting
  final bool debugForceBlockedGateForTest;

  @override
  State<TodayTarotScreen> createState() => _TodayTarotScreenState();
}

class _TodayTarotScreenState extends State<TodayTarotScreen> {
  late List<TodayTarotDeckEntry> _deck;
  late List<TodayTarotDeckEntry?> _slotEntries;
  late List<bool> _slotFlipped;
  var _phase = _TodayPhase.intro;
  var _posted = false;
  var _skippedFeedPost = false;
  var _postingInFlight = false;
  var _didAdvanceToResults = false;
  var _gateLoaded = false;
  var _blockedCompletedToday = false;
  late String _keyword;
  final GlobalKey _gridExportKey = GlobalKey();

  /// 길게 눌러 드래그 중인 풀 인덱스 — 같은 카드가 탭으로 중복 배치되지 않게 함.
  int? _draggingPoolIndex;
  bool _showCardDescriptionOnFlip = true;

  List<TodayTarotDeckEntry> get _pickedInSlotOrder {
    return [
      for (var i = 0; i < _pickCount; i++)
        if (_slotEntries[i] != null) _slotEntries[i]!,
    ];
  }

  List<TodayTarotDeckEntry> get _sortedPicked {
    final list = List<TodayTarotDeckEntry>.from(_pickedInSlotOrder)
      ..sort((a, b) {
        final p = b.points.compareTo(a.points);
        if (p != 0) {
          return p;
        }
        return a.poolIndex.compareTo(b.poolIndex);
      });
    return list;
  }

  int get _totalScore =>
      _pickedInSlotOrder.fold<int>(0, (s, e) => s + e.points);

  bool get _slotsFull => _slotEntries.every((e) => e != null);

  bool get _allFlipped {
    for (var i = 0; i < _pickCount; i++) {
      if (_slotEntries[i] == null || !_slotFlipped[i]) {
        return false;
      }
    }
    return true;
  }

  int get _nextEmptySlot {
    for (var i = 0; i < _pickCount; i++) {
      if (_slotEntries[i] == null) {
        return i;
      }
    }
    return -1;
  }

  void _shuffleDeck(math.Random rnd) {
    final base = buildTodayTarotDeckEntries();
    final shuffled = List<TodayTarotDeckEntry>.from(base)..shuffle(rnd);
    _deck = [
      for (var i = 0; i < shuffled.length; i++)
        TodayTarotDeckEntry(
          poolIndex: i,
          grade: shuffled[i].grade,
          points: shuffled[i].points,
          assetPath: shuffled[i].assetPath,
          labelKo: shuffled[i].labelKo,
          tarotId: shuffled[i].tarotId,
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _keyword = todayTarotKeywordForDate(today);
    _shuffleDeck(
      math.Random(today.year * 10000 + today.month * 100 + today.day),
    );
    _slotEntries = List<TodayTarotDeckEntry?>.filled(_pickCount, null);
    _slotFlipped = List<bool>.filled(_pickCount, false);
    _didAdvanceToResults = false;
    if (widget.debugForceBlockedGateForTest) {
      _gateLoaded = true;
      _blockedCompletedToday = true;
    } else if (widget.skipDailyCompletionLock) {
      _gateLoaded = true;
      _blockedCompletedToday = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_loadCompletionGate()),
      );
    }
  }

  Future<void> _loadCompletionGate() async {
    final done = await LocalAppPreferences.isTodayTarotCompletedToday(
      widget.userId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _gateLoaded = true;
      _blockedCompletedToday = done;
    });
  }

  Future<void> _redoTodayTarot() async {
    await LocalAppPreferences.clearTodayTarotDayMarks(widget.userId);
    if (!mounted) {
      return;
    }
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    setState(() {
      _blockedCompletedToday = false;
      _posted = false;
      _skippedFeedPost = false;
      _postingInFlight = false;
      _didAdvanceToResults = false;
      _phase = _TodayPhase.intro;
      _keyword = todayTarotKeywordForDate(today);
      _shuffleDeck(math.Random(seed));
      _slotEntries = List<TodayTarotDeckEntry?>.filled(_pickCount, null);
      _slotFlipped = List<bool>.filled(_pickCount, false);
      _draggingPoolIndex = null;
    });
  }

  void _advanceToResultsAfterCompletion() {
    if (_didAdvanceToResults || !_slotsFull || !_allFlipped) {
      return;
    }
    _didAdvanceToResults = true;
    unawaited(LocalAppPreferences.markTodayTarotCompletedToday(widget.userId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _phase = _TodayPhase.results);
    });
  }

  Future<void> _onPressPostFromSpread() async {
    if (_postingInFlight || _posted || _skippedFeedPost) {
      return;
    }
    final feed = widget.feed;
    if (feed == null) {
      return;
    }
    await _postToFeed();
    if (mounted && _posted) {
      _advanceToResultsAfterCompletion();
    }
  }

  void _onPressSkipPostFromSpread() {
    if (_posted || _postingInFlight) {
      return;
    }
    setState(() => _skippedFeedPost = true);
    _advanceToResultsAfterCompletion();
  }

  void _onPressResultsOnlyFromSpread() {
    if (widget.feed != null) {
      return;
    }
    _advanceToResultsAfterCompletion();
  }

  Set<int> get _usedPoolIndices {
    return {
      for (final e in _slotEntries)
        if (e != null) e.poolIndex,
    };
  }

  List<int> get _visiblePoolIndices {
    final visible = <int>[];
    final used = _usedPoolIndices;
    for (var i = 0; i < _poolSize; i++) {
      if (!used.contains(i)) {
        visible.add(i);
      }
    }
    return visible;
  }

  Future<Uint8List?> _captureGridPng() async {
    final ctx = _gridExportKey.currentContext;
    if (ctx == null) {
      return null;
    }
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 2.5);
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    return bd?.buffer.asUint8List();
  }

  Future<void> _postToFeed() async {
    if (_posted || _skippedFeedPost || _postingInFlight) {
      return;
    }
    final feed = widget.feed;
    if (feed == null) {
      return;
    }
    setState(() => _postingInFlight = true);
    Uint8List? png;
    try {
      png = await _captureGridPng();
    } catch (_) {}
    final lines = <String>[
      '키워드 「$_keyword」 · 합계 $_totalScore점',
    ];
    try {
      await feed.addPost(
        userId: widget.userId,
        username: widget.displayName,
        avatar: widget.avatarEmojiOrUrl,
        content: lines.join('\n'),
        tags: const [kFeedTagTodayTarotMatchKey],
        imagePngBytes: png?.toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _posted = true;
        _postingInFlight = false;
      });
      widget.onPosted?.call();
    } catch (_) {
      if (mounted) {
        setState(() => _postingInFlight = false);
      }
    }
  }

  void _onTapPoolCard(int visibleSlotIndex) {
    if (_phase != _TodayPhase.picking) {
      return;
    }
    if (_draggingPoolIndex != null) {
      return;
    }
    final empty = _nextEmptySlot;
    if (empty < 0) {
      return;
    }
    final visible = _visiblePoolIndices;
    if (visibleSlotIndex < 0 || visibleSlotIndex >= visible.length) {
      return;
    }
    final poolIdx = visible[visibleSlotIndex];
    if (_usedPoolIndices.contains(poolIdx)) {
      return;
    }
    final entry = _deck[poolIdx];
    setState(() {
      _slotEntries[empty] = entry;
      _slotFlipped[empty] = false;
    });
  }

  void _onTapSlot(int slotIndex) {
    if (_phase != _TodayPhase.picking) {
      return;
    }
    if (slotIndex < 0 || slotIndex >= _pickCount) {
      return;
    }
    final entry = _slotEntries[slotIndex];
    if (entry == null) {
      return;
    }
    if (!_slotFlipped[slotIndex]) {
      setState(() => _slotFlipped[slotIndex] = true);
      if (!_showCardDescriptionOnFlip) {
        _advanceToResultsAfterCompletion();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showBigCard(context, entry);
        }
      });
    } else {
      if (!_showCardDescriptionOnFlip) {
        _advanceToResultsAfterCompletion();
        return;
      }
      _showBigCard(context, entry);
    }
    _advanceToResultsAfterCompletion();
  }

  TarotCard? _tarotMetaFor(TodayTarotDeckEntry entry) {
    for (final c in tarotDeck) {
      if (c.id == entry.tarotId) {
        return c;
      }
    }
    return null;
  }

  Widget _buildTodayCardFront(
    TodayTarotDeckEntry entry, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    final fallbackAsset = _todayTarotLocalFallbackAssetByTarotId(entry.tarotId);
    return AdaptiveNetworkOrAssetImage(
      src: _todayTarotDisplaySrc(entry.assetPath),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, error, stackTrace) {
        if (fallbackAsset != null && fallbackAsset.isNotEmpty) {
          return Image.asset(
            fallbackAsset,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, imageError, imageStackTrace) => ColoredBox(
              color: Colors.grey.shade300,
              child: Center(child: Text(entry.tarotId.toString())),
            ),
          );
        }
        return ColoredBox(
          color: Colors.grey.shade300,
          child: Center(child: Text(entry.tarotId.toString())),
        );
      },
    );
  }

  void _showBigCard(BuildContext context, TodayTarotDeckEntry entry) {
    final meta = _tarotMetaFor(entry);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        final w = MediaQuery.sizeOf(ctx).width;
        final h = MediaQuery.sizeOf(ctx).height;
        final maxW = (w - 48).clamp(260.0, 400.0);
        final dialogMaxH = (h - 48).clamp(340.0, 760.0);
        final imageMaxH = (dialogMaxH * 0.56).clamp(220.0, 420.0);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: dialogMaxH),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: imageMaxH),
                  child: AspectRatio(
                    aspectRatio: 0.68,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: _buildTodayCardFront(
                          entry,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.labelKo,
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${entry.points}점 · ${entry.grade.labelKo}',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '의미',
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meta.meaning,
                            textAlign: TextAlign.center,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '조언',
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meta.advice,
                            textAlign: TextAlign.center,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.45,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGuideDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('오늘의 타로 설명서')),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            kTodayTarotGuideBody.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_gateLoaded) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: const Text('오늘의 타로'),
          backgroundColor: AppColors.bgMain,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
        ),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_blockedCompletedToday) {
      return _buildBlockedAlreadyToday(theme);
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: const Text('오늘의 타로'),
        backgroundColor: AppColors.bgMain,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '다시 뽑기',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => unawaited(_redoTodayTarot()),
          ),
          IconButton(
            tooltip: '설명서',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showGuideDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_phase) {
          _TodayPhase.intro => _buildIntro(theme),
          _TodayPhase.picking => _buildPicking(theme),
          _TodayPhase.results => _buildResults(theme),
        },
      ),
    );
  }

  Widget _buildBlockedAlreadyToday(ThemeData theme) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: const Text('오늘의 타로'),
        backgroundColor: AppColors.bgMain,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '다시 뽑기',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => unawaited(_redoTodayTarot()),
          ),
          IconButton(
            tooltip: '설명서',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showGuideDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = math.min(c.maxWidth, _kTodayTarotMaxContentWidth);
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: w,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '오늘은 이미 완료했어요',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '상단 «다시 뽑기»로 기록을 지우면 같은 날에도 처음부터 다시 할 수 있어요.\n\n'
                                '올린 글은 «오늘의 게시» 탭(#오늘의타로)에서 ♥와 정렬로 다시 찾아볼 수 있어요.\n\n'
                                '키워드에 집중해서 높은 점수의 카드를 뽑아보세요. 다른 분들의 카드를 보고 좋아요로 투표해 주세요.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: () => unawaited(_redoTodayTarot()),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Text('다시 뽑기'),
                                ),
                              ),
                              if (!widget.embeddedInHomeShell &&
                                  Navigator.of(context).canPop()) ...[
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text('닫기'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.min(c.maxWidth, _kTodayTarotMaxContentWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: w,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, box) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '오늘의 키워드',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '「$_keyword」',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '이 키워드를 떠올리며 마음을 가다듬은 뒤, 아래로 내려가 카드를 받아 보세요.\n\n'
                            '• 위 슬롯 5×2(10칸)에 부채 덱에서 카드를 누르면 빈 칸 순으로 깔리고, 길게 눌러 드래그하면 원하는 빈 칸에 놓을 수 있어요.\n'
                            '• 슬롯을 눌러 앞면을 뒤집으면 크게 보고 의미·조언을 읽을 수 있어요.\n'
                            '• 10장을 모두 뒤집으면 같은 화면에서 게시 여부를 고른 뒤 결과로 넘어가요.\n'
                            '• 상단 «다시 뽑기」로 같은 날에도 처음부터 다시 할 수 있어요.\n\n'
                            '• 마이너 1점 · 궁정 2점 · 메이저 3점 · 한국전통 메이저 4점',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () =>
                                setState(() => _phase = _TodayPhase.picking),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('카드 뽑으러 가기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotGrid() {
    final inner = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: List.generate(_slotRows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row == 0 ? 8 : 0),
            child: Row(
              children: List.generate(_slotCols, (col) {
                final i = row * _slotCols + col;
                final entry = _slotEntries[i];
                final flipped = _slotFlipped[i];
                final interactive = _phase == _TodayPhase.picking;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: col < _slotCols - 1 ? 6 : 0,
                    ),
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        if (!interactive) {
                          return false;
                        }
                        if (entry != null) {
                          return false;
                        }
                        final idx = details.data;
                        if (_usedPoolIndices.contains(idx)) {
                          return false;
                        }
                        return true;
                      },
                      onAcceptWithDetails: (details) {
                        final idx = details.data;
                        if (_phase != _TodayPhase.picking) {
                          return;
                        }
                        if (_slotEntries[i] != null) {
                          return;
                        }
                        if (_usedPoolIndices.contains(idx)) {
                          return;
                        }
                        setState(() {
                          _slotEntries[i] = _deck[idx];
                          _slotFlipped[i] = false;
                        });
                      },
                      builder: (context, candidate, rejected) {
                        final highlight = candidate.isNotEmpty;
                        return AspectRatio(
                          aspectRatio: 0.68,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: interactive && entry != null
                                  ? () => _onTapSlot(i)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: highlight
                                        ? const Color(0xFF22C55E)
                                        : AppColors.textSecondary.withValues(
                                            alpha: 0.25,
                                          ),
                                    width: highlight ? 2.2 : 1,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: entry == null
                                      ? _TodayEmptySlotFace(
                                          index: i + 1,
                                          imageSrc: widget.emptySlotImageSrc,
                                        )
                                      : !flipped
                                      ? _TodayCardBack(
                                          width: double.infinity,
                                          height: double.infinity,
                                          imageSrc: widget.cardBackImageSrc,
                                        )
                                      : _buildTodayCardFront(entry),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
    return RepaintBoundary(key: _gridExportKey, child: inner);
  }

  Widget _buildSpreadPostChoiceBar(ThemeData theme) {
    if (!_slotsFull || !_allFlipped) {
      return const SizedBox.shrink();
    }
    final frame = BoxDecoration(
      color: AppColors.bgCard.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.35)),
    );
    if (widget.feed != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: frame,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '10장을 모두 뒤집었어요. 피드에 올릴까요?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _postingInFlight
                        ? null
                        : () => unawaited(_onPressPostFromSpread()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _postingInFlight
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('게시'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _postingInFlight
                        ? null
                        : _onPressSkipPostFromSpread,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('게시 안함'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: frame,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '10장을 모두 뒤집었어요.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _onPressResultsOnlyFromSpread,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('결과 보기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicking(ThemeData theme) {
    final visible = _visiblePoolIndices;
    final n = visible.length;
    final filled = _pickedInSlotOrder.length;
    return LayoutBuilder(
      builder: (context, outer) {
        final contentW = math.min(outer.maxWidth, _kTodayTarotMaxContentWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '키워드 「$_keyword」 · 슬롯 $filled / $_pickCount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        kIsWeb
                            ? '덱: 카드를 누르면 빈 슬롯 순으로 깔려요. '
                                  '슬롯을 누르면 뒤집힌 뒤 크게 보고 설명을 읽을 수 있어요.'
                            : '덱: 탭하면 빈 슬롯 순으로 깔리고, 길게 눌러 드래그하면 원하는 빈 칸에 놓을 수 있어요. '
                                  '슬롯을 누르면 뒤집힌 뒤 크게 보고 설명을 읽을 수 있어요.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '카드 설명 보기',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Switch(
                            value: _showCardDescriptionOnFlip,
                            onChanged: (v) {
                              setState(() => _showCardDescriptionOnFlip = v);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildSlotGrid(),
                ),
                if (_allFlipped)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: _buildSpreadPostChoiceBar(theme),
                  )
                else
                  const SizedBox(height: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: _fanChildren(
                          stackWidth: c.maxWidth,
                          stackHeight: c.maxHeight,
                          visible: visible,
                          n: n,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _fanChildren({
    required double stackWidth,
    required double stackHeight,
    required List<int> visible,
    required int n,
  }) {
    const fanW = 28.0;
    const fanH = 40.0;
    final halfW = fanW / 2;
    final spreadRad = 148 * math.pi / 180;
    final arcR = (stackWidth * 0.44).clamp(110.0, 200.0);

    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final ca = (a - (n - 1) / 2).abs();
        final cb = (b - (n - 1) / 2).abs();
        if (ca != cb) {
          return cb.compareTo(ca);
        }
        return a.compareTo(b);
      });

    return order.map((vi) {
      final t = n > 1 ? vi / (n - 1) : 0.5;
      final ang = -spreadRad / 2 + t * spreadRad;
      final dx = arcR * math.sin(ang);
      final lift = arcR * (1 - math.cos(ang)) * 0.28;
      final bottomPad = (stackHeight * 0.08).clamp(12.0, 40.0);
      final poolIdx = visible[vi];
      final fanCard = _TodayFanPoolCard(
        onTap: () => _onTapPoolCard(vi),
        width: fanW,
        height: fanH,
        imageSrc: widget.cardBackImageSrc,
      );
      // 웹: LongPressDraggable이 짧은 탭과 제스처 경쟁에서 이겨 덱 탭이 먹통이 되는 경우가 많음.
      // 데스크톱·모바일 브라우저 모두 탭으로 빈 슬롯 순 배치만 보장(드래그는 모바일 앱 위주).
      final draggableChild = kIsWeb
          ? fanCard
          : LongPressDraggable<int>(
              data: poolIdx,
              onDragStarted: () => setState(() => _draggingPoolIndex = poolIdx),
              onDragEnd: (_) {
                if (mounted) {
                  setState(() => _draggingPoolIndex = null);
                }
              },
              feedback: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 70,
                  child: _TodayCardBack(
                    width: 48,
                    height: 70,
                    imageSrc: widget.cardBackImageSrc,
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: fanCard),
              child: fanCard,
            );
      return Positioned(
        left: stackWidth / 2 - halfW + dx,
        bottom: bottomPad - lift,
        child: Transform.rotate(
          angle: ang,
          alignment: Alignment.bottomCenter,
          child: draggableChild,
        ),
      );
    }).toList();
  }

  Widget _buildResults(ThemeData theme) {
    final sorted = _sortedPicked;
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.min(c.maxWidth, _kTodayTarotMaxContentWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: w,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  '키워드 「$_keyword」',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '합계 $_totalScore점 · 슬롯 순서는 아래 그리드와 같아요 · 점수 높은 순으로도 정리했어요',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                RepaintBoundary(
                  key: _gridExportKey,
                  child: _buildResultsGridReadOnly(),
                ),
                const SizedBox(height: 16),
                ...sorted.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ResultSummaryTile(entry: e),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.feed != null && !_posted && !_skippedFeedPost) ...[
                  Text(
                    '스프레드와 요약을 피드에 올릴까요?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _postingInFlight
                              ? null
                              : () => unawaited(_postToFeed()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _postingInFlight
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('게시하기'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _postingInFlight
                              ? null
                              : () => setState(() => _skippedFeedPost = true),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('게시 안함'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.feed != null && _posted)
                  Text(
                    '5×2 이미지와 요약이 «오늘의 게시»에 올라갔어요. ♥ 좋아요·정렬로 모아 보세요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (widget.feed != null && _skippedFeedPost && !_posted)
                  Text(
                    '피드에는 올리지 않았어요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                if (widget.feed == null)
                  Text(
                    '지금 빌드에서는 피드가 없어 게시할 수 없어요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 16),
                if (!widget.embeddedInHomeShell &&
                    Navigator.of(context).canPop())
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 결과 화면용 5×2(앞면만) — 캡처와 동일 레이아웃.
  Widget _buildResultsGridReadOnly() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: List.generate(_slotRows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row == 0 ? 8 : 0),
            child: Row(
              children: List.generate(_slotCols, (col) {
                final i = row * _slotCols + col;
                final entry = _slotEntries[i]!;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: col < _slotCols - 1 ? 6 : 0,
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.68,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildTodayCardFront(entry),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

enum _TodayPhase { intro, picking, results }

class _TodayFanPoolCard extends StatefulWidget {
  const _TodayFanPoolCard({
    required this.onTap,
    required this.width,
    required this.height,
    this.imageSrc,
  });

  final VoidCallback onTap;
  final double width;
  final double height;
  final String? imageSrc;

  @override
  State<_TodayFanPoolCard> createState() => _TodayFanPoolCardState();
}

class _TodayFanPoolCardState extends State<_TodayFanPoolCard> {
  var _hover = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lifted = _hover || _pressed;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: lifted ? 1.07 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            offset: lifted ? const Offset(0, -0.14) : Offset.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(7),
                mouseCursor: SystemMouseCursors.click,
                child: _TodayCardBack(
                  width: widget.width,
                  height: widget.height,
                  imageSrc: widget.imageSrc,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCardBack extends StatelessWidget {
  const _TodayCardBack({
    required this.width,
    required this.height,
    this.imageSrc,
  });

  final double width;
  final double height;
  final String? imageSrc;

  @override
  Widget build(BuildContext context) {
    final img = imageSrc;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFB8A0D4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: img != null && img.isNotEmpty
          ? AdaptiveNetworkOrAssetImage(
              src: img,
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (_, _, _) => _gradientFallback(),
            )
          : _gradientFallback(),
    );
  }

  Widget _gradientFallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC4B0E0), Color(0xFFA892C9), Color(0xFF9580B8)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        '✦',
        style: TextStyle(fontSize: 11, color: Colors.black26),
      ),
    );
  }
}

class _TodayEmptySlotFace extends StatelessWidget {
  const _TodayEmptySlotFace({required this.index, this.imageSrc});

  final int index;
  final String? imageSrc;

  @override
  Widget build(BuildContext context) {
    final src = imageSrc?.trim() ?? '';
    if (src.isEmpty) {
      return _fallback(index);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AdaptiveNetworkOrAssetImage(src: src, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
          ),
        ),
        Center(child: _indexText(index)),
      ],
    );
  }

  Widget _fallback(int idx) {
    return Center(child: _indexText(idx));
  }

  Widget _indexText(int idx) {
    return Text(
      '$idx',
      style: TextStyle(
        color: AppColors.textLight.withValues(alpha: 0.75),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class _ResultSummaryTile extends StatelessWidget {
  const _ResultSummaryTile({required this.entry});

  final TodayTarotDeckEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AdaptiveNetworkOrAssetImage(
                  src: _todayTarotDisplaySrc(entry.assetPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) {
                    final fallback = _todayTarotLocalFallbackAssetByTarotId(
                      entry.tarotId,
                    );
                    if (fallback != null && fallback.isNotEmpty) {
                      return Image.asset(
                        fallback,
                        fit: BoxFit.cover,
                        errorBuilder: (_, imageError, imageStackTrace) =>
                            ColoredBox(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Text(
                              '${entry.tarotId}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    }
                    return ColoredBox(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Text(
                          '${entry.tarotId}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+${entry.points}점 · ${entry.grade.labelKo}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    entry.labelKo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
