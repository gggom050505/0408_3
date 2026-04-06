/// 출석 「행운이 가득한 날」 상점 서비스 지급 간격 — 유저 JSON / 별도 파일.
class AttendanceLuckyState {
  AttendanceLuckyState({this.nextEligibleAfterUtc});

  /// 이 시각(UTC) 이후 출석 시 상점 품목 지급 후보. null이면 이번 출석에서 행운 지급 가능(첫 출석 등).
  DateTime? nextEligibleAfterUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (nextEligibleAfterUtc != null)
          'next_eligible_after': nextEligibleAfterUtc!.toUtc().toIso8601String(),
      };

  factory AttendanceLuckyState.fromJson(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) {
      return AttendanceLuckyState();
    }
    DateTime? next;
    final raw = m['next_eligible_after'];
    if (raw is String && raw.isNotEmpty) {
      next = DateTime.tryParse(raw)?.toUtc();
    }
    return AttendanceLuckyState(nextEligibleAfterUtc: next);
  }
}
