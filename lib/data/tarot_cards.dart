import 'dart:math' as math;

class TarotCard {
  const TarotCard({
    required this.id,
    required this.name,
    required this.nameKo,
    required this.arcana,
    this.suit,
    required this.emoji,
    required this.meaning,
    required this.advice,
  });

  final int id;
  final String name;
  final String nameKo;
  final String arcana;
  final String? suit;
  final String emoji;
  final String meaning;
  final String advice;
}

const _rankNamesEn = [
  'Ace', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven',
  'Eight', 'Nine', 'Ten', 'Page', 'Knight', 'Queen', 'King',
];

const _rankNamesKo = [
  '에이스', '2', '3', '4', '5', '6', '7',
  '8', '9', '10', '시종', '기사', '여왕', '왕',
];

const _majorArcana = <TarotCard>[
  TarotCard(
    id: 0,
    name: 'The Fool',
    nameKo: '광대',
    arcana: 'major',
    emoji: '🤡',
    meaning: '메이저 광대(0) — 큰 흐름·인생 단계. 키워드: 시작, 자유, 모험. (좋다/나쁘다가 아니라 피할 수 없는 흐름으로 읽어요.)',
    advice: '그림자·주의: 무계획, 현실감 없음. 설렘은 유지하고 안전·예산·일정 한 줄은 챙기세요 🤡',
  ),
  TarotCard(
    id: 1,
    name: 'The Magician',
    nameKo: '마법사',
    arcana: 'major',
    emoji: '🧙',
    meaning: '메이저 마법사(1) — 키워드: 능력, 실행, 창조. 기회와 대가가 함께 옵니다.',
    advice: '그림자·주의: 사기, 말만 번지르르함. 약속은 결과·증거와 묶어 확인해 보세요 🧙',
  ),
  TarotCard(
    id: 2,
    name: 'The High Priestess',
    nameKo: '여사제',
    arcana: 'major',
    emoji: '🔮',
    meaning: '메이저 여사제(2) — 키워드: 직관, 비밀, 내면.',
    advice: '그림자·주의: 숨김, 소통 단절. 필요한 만큼만 나누고 연결 통로는 남기세요 🔮',
  ),
  TarotCard(
    id: 3,
    name: 'The Empress',
    nameKo: '여황제',
    arcana: 'major',
    emoji: '👸',
    meaning: '메이저 여황제(3) — 키워드: 풍요, 성장, 사랑.',
    advice: '그림자·주의: 과보호, 나태. 돌봄·양육과 휴식·회복의 균형을 맞춰 보세요 👸',
  ),
  TarotCard(
    id: 4,
    name: 'The Emperor',
    nameKo: '황제',
    arcana: 'major',
    emoji: '🤴',
    meaning: '메이저 황제(4) — 키워드: 통제, 권위, 안정.',
    advice: '그림자·주의: 독단, 강압. 질서는 세우되 한 번은 상대 말을 끝까지 들어 보세요 🤴',
  ),
  TarotCard(
    id: 5,
    name: 'The Hierophant',
    nameKo: '교황',
    arcana: 'major',
    emoji: '📿',
    meaning: '메이저 교황(5) — 키워드: 전통, 규칙, 교육.',
    advice: '그림자·주의: 고정관념, 융통성 부족. 원칙 속에 예외 한 칸을 허용해 보세요 📿',
  ),
  TarotCard(
    id: 6,
    name: 'The Lovers',
    nameKo: '연인',
    arcana: 'major',
    emoji: '💑',
    meaning: '메이저 연인(6) — 키워드: 선택, 관계, 조화.',
    advice: '그림자·주의: 우유부단, 유혹. 선택 기준을 한 줄로 적어 보세요 💑',
  ),
  TarotCard(
    id: 7,
    name: 'The Chariot',
    nameKo: '전차',
    arcana: 'major',
    emoji: '🐎',
    meaning: '메이저 전차(7) — 키워드: 승리, 돌진, 통제.',
    advice: '그림자·주의: 폭주, 충돌. 속도를 줄일 타이밍·브레이크를 미리 정해 두세요 🐎',
  ),
  TarotCard(
    id: 8,
    name: 'Strength',
    nameKo: '힘',
    arcana: 'major',
    emoji: '🦁',
    meaning: '메이저 힘(8) — 키워드: 인내, 절제, 내면의 힘.',
    advice: '그림자·주의: 참다가 폭발. 말하기 전 숨 한 번, 문장은 짧게 🦁',
  ),
  TarotCard(
    id: 9,
    name: 'The Hermit',
    nameKo: '은둔자',
    arcana: 'major',
    emoji: '🏔️',
    meaning: '메이저 은둔자(9) — 키워드: 탐색, 고독, 지혜.',
    advice: '그림자·주의: 고립, 단절. 멈춤도 좋지만 신뢰할 한 사람에게 신호를 보내 보세요 🏔️',
  ),
  TarotCard(
    id: 10,
    name: 'Wheel of Fortune',
    nameKo: '운명의 수레바퀴',
    arcana: 'major',
    emoji: '🎡',
    meaning: '메이저 운명의 수레바퀴(10) — 키워드: 변화, 운명, 전환.',
    advice: '그림자·주의: 불안정, 예측 불가. 통제할 것·맡길 것을 나누고 백업 한 줄을 🎡',
  ),
  TarotCard(
    id: 11,
    name: 'Justice',
    nameKo: '정의',
    arcana: 'major',
    emoji: '⚖️',
    meaning: '메이저 정의(11) — 키워드: 균형, 판단, 결과.',
    advice: '그림자·주의: 냉정, 인과의 대가. 판단 전 사실·맥락을 적어 두세요 ⚖️',
  ),
  TarotCard(
    id: 12,
    name: 'The Hanged Man',
    nameKo: '매달린 사람',
    arcana: 'major',
    emoji: '🙃',
    meaning: '메이저 매달린 사람(12) — 키워드: 희생, 멈춤, 관점 변화.',
    advice: '그림자·주의: 정체, 손해. 멈춤의 목적 한 줄을 적어 두면 헛손해가 줄어요 🙃',
  ),
  TarotCard(
    id: 13,
    name: 'Death',
    nameKo: '죽음',
    arcana: 'major',
    emoji: '🦋',
    meaning: '메이저 죽음(13) — 키워드: 끝, 변화, 재시작.',
    advice: '그림자·주의: 상실, 강제 종료. 끝난 걸 인정하고 새 장의 첫 줄만 적어 보세요 🦋',
  ),
  TarotCard(
    id: 14,
    name: 'Temperance',
    nameKo: '절제',
    arcana: 'major',
    emoji: '🌊',
    meaning: '메이저 절제(14) — 키워드: 조화, 균형, 조절.',
    advice: '그림자·주의: 답답함, 속도 느림. 작은 실험 한 칸만 열어 속도를 조절해 보세요 🌊',
  ),
  TarotCard(
    id: 15,
    name: 'The Devil',
    nameKo: '악마',
    arcana: 'major',
    emoji: '😈',
    meaning: '메이저 악마(15) — 키워드: 집착, 욕망, 중독.',
    advice: '그림자·주의: 통제 불가, 빠져나오기 어려움. 사슬 하나부터 끊을 방법을 찾아 보세요 😈',
  ),
  TarotCard(
    id: 16,
    name: 'The Tower',
    nameKo: '탑',
    arcana: 'major',
    emoji: '⚡',
    meaning: '메이저 탑(16) — 키워드: 붕괴, 충격, 파괴.',
    advice: '그림자·주의: 갑작스러운 실패·충격. 안전·백업·연락망부터 정리해 보세요 ⚡',
  ),
  TarotCard(
    id: 17,
    name: 'The Star',
    nameKo: '별',
    arcana: 'major',
    emoji: '⭐',
    meaning: '메이저 별(17) — 키워드: 희망, 치유, 기대.',
    advice: '그림자·주의: 현실성 부족. 희망은 두고 실행 계획·숫자 한 줄을 ⭐',
  ),
  TarotCard(
    id: 18,
    name: 'The Moon',
    nameKo: '달',
    arcana: 'major',
    emoji: '🌙',
    meaning: '메이저 달(18) — 키워드: 불안, 혼란, 착각.',
    advice: '그림자·주의: 속임, 오해. 확인 가능한 사실만 따로 적어 보세요 🌙',
  ),
  TarotCard(
    id: 19,
    name: 'The Sun',
    nameKo: '태양',
    arcana: 'major',
    emoji: '☀️',
    meaning: '메이저 태양(19) — 키워드: 성공, 기쁨, 명확함.',
    advice: '그림자·주의: 방심, 과신. 좋을 때일수록 체크리스트 한 번 ☀️',
  ),
  TarotCard(
    id: 20,
    name: 'Judgement',
    nameKo: '심판',
    arcana: 'major',
    emoji: '🎺',
    meaning: '메이저 심판(20) — 키워드: 각성, 결론, 부활.',
    advice: '그림자·주의: 후회, 책임. 각성을 짓누르지 말고 다음 행동 한 줄로 옮겨 보세요 🎺',
  ),
  TarotCard(
    id: 21,
    name: 'The World',
    nameKo: '세계',
    arcana: 'major',
    emoji: '🌍',
    meaning: '메이저 세계(21) — 키워드: 완성, 성공, 마무리.',
    advice: '그림자·주의: 끝 이후 공허함. 축하한 뒤 다음 목적·역할 한 가지만 정해 보세요 🌍',
  ),
];

