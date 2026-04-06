import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/shop_admin_gate.dart';
import '../data/card_themes.dart' show resolveShopItemThumbnailSrc;
import '../models/shop_models.dart';
import '../standalone/local_json_workspace_export.dart';
import '../standalone/local_shop_repository.dart';
import '../theme/app_colors.dart';
import 'admin_user_activity_screen.dart';
import 'adaptive_network_asset_image.dart';
import 'shop_bulk_card_import_io.dart'
    if (dart.library.html) 'shop_bulk_card_import_web.dart' as bulk_import;

enum _AdminBulkKind { cardDeck, mat, cardBack }

/// 지정 구글 계정([shopAdminGateAllowsCurrentUser])만 **관리자 모드**로 진입.
/// 오프라인·베타: 상점 `ShopItemRow` 카탈로그 CRUD (JSON 저장).
class ShopAdminScreen extends StatefulWidget {
  const ShopAdminScreen({
    super.key,
    required this.repo,
    /// 홈과 동일한 타로 세션 즉시 저장([TarotTab] 플러시). 오프라인·베타 번들·비웹에서만 넘깁니다.
    this.workspaceFlushSignal,
    /// `true`(기본): Supabase 세션이 [shopAdminGateAllowsCurrentUser] 일 때만 본문 표시.
    /// 위젯 테스트에서만 `false` 로 게이트 생략.
    this.enforceSupabaseAdminGate = true,
  });

  final LocalShopRepository repo;
  final ValueNotifier<int>? workspaceFlushSignal;
  final bool enforceSupabaseAdminGate;

  @override
  State<ShopAdminScreen> createState() => _ShopAdminScreenState();
}

class _ShopAdminScreenState extends State<ShopAdminScreen> {
  List<ShopItemRow> _items = [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repo.loadFullCatalogForAdmin();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _persist(List<ShopItemRow> next) async {
    await widget.repo.saveCatalogForAdmin(next);
    if (mounted) {
      setState(() => _items = List<ShopItemRow>.from(next));
    }
  }

  /// 카탈로그·상점 사용자 상태·타로 등 앱 로컬 JSON 전부 기기에 확정 후 프로젝트 미러.
  Future<void> _saveCurrentCatalog() async {
    if (_loading) {
      return;
    }
    try {
      await widget.repo.saveCatalogForAdmin(List<ShopItemRow>.from(_items));
      await widget.repo.persistUserStateToDisk();
      if (!kIsWeb && widget.workspaceFlushSignal != null) {
        widget.workspaceFlushSignal!.value++;
        await Future<void>.delayed(const Duration(milliseconds: 140));
      }
      final synced = await syncAllGggomJsonFromAppSupportToWorkspace();
      if (mounted) {
        final base = _items.isEmpty
            ? '상품 목록·앱 로컬 기록을 기기에 저장했어요.'
            : '상품 ${_items.length}개·앱 로컬 기록을 기기에 저장했어요.';
        final extra = synced > 0
            ? '\n프로젝트 assets/local_dev_state/ 에 JSON $synced개를 맞췄어요. (타로·채팅·피드·상점 등)'
            : '\n프로젝트 미러는 스킵됐어요. PC에서 프로젝트 루트로 실행하거나 GGGOM_PROJECT_ROOT 를 지정해 주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$base$extra'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했어요: $e')),
        );
      }
    }
  }

