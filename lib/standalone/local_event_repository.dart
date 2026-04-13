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
        id: 90003,
        title: '📝 게시 선물 — 하루 첫 게시에 ⭐5',
        description:
            '이벤트 기간 동안 **오늘의 타로**를 피드에 게시하거나, **타로** 탭에서 스프레드 캡처를 '
            '「게시물」탭으로 올리면, **한국 날짜 기준 하루에 한 번(첫 성공 게시)** ⭐ 별조각 5개를 '
            '가방에 바로 지급해 드려요. 같은 날 두 번째부터는 선물 없이 게시만 됩니다.\n\n'
            '지급이 될 때만 홈 상단 선물 배너가 뜨고, 이미 받은 날에는 짧은 안내 스낵바만 나와요.',
        type: 'notice',
        gradient:
            'linear-gradient(135deg, #FFF0C2 0%, #FFE28A 52%, #FFD65C 100%)',
        badgeText: '게시 +5⭐/일',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 0,
      ),
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
            '지급 내용은 출석 후 화면 하단 스낵바를 확인해 주세요.',
        type: 'notice',
        gradient:
            'linear-gradient(135deg, #E8DDF2 0%, #D4C4E8 50%, #C4B5E0 100%)',
        badgeText: '출석',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 1,
      ),
      ...bundledAppGuideEventCards(start),
      EventItemRow(
        id: 90001,
        title: '베타·오프라인 번들 안내',
        description:
            '지금 보시는 이벤트·공지는 기기에 포함된 베타·오프라인 번들 안내예요. '
            '별도 서버 연동 없이 동작합니다.',
        type: 'notice',
        gradient: null,
        badgeText: 'BETA',
        startDate: start,
        endDate: null,
        isActive: true,
        sortOrder: 8,
      ),
    ];
  }
}
