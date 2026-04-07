/// 출석 연동 레거시 상태(쿨다운). 현재는 매 출석마다 무작위 선물만 추첨하며 [nextEligibleAfterUtc]는 비웁니다.
class AttendanceLuckyState {
  AttendanceLuckyState({this.nextEligibleAfterUtc});

  /// 이전 버전용 쿨다운 시각. 유지 필드만 저장·복원(신규 로직에서는 null).
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