/// 메이저 22장만 — `한국전통 메이저` 덱(에셋 0~21)과 id가 일치하는 소스.
final List<TarotCard> tarotMajorArcanaOnly =
    List<TarotCard>.unmodifiable(_majorArcana);

const _suitMeta = <String, (String, String)>{
  'wands': ('🪄', '완드'),
  'cups': ('🏆', '컵'),
  'swords': ('⚔️', '검'),
  'pentacles': ('🪙', '펜타클'),
};

const _suitEmojis = {
  'wands': ['🔥', '🗺️', '🌟', '🎉', '⚔️', '🏅', '🛡️', '🚀', '💪', '🏋️', '🐱', '🐎', '🦊', '🦅'],
  'cups': ['💗', '💑', '🥂', '😶', '😢', '📸', '🌈', '🚶', '🌠', '🏠', '🐟', '🦢', '🧜', '👑'],
  'swords': ['💡', '🤔', '💔', '😴', '🌧️', '⛵', '🦝', '🕸️', '😰', '🌑', '🦉', '🐆', '❄️', '🗡️'],
  'pentacles': ['🌱', '🎪', '🔨', '🏡', '❄️', '🎁', '🌿', '⚒️', '🍇', '🏰', '📖', '🐢', '🌺', '💰'],
};

