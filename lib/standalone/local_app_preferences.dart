import 'dart:convert';

import 'local_json_store.dart';

/// 홈 마지막 탭·피드 정렬 등 UI 설정 — 앱 재시작 후 복원.
class LocalAppPreferences {
  static const _file = 'local_app_preferences_v1.json';

  static Future<Map<String, dynamic>> _load() async {
    try {
      final raw = await loadLocalJsonFile(_file);
      if (raw == null || raw.isEmpty) {
        return {'version': 1};
      }
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if ((m['version'] as num?)?.toInt() != 1) {
        return {'version': 1};
      }
      return m;
    } catch (_) {
      return {'version': 1};
    }
  }

  static Future<void> _save(Map<String, dynamic> data) async {
    data['version'] = 1;
    await saveLocalJsonFile(_file, jsonEncode(data));
  }

  static Future<void> setMainTabName(String name) async {
    final m = await _load();
    m['main_tab'] = name;
    await _save(m);
  }

  static Future<String?> getMainTabName() async {
    final m = await _load();
    final v = m['main_tab'];
    return v is String ? v : null;
  }

  static Future<void> setFeedSortName(String name) async {
    final m = await _load();
    m['feed_sort'] = name;
    await _save(m);
  }

  static Future<String?> getFeedSortName() async {
    final m = await _load();
    final v = m['feed_sort'];
    return v is String ? v : null;
  }

  /// 광고 보상(시뮬) 마지막 수령 시각(UTC) — 계정(`userId`)별.
  static Future<DateTime?> getAdRewardLastCompletedUtc(String userId) async {
    final m = await _load();
    final v = m[_adRewardKey(userId)];
    if (v == null) {
      return null;
    }
    final ms = v is int ? v : (v as num).toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static Future<void> setAdRewardLastCompletedUtc(String userId, DateTime utc) async {
    final m = await _load();
    m[_adRewardKey(userId)] = utc.millisecondsSinceEpoch;
    await _save(m);
  }

  static String _adRewardKey(String userId) =>
      'ad_reward_last_completed_utc_ms_${userId.trim()}';

  /// 다음 광고에 표시할 이미지 인덱스(0부터). 보상 **성공** 후에만 바꿉니다.
  static Future<int> getAdRewardNextPromoAssetIndex(String userId) async {
    final m = await _load();
    final v = m[_adRewardPromoIdxKey(userId)];
    if (v == null) {
      return 0;
    }
    final n = v is int ? v : (v as num).toInt();
    return n < 0 ? 0 : n;
  }

  static Future<void> setAdRewardNextPromoAssetIndex(
    String userId,
    int index,
  ) async {
    final m = await _load();
    m[_adRewardPromoIdxKey(userId)] = index;
    await _save(m);
  }

  static String _adRewardPromoIdxKey(String userId) =>
      'ad_reward_next_promo_asset_idx_${userId.trim()}';

  static String _firstSetupWizardV1Key(String userId) =>
      'first_setup_wizard_v1_done_${userId.trim()}';

  /// 첫 세팅 마법사(오라클·이모 지급) 완료 여부 — 계정별.
  static Future<bool> isFirstSetupWizardV1Done(String userId) async {
    final m = await _load();
    return m[_firstSetupWizardV1Key(userId)] == true;
  }

  static Future<void> markFirstSetupWizardV1Done(String userId) async {
    final m = await _load();
    m[_firstSetupWizardV1Key(userId)] = true;
    await _save(m);
  }

  static String _tarotEquipDefaultsV1Key(String userId) =>
      'tarot_equip_defaults_v1_done_${userId.trim()}';

  static String _todayTarotDismissedYmdKey(String userId) =>
      'today_tarot_dismissed_ymd_${userId.trim()}';

  static String _todayTarotDoneYmdKey(String userId) =>
      'today_tarot_done_ymd_${userId.trim()}';

  static String _ymdLocal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 오늘의 타로 안내: 오늘 이미 완료했거나 "다음에" 눌렀으면 false.
  static Future<bool> shouldShowTodayTarotPrompt(String userId) async {
    final m = await _load();
    final today = _ymdLocal(DateTime.now());
    if (m[_todayTarotDoneYmdKey(userId)] == today) {
      return false;
    }
    if (m[_todayTarotDismissedYmdKey(userId)] == today) {
      return false;
    }
    return true;
  }

  static Future<void> markTodayTarotPromptDismissedToday(String userId) async {
    final m = await _load();
    m[_todayTarotDismissedYmdKey(userId)] = _ymdLocal(DateTime.now());
    await _save(m);
  }

  static Future<void> markTodayTarotCompletedToday(String userId) async {
    final m = await _load();
    m[_todayTarotDoneYmdKey(userId)] = _ymdLocal(DateTime.now());
    await _save(m);
  }

  /// 오늘(로컬) 이미 오늘의 타로를 **끝까지 완료**해 잠겼는지.
  static Future<bool> isTodayTarotCompletedToday(String userId) async {
    final m = await _load();
    final today = _ymdLocal(DateTime.now());
    return m[_todayTarotDoneYmdKey(userId)] == today;
  }

  /// 오늘의 타로: 완료·「다음에」 표시를 지워 홈 안내·다시 시작이 가능하게.
  static Future<void> clearTodayTarotDayMarks(String userId) async {
    final m = await _load();
    m.remove(_todayTarotDismissedYmdKey(userId));
    m.remove(_todayTarotDoneYmdKey(userId));
    await _save(m);
  }

  /// 아직 [markTarotEquipDefaultsV1Done] 전이면 `true` — 덱·뒷면·슬롯 기본 장착 일회 적용용.
  static Future<bool> needsTarotEquipDefaultsV1(String userId) async {
    final m = await _load();
    return m[_tarotEquipDefaultsV1Key(userId)] != true;
  }

  static Future<void> markTarotEquipDefaultsV1Done(String userId) async {
    final m = await _load();
    m[_tarotEquipDefaultsV1Key(userId)] = true;
    await _save(m);
  }

  /// 탈퇴·계정 삭제 시 이 `userId` 전용 키만 제거합니다.
  static Future<void> removePerUserEntries(String userId) async {
    final m = await _load();
    m.remove(_adRewardKey(userId));
    m.remove(_adRewardPromoIdxKey(userId));
    m.remove(_firstSetupWizardV1Key(userId));
    m.remove(_tarotEquipDefaultsV1Key(userId));
    m.remove(_todayTarotDismissedYmdKey(userId));
    m.remove(_todayTarotDoneYmdKey(userId));
    await _save(m);
  }
}
