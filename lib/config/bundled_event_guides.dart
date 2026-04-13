import '../models/event_item.dart';

/// 오늘 0시(UTC) 기준 [EventItemRow.startDate] — 활성 필터와 맞춤.
String gggomEventStartDateUtcIsoToday() {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
}

/// 이벤트 탭에 붙이는 **앱 이용·응용 가이드** (출석 안내 본문과 중복 없음).
/// 오프라인 번들 목록에도 끼워 넣습니다.
List<EventItemRow> bundledAppGuideEventCards([String? startDateIsoUtc]) {
  final start = startDateIsoUtc ?? gggomEventStartDateUtcIsoToday();
  return [
    EventItemRow(
      id: 90009,
      title: '🌅 오늘의 타로 — 매일 10장·5×2',
      description:
          '하단 **「오늘의 타로」** 탭에서 하루 한 키워드(날짜마다 달라요)를 두고, 106장 덱에서 '
          '10장을 받아 5×2 슬롯에 올린 뒤 한 장씩 뒤집을 수 있어요. 마이너·궁정·메이저·한국전통 메이저 '
          '마다 점수가 다르고, 모두 뒤집으면 합계와 정리가 나와요.\n\n'
          '• **게시**: 결과 화면에서 **「게시하기」**를 눌러야 피드(`#오늘의타로`)에 올라가요. '
          '**「게시 안함」**을 고르면 그날 기록만 남고 피드에는 안 올라갑니다.\n'
          '• **오늘의 게시** 탭: 오늘의 타로로 올린 글만 모아 봅니다. 정렬에서 **타로점수순**도 써 보세요.\n'
          '• **다시 뽑기**: 상단 새로고침으로 완료 표시를 지우면 같은 날 처음부터 다시 할 수 있어요.\n\n'
          '오프라인(피드 미연동) 빌드에서는 게시 단계가 비활성일 수 있어요.',
      type: 'notice',
      gradient: 'linear-gradient(135deg, #FFF8E1 0%, #FFE082 50%, #FFD54F 100%)',
      badgeText: '데일리',
      startDate: start,
      endDate: null,
      isActive: true,
      sortOrder: 3,
    ),
    EventItemRow(
      id: 90005,
      title: '🃏 타로 매트·캡처·게시물 — 한 판을 길게 남기기',
      description:
          '「타로」탭에서 덱·매트·슬롯·카드 뒷면을 바꿔 분위기를 바꿀 수 있어요. '
          '뽑은 배열이 마음에 들면 화면 캡처로 **「게시물」** 탭 전용 태그(`#타로스프레드`)와 함께 올려 보세요. '
          '「오늘의 게시」는 **오늘의 타로** 데일리 결과만 모읍니다.\n\n'
          '나중에 같은 스프레드를 다시 펼쳐 보며 해석을 덧붙이는 식으로 '
          '일기·기록으로 응용할 수 있어요.\n\n'
          '한국전통 메이저 덱은 가방에서 모은 장만 섞여 나오므로, 카드를 모을수록 내 타로가 풍성해져요.',
      type: 'notice',
      gradient: 'linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 50%, #90CAF9 100%)',
      badgeText: '가이드',
      startDate: start,
      endDate: null,
      isActive: true,
      sortOrder: 4,
    ),
    EventItemRow(
      id: 90006,
      title: '⭐ 별조각 모으기 — 출석·광고·행운의 조합',
      description:
          '⭐ 별조각은 상점에서 덱·오라클·한국전통 메이저 장 등을 살 때 씁니다.\n\n'
          '• 매일 첫 출석: 별조각 +1과 미보유 유료 상품 1개를 무작위로 함께 드려요(후보가 없으면 별만).\n'
          '• 「별조각 광고」: `assets/advert/` 영상 시청 완료 후 별조각 3개 지급(10분 쿨타임). '
          '원치 않으면 재생 중 나가기로 종료할 수 있고, 이 경우 보상은 지급되지 않아요.\n\n'
          '가방에 이미 있는 품목은 선물·행운 모두에서 중복으로 쌓이지 않도록 맞춰 두었어요.',
      type: 'notice',
      gradient: 'linear-gradient(135deg, #FCE4EC 0%, #F8BBD0 50%, #F48FB1 100%)',
      badgeText: '경제',
      startDate: start,
      endDate: null,
      isActive: true,
      sortOrder: 5,
    ),
    EventItemRow(
      id: 90007,
      title: '🔮 오라클 80장·짧은 질문에 어울리는 활용',
      description:
          '오라클 카드는 메이저 22장 타로와는 다른 80장의 메시지예요. '
          '「오늘의 한 장」「한 문장 조언」처럼 가볍게 뽑기 좋고, 타로 스프레드와 섞어 쓰지 않고 '
          '별도 흐름으로 쓰면 해석이 더 선명해져요.\n\n'
          '상점에서 별조각으로 한 장씩 모으거나 번들로 여러 장을 열 수 있어요. '
          '가방의 🇰🇷 한국전통 메이저는 「한 장씩 수집하는 덱」에 가깝습니다 — 22장을 다 모을 필요 없이, '
          '가진 장만으로 타로 덱이 구성돼요.\n\n'
          '유니크 품목(한국전통 7장·오라클 24장·이모티콘 12장)은 상점에서 직접 구매하지 않고 '
          '선물/개인 상점 거래로 모으는 흐름을 권장합니다.',
      type: 'notice',
      gradient: 'linear-gradient(135deg, #EDE7F6 0%, #D1C4E9 50%, #B39DDB 100%)',
      badgeText: '컬렉션',
      startDate: start,
      endDate: null,
      isActive: true,
      sortOrder: 6,
    ),
    EventItemRow(
      id: 90008,
      title: '💬 채팅·이모티콘·가방 — 꾸미기와 정리',
      description:
          '「채팅」에서는 텍스트와 이모티콘을 쓸 수 있어요. 상점에서 이모팩을 사면 채팅창에서 더 다양한 '
          '캐릭터를 꺼낼 수 있습니다.\n\n'
          '「가방」에서는 장착 중인 카드 덱·카드 뒷면·슬롯·오라클·한국전통 메이저를 바꿀 수 있어요. '
          '타로 탭에 반영되니, 오늘의 분위기에 맞게 정리해 보세요.\n\n'
          'PC 설치판에서는 GNB의 「저장하기」로 로컬 기록을 개발용 JSON 폴더로 옮길 수 있어요(비웹에서는 숨김).',
      type: 'notice',
      gradient: 'linear-gradient(135deg, #E0F7FA 0%, #B2EBF2 50%, #80DEEA 100%)',
      badgeText: '꾸미기',
      startDate: start,
      endDate: null,
      isActive: true,
      sortOrder: 7,
    ),
  ];
}