final _suitData = <String, (List<String>, List<String>)>{
  'wands': (
    [
      '마이너 완드 · Ace — 행동·일·에너지. 키워드: 시작, 열정. (좋아도 과속·과부하 주의)',
      '마이너 완드 · 2 — 키워드: 계획, 방향 설정.',
      '마이너 완드 · 3 — 키워드: 확장, 기회.',
      '마이너 완드 · 4 — 키워드: 안정, 기반.',
      '마이너 완드 · 5 — 키워드: 경쟁, 충돌.',
      '마이너 완드 · 6 — 키워드: 승리, 인정.',
      '마이너 완드 · 7 — 키워드: 방어, 버팀.',
      '마이너 완드 · 8 — 키워드: 속도, 급변.',
      '마이너 완드 · 9 — 키워드: 버팀, 인내.',
      '마이너 완드 · 10 — 키워드: 부담, 책임.',
      '궁정 완드 · Page — 행동·열정 슈트의 시작·배우는 단계. 키워드: 도전, 호기심, 새 출발. (사람일 수도, 내 태도일 수도 있어요.)',
      '궁정 완드 · Knight — 지금 움직이는 실행. 키워드: 돌진, 열정, 빠른 행동.',
      '궁정 완드 · Queen — 내면에서 불을 다루는 단계. 키워드: 자신감, 매력, 리더십.',
      '궁정 완드 · King — 밖으로 비전을 세우고 이끔. 키워드: 통솔, 큰 그림, 카리스마.',
    ],
    [
      '주의: 지속력 부족. 불씨는 키우되 리듬·휴식 슬롯을 같이 잡아 보세요 🔥',
      '주의: 실행 안 함. 방향 하나 정하고 첫 스텝만 오늘 찍어 보세요 🗺️',
      '주의: 과한 기대. 숫자·일정으로 기대치를 현실에 맞춰 보세요 🌟',
      '주의: 안주. 기반은 지키되 새 시도 창구는 작게라도 열어 두세요 🎉',
      '주의: 갈등 확대. 이기려 하기 전에 규칙·협상으로 불부터 끄세요 💪',
      '주의: 자만. 축하한 뒤 다음 목표를 한 단계만 낮춰 잡아 보세요 🏅',
      '주의: 스트레스. 지킬 선만 정하고 숨 쉴 틈·지원을 허용하세요 🛡️',
      '주의: 성급함. 급변 전 체크리스트·안전장치 한 번만 더 ⚡',
      '주의: 지침. 버티기와 포기·위임의 기준을 나눠 보세요 🔥',
      '주의: 과부하. 짐 나누기·우선순위 줄이기를 먼저 🤝',
      '주의: 쉽게 질림·지속력 부족. 작게 나눠 시작하고 리듬을 유지해 보세요 🐱',
      '주의: 충동·준비 부족·사고. 속도와 안전·계획의 균형을 보세요 🐎',
      '주의: 고집·자기중심. 매력은 유지하되 한 번 더 들어 주세요 🦊',
      '주의: 독단·과신. 비전은 함께 나누면 더 커져요 🦅',
    ],
  ),
  'cups': (
    [
      '마이너 컵 · Ace — 감정·관계·사랑. 키워드: 감정 시작, 호감, 설렘. (좋아도 과몰입 주의)',
      '마이너 컵 · 2 — 키워드: 관계 형성, 연결, 파트너.',
      '마이너 컵 · 3 — 키워드: 기쁨, 모임, 축하.',
      '마이너 컵 · 4 — 키워드: 지루함, 무관심.',
      '마이너 컵 · 5 — 키워드: 후회, 상실, 실망.',
      '마이너 컵 · 6 — 키워드: 추억, 재회.',
      '마이너 컵 · 7 — 키워드: 선택 혼란, 환상.',
      '마이너 컵 · 8 — 키워드: 떠남, 포기.',
      '마이너 컵 · 9 — 키워드: 만족, 소원 성취.',
      '마이너 컵 · 10 — 키워드: 행복, 관계 완성.',
      '궁정 컵 · Page — 감정·관계 슈트의 시작·배우는 단계. 키워드: 순수, 감정의 시작, 설렘.',
      '궁정 컵 · Knight — 감성으로 움직임. 키워드: 로맨스, 이상, 감성 행동.',
      '궁정 컵 · Queen — 마음의 물결을 다룸. 키워드: 공감, 배려, 감정 안정.',
      '궁정 컵 · King — 분위기·관계를 성숙하게 이끔. 키워드: 감정 통제, 온화, 책임.',
    ],
    [
      '주의: 착각, 과몰입. 느낌은 따로 두고 사실·경계도 확인해 보세요 💗',
      '주의: 의존, 집착. 연결은 유지하되 나만의 루틴·호흡은 지키세요 💑',
      '주의: 가벼움, 삼각관계. 즐거움 속에서도 약속과 선은 명확히 🥂',
      '주의: 기회 놓침. 무관심 속 신호·새 자극을 한 번 더 들여다보세요 🔄',
      '주의: 과거 집착. 슬픔은 인정하고 오늘 할 수 있는 선택 하나만 🙏',
      '주의: 과거에 머묾. 추억은 참고하고 지금의 필요를 물어 보세요 📸',
      '주의: 현실 착각. 옵션마다 사실·비용·리스크를 적어 보세요 👁️',
      '주의: 도피. 떠나도 되지만 회피인지 결단인지 구분해 보세요 🚶',
      '주의: 자기만족, 자만. 좋을 때일수록 피드백 한 줄만 받아 보세요 🌠',
      '주의: 이상화. 완벽한 그림보다 일상의 대화를 나눠 보세요 🏠',
      '주의: 감정 과몰입·현실감 부족. 설렘은 유지하고 사실도 확인해 보세요 🐟',
      '주의: 말만 하고 실행 부족·변덕. 마음은 행동으로 보여 주세요 🦢',
      '주의: 남 감정에 휘둘림·과한 희생. 경계와 나만의 공간을 지키세요 🧜',
      '주의: 속마음 숨김·감정 억압. 필요할 땐 솔직히 한 줄이라도 꺼내 보세요 👑',
    ],
  ),
  'swords': (
    [
      '마이너 소드 · Ace — 생각·문제·갈등. 키워드: 판단, 진실. (항상 리스크·냉기 짝꿍)',
      '마이너 소드 · 2 — 키워드: 고민, 선택 회피.',
      '마이너 소드 · 3 — 키워드: 상처, 이별.',
      '마이너 소드 · 4 — 키워드: 휴식, 회복.',
      '마이너 소드 · 5 — 키워드: 갈등, 승패.',
      '마이너 소드 · 6 — 키워드: 이동, 변화.',
      '마이너 소드 · 7 — 키워드: 속임, 전략.',
      '마이너 소드 · 8 — 키워드: 묶임, 제한.',
      '마이너 소드 · 9 — 키워드: 불안, 걱정.',
      '마이너 소드 · 10 — 키워드: 끝, 붕괴.',
      '궁정 소드 · Page — 생각·말의 시작·관찰. 키워드: 정보, 호기심, 관찰.',
      '궁정 소드 · Knight — 빠르게 찌르는 판단과 행동. 키워드: 속도, 직진, 논쟁.',
      '궁정 소드 · Queen — 냉정한 판단과 독립. 키워드: 경계, 진실, 명료함.',
      '궁정 소드 · King — 규칙·전략·권위. 키워드: 이성, 원칙, 결단.',
    ],
    [
      '주의: 차가움. 진실·판단은 말하되 말투·온도는 조절해 보세요 💡',
      '주의: 결정 못함. “최악·최선” 말고 기준 한 줄만 정해 보세요 🤔',
      '주의: 감정 고통. 아픔은 인정하고 휴식·지원·대화 창구를 열어 두세요 💐',
      '주의: 정체. 쉬되 멈춤이 아니라 “다음 한 동작” 한 줄만 적어 두세요 😴',
      '주의: 관계 깨짐. 이기기 전에 지킬 선·대화 룰부터 📝',
      '주의: 도망. 전환인지 도피인지 구분해 보고 한 문장으로 적어 보세요 ⛵',
      '주의: 배신. 전략은 쓰되 신뢰·투명함의 하한선은 지키세요 🧠',
      '주의: 자기 제한. 외부 전에 스스로 건 가정·룰을 점검해 보세요 🗝️',
      '주의: 과한 스트레스. 걱정 목록을 적고 오늘 하나만 처리해 보세요 🌤️',
      '주의: “완전 실패” 낙인. 끝난 건 정리·폐기하고 새 장의 첫 줄을 🕊️',
      '주의: 뒷조사·말실수. 사실 확인 후 말하고, 표현은 한 템포 늦춰 보세요 🦉',
      '주의: 말로 상처·성급함. 속도는 좋지만 한 번 숨 고르기 🐆',
      '주의: 차가움·단절. 이성과 공감의 비율을 조절해 보세요 ❄️',
      '주의: 독재적으로 보이거나 감정 무시. 맥락을 함께 설명해 보세요 🗡️',
    ],
  ),
  'pentacles': (
    [
      '마이너 펜타클 · Ace — 돈·현실·안정. 키워드: 기회, 돈·현실의 시작. (느리지만 현실)',
      '마이너 펜타클 · 2 — 키워드: 균형, 관리.',
      '마이너 펜타클 · 3 — 키워드: 협력, 성장.',
      '마이너 펜타클 · 4 — 키워드: 소유, 집착.',
      '마이너 펜타클 · 5 — 키워드: 결핍, 어려움.',
      '마이너 펜타클 · 6 — 키워드: 나눔, 지원.',
      '마이너 펜타클 · 7 — 키워드: 기다림, 투자.',
      '마이너 펜타클 · 8 — 키워드: 노력, 숙련.',
      '마이너 펜타클 · 9 — 키워드: 안정, 여유.',
      '마이너 펜타클 · 10 — 키워드: 부, 완성.',
      '궁정 펜타클 · Page — 돈·현실·몸의 시작·학습. 키워드: 공부, 기회, 작은 시동.',
      '궁정 펜타클 · Knight — 꾸준한 실행. 키워드: 성실, 인내, 안정 추구.',
      '궁정 펜타클 · Queen — 현실을 돌보는 관리. 키워드: 현실 감각, 관리, 안정.',
      '궁정 펜타클 · King — 성과와 책임의 정점. 키워드: 부·성공, 신뢰, 책임.',
    ],
    [
      '주의: 기회 놓침. 작은 계좌·일정이라도 오늘 한 걸음으로 잡아 보세요 🌱',
      '주의: 불안정. 수입·지출·시간 한 줄이라도 맞춰 보세요 ⚖️',
      '주의: 의존. 함께하되 역할·몫은 말·글로 남겨 보세요 🤝',
      '주의: 욕심. 가진 것과 필요한 것을 구분해 보세요 🏡',
      '주의: 경제 문제. 숫자 확인·지원 창구를 미루지 마세요 🆘',
      '주의: 조건부 관계. 나눔과 거래는 따로 적어 보세요 🎁',
      '주의: 결과 지연. 기간·기준·중간 점검일을 다시 적어 보세요 🌿',
      '주의: 반복 지침. 방법 바꾸기와 휴식 슬롯을 번갈아 보세요 ✨',
      '주의: 고립. 안정 속에서도 연결 한 사람·통로는 유지해 보세요 🍇',
      '주의: 가족·재산 문제. 문서·대화로 선명하게 정리해 보세요 🏰',
      '주의: 실행력 부족·느림. 작은 할 일 하나부터 찍어 보세요 📖',
      '주의: 답답함·변화 거부. 필요하면 속도만 살짝 올려 보세요 🐢',
      '주의: 집착·물질·루틴만 중시. 사람과 여유에도 예산을 남겨 두세요 🌺',
      '주의: 욕심·권력 집착. 얻은 만큼 나눌 통로를 만들어 보세요 💰',
    ],
  ),
};