  /// 탐색기(또는 브라우저 파일 선택): 이미지 선택 후 `file://` 또는 `data:image/...` 로 썸네일 필드 채움.
  Future<void> _pickThumbnailFromDisk(
    BuildContext dialogContext,
    void Function(void Function()) setDialogState,
    TextEditingController idCtrl,
    TextEditingController thumbCtrl,
    ShopItemRow? existing,
  ) async {
    final itemId = existing?.id ?? idCtrl.text.trim();
    if (itemId.isEmpty || !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(itemId)) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('저장 장치에서 이미지를 쓰려면 먼저 올바른 상품 ID를 입력해 주세요.'),
          ),
        );
      }
      return;
    }
    final uri = await bulk_import.pickAndCopyThumbnailForShopItem(itemId: itemId);
    if (!dialogContext.mounted) {
      return;
    }
    if (uri == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('선택이 취소되었거나 png/jpg/webp/gif 만 지원해요.'),
        ),
      );
      return;
    }
    thumbCtrl.text = uri;
    setDialogState(() {});
  }

  Future<void> _addOrEdit([ShopItemRow? existing]) async {
    final idCtrl = TextEditingController(text: existing?.id ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: '${existing?.price ?? 0}');
    final thumbCtrl = TextEditingController(text: existing?.thumbnailUrl ?? '');
    var type = existing?.type ?? 'mat';
    var active = existing?.isActive ?? true;

    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(existing == null ? '상품 추가' : '상품 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                      labelText: '상품 ID (고유, 영문·숫자·하이픈)',
                      hintText: '예: my-mat-01',
                    ),
                    enabled: existing == null,
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '이름'),
                  ),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '상품 종류',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: type,
                        items: [
                          const DropdownMenuItem(value: 'card', child: Text('카드 덱')),
                          const DropdownMenuItem(value: 'card_back', child: Text('카드 뒷면')),
                          const DropdownMenuItem(value: 'mat', child: Text('매트')),
                          const DropdownMenuItem(value: 'slot', child: Text('카드 슬롯')),
                          const DropdownMenuItem(value: 'oracle_card', child: Text('오라클 카드')),
                          const DropdownMenuItem(
                            value: 'korea_major_card',
                            child: Text('한국전통 메이저(장)'),
                          ),
                          if (existing != null &&
                              !const {
                                'card',
                                'card_back',
                                'mat',
                                'slot',
                                'oracle_card',
                                'korea_major_card',
                              }.contains(existing.type))
                            DropdownMenuItem(
                              value: existing.type,
                              child: Text('기존: ${existing.type}'),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setS(() => type = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: '가격 (별조각, 0=무료)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: thumbCtrl,
                    decoration: InputDecoration(
                      labelText: '썸네일 (선택)',
                      hintText: '/cards/... · https://... · 또는 폴더 아이콘',
                      suffixIcon: IconButton(
                        tooltip: '저장 장치에서 이미지 선택',
                        icon: const Icon(Icons.folder_open_outlined),
                        onPressed: () => _pickThumbnailFromDisk(
                          ctx,
                          setS,
                          idCtrl,
                          thumbCtrl,
                          existing,
                        ),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('상점에 표시'),
                    value: active,
                    onChanged: (v) => setS(() => active = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );
    } finally {
      idCtrl.dispose();
      nameCtrl.dispose();
      priceCtrl.dispose();
      thumbCtrl.dispose();
    }
    if (ok != true || !mounted) {
      return;
    }

    final id = existing?.id ?? idCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
    final thumb = thumbCtrl.text.trim().isEmpty ? null : thumbCtrl.text.trim();

    if (existing == null) {
      final rawId = idCtrl.text.trim();
      if (rawId.isEmpty || !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(rawId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID는 영문·숫자·.-_ 만 사용해 주세요.')),
        );
        return;
      }
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요.')),
      );
      return;
    }

    final next = List<ShopItemRow>.from(_items);
    final row = ShopItemRow(
      id: id,
      name: name,
      type: type,
      price: price < 0 ? 0 : price,
      thumbnailUrl: thumb,
      isActive: active,
    );

    if (existing == null) {
      if (next.any((e) => e.id == id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 같은 ID가 있어요.')),
        );
        return;
      }
      next.add(row);
    } else {
      final i = next.indexWhere((e) => e.id == existing.id);
      if (i < 0) {
        return;
      }
      if (existing.id != id) {
        /* ID 변경 없음 (필드 비활성) */
      }
      next[i] = row;
    }

    await _persist(next);
  }

  Future<void> _delete(ShopItemRow item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('삭제'),
        content: Text('「${item.name}」(${item.id}) 를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await _persist(_items.where((e) => e.id != item.id).toList());
  }

  /// Windows/macOS/Linux 등: 파일 선택으로 카드 덱·매트·카드 뒷면(썸네일=file://) 여러 개 등록
  Future<void> _bulkImportDesktop(_AdminBulkKind kind) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '이미지 일괄 등록은 Windows·macOS·Linux 설치판에서 사용할 수 있어요.',
            ),
          ),
        );
      }
      return;
    }
    try {
      final added = switch (kind) {
        _AdminBulkKind.cardDeck =>
          await bulk_import.pickAndRegisterCardDeckImages(existingItems: _items),
        _AdminBulkKind.mat =>
          await bulk_import.pickAndRegisterMatImages(existingItems: _items),
        _AdminBulkKind.cardBack =>
          await bulk_import.pickAndRegisterCardBackImages(existingItems: _items),
      };
      if (!mounted) {
        return;
      }
      if (added == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택이 취소되었어요.')),
        );
        return;
      }
      if (added.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복사할 이미지가 없어요. (png/jpg/webp/gif)')),
        );
        return;
      }
      await _persist([..._items, ...added]);
      if (mounted) {
        final label = switch (kind) {
          _AdminBulkKind.cardDeck => '카드 덱',
          _AdminBulkKind.mat => '매트',
          _AdminBulkKind.cardBack => '카드 뒷면',
        };
        final priceHint = kind == _AdminBulkKind.cardDeck
            ? ''
            : ' (기본 가격 ⭐500)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label ${added.length}개를 등록했어요.$priceHint')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일괄 등록 실패: $e')),
        );
      }
    }
  }

  Future<void> _exportJson() async {
    final m = _items.map((e) => e.toJson()).toList();
    final s = const JsonEncoder.withIndent('  ').convert(m);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('카탈로그 JSON'),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: SingleChildScrollView(child: SelectableText(s)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('닫기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enforceSupabaseAdminGate &&
        !shopAdminGateAllowsCurrentUser()) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: const Text('관리자 전용'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '이 화면은\n$kShopAdminGoogleEmail\n구글 계정으로 로그인한 경우에만 쓸 수 있어요.\n\n'
              '일반 모드에서는 상점 탭에서 구매만 가능합니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C2D12).withValues(alpha: 0.12),
        foregroundColor: AppColors.textPrimary,
        title: const Text('관리자 모드 · 상점 상품 편집'),
        actions: [
          IconButton(
            tooltip: '접속·활동 모니터',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (c) => const AdminUserActivityScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '카드 덱 이미지 일괄 등록 (PC)',
            icon: const Icon(Icons.folder_open),
            onPressed: _loading ? null : () => _bulkImportDesktop(_AdminBulkKind.cardDeck),
          ),
          IconButton(
            tooltip: '매트 이미지 일괄 등록 (PC)',
            icon: const Icon(Icons.grid_4x4_outlined),
            onPressed: _loading ? null : () => _bulkImportDesktop(_AdminBulkKind.mat),
          ),
          IconButton(
            tooltip: '카드 뒷면 이미지 일괄 등록 (PC)',
            icon: const Icon(Icons.style_outlined),
            onPressed: _loading ? null : () => _bulkImportDesktop(_AdminBulkKind.cardBack),
          ),
          IconButton(
            tooltip: 'JSON 보기',
            icon: const Icon(Icons.code),
            onPressed: _items.isEmpty ? null : _exportJson,
          ),
          IconButton(
            tooltip: '현재 입력된 값들 저장하기',
            icon: const Icon(Icons.save_outlined),
            onPressed: _loading ? null : _saveCurrentCatalog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(null),
        backgroundColor: AppColors.accentPurple,
        foregroundColor: AppColors.textLight,
        icon: const Icon(Icons.add),
        label: const Text('상품 추가'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    Text(
                      '오프라인·베타 번들에만 적용됩니다.「저장하기」는 편집 중인 상품 목록과 함께 상점 사용자 상태·타로·피드·채팅 등 '
                      '기기에 있는 로컬 JSON 을 모두 확정한 뒤, 가능하면 프로젝트 assets/local_dev_state/ 로 미러합니다 '
                      '(단위·위젯 테스트 실행 시에는 미러 생략). '
                      '루트 인식: 프로젝트에서 실행하거나 dart-define GGGOM_PROJECT_ROOT '
                      '(또는 SHOP_CATALOG_REPO_ROOT). '
                      '상점에 쓰는 카드 덱·뒷면·매트·슬롯·오라클 카드 품목을 모두 여기서 추가·수정·삭제·숨김 처리할 수 있어요. '
                      '폴더·격자·스타일 아이콘으로 PC에서 카드 덱·매트·카드 뒷면 썸네일을 각각 여러 장 한 번에 등록할 수 있어요. '
                      '매트·카드 뒷면 일괄 등록은 기본 ⭐500이며 목록에서 수정 가능합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _loading ? null : _saveCurrentCatalog,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('현재 입력된 값들 저장하기'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildGrouped(),
                  ],
                ),
    );
  }

  List<Widget> _buildGrouped() {
    final cards = _items.where((e) => e.type == 'card').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final cardBacks = _items.where((e) => e.type == 'card_back').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final slots = _items.where((e) => e.type == 'slot').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final oracles = _items.where((e) => e.type == 'oracle_card').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final koreaMajors = _items.where((e) => e.type == 'korea_major_card').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final mats = _items.where((e) => e.type == 'mat').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final known = cards.length +
        cardBacks.length +
        slots.length +
        oracles.length +
        koreaMajors.length +
        mats.length;
    final other = _items.length - known;

    return [
      _groupTitle('🃏 카드 덱'),
      ...cards.map((e) => _tile(e)),
      _groupTitle('🎴 카드 뒷면'),
      ...cardBacks.map((e) => _tile(e)),
      _groupTitle('🪟 카드 슬롯'),
      ...slots.map((e) => _tile(e)),
      _groupTitle('🔮 오라클 카드'),
      ...oracles.map((e) => _tile(e)),
      _groupTitle('🇰🇷 한국전통 메이저(장)'),
      ...koreaMajors.map((e) => _tile(e)),
      _groupTitle('🧘 매트'),
      ...mats.map((e) => _tile(e)),
      if (other > 0) ...[
        _groupTitle('📦 기타 타입'),
        ..._items
            .where((e) =>
                e.type != 'card' &&
                e.type != 'card_back' &&
                e.type != 'slot' &&
                e.type != 'oracle_card' &&
                e.type != 'korea_major_card' &&
                e.type != 'mat')
            .map((e) => _tile(e)),
      ],
      if (_items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('상품이 없습니다. + 를 눌러 추가하세요.'),
        ),
    ];
  }

  Widget _groupTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _tile(ShopItemRow item) {
    final thumb = item.thumbnailUrl;
    final phEmoji = switch (item.type) {
      'card_back' => '🎴',
      'mat' => '🧘',
      'slot' => '🪟',
      'oracle_card' => '🔮',
      'korea_major_card' => '🇰🇷',
      _ => '🃏',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 60,
            child: thumb != null && thumb.isNotEmpty
                ? AdaptiveNetworkOrAssetImage(
                    src: resolveShopItemThumbnailSrc(thumb, AppConfig.assetOrigin) ?? thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Center(child: Text(phEmoji, style: const TextStyle(fontSize: 22))),
                  )
                : Container(
                    alignment: Alignment.center,
                    color: AppColors.cardInner,
                    child: Text(phEmoji, style: const TextStyle(fontSize: 22)),
                  ),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${item.id} · ${item.type} · ⭐${item.price}${item.isActive ? '' : ' · 숨김'}',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _addOrEdit(item),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _delete(item),
            ),
          ],
        ),
      ),
    );
  }
}
