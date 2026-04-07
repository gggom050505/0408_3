import '../config/bundled_event_guides.dart';
import '../models/event_item.dart';
import 'data_sources.dart';

class LocalEventRepository implements EventDataSource {
  @override
  Future<List<EventItemRow>> fetchActiveEvents() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .toUtc()
        .toIso8601String();
    return [
      EventItemRow(
        id: 90002,
        title: '📅 매일 출석 선물',
        description:
            '매일 첫 출석마다 아래가 함께 지급됩니다.\n\n'
            '⭐ 별조각 1개\n'
            '🎁 상점에서 별조각으로 파는 유료 품목 중, 가방에 아직 없는 것을 무작위로 1개 '
            '(카드 덱·뒷면·매트·슬롯·오라클·한국전통 메이저 장 등 — 이모티콘 단품·팩 행은 제외)\n\n'
            '이미 모은 품목은 후보에서 빼므로 겹치지 않습니다. 유료로 살 수 있는 것을 '
            '전부 모은 경우에는 그날은 별조각만 받을 수 있어요.\n\n'
            '상점 「깜짝 선물」로 예약된 품목은 출석 선물 후보에서 빼서 같은 날 두 번 받지 않도록 '
            '맞춰 두었습니다. 지급 내용은 출석 후 화면 하단 스낵바를 확인해 주세요.',
        type: 'notice',
        gradient:
            'linear-gradient(135deg, #E8DDF2 0%, #D4C4E8 50%, #C4B5E0 100%)',
        badgeText: '출석',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 0,
      ),
      EventItemRow(
        id: 90003,
        title: '🎁 상점 깜짝 선물 (2~7일)',
        description:
            '🏪 상점 탭을 열 때마다 동기화되며, 2~7일 간격(무작위)으로 '
            '유료·미보유 상품 한 개를 깜짝 선물로 받을 수 있어요. 가방에 이미 있는 품목은 '
            '후보에서 빼므로 겹치지 않습니다.\n\n'
            '상단 배너에 무료 받기가 뜨면 탭해서 수령하면 됩니다. 매일 출석 선물과는 별도 주기이며, '
            '예약 품목은 출석 무작위 선물 후보에서 빠집니다.',
        type: 'notice',
        gradient: 'linear-gradient(135deg, #DFF0E8 0%, #C8E6D5 50%, #A8D5BA 100%)',
        badgeText: '상점',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 1,
      ),
      EventItemRow(
        id: 90004,
        title: '📈 매일 바뀌는 상점 시세',
        description:
            '상점 품목 별조각 가격(시세)은 매 UTC일마다 바뀌어요. '
            '날마다 1~100 구간에서 정해진 뒤 ⭐1~3 저가 구간이 잡히기도 하고, '
            '그 외에는 ⭐4~10 중으로 책정됩니다. 같은 카드라도 오늘과 내일 다를 수 있어요.',
        type: 'notice',
        gradient: 'linear-gradient(135deg, #FFF4E0 0%, #FFE0B2 50%, #FFCC80 100%)',
        badgeText: '시세',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 2,
      ),
      ...bundledAppGuideEventCards(start),
      EventItemRow(
        id: 90001,
        title: '베타·오프라인 번들 안내',
        description:
            '지금 보시는 이벤트·공지는 서버 없이 돌아가는 베타 번들용으로 앱에 포함된 안내예요. '
            'Supabase를 연 빌드에서는 DB events 테이블의 공지가 함께 표시됩니다. '
            '운영 서버에도 같은 내용의 공지를 올려 두면, 정식·연동 사용자에게 동일하게 전달할 수 있어요.',
        type: 'notice',
        gradient: null,
        badgeText: 'BETA',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 7,
      ),
    ];
  }
}