const _specialCards = <TarotCard>[
  TarotCard(id: 78, name: 'Son of Wands', nameKo: '완드의 아들', arcana: 'special', suit: 'wands', emoji: '🔥', meaning: '불의 에너지를 품은 젊은 영혼, 열정과 모험의 화신입니다.', advice: '내면의 불꽃을 따라가세요. 당신의 열정이 길을 밝혀줄 거예요 🔥'),
  TarotCard(id: 79, name: 'Daughter of Pentacles', nameKo: '펜타클의 딸', arcana: 'special', suit: 'pentacles', emoji: '🌍', meaning: '대지의 에너지를 품은 순수한 영혼, 풍요와 성장을 상징합니다.', advice: '자연과 함께 호흡하며 천천히 성장해보세요. 뿌리가 깊을수록 높이 자라요 🌱'),
  TarotCard(id: 80, name: 'Daughter of Cups', nameKo: '컵의 딸', arcana: 'special', suit: 'cups', emoji: '💧', meaning: '물의 에너지를 품은 감성적인 영혼, 직관과 치유를 상징합니다.', advice: '감정의 흐름에 몸을 맡겨보세요. 물처럼 유연하면 어디든 갈 수 있어요 💧'),
  TarotCard(id: 81, name: 'Son of Swords', nameKo: '검의 아들', arcana: 'special', suit: 'swords', emoji: '💨', meaning: '바람의 에너지를 품은 명석한 영혼, 진실과 정의를 추구합니다.', advice: '맑은 정신으로 진실을 바라보세요. 바람처럼 자유로운 사고가 답을 찾아줄 거예요 💨'),
  TarotCard(id: 82, name: 'The Mother of Earth & Water', nameKo: '대지와 물의 어머니', arcana: 'special', emoji: '🌊', meaning: '대지와 물의 조화, 생명의 근원이자 양육과 보호의 상징입니다.', advice: '모든 것을 품어안는 어머니의 마음으로 세상을 바라보세요. 사랑이 치유의 시작이에요 🌿'),
  TarotCard(id: 83, name: 'The Father of Fire & Air', nameKo: '불과 바람의 아버지', arcana: 'special', emoji: '⚡', meaning: '불과 바람의 합일, 창조와 변혁의 힘을 지닌 수호자입니다.', advice: '강한 의지와 지혜로 새로운 세계를 열어가세요. 변화의 바람이 당신과 함께해요 ⚡'),
];

