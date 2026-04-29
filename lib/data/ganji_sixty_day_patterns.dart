// 60갑자 일간(일진) 참고 패턴 — 역사 별칭은 대개 연간 기준이며,
// 같은 한자 간지는 에너지·사건 유형을 끌어와 읽는 용도로 씁니다.

/// 단일 일진(일간) 해설 항목.
class GanjiDayPattern {
  const GanjiDayPattern({
    required this.orderIndex,
    required this.nameKo,
    required this.themeShort,
    this.notableYearEvent,
    required this.patternNote,
  });

  /// 1~60 (갑자=1 … 계해=60).
  final int orderIndex;

  /// 천간·지지 한글 두 글자 (예: 갑자).
  final String nameKo;

  /// 오행·기운을 한 줄로 요약.
  final String themeShort;

  /// 역사적 연호·사건명에 자주 쓰인 간지(있을 때만).
  final String? notableYearEvent;

  /// 흐름·패턴 해석.
  final String patternNote;
}

/// 천간 두 글자 → [GanjiDayPattern].
const Map<String, GanjiDayPattern> kGanjiDayPatternByStemBranchKo = {
  '갑자': GanjiDayPattern(
    orderIndex: 1,
    nameKo: '갑자',
    themeShort: '시작, 혁명의 씨앗 — 천간 목(木)·지지 수(水)',
    patternNote: '새 판을 깔고 새 출발을 준비하는 흐름. 시작·씨앗 단계로 보면 됩니다.',
  ),
  '을축': GanjiDayPattern(
    orderIndex: 2,
    nameKo: '을축',
    themeShort: '정체, 내부 갈등 — 목·토',
    patternNote: '밀착·정체 속에서 갈등이 응축되는 패턴. 속사정 정리가 필요해 보일 수 있어요.',
  ),
  '병인': GanjiDayPattern(
    orderIndex: 3,
    nameKo: '병인',
    themeShort: '확장, 공격성 상승 — 화·목',
    patternNote: '밖으로 뻗고 밀어붙이는 기운. 전쟁·대립을 ‘준비’하는 단계에 가깝게 읽을 수 있어요.',
  ),
  '정묘': GanjiDayPattern(
    orderIndex: 4,
    nameKo: '정묘',
    themeShort: '정치·관계의 재편 — 화·목',
    patternNote: '표면의 균형이 바뀌고 자리가 옮겨가는 느낌. 권력·역할 이동으로 보면 됩니다.',
  ),
  '무진': GanjiDayPattern(
    orderIndex: 5,
    nameKo: '무진',
    themeShort: '기반·틀의 변화 — 토·토',
    patternNote: '제도·구조·현실의 토대가 바뀌는 시기. 개편·재구축으로 연결해 볼 수 있어요.',
  ),
  '기사': GanjiDayPattern(
    orderIndex: 6,
    nameKo: '기사',
    themeShort: '충돌·긴장 고조 — 토·화',
    patternNote: '이해관계가 얽히며 갈등이 표면으로 드러나기 쉬운 패턴입니다.',
  ),
  '경오': GanjiDayPattern(
    orderIndex: 7,
    nameKo: '경오',
    themeShort: '충돌이 폭발적으로 드러남 — 금·화',
    patternNote: '극단적 대립·사건으로 번지기 쉬운 기운. 전쟁·폭동·대립 사건과 자주 엮여 해석됩니다.',
  ),
  '신미': GanjiDayPattern(
    orderIndex: 8,
    nameKo: '신미',
    themeShort: '정리·수습 단계 — 금·토',
    patternNote: '한바탕 지나간 뒤 겉을 다듬고 구조를 재편하는 흐름입니다.',
  ),
  '임신': GanjiDayPattern(
    orderIndex: 9,
    nameKo: '임신',
    themeShort: '정보·소통·외교 — 수·금',
    patternNote: '말·교섭·정보가 오가며 판이 움직이는 패턴. 대외·소통 변화로 읽을 수 있어요.',
  ),
  '계유': GanjiDayPattern(
    orderIndex: 10,
    nameKo: '계유',
    themeShort: '권력 교체·숙청 — 수·금',
    notableYearEvent: '계유정난(연간 명칭 예)',
    patternNote: '자리를 바꾸고 내부를 정리하는 기운. 역사적 명칭은 보통 그 해의 간지(연간)를 따릅니다.',
  ),
  '갑술': GanjiDayPattern(
    orderIndex: 11,
    nameKo: '갑술',
    themeShort: '제도·개혁 시도 — 목·토',
    patternNote: '새 방향으로 제도나 규칙을 바꾸려는 움직임이 나타나기 쉽습니다.',
  ),
  '을해': GanjiDayPattern(
    orderIndex: 12,
    nameKo: '을해',
    themeShort: '숨은 변화·유연성 — 목·수',
    patternNote: '겉으로는 잔잔해 보여도 아래에서는 방향이 바뀌는 식으로 읽을 수 있어요.',
  ),
  '병자': GanjiDayPattern(
    orderIndex: 13,
    nameKo: '병자',
    themeShort: '외부 충격·침입 — 화·수',
    notableYearEvent: '병자호란(연간 명칭 예)',
    patternNote: '밖에서 압력이 들어오거나 경계가 흔들리는 유형. 역사 별칭은 연간 기준이 많습니다.',
  ),
  '정축': GanjiDayPattern(
    orderIndex: 14,
    nameKo: '정축',
    themeShort: '혼란 수습 — 화·토',
    patternNote: '어수선한 틈을 메우고 정돈하려는 단계로 볼 수 있어요.',
  ),
  '무인': GanjiDayPattern(
    orderIndex: 15,
    nameKo: '무인',
    themeShort: '내부 성장·축적 — 토·목',
    patternNote: '겉보다 내부의 성장·밑천이 쌓이는 기운입니다.',
  ),
  '기묘': GanjiDayPattern(
    orderIndex: 16,
    nameKo: '기묘',
    themeShort: '내부 숙청·이념 대립 — 토·목',
    notableYearEvent: '기묘사화(연간 명칭 예)',
    patternNote: '안쪽에서 줄 세우기·정리가 일어나기 쉬운 패턴입니다.',
  ),
  '경진': GanjiDayPattern(
    orderIndex: 17,
    nameKo: '경진',
    themeShort: '권력 구조의 재편 — 금·토',
    patternNote: '조직·서열이 바뀌는 전환기로 읽을 수 있어요.',
  ),
  '신사': GanjiDayPattern(
    orderIndex: 18,
    nameKo: '신사',
    themeShort: '급변·돌발 — 금·화',
    patternNote: '짧은 시간에 판이 바뀌는 느낌. 예측 밖 변동으로 연결해 볼 수 있어요.',
  ),
  '임오': GanjiDayPattern(
    orderIndex: 19,
    nameKo: '임오',
    themeShort: '폭동·봉기 — 수·화',
    notableYearEvent: '임오군란(연간 명칭 예)',
    patternNote: '감정·민심이 격해져 사태로 번지기 쉬운 기운입니다.',
  ),
  '계미': GanjiDayPattern(
    orderIndex: 20,
    nameKo: '계미',
    themeShort: '안정·완충 시도 — 수·토',
    patternNote: '긴장을 누그러뜨리고 토지에 발 붙이려는 형국으로 볼 수 있어요.',
  ),
  '갑신': GanjiDayPattern(
    orderIndex: 21,
    nameKo: '갑신',
    themeShort: '급작스런 정변 — 목·금',
    notableYearEvent: '갑신정변(연간 명칭 예)',
    patternNote: '기존 질서를 한 번에 뒤집는 축에 가깝습니다. 쿠데타·급변 유형으로 자주 쓰입니다.',
  ),
  '을유': GanjiDayPattern(
    orderIndex: 22,
    nameKo: '을유',
    themeShort: '충돌·대립 — 목·금',
    patternNote: '의견·이해관계가 양날로 갈라지기 쉬운 날로 볼 수 있어요.',
  ),
  '병술': GanjiDayPattern(
    orderIndex: 23,
    nameKo: '병술',
    themeShort: '권력·자리 이동 — 화·토',
    patternNote: '자리를 옮기고 세력이 재배치되는 흐름입니다.',
  ),
  '정해': GanjiDayPattern(
    orderIndex: 24,
    nameKo: '정해',
    themeShort: '혼란·모호함 — 화·수',
    patternNote: '경계가 흐려지고 방향 잡기 어려운 느낌으로 읽을 수 있어요.',
  ),
  '무자': GanjiDayPattern(
    orderIndex: 25,
    nameKo: '무자',
    themeShort: '변화의 시동 — 토·수',
    patternNote: '얼어붙었던 것이 움직이기 시작하는 출발점에 가깝습니다.',
  ),
  '기축': GanjiDayPattern(
    orderIndex: 26,
    nameKo: '기축',
    themeShort: '정체·버티기 — 토·토',
    patternNote: '크게 판을 안 바꾸고 버티거나 유지하려는 기운입니다.',
  ),
  '경인': GanjiDayPattern(
    orderIndex: 27,
    nameKo: '경인',
    themeShort: '단단함과 성장이 부딪힘 — 금·목',
    patternNote: '규칙·강함과 생명력이 충돌하는 패턴으로 해석할 수 있어요.',
  ),
  '신묘': GanjiDayPattern(
    orderIndex: 28,
    nameKo: '신묘',
    themeShort: '정치·논쟁 — 금·목',
    patternNote: '말·논리·이념이 부딪히기 쉬운 시기로 볼 수 있습니다.',
  ),
  '임진': GanjiDayPattern(
    orderIndex: 29,
    nameKo: '임진',
    themeShort: '대형 충돌·전쟁 — 수·토',
    notableYearEvent: '임진왜란(연간 명칭 예)',
    patternNote: '국가·진영 단위의 큰 충돌을 상징하는 간지로 자주 인용됩니다. 일간은 같은 유형으로 참고하세요.',
  ),
  '계사': GanjiDayPattern(
    orderIndex: 30,
    nameKo: '계사',
    themeShort: '갈등의 점화 — 수·화',
    patternNote: '감정·이해관계가 한꺼번에 달아오르기 쉬운 날로 볼 수 있어요.',
  ),
  '갑오': GanjiDayPattern(
    orderIndex: 31,
    nameKo: '갑오',
    themeShort: '제도·체계의 개편 — 목·화',
    notableYearEvent: '갑오개혁(연간 명칭 예)',
    patternNote: '큰 틀을 바꾸는 개혁·개편과 잘 맞닿는 간지입니다.',
  ),
  '을미': GanjiDayPattern(
    orderIndex: 32,
    nameKo: '을미',
    themeShort: '충격·잠복된 변 — 목·토',
    notableYearEvent: '을미사변(연간 명칭 예)',
    patternNote: '갑작스런 사건·충격으로 기록에 남는 유형. 명칭은 대개 연간을 따릅니다.',
  ),
  '병신': GanjiDayPattern(
    orderIndex: 33,
    nameKo: '병신',
    themeShort: '날카로운 충돌 — 화·금',
    patternNote: '말·행동이 직선으로 부딪히기 쉬운 기운입니다.',
  ),
  '정유': GanjiDayPattern(
    orderIndex: 34,
    nameKo: '정유',
    themeShort: '재충돌·재개전 — 화·금',
    notableYearEvent: '정유재란(연간 명칭 예)',
    patternNote: '한 차례 지난 뒤 다시 불이 붙는 식의 패턴으로 읽을 수 있어요.',
  ),
  '무술': GanjiDayPattern(
    orderIndex: 35,
    nameKo: '무술',
    themeShort: '유지·안정 지향 — 토·토',
    patternNote: '격변 직후의 숨 고르기·경계 확보에 가깝습니다.',
  ),
  '기해': GanjiDayPattern(
    orderIndex: 36,
    nameKo: '기해',
    themeShort: '경계·흐름의 변화 — 토·수',
    patternNote: '물처럼 새 통로가 열리거나 방향이 바뀌는 느낌입니다.',
  ),
  '경자': GanjiDayPattern(
    orderIndex: 37,
    nameKo: '경자',
    themeShort: '기술·자본·도구의 전환 — 금·수',
    notableYearEvent: '경자유전(연간 명칭 예)',
    patternNote: '새 물건·새 제도·새 자금이 들어오는 시대상과 잘 맞는 간지입니다.',
  ),
  '신축': GanjiDayPattern(
    orderIndex: 38,
    nameKo: '신축',
    themeShort: '구조의 재정비 — 금·토',
    patternNote: '땅·조직·현실의 형태를 고치는 단계로 볼 수 있어요.',
  ),
  '임인': GanjiDayPattern(
    orderIndex: 39,
    nameKo: '임인',
    themeShort: '확장·도약 — 수·목',
    patternNote: '아이디어·세력이 한 번에 자라나는 기운입니다.',
  ),
  '계묘': GanjiDayPattern(
    orderIndex: 40,
    nameKo: '계묘',
    themeShort: '잔잔한 변화·씨뿌리기 — 수·목',
    patternNote: '겉은 부드럽게 보여도 방향 전환의 씨가 심기는 느낌입니다.',
  ),
  '갑진': GanjiDayPattern(
    orderIndex: 41,
    nameKo: '갑진',
    themeShort: '틀·조직 개편 — 목·토',
    patternNote: '현실의 칸막이를 바꾸는 개편기로 읽을 수 있어요.',
  ),
  '을사': GanjiDayPattern(
    orderIndex: 42,
    nameKo: '을사',
    themeShort: '외교·조약의 붕괴 — 목·화',
    notableYearEvent: '을사늑약(연간 명칭 예)',
    patternNote: '말로 맺은 균형이 깨지거나 굴욕적 조건으로 기억되는 유형입니다.',
  ),
  '병오': GanjiDayPattern(
    orderIndex: 43,
    nameKo: '병오',
    themeShort: '폭발·과열 — 화·화',
    patternNote: '한꺼번에 타오르는 기운. 과열·충돌에 가깝게 해석합니다.',
  ),
  '정미': GanjiDayPattern(
    orderIndex: 44,
    nameKo: '정미',
    themeShort: '안정·완충 시도 — 화·토',
    patternNote: '뜨거운 걸 누그러뜨리고 토대를 다지려는 흐름입니다.',
  ),
  '무신': GanjiDayPattern(
    orderIndex: 45,
    nameKo: '무신',
    themeShort: '군사·힘의 재편 — 토·금',
    patternNote: '물리력·군·경계선이 움직이는 패턴으로 볼 수 있어요.',
  ),
  '기유': GanjiDayPattern(
    orderIndex: 46,
    nameKo: '기유',
    themeShort: '정리·마무리 — 토·금',
    patternNote: '정리하고 칼을 넣는 단계에 가깝습니다.',
  ),
  '경술': GanjiDayPattern(
    orderIndex: 47,
    nameKo: '경술',
    themeShort: '국체·체제의 붕괴 — 금·토',
    notableYearEvent: '경술국치(연간 명칭 예)',
    patternNote: '국가·왕조 단위의 큰 전환과 함께 기록되는 간지입니다.',
  ),
  '신해': GanjiDayPattern(
    orderIndex: 48,
    nameKo: '신해',
    themeShort: '순환·개방 — 금·수',
    patternNote: '닫혔던 것이 풀리고 새로운 통로가 열리는 느낌입니다.',
  ),
  '임자': GanjiDayPattern(
    orderIndex: 49,
    nameKo: '임자',
    themeShort: '흐름의 전환 — 수·수',
    patternNote: '물줄기가 합쳐지거나 방향이 바뀌는 식으로 읽을 수 있어요.',
  ),
  '계축': GanjiDayPattern(
    orderIndex: 50,
    nameKo: '계축',
    themeShort: '정체·응축 — 수·토',
    patternNote: '움직임이 잠시 멈추고 바닥에 가라앉는 기운입니다.',
  ),
  '갑인': GanjiDayPattern(
    orderIndex: 51,
    nameKo: '갑인',
    themeShort: '새 출발 준비 — 목·목',
    patternNote: '싹이 올라오기 직전의 준비·동력 축적 단계입니다.',
  ),
  '을묘': GanjiDayPattern(
    orderIndex: 52,
    nameKo: '을묘',
    themeShort: '외부 침입·압박 — 목·목',
    notableYearEvent: '을묘왜변(연간 명칭 예)',
    patternNote: '경계 밖의 힘이 밀려오는 유형. 역사적 이름은 연간을 따른 경우가 많습니다.',
  ),
  '병진': GanjiDayPattern(
    orderIndex: 53,
    nameKo: '병진',
    themeShort: '성장·팽창 — 화·토',
    patternNote: '세력·규모가 부풀어 오르는 시기로 볼 수 있어요.',
  ),
  '정사': GanjiDayPattern(
    orderIndex: 54,
    nameKo: '정사',
    themeShort: '점화·폭발 — 화·화',
    patternNote: '한 점에서 불이 번지는 집중·폭발 기운입니다.',
  ),
  '무오': GanjiDayPattern(
    orderIndex: 55,
    nameKo: '무오',
    themeShort: '열기·변동 — 토·화',
    patternNote: '땅 위에 열이 올라 형세가 바뀌는 패턴입니다.',
  ),
  '기미': GanjiDayPattern(
    orderIndex: 56,
    nameKo: '기미',
    themeShort: '완만·버팀 — 토·토',
    patternNote: '큰 파동이 지난 뒤 안정을 찾으려는 기운입니다.',
  ),
  '경신': GanjiDayPattern(
    orderIndex: 57,
    nameKo: '경신',
    themeShort: '단단한 정리·단속 — 금·금',
    patternNote: '규칙·칼날·경계가 또렷해지는 강한 정리의 기운입니다.',
  ),
  '신유': GanjiDayPattern(
    orderIndex: 58,
    nameKo: '신유',
    themeShort: '수확·절단 — 금·금',
    patternNote: '결실을 거두고 불필요한 것을 잘라 내는 시기로 읽을 수 있어요.',
  ),
  '임술': GanjiDayPattern(
    orderIndex: 59,
    nameKo: '임술',
    themeShort: '경계·토대의 변화 — 수·토',
    patternNote: '흐름이 땅을 바꾸거나 저축·안전망이 흔들리는 느낌입니다.',
  ),
  '계해': GanjiDayPattern(
    orderIndex: 60,
    nameKo: '계해',
    themeShort: '순환의 끝·초기화 — 수·수',
    patternNote: '한 바퀴를 마치고 다시 비워 새 주기를 준비하는 기운으로 볼 수 있어요.',
  ),
};

GanjiDayPattern? lookupGanjiDayPatternKo(String stemBranchKo) {
  if (stemBranchKo.length != 2) {
    return null;
  }
  return kGanjiDayPatternByStemBranchKo[stemBranchKo];
}
