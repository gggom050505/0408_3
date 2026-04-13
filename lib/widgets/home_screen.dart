import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/gggom_offline_landing.dart' show kGggomBundledPublicRoot;
import '../theme/app_colors.dart';
import '../data/card_themes.dart' show resolveShopItemThumbnailSrc;
import '../data/feed_tags.dart';
import '../config/korea_major_card_catalog.dart';
import '../data/oracle_assets.dart' show oracleItemIdToCardNumber;
import '../data/slot_shop_assets.dart';
import '../models/emoticon_models.dart';
import '../models/shop_models.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_peer_shop_repository.dart';
import '../standalone/local_app_preferences.dart';
import '../standalone/local_json_workspace_export.dart';
import '../standalone/local_attendance_repository.dart';
import '../standalone/local_emoticon_repository.dart';
import '../standalone/local_event_repository.dart';
import '../standalone/local_feed_repository.dart';
import '../standalone/local_periodic_backup.dart';
import '../standalone/local_shop_repository.dart';
import '../services/daily_visitor_counter.dart';
import '../services/local_account_store.dart' show LocalAccountSession;
import 'account_manage_screen.dart';
import 'ad_reward_sheet.dart';
import 'attendance_modal.dart';
import 'bag_tab.dart';
import 'event_tab.dart';
import 'feed_tab.dart';
import 'first_setup_wizard_screen.dart';
import 'gnb.dart';
import 'app_motion.dart';
import 'making_notes_screen.dart';
import 'personal_shop_screen.dart';
import 'shop_tab.dart';
import 'simple_tab_page.dart';
import 'standalone_chat_tab.dart';
import 'tarot_tab.dart';
import 'today_tarot_screen.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late String _effectiveDisplayName;
  final List<_GiftBannerData> _giftBanners = <_GiftBannerData>[];
  final Map<String, Future<void> Function()> _giftBannerClaimActions =
      <String, Future<void> Function()>{};

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
  bool? _checkedInToday;
  var _firstSetupWizardPushStarted = false;
  var _todayTarotPromptInFlight = false;

  /// Supabase 연동 시 GNB «오늘 접속 N명» — [AppConfig.supabaseEnabled] 가 false면 미사용.
  var _todayVisitorCountLoaded = false;
  int? _todayVisitorCount;
  Timer? _backupTimer;

  LocalFeedRepository? _localFeed;
  LocalShopRepository? _localShop;
  LocalEmoticonRepository? _localEmo;
  LocalEventRepository? _localEvent;
  LocalAttendanceRepository? _localAttendance;

  FeedDataSource? get _feed => _localFeed;

  ShopDataSource? get _shopRepo => _localShop;

  PeerShopDataSource get _peerShop => LocalPeerShopRepository.instance;

  AttendanceDataSource? get _attendance => _localAttendance;

  EmoticonDataSource? get _emoticonRepo => _localEmo;

  EventDataSource? get _eventRepo => _localEvent;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backupTimer?.cancel();
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

  void _showGiftBanner({
    required String title,
    required String message,
    Color? accentColor,
    String? claimLabel,
    Future<void> Function()? onClaim,
  }) {
    if (!mounted) {
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _giftBanners.add(
        _GiftBannerData(
          id: id,
          title: title,
          message: message,
          accentColor: accentColor ?? AppColors.uniqueItemBorder,
          claimLabel: claimLabel,
        ),
      );
      if (onClaim != null) {
        _giftBannerClaimActions[id] = onClaim;
      }
    });
  }

  void _removeGiftBanner(String id) {
    if (!mounted) {
      return;
    }
    setState(() {
      _giftBanners.removeWhere((b) => b.id == id);
      _giftBannerClaimActions.remove(id);
    });
  }

  void _updateGiftBanner(String id, {bool? claiming, bool? claimed}) {
    final idx = _giftBanners.indexWhere((b) => b.id == id);
    if (idx < 0) {
      return;
    }
    setState(() {
      _giftBanners[idx] = _giftBanners[idx].copyWith(
        claiming: claiming,
        claimed: claimed,
      );
    });
  }

  Future<void> _claimGiftBanner(String id) async {
    final banner = _giftBanners.where((b) => b.id == id).firstOrNull;
    final claim = _giftBannerClaimActions[id];
    if (banner == null || claim == null || banner.claimed || banner.claiming) {
      return;
    }
    _updateGiftBanner(id, claiming: true);
    try {
      await claim();
      _updateGiftBanner(id, claiming: false, claimed: true);
    } catch (e) {
      _updateGiftBanner(id, claiming: false);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('선물 적용 중 오류: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _effectiveDisplayName = widget.displayName;
    _localFeed = LocalFeedRepository();
    _localShop = LocalShopRepository(widget.userId);
    _localEmo = LocalEmoticonRepository(wallet: _localShop);
    _localEvent = LocalEventRepository();
    _localAttendance = LocalAttendanceRepository();
    unawaited(_restoreMainTab());
    _bootstrap();
    _startPeriodicBackup();
    if (AppConfig.supabaseEnabled) {
      unawaited(_refreshTodayVisitorCount());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(LocalPeriodicBackup.backupNow(widget.userId));
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _firstSetupWizardPushStarted = false;
      _localShop = LocalShopRepository(widget.userId);
      _localEmo = LocalEmoticonRepository(wallet: _localShop);
      unawaited(_refreshShop());
      _startPeriodicBackup();
    }
    if (oldWidget.displayName != widget.displayName) {
      _effectiveDisplayName = widget.displayName;
    }
  }

  Future<void> _openAccountManage() async {
    final s = widget.localAccountSession;
    if (s == null) {
      return;
    }
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<void>(builder: (c) => AccountManageScreen(session: s)),
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

  void _setMainTab(MainTab t) {
    setState(() => _tab = t);
    _persistMainTab(t);
  }

  Future<void> _bootstrap() async {
    await _refreshShop();
    await _refreshAttendance();
  }

  void _startPeriodicBackup() {
    _backupTimer?.cancel();
    unawaited(_runPeriodicBackupIfDue());
    _backupTimer = Timer.periodic(
      const Duration(minutes: 20),
      (_) => unawaited(_runPeriodicBackupIfDue()),
    );
  }

  Future<void> _runPeriodicBackupIfDue() async {
    try {
      await LocalPeriodicBackup.backupIfDue(widget.userId);
    } catch (_) {}
  }

  Future<void> _refreshTodayVisitorCount() async {
    if (!AppConfig.supabaseEnabled) {
      return;
    }
    final n = await DailyVisitorCounter.instance.registerAndFetchTodayCount();
    if (!mounted) {
      return;
    }
    setState(() {
      _todayVisitorCount = n;
      _todayVisitorCountLoaded = true;
    });
  }

  Future<void> _runPostHomeDialogs() async {
    await _scheduleFirstSetupWizardIfNeeded();
    if (!mounted) {
      return;
    }
    await _maybePromptTodayTarot();
  }

  Future<void> _maybePromptTodayTarot() async {
    if (_todayTarotPromptInFlight || !mounted) {
      return;
    }
    _todayTarotPromptInFlight = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _shopLoading) {
        return;
      }
      if (!await LocalAppPreferences.shouldShowTodayTarotPrompt(
        widget.userId,
      )) {
        return;
      }
      if (!mounted) {
        return;
      }
      final go = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('오늘의 타로'),
          content: const Text(
            '오늘의 타로에 참여하시겠어요?\n\n'
            '오늘의 키워드를 떠올리며 덱에서 카드를 받아 5×2 슬롯에 올리고, '
            '한 장씩 뒤집을 수 있어요. 모두 뒤집으면 결과·점수가 정리되고, '
            '연동 시 결과 화면에서 «게시하기»를 눌러 피드에 올리거나 «게시 안함»을 고를 수 있어요.\n\n'
            '완료 후에도 «다시 뽑기»로 같은 날 다시 할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('다음에'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('참여하기'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      if (go == true) {
        await Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (c) => TodayTarotScreen(
              userId: widget.userId,
              displayName: _effectiveDisplayName,
              avatarEmojiOrUrl: widget.avatarUrl ?? '🔮',
              cardBackImageSrc: _resolveEquippedCardBackThumb(
                _profile?.equippedCardBack ?? defaultEquippedCardBack,
              ),
              emptySlotImageSrc: _resolveEquippedSlotDecorationSrc(
                _profile?.equippedSlot ?? kDefaultEquippedSlotId,
              ),
              feed: _feed,
              onPosted: _onPostedTodayTarotToFeed,
              embeddedInHomeShell: false,
            ),
          ),
        );
      } else if (go == false) {
        await LocalAppPreferences.markTodayTarotPromptDismissedToday(
          widget.userId,
        );
      }
    } finally {
      _todayTarotPromptInFlight = false;
    }
  }

  Future<void> _scheduleFirstSetupWizardIfNeeded() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    final repo = _shopRepo;
    if (repo == null) {
      return;
    }
    final uid = widget.userId;
    if (await LocalAppPreferences.isFirstSetupWizardV1Done(uid)) {
      return;
    }
    final oracleN = _owned.where((e) => e.itemType == 'oracle_card').length;
    final emoN = _ownedEmoticonIds.length;
    if (oracleN >= 8 && emoN >= 7) {
      await LocalAppPreferences.markFirstSetupWizardV1Done(uid);
      return;
    }
    if (_firstSetupWizardPushStarted) {
      return;
    }
    _firstSetupWizardPushStarted = true;
    if (!mounted) {
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (c) => FirstSetupWizardScreen(shopRepo: repo, userId: uid),
      ),
    );
    if (ok != true && mounted) {
      _firstSetupWizardPushStarted = false;
    }
    if (ok == true && mounted) {
      await _refreshShop();
      _setMainTab(MainTab.bag);
    }
  }

  /// 덱·카드 뒷면·슬롯을 기본값으로 **계정당 한 번만** 맞춤(로컬·게스트).
  Future<void> _maybeApplyTarotEquipDefaultsV1Once(
    ShopDataSource repo,
    String uid,
  ) async {
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
      final ownedEmoSet = <String>{};
      final emo = _emoticonRepo;
      if (emo != null) {
        try {
          ownedEmoSet.addAll(await emo.fetchOwned(uid));
        } catch (_) {}
      }
      try {
        ownedEmoSet.addAll(await repo.getOwnedEmoticonIds());
      } catch (_) {}
      final ownedEmo = ownedEmoSet.toList()..sort();
      if (mounted) {
        final starterPackJustApplied = repo
            .consumeStarterWelcomePackJustAppliedFlag();
        setState(() {
          _shopItems = items;
          _owned = owned;
          _profile = profile;
          _emoticonPacks = [];
          _ownedEmoticonIds = ownedEmo;
          _shopLoading = false;
        });
        if (starterPackJustApplied) {
          _showGiftBanner(
            title: '환영 선물 도착',
            message: '⭐20 · 이모티콘 7 · 오라클 8 지급 완료',
            accentColor: AppColors.accentMint,
            claimLabel: '받기',
            onClaim: () async {
              _setMainTab(MainTab.bag);
              await _refreshShop();
            },
          );
        }
        unawaited(_runPostHomeDialogs());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shopLoading = false;
        });
        unawaited(_runPostHomeDialogs());
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

  Future<void> _openPersonalShop(BuildContext context) async {
    final shop = _shopRepo;
    if (shop == null || !context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => PersonalShopScreen(
          shopRepo: shop,
          peerShop: _peerShop,
          userId: widget.userId,
          displayName: _effectiveDisplayName,
          shopItems: _shopItems,
          onNeedRefreshShop: _refreshShop,
          scaffoldMessengerKey: _scaffoldMessengerKey,
        ),
      ),
    );
    if (mounted) {
      await _refreshShop();
    }
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
              final msg =
                  grant.luckyShopItemGranted &&
                      grant.luckyShopItemName != null &&
                      grant.luckyShopItemName!.isNotEmpty
                  ? '⭐ 별조각 +${grant.starFragmentsAdded} · 출석 선물 「${grant.luckyShopItemName}」을(를) 드렸어요'
                  : '⭐ 별조각 +${grant.starFragmentsAdded} (미보유 유료 품목이 없어 선물은 생략됐어요)';
              _showGiftBanner(
                title: '출석 선물 도착',
                message: msg,
                accentColor: AppColors.accentPurple,
                claimLabel: '받기',
                onClaim: () async {
                  _setMainTab(MainTab.bag);
                  await _refreshShop();
                },
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
  }

  /// 오늘의 타로 탭에서 피드에 올린 뒤 — 「오늘의 게시」만 갱신·이동.
  void _onPostedTodayTarotToFeed() {
    unawaited(_grantFeedPostEventReward());
    setState(() {
      _feedReloadToken++;
      _tab = MainTab.todayTarotFeed;
    });
    _persistMainTab(MainTab.todayTarotFeed);
  }

  /// 타로 탭 스프레드 캡처 게시 후 — 「게시물」만 갱신·이동.
  void _onPostedTarotSpreadToFeed() {
    unawaited(_grantFeedPostEventReward());
    setState(() {
      _feedReloadToken++;
      _tab = MainTab.feed;
    });
    _persistMainTab(MainTab.feed);
  }

  Future<void> _grantFeedPostEventReward() async {
    if (!mounted) {
      return;
    }
    if (await LocalAppPreferences.isFeedPostEventGiftClaimedKoreaToday(
      widget.userId,
    )) {
      if (!mounted) {
        return;
      }
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            '오늘은 이미 게시 선물(⭐5)을 받았어요. 한국 날짜 기준으로 내일 첫 게시부터 다시 드려요.',
          ),
        ),
      );
      return;
    }
    final shop = _shopRepo;
    if (shop == null) {
      _showGiftBanner(
        title: '게시 선물',
        message: '상점을 불러오지 못해 별조각을 지급하지 못했어요. 잠시 후 다시 시도해 주세요.',
        accentColor: AppColors.uniqueItemBorder,
      );
      return;
    }
    final profile = await shop.grantAdRewardStars(widget.userId, amount: 5);
    if (!mounted) {
      return;
    }
    if (profile == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('별조각 지급에 실패했어요. 나중에 다시 시도해 주세요.')),
      );
      return;
    }
    await LocalAppPreferences.markFeedPostEventGiftClaimedKoreaToday(
      widget.userId,
    );
    await _refreshShop();
    if (!mounted) {
      return;
    }
    _showGiftBanner(
      title: '게시 선물 지급 완료',
      message: '오늘 첫 게시 보상으로 ⭐ 별조각 5개가 가방에 적용됐어요. (하루 1회)',
      accentColor: AppColors.uniqueItemBorder,
    );
  }

  String? _resolveEquippedCardBackThumb(String equippedId) {
    for (final s in _shopItems) {
      if (s.id == equippedId && s.type == 'card_back') {
        final src = resolveShopItemThumbnailSrc(
          s.thumbnailUrl,
          AppConfig.assetOrigin,
        );
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

  String? _resolveEquippedSlotDecorationSrc(String equippedSlotId) {
    for (final s in _shopItems) {
      if (s.id == equippedSlotId && s.type == 'slot') {
        final src = resolveShopItemThumbnailSrc(
          s.thumbnailUrl,
          AppConfig.assetOrigin,
        );
        if (src != null && src.isNotEmpty) {
          return src;
        }
        break;
      }
    }
    return bundledSlotAssetPathForShopId(equippedSlotId);
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.userId;
    final avatarForFeed = widget.avatarUrl ?? '🔮';
    final helloName = _effectiveDisplayName;
    final equippedCard = _profile?.equippedCard ?? defaultEquippedCard;
    final equippedMat = _profile?.equippedMat ?? defaultEquippedMat;
    final equippedCardBack =
        _profile?.equippedCardBack ?? defaultEquippedCardBack;
    final equippedSlotId = _profile?.equippedSlot ?? kDefaultEquippedSlotId;
    final equippedSlotDecorationSrc = _resolveEquippedSlotDecorationSrc(
      equippedSlotId,
    );
    final equippedCardBackImageSrc = _resolveEquippedCardBackThumb(
      equippedCardBack,
    );
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

    final visitorCountLabel = AppConfig.supabaseEnabled
        ? (!_todayVisitorCountLoaded
              ? '오늘 접속 · …'
              : (_todayVisitorCount != null
                    ? '오늘 접속 $_todayVisitorCount명'
                    : '오늘 접속 · —'))
        : null;

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
                      onSignOut: widget.onSignOut,
                      visitorCountLabel: visitorCountLabel,
                      starFragmentBalance: _profile?.starFragments,
                      checkedInToday: _checkedInToday,
                      onAttendance: () => _openAttendance(context),
                      onAdReward:
                          AppConfig.showBetaStarAdRewardMenu &&
                              _shopRepo != null
                          ? () => unawaited(_openAdReward(context))
                          : null,
                      onSaveForCoding: kIsWeb
                          ? null
                          : _saveAllLocalStateForCoding,
                      onAccountSettings: widget.localAccountSession != null
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
                        builder: (context, t, child) =>
                            Opacity(opacity: t, child: child),
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                    ],
                    if (_giftBanners.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.cardBorder.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              child: const Text(
                                '게시 이벤트 보상은 게시 직후 자동으로 가방에 반영돼요. '
                                '환영·출석 등 「받기」가 보이는 배너는 눌러야 적용돼요.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            for (final b in _giftBanners)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _GiftBannerCard(
                                  data: b,
                                  onClaim: () => _claimGiftBanner(b.id),
                                  onClose: () => _removeGiftBanner(b.id),
                                ),
                              ),
                          ],
                        ),
                      ),
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
                            onPostedToFeed: _onPostedTarotSpreadToFeed,
                            workspaceFlushSignal: kIsWeb
                                ? null
                                : _workspaceFlushSignal,
                          ),
                          MainTab.todayTarot => TodayTarotScreen(
                            key: const ValueKey('today-tarot-tab'),
                            userId: widget.userId,
                            displayName: helloName,
                            avatarEmojiOrUrl: avatarForFeed,
                            cardBackImageSrc: _resolveEquippedCardBackThumb(
                              _profile?.equippedCardBack ??
                                  defaultEquippedCardBack,
                            ),
                            emptySlotImageSrc: equippedSlotDecorationSrc,
                            feed: _feed,
                            onPosted: _onPostedTodayTarotToFeed,
                            embeddedInHomeShell: true,
                          ),
                          MainTab.todayTarotFeed =>
                            _feed == null
                                ? const SimpleTabPage(
                                    key: ValueKey('today-tarot-feed-off'),
                                    emoji: '📿',
                                    title: '오늘의 게시',
                                    subtitle: '피드를 불러오지 못했어요. 앱을 다시 실행해 주세요.',
                                  )
                                : FeedTab(
                                    key: ValueKey(
                                      'today-tarot-feed-$_feedReloadToken',
                                    ),
                                    feed: _feed!,
                                    currentUserId: uid,
                                    displayName: helloName,
                                    avatar: avatarForFeed,
                                    onNeedLogin: _needLogin,
                                    fixedTagFilterKey:
                                        kFeedTagTodayTarotMatchKey,
                                    listHeaderTitle:
                                        '#오늘의타로 로 올린 글만 보여요 · 아래에서 정렬 변경 가능',
                                  ),
                          MainTab.feed =>
                            _feed == null
                                ? const SimpleTabPage(
                                    key: ValueKey('feed-off'),
                                    emoji: '📝',
                                    title: '게시물',
                                    subtitle: '피드를 불러오지 못했어요. 앱을 다시 실행해 주세요.',
                                  )
                                : FeedTab(
                                    key: ValueKey('feed-$_feedReloadToken'),
                                    feed: _feed!,
                                    currentUserId: uid,
                                    displayName: helloName,
                                    avatar: avatarForFeed,
                                    onNeedLogin: _needLogin,
                                    fixedTagFilterKey:
                                        kFeedTagTarotSpreadMatchKey,
                                    listHeaderTitle:
                                        '타로 탭에서 캡처해 올린 글만 보여요 (#타로스프레드) · 정렬 변경 가능',
                                  ),
                          MainTab.chat => StandaloneChatTab(
                            key: const ValueKey('chat-standalone'),
                            displayName: helloName,
                            userId: uid,
                            emoticonRepo: _emoticonRepo!,
                          ),
                          MainTab.shop =>
                            _shopRepo == null
                                ? const SimpleTabPage(
                                    key: ValueKey('shop-off'),
                                    emoji: '🏪',
                                    title: '상점',
                                    subtitle: '상점 데이터를 불러오지 못했어요.',
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
                                    onBetaAdReward:
                                        AppConfig.showBetaStarAdRewardMenu
                                        ? () =>
                                              unawaited(_openAdReward(context))
                                        : null,
                                  ),
                          MainTab.bag =>
                            _shopRepo == null
                                ? const SimpleTabPage(
                                    key: ValueKey('bag-off'),
                                    emoji: '🎒',
                                    title: '가방',
                                    subtitle: '가방 데이터를 불러오지 못했어요.',
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
                                    onOpenPersonalShop: () =>
                                        unawaited(_openPersonalShop(context)),
                                  ),
                          MainTab.event =>
                            _eventRepo == null
                                ? const SimpleTabPage(
                                    key: ValueKey('event-off'),
                                    emoji: '🎁',
                                    title: '이벤트',
                                    subtitle: '이벤트 안내를 불러오지 못했어요.',
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

class _GiftBannerData {
  const _GiftBannerData({
    required this.id,
    required this.title,
    required this.message,
    required this.accentColor,
    this.claimLabel,
    this.claiming = false,
    this.claimed = false,
  });

  final String id;
  final String title;
  final String message;
  final Color accentColor;
  final String? claimLabel;
  final bool claiming;
  final bool claimed;

  _GiftBannerData copyWith({bool? claiming, bool? claimed}) {
    return _GiftBannerData(
      id: id,
      title: title,
      message: message,
      accentColor: accentColor,
      claimLabel: claimLabel,
      claiming: claiming ?? this.claiming,
      claimed: claimed ?? this.claimed,
    );
  }
}

class _GiftBannerCard extends StatelessWidget {
  const _GiftBannerCard({
    required this.data,
    required this.onClaim,
    required this.onClose,
  });

  final _GiftBannerData data;
  final VoidCallback onClaim;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.uniqueItemSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.accentColor, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎁', style: TextStyle(fontSize: 18, color: data.accentColor)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: data.accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.message,
                    style: const TextStyle(
                      color: AppColors.textOnLightCard,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (data.claimLabel != null) ...[
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: data.claiming || data.claimed ? null : onClaim,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(56, 32),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.uniqueItemSurface,
                  foregroundColor: AppColors.textOnLightCard,
                ),
                child: Text(
                  data.claimed
                      ? '받음'
                      : (data.claiming ? '처리중' : data.claimLabel!),
                ),
              ),
            ],
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textSecondary,
              tooltip: '닫기',
            ),
          ],
        ),
      ),
    );
  }
}

const defaultEquippedCard = 'default';
const defaultEquippedMat = 'default-mint';
const defaultEquippedCardBack = 'default-card-back';