List<TarotCard> _generateMinorArcana() {
  final suits = ['wands', 'cups', 'swords', 'pentacles'];
  var id = 22;
  final out = <TarotCard>[];
  for (final suit in suits) {
    final meta = _suitMeta[suit]!;
    final data = _suitData[suit]!;
    final emojis = _suitEmojis[suit]!;
    for (var rank = 0; rank < 14; rank++) {
      final cap = suit[0].toUpperCase() + suit.substring(1);
      final nameEn = '${_rankNamesEn[rank]} of $cap';
      out.add(TarotCard(
        id: id++,
        name: nameEn,
        nameKo: '${meta.$2} ${_rankNamesKo[rank]}',
        arcana: 'minor',
        suit: suit,
        emoji: emojis[rank],
        meaning: data.$1[rank],
        advice: data.$2[rank],
      ));
    }
  }
  return out;
}

/// Next.js `TAROT_DECK`과 동일한 84장.
final List<TarotCard> tarotDeck = [
  ..._majorArcana,
  ..._generateMinorArcana(),
  ..._specialCards,
];

final _rnd = math.Random();

List<TarotCard> shuffleDeck(List<TarotCard> deck) {
  final arr = List<TarotCard>.from(deck);
  for (var i = arr.length - 1; i > 0; i--) {
    final r = _rnd.nextInt(i + 1);
    final t = arr[i];
    arr[i] = arr[r];
    arr[r] = t;
  }
  return arr;
}
