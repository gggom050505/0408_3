import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/shop_admin_gate.dart';
import '../config/gggom_offline_landing.dart' show kGggomBundledPublicRoot;
import '../theme/app_colors.dart';
import '../data/card_themes.dart' show resolveShopItemThumbnailSrc;
import '../config/korea_major_card_catalog.dart';
import '../data/oracle_assets.dart' show oracleItemIdToCardNumber;
import '../data/slot_shop_assets.dart';
import '../models/emoticon_models.dart';
import '../models/shop_models.dart';
import '../models/surprise_gift_models.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/emoticon_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/disk_caching_feed_repository.dart';
import '../repositories/feed_repository.dart';
import '../repositories/shop_repository.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../standalone/local_json_workspace_export.dart';
import '../standalone/local_attendance_repository.dart';
import '../standalone/local_emoticon_repository.dart';
import '../standalone/local_event_repository.dart';
import '../standalone/local_feed_repository.dart';
import '../standalone/local_shop_repository.dart';
import '../services/local_account_store.dart';
import '../services/user_monitoring_service.dart';
import 'account_manage_screen.dart';
import 'supabase_account_screen.dart';
import 'ad_reward_sheet.dart';
import 'attendance_modal.dart';
import 'bag_tab.dart';
import 'chat_tab.dart';
import 'event_tab.dart';
import 'feed_tab.dart';
import 'gnb.dart';
import 'app_motion.dart';
import 'making_notes_screen.dart';
import 'shop_admin_screen.dart';
import 'shop_tab.dart';
import 'simple_tab_page.dart';
import 'standalone_chat_tab.dart';
import 'tarot_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.onSignOut,
    this.localAccountSession,
    this.onLocalSessionReload,
  });

  /// 위젯 테스트·디버그: [\_saveAllLocalStateForCoding] 호출 횟수.
  @visibleForTesting
  static int debugSaveToWorkspaceCalls = 0;

  @visibleForTesting
  static void debugResetSaveToWorkspaceCalls() => debugSaveToWorkspaceCalls = 0;

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final VoidCallback onSignOut;
  /// 자체(로컬) 계정일 때만 전달 — GNB에서 계정 관리 진입
  final LocalAccountSession? localAccountSession;
  /// 닉네임 변경 후 [LocalAccountStore]와 부모 상태를 맞출 때 호출
  final Future<void> Function()? onLocalSessionReload;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _effectiveDisplayName;

  final _workspaceFlushSignal = ValueNotifier<int>(0);
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  MainTab _tab = MainTab.tarot;

  /// 피드에 게시 직후 게시물 탭을 새로고침하기 위한 키(같은 탭이어도 목록 다시 로드).
  var _feedReloadToken = 0;

  List<ShopItemRow> _shopItems = [];
  UserProfileRow? _profile;
  List<UserItemRow> _owned = [];
  List<EmoticonPackRow> _emoticonPacks = [];
  List<String> _ownedEmoticonIds = [];
  var _shopLoading = false;
  SurpriseGiftOffer? _surpriseGiftOffer;
  bool? _checkedInToday;

  /// 오프라인·베타 번들(Supabase 미사용)일 때만 유지 — 상태 보존.
  LocalFeedRepository? _localFeed;
  LocalShopRepository? _localShop;
  LocalEmoticonRepository? _localEmo;
  LocalEventRepository? _localEvent;
  LocalAttendanceRepository? _localAttendance;

  /// Supabase 모드에서 `build()`마다 새 인스턴스를 만들면 탭·시트가 서로 다른 리포를 참조할 수 있어 한 번만 생성.
  FeedRepository? _supabaseFeed;
  DiskCachingFeedRepository? _supabaseFeedCached;

  /// [initState] 직후에는 Supabase 세션이 아직 없어 [shopAdminGateAllowsCurrentUser] 가 false일 수 있음.
  /// 그러면 [_localShop] 이 비어 상점 「관리자」 버튼이 붙지 않음 → 한 프레임 뒤 세션 반영 시 로컬 미러 리포를 만듦.
  var _pendingAdminLocalShop = false;

  /// **기본 로그인(아이디·비밀번호)** 과 동일한 데이터 경로: Supabase 미사용 · `local-acc-…` · (예전부터 남은) `local-guest`.
  /// 일반 구글 사용자 세션은 쓰지 않으므로, 연동 빌드에서도 로컬 계정·게스트는 기기 로컬 레포로 통일합니다.
  bool get _usesLocalDataLayer =>
      !AppConfig.supabaseEnabled ||
      LocalAccountStore.isLocalAppUserId(widget.userId) ||
      widget.userId == 'local-guest';

  FeedDataSource? get _feed {
    if (_usesLocalDataLayer) {
      return _localFeed;
    }
    _supabaseFeed ??= FeedRepository(Supabase.instance.client);
    _supabaseFeedCached ??= DiskCachingFeedRepository(_supabaseFeed!);
    return _supabaseFeedCached;
  }

  ShopDataSource? get _shopRepo => _usesLocalDataLayer
      ? _localShop
      : ShopRepository(Supabase.instance.client);

  AttendanceDataSource? get _attendance => _usesLocalDataLayer
      ? _localAttendance
      : AttendanceRepository(Supabase.instance.client);

  EmoticonDataSource? get _emoticonRepo => _usesLocalDataLayer
      ? _localEmo
      : EmoticonRepository(Supabase.instance.client);

  EventDataSource? get _eventRepo => _usesLocalDataLayer
      ? _localEvent
      : EventRepository(Supabase.instance.client);

  @override
  void dispose() {
    _authStateSub?.cancel();
    _workspaceFlushSignal.dispose();
    super.dispose();
  }

  /// 기기의 모든 로컬 JSON 을 프로젝트 `assets/local_dev_state/` 에 복사 + 타로 세션 즉시 저장.
  /// 비동기 이후 스낵바는 [BuildContext] 대신 [_scaffoldMessengerKey]로 띄워 재빌드로 ctx가 끊기지 않게 함.
  Future<void> _saveAllLocalStateForCoding() async {
    HomeScreen.debugSaveToWorkspaceCalls++;
    void showMsg(String text) {
      if (!mounted) {
        return;
      }
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 7)),
      );
    }

    try {
      if (kIsWeb) {
        showMsg('웹 빌드에서는 브라우저 저장소만 사용해요.');
        return;
      }
      _workspaceFlushSignal.value++;
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) {
        return;
      }
      final n = await syncAllGggomJsonFromAppSupportToWorkspace();
      if (!mounted) {
        return;
      }
      final text = n > 0
          ? '프로젝트 assets/local_dev_state/ 에 JSON $n개를 맞췄어요. (타로·채팅·피드·상점 등)'
          : '프로젝트로 복사하지 못했어요. 프로젝트 루트에서 실행하거나 dart-define GGGOM_PROJECT_ROOT 를 넣어 주세요.';
      showMsg(text);
    } catch (e) {
      showMsg('저장하기 처리 중 오류: $e');
    }
  }

  StreamSubscription<AuthState>? _authStateSub;

  @override
  void initState() {
    super.initState();
    _effectiveDisplayName = widget.displayName;
    if (_usesLocalDataLayer) {
      _localFeed = LocalFeedRepository();
      _localShop = LocalShopRepository(widget.userId);
      _localEmo = LocalEmoticonRepository(wallet: _localShop);
      _localEvent = LocalEventRepository();
      _localAttendance = LocalAttendanceRepository();
    } else if (AppConfig.supabaseEnabled && shopAdminGateAllowsCurrentUser()) {
      _localShop = LocalShopRepository(widget.userId);
    }
    if (AppConfig.supabaseEnabled) {
      _authStateSub =
          Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
    unawaited(_restoreMainTab());
    _bootstrap();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayName != widget.displayName) {
      _effectiveDisplayName = widget.displayName;
    }
    if (oldWidget.userId != widget.userId && AppConfig.supabaseEnabled) {
      _localShop = null;
      _pendingAdminLocalShop = false;
    }
  }

  Future<void> _openAccountManage() async {
    final s = widget.localAccountSession;
    if (s == null) {
      return;
    }
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<void>(
        builder: (c) => AccountManageScreen(session: s),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result is AccountDeletedResult) {
      widget.onSignOut();
      return;
    }
    if (result is String) {
      setState(() => _effectiveDisplayName = result);
      await widget.onLocalSessionReload?.call();
    }
  }

  Future<void> _openAccountSettings() async {
    if (widget.localAccountSession != null) {
      await _openAccountManage();
      return;
    }
    if (!AppConfig.supabaseEnabled || widget.userId == 'local-guest') {
      return;
    }
    final withdrew = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (c) => const SupabaseAccountScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (withdrew == true) {
      widget.onSignOut();
    }
  }

  Future<void> _restoreMainTab() async {
    final name = await LocalAppPreferences.getMainTabName();
    if (!mounted || name == null || name.isEmpty) {
      return;
    }
    for (final t in MainTab.values) {
      if (t.name == name) {
        setState(() => _tab = t);
        return;
      }
    }
  }

  void _persistMainTab(MainTab t) {
    unawaited(LocalAppPreferences.setMainTabName(t.name));
  }

  String _mainTabActivityLabel(MainTab t) => switch (t) {
        MainTab.tarot => '타로',
        MainTab.feed => '게시물',
        MainTab.chat => '채팅',
        MainTab.shop => '상점',
        MainTab.bag => '가방',
        MainTab.event => '이벤트',
      };

  void _setMainTab(MainTab t) {
    setState(() => _tab = t);
    _persistMainTab(t);
    if (AppConfig.supabaseEnabled &&
        widget.userId != 'local-guest' &&
        !LocalAccountStore.isLocalAppUserId(widget.userId)) {
      unawaited(
        UserMonitoringService.instance.logAppEvent(
          '메인 탭 이동',
          detail: _mainTabActivityLabel(t),
        ),
      );
    }
  }

  Future<void> _bootstrap() async {
    await _refreshShop();
    await _refreshAttendance();
  }

  /// Supabase에 원격 프로필이 있는 **로그인 계정**(구글 등). 가방·별조각·장착은 DB가 권위이며
  /// 클라이언트 일회 장착 스냅샷으로 덮어쓰지 않는다.
  bool _isSupabaseRemoteProfileAccount(String uid) {
    return AppConfig.supabaseEnabled &&
        uid != 'local-guest' &&
        !LocalAccountStore.isLocalAppUserId(uid);
  }

  /// 덱·카드 뒷면·슬롯을 기본값으로 **계정당 한 번만** 맞춤(로컬·게스트·오프라인 스냅샷용).
  /// 서버 로그인 계정은 적용하지 않아 별조각·가방 아이템·장착 상태를 DB 그대로 유지한다.
  Future<void> _maybeApplyTarotEquipDefaultsV1Once(
    ShopDataSource repo,
    String uid,
  ) async {
    if (_isSupabaseRemoteProfileAccount(uid)) {
      if (await LocalAppPreferences.needsTarotEquipDefaultsV1(uid)) {
        await LocalAppPreferences.markTarotEquipDefaultsV1Done(uid);
      }
      return;
    }
    if (!await LocalAppPreferences.needsTarotEquipDefaultsV1(uid)) {
      return;
    }
    try {
      final c = await repo.equipItem(
        userId: uid,
        itemId: defaultEquippedCard,
        type: 'card',
      );
      final b = await repo.equipItem(
        userId: uid,
        itemId: defaultEquippedCardBack,
        type: 'card_back',
      );
      final s = await repo.equipItem(
        userId: uid,
        itemId: kDefaultEquippedSlotId,
        type: 'slot',
      );
      if (c != null && b != null && s != null) {
        await LocalAppPreferences.markTarotEquipDefaultsV1Done(uid);
      }
    } catch (_) {}
  }

  Future<void> _refreshShop() async {
    final uid = widget.userId;
    if (!AppConfig.supabaseEnabled) {
      final repo = _localShop;
      if (repo == null) {
        return;
      }
      setState(() => _shopLoading = true);
      try {
        final items = await repo.fetchShopItems();
        await repo.ensureDefaultUserItems(uid);
        await _maybeApplyTarotEquipDefaultsV1Once(repo, uid);
        final owned = await repo.fetchOwnedItems(uid);
        final profile = await repo.fetchProfile(uid);
        var ownedEmo = <String>[];
        final emo = _emoticonRepo;
        if (emo != null) {
          try {
            ownedEmo = await emo.fetchOwned(uid);
          } catch (_) {}
        }
        SurpriseGiftOffer? surprise;
        try {
          surprise = await repo.syncSurpriseGift(uid, items);
        } catch (_) {
          surprise = null;
        }
        if (mounted) {
          setState(() {
            _shopItems = items;
            _owned = owned;
            _profile = profile;
            _emoticonPacks = [];
            _ownedEmoticonIds = ownedEmo;
            _surpriseGiftOffer = surprise;
            _shopLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _shopLoading = false;
            _surpriseGiftOffer = null;
          });
        }
      }
      return;
    }
    final repo = _shopRepo;
    if (repo == null) {
      return;
    }
    setState(() => _shopLoading = true);
    try {
      final items = await repo.fetchShopItems();
      await repo.fetchProfile(uid);
      await repo.ensureDefaultUserItems(uid);
      await _maybeApplyTarotEquipDefaultsV1Once(repo, uid);
      final owned = await repo.fetchOwnedItems(uid);
      final profile = await repo.fetchProfile(uid);
      var packs = <EmoticonPackRow>[];
      var ownedEmo = <String>[];
      final emo = _emoticonRepo;
      if (emo != null) {
        try {
          packs = await emo.fetchPacks();
          ownedEmo = await emo.fetchOwned(uid);
        } catch (_) {}
      }
      SurpriseGiftOffer? surprise;
      try {
        surprise = await repo.syncSurpriseGift(uid, items);
      } catch (_) {
        surprise = null;
      }
      if (mounted) {
        setState(() {
          _shopItems = items;
          _owned = owned;
          _profile = profile;
          _emoticonPacks = packs;
          _ownedEmoticonIds = ownedEmo;
          _surpriseGiftOffer = surprise;
          _shopLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shopLoading = false;
          _surpriseGiftOffer = null;
        });
      }
    }
  }

  Future<void> _refreshAttendance() async {
    final a = _attendance;
    if (a == null) {
      return;
    }
    final v = await a.checkToday(widget.userId);
    if (mounted) {
      setState(() => _checkedInToday = v);
    }
  }

  Future<void> _openAdReward(BuildContext context) async {
    final repo = _shopRepo;
    if (repo == null || !context.mounted) {
      return;
    }
    await AdRewardSheet.show(
      context,
      userId: widget.userId,
      shopRepo: repo,
      onBalanceRefresh: _refreshShop,
      messengerKey: _scaffoldMessengerKey,
    );
  }

  Future<void> _openAttendance(BuildContext context) async {
    final a = _attendance;
    if (a == null) {
      return;
    }
    await showAttendanceModal(
      context,
      checkedInToday: _checkedInToday == true,
      userId: widget.userId,
      repo: a,
      onCheckedIn: () async {
        setState(() => _checkedInToday = true);
        final shop = _shopRepo;
        if (shop != null) {
          try {
            final grant = await shop.grantAttendanceDailyReward(widget.userId);
            if (!mounted) {
              return;
            }
            if (grant != null) {
              final msg = grant.luckyShopItemGranted &&
                      grant.luckyShopItemName != null &&
                      grant.luckyShopItemName!.isNotEmpty
                  ? '✨ 행운이 가득한 날! ⭐ +${grant.starFragmentsAdded} · 「${grant.luckyShopItemName}」을(를) 드렸어요'
                  : '⭐ 별조각 +${grant.starFragmentsAdded} (다음 「행운이 가득한 날」에는 상점 품목도 드려요)';
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text(msg)),
              );
            }
          } catch (e) {
            if (mounted) {
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text('출석 보상 지급 오류: $e')),
              );
            }
          }
        }
        await _refreshShop();
      },
    );
    await _refreshAttendance();
  }

  void _needLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그인이 필요합니다.'),
      ),
    );
  }

  void _onPostedToFeed() {
    setState(() {
      _feedReloadToken++;
      _tab = MainTab.feed;
    });
    _persistMainTab(MainTab.feed);
  }

  String? _resolveEquippedCardBackThumb(String equippedId) {
    for (final s in _shopItems) {
      if (s.id == equippedId && s.type == 'card_back') {
        final src = resolveShopItemThumbnailSrc(s.thumbnailUrl, AppConfig.assetOrigin);
        if (src != null && src.isNotEmpty) {
          return src;
        }
        break;
      }
    }
    if (equippedId == defaultEquippedCardBack) {
      return '$kGggomBundledPublicRoot/card_backs/owl_card_back.png';
    }
    return null;
  }

  void _ensureSupabaseAdminLocalShopIfNeeded() {
    if (_usesLocalDataLayer || !AppConfig.supabaseEnabled) {
      return;
    }
    if (!shopAdminGateAllowsCurrentUser()) {
      _pendingAdminLocalShop = false;
      return;
    }
    if (_localShop != null || _pendingAdminLocalShop) {
      return;
    }
    _pendingAdminLocalShop = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingAdminLocalShop = false;
      if (!mounted ||
          _usesLocalDataLayer ||
          !AppConfig.supabaseEnabled ||
          !shopAdminGateAllowsCurrentUser() ||
          _localShop != null) {
        return;
      }
      setState(() {
        _localShop = LocalShopRepository(widget.userId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureSupabaseAdminLocalShopIfNeeded();
    final uid = widget.userId;
    final avatarForFeed = widget.avatarUrl ?? '🔮';
    final helloName = _effectiveDisplayName;
    final equippedCard = _profile?.equippedCard ?? defaultEquippedCard;
    final equippedMat = _profile?.equippedMat ?? defaultEquippedMat;
    final equippedCardBack = _profile?.equippedCardBack ?? defaultEquippedCardBack;
    final equippedSlotId = _profile?.equippedSlot ?? kDefaultEquippedSlotId;
    String? equippedSlotDecorationSrc;
    for (final s in _shopItems) {
      if (s.id == equippedSlotId && s.type == 'slot') {
        equippedSlotDecorationSrc =
            resolveShopItemThumbnailSrc(s.thumbnailUrl, AppConfig.assetOrigin);
        break;
      }
    }
    equippedSlotDecorationSrc ??= bundledSlotAssetPathForShopId(equippedSlotId);
    final equippedCardBackImageSrc = _resolveEquippedCardBackThumb(equippedCardBack);
    final ownedOracleNums = <int>{};
    for (final row in _owned.where((e) => e.itemType == 'oracle_card')) {
      final n = oracleItemIdToCardNumber(row.itemId);
      if (n != null) {
        ownedOracleNums.add(n);
      }
    }
    final ownedKoreaMajorCardIds = <int>[];
    for (final row in _owned.where((e) => e.itemType == 'korea_major_card')) {
      final idx = koreaMajorCardIndexFromShopItemId(row.itemId);
      if (idx != null) {
        ownedKoreaMajorCardIds.add(idx);
      }
    }
    ownedKoreaMajorCardIds.sort();

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.scaffoldGradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                children: [
                  Gnb(
                    active: _tab,
                    onTab: _setMainTab,
                    displayName: helloName,
                    avatarUrl: widget.avatarUrl,
                    isShopAdminSession: shopAdminGateAllowsCurrentUser(),
                    onSignOut: widget.onSignOut,
                    checkedInToday: _checkedInToday,
                    onAttendance: () => _openAttendance(context),
                    onAdReward: AppConfig.showBetaStarAdRewardMenu &&
                            _shopRepo != null
                        ? () => unawaited(_openAdReward(context))
                        : null,
                    onSaveForCoding:
                        kIsWeb ? null : _saveAllLocalStateForCoding,
                    onAccountSettings: widget.localAccountSession != null ||
                            (AppConfig.supabaseEnabled &&
                                widget.userId != 'local-guest')
                        ? _openAccountSettings
                        : null,
                    onMakingNotes: () =>
                        unawaited(MakingNotesScreen.open(context)),
                  ),
                if (_shopLoading) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(opacity: t, child: child),
                    child: const LinearProgressIndicator(minHeight: 2),
                  ),
                ],
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: tabSwitchChildTransition,
                    child: switch (_tab) {
                      MainTab.tarot => TarotTab(
                          key: const ValueKey('tarot-tab'),
                          userId: uid,
                          displayName: helloName,
                          avatarEmojiOrUrl: avatarForFeed,
                          equippedCardThemeId: equippedCard,
                          equippedMatId: equippedMat,
                          equippedCardBackId: equippedCardBack,
                          equippedCardBackImageSrc: equippedCardBackImageSrc,
                          equippedSlotId: equippedSlotId,
                          emptySlotDecorationSrc: equippedSlotDecorationSrc,
                          ownedOracleCardNumbers: ownedOracleNums.toList()
                            ..sort(),
                          ownedKoreaMajorCardIds: ownedKoreaMajorCardIds,
                          feedRepository: _feed,
                          onNeedLogin: _needLogin,
                          onPostedToFeed: _onPostedToFeed,
                          workspaceFlushSignal:
                              kIsWeb ? null : _workspaceFlushSignal,
                        ),
                      MainTab.feed => _feed == null
                          ? const SimpleTabPage(
                              key: ValueKey('feed-off'),
                              emoji: '📝',
                              title: '게시물',
                              subtitle: '베타: 서버(Supabase) 연동 시 피드를 불러옵니다.',
                            )
                          : FeedTab(
                              key: ValueKey('feed-$_feedReloadToken'),
                              feed: _feed!,
                              currentUserId: uid,
                              displayName: helloName,
                              avatar: avatarForFeed,
                              onNeedLogin: _needLogin,
                            ),
                      MainTab.chat => _usesLocalDataLayer
                          ? StandaloneChatTab(
                              key: const ValueKey('chat-standalone'),
                              displayName: helloName,
                              userId: uid,
                              emoticonRepo: _emoticonRepo!,
                            )
                          : ChatTab(
                              key: ValueKey('chat-$uid'),
                              userId: uid,
                              displayName: helloName,
                              avatarUrl: widget.avatarUrl,
                              emoticonRepo: _emoticonRepo!,
                              onNeedLogin: _needLogin,
                            ),
                      MainTab.shop => _shopRepo == null
                          ? const SimpleTabPage(
                              key: ValueKey('shop-off'),
                              emoji: '🏪',
                              title: '상점',
                              subtitle: '베타: Supabase 연동 시 상점이 열립니다.',
                            )
                          : ShopTab(
                              key: ValueKey('shop-$uid'),
                              repo: _shopRepo!,
                              userId: uid,
                              displayName: helloName,
                              shopItems: _shopItems,
                              profile: _profile,
                              ownedItems: _owned,
                              onRefresh: _refreshShop,
                              onNeedLogin: _needLogin,
                              emoticonRepo: _emoticonRepo!,
                              emoticonPacks: _emoticonPacks,
                              ownedEmoticonIds: _ownedEmoticonIds,
                              surpriseGiftOffer: _surpriseGiftOffer,
                              onClaimSurpriseGift: (offer) async {
                                final shop = _shopRepo;
                                if (shop == null || !mounted) {
                                  return;
                                }
                                final result = await shop.claimSurpriseGift(uid, offer);
                                if (!mounted) {
                                  return;
                                }
                                await _refreshShop();
                                if (!mounted) {
                                  return;
                                }
                                final messenger = _scaffoldMessengerKey.currentState;
                                switch (result) {
                                  case ClaimSurpriseGiftResult.granted:
                                    messenger?.showSnackBar(
                                      const SnackBar(content: Text('깜짝 선물을 받았어요!')),
                                    );
                                  case ClaimSurpriseGiftResult.alreadyOwned:
                                    messenger?.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '이미 가방에 있는 품목이에요. 중복 지급 없이 다음 깜짝 선물 주기로 넘어갔어요.',
                                        ),
                                      ),
                                    );
                                  case ClaimSurpriseGiftResult.failed:
                                    messenger?.showSnackBar(
                                      const SnackBar(content: Text('선물을 받지 못했어요.')),
                                    );
                                }
                              },
                              onBetaAdReward: AppConfig.showBetaStarAdRewardMenu
                                  ? () => unawaited(_openAdReward(context))
                                  : null,
                              onOpenShopAdmin: _localShop != null &&
                                      shopAdminGateAllowsCurrentUser()
                                  ? () async {
                                      await Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (c) => ShopAdminScreen(
                                            repo: _localShop!,
                                            workspaceFlushSignal:
                                                _workspaceFlushSignal,
                                          ),
                                        ),
                                      );
                                      if (context.mounted) {
                                        await _refreshShop();
                                      }
                                    }
                                  : null,
                            ),
                      MainTab.bag => _shopRepo == null
                          ? const SimpleTabPage(
                              key: ValueKey('bag-off'),
                              emoji: '🎒',
                              title: '가방',
                              subtitle: '베타: Supabase 연동 시 보유품을 표시합니다.',
                            )
                          : BagTab(
                              key: ValueKey('bag-$uid'),
                              repo: _shopRepo!,
                              userId: uid,
                              shopItems: _shopItems,
                              profile: _profile,
                              ownedItems: _owned,
                              ownedEmoticonIds: _ownedEmoticonIds,
                              onRefresh: _refreshShop,
                              onNeedLogin: _needLogin,
                            ),
                      MainTab.event => _eventRepo == null
                          ? const SimpleTabPage(
                              key: ValueKey('event-off'),
                              emoji: '🎁',
                              title: '이벤트',
                              subtitle: '베타: Supabase 연동 시 이벤트·공지를 불러옵니다.',
                            )
                          : EventTab(
                              key: ValueKey('event-$uid'),
                              repo: _eventRepo!,
                            ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}

const defaultEquippedCard = 'default';
const defaultEquippedMat = 'default-mint';
const defaultEquippedCardBack = 'default-card-back';
