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
  TarotCard(id: 0, name: 'The Fool', nameKo: '광대', arcana: 'major', emoji: '🤡', meaning: '자유, 순수, 모험의 시작을 의미합니다.', advice: '두려움 없이 새로운 여정을 시작해보세요. 가능성은 무한해요! 🌈'),
  TarotCard(id: 1, name: 'The Magician', nameKo: '마법사', arcana: 'major', emoji: '🧙', meaning: '의지와 능력, 새로운 시작을 나타냅니다.', advice: '당신에게는 원하는 것을 이루는 힘이 있어요. 첫 발을 내딛어보세요 ✨'),
  TarotCard(id: 2, name: 'The High Priestess', nameKo: '여사제', arcana: 'major', emoji: '🔮', meaning: '직관, 신비, 내면의 지혜를 상징합니다.', advice: '마음속 깊은 곳의 목소리에 귀 기울여보세요. 답은 이미 알고 있어요 🔮'),
  TarotCard(id: 3, name: 'The Empress', nameKo: '여황제', arcana: 'major', emoji: '👸', meaning: '풍요, 아름다움, 창조성을 의미합니다.', advice: '당신의 창의력이 빛나는 시기예요. 마음이 끌리는 것을 시작해보세요 👑'),
  TarotCard(id: 4, name: 'The Emperor', nameKo: '황제', arcana: 'major', emoji: '🤴', meaning: '권위, 안정, 체계를 나타냅니다.', advice: '계획을 세우고 차근차근 실행해보세요. 리더십이 빛날 거예요 🏛️'),
  TarotCard(id: 5, name: 'The Hierophant', nameKo: '교황', arcana: 'major', emoji: '📿', meaning: '전통, 가르침, 신뢰를 상징합니다.', advice: '경험 많은 사람의 조언에 귀 기울여보세요. 배움의 시기예요 📚'),
  TarotCard(id: 6, name: 'The Lovers', nameKo: '연인', arcana: 'major', emoji: '💑', meaning: '사랑, 관계, 중요한 선택을 의미합니다.', advice: '마음이 이끄는 방향으로 가세요. 진심은 언제나 통한답니다 💕'),
  TarotCard(id: 7, name: 'The Chariot', nameKo: '전차', arcana: 'major', emoji: '🐎', meaning: '승리, 의지력, 행동력을 나타냅니다.', advice: '목표를 향해 힘차게 전진하세요. 당신의 결단력이 승리를 가져올 거예요 🏆'),
  TarotCard(id: 8, name: 'Strength', nameKo: '힘', arcana: 'major', emoji: '🦁', meaning: '용기, 인내, 내면의 힘을 상징합니다.', advice: '당신은 생각보다 강한 사람이에요. 자신을 믿어보세요 🦁'),
  TarotCard(id: 9, name: 'The Hermit', nameKo: '은둔자', arcana: 'major', emoji: '🏔️', meaning: '내면의 성찰과 지혜의 추구를 나타냅니다.', advice: '혼자만의 시간을 가져보세요. 고요 속에서 답을 찾을 수 있어요 🏔️'),
  TarotCard(id: 10, name: 'Wheel of Fortune', nameKo: '운명의 수레바퀴', arcana: 'major', emoji: '🎡', meaning: '운명의 전환점, 행운의 순간이 다가옵니다.', advice: '변화를 두려워하지 마세요. 흐름에 몸을 맡기면 좋은 곳으로 향할 거예요 🎡'),
  TarotCard(id: 11, name: 'Justice', nameKo: '정의', arcana: 'major', emoji: '⚖️', meaning: '공정, 균형, 진실을 상징합니다.', advice: '정직하게 행동하면 좋은 결과가 따라올 거예요. 공정함을 믿으세요 ⚖️'),
  TarotCard(id: 12, name: 'The Hanged Man', nameKo: '매달린 사람', arcana: 'major', emoji: '🙃', meaning: '희생, 새로운 관점, 멈춤을 의미합니다.', advice: '잠시 멈추고 다른 시각으로 바라보세요. 새로운 깨달음이 올 거예요 🙃'),
  TarotCard(id: 13, name: 'Death', nameKo: '죽음', arcana: 'major', emoji: '🦋', meaning: '변화, 끝과 새로운 시작을 나타냅니다.', advice: '하나의 문이 닫히면 새로운 문이 열려요. 변화를 받아들이세요 🦋'),
  TarotCard(id: 14, name: 'Temperance', nameKo: '절제', arcana: 'major', emoji: '🌊', meaning: '균형, 절제, 조화를 상징합니다.', advice: '서두르지 않아도 괜찮아요. 균형 잡힌 하루를 보내보세요 🌊'),
  TarotCard(id: 15, name: 'The Devil', nameKo: '악마', arcana: 'major', emoji: '😈', meaning: '유혹, 집착, 속박을 의미합니다.', advice: '나를 얽매는 것이 무엇인지 돌아보세요. 자유는 내 안에 있어요 🔓'),
  TarotCard(id: 16, name: 'The Tower', nameKo: '탑', arcana: 'major', emoji: '⚡', meaning: '급격한 변화, 파괴, 깨달음을 나타냅니다.', advice: '갑작스러운 변화도 결국 성장의 기회가 돼요. 다시 일어설 수 있어요 ⚡'),
  TarotCard(id: 17, name: 'The Star', nameKo: '별', arcana: 'major', emoji: '⭐', meaning: '희망, 영감, 새로운 시작을 의미합니다.', advice: '지금 당신이 하고 있는 일은 올바른 방향이에요. 좋은 일이 곧 찾아올 거예요! ✨'),
  TarotCard(id: 18, name: 'The Moon', nameKo: '달', arcana: 'major', emoji: '🌙', meaning: '직감과 무의식의 세계를 나타냅니다.', advice: '지금은 감정에 솔직해지는 것이 중요해요. 내면의 목소리에 귀를 기울여보세요 🌙'),
  TarotCard(id: 19, name: 'The Sun', nameKo: '태양', arcana: 'major', emoji: '☀️', meaning: '기쁨, 활력, 성공의 에너지를 품고 있습니다.', advice: '자신감을 가지세요! 당신의 밝은 에너지가 주변을 환하게 비추고 있어요 ☀️'),
  TarotCard(id: 20, name: 'Judgement', nameKo: '심판', arcana: 'major', emoji: '🎺', meaning: '부활, 각성, 결단의 시기입니다.', advice: '과거를 돌아보고 새로운 결심을 해보세요. 다시 시작할 수 있어요 🎺'),
  TarotCard(id: 21, name: 'The World', nameKo: '세계', arcana: 'major', emoji: '🌍', meaning: '완성과 달성, 여행을 상징합니다.', advice: '한 단계가 마무리되고 새로운 챕터가 시작돼요. 스스로를 축하해주세요 🌍'),
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
      '새로운 열정과 창조적 에너지의 시작입니다.',
      '미래를 위한 계획과 결정의 시기입니다.',
      '노력의 첫 결실, 확장의 기회가 옵니다.',
      '안정과 축하, 기반이 완성되는 때입니다.',
      '경쟁과 갈등, 하지만 성장의 기회이기도 합니다.',
      '승리와 인정, 성취를 축하받는 때입니다.',
      '도전에 맞서 자신의 입장을 지켜야 합니다.',
      '빠른 변화와 진전이 있을 것입니다.',
      '끈기와 인내가 필요한 시기입니다.',
      '책임감과 부담, 하지만 끝이 보이고 있어요.',
      '열정적이고 모험을 좋아하는 에너지가 필요합니다.',
      '행동력과 용기로 앞으로 나아갈 때입니다.',
      '따뜻하고 자신감 넘치는 리더십을 발휘하세요.',
      '비전과 리더십으로 주변을 이끌 수 있습니다.',
    ],
    [
      '새로운 프로젝트를 시작하기 딱 좋은 타이밍이에요! 🔥',
      '큰 그림을 그려보세요. 가능성이 열려 있어요 🗺️',
      '지금까지의 노력이 빛을 발할 거예요 🌟',
      '소중한 사람들과 기쁨을 나누세요 🎉',
      '갈등 속에서도 배울 점을 찾아보세요 💪',
      '자신의 성과를 당당히 자랑해도 괜찮아요 🏅',
      '포기하지 마세요. 당신의 신념이 맞아요 🛡️',
      '변화의 흐름을 타고 빠르게 움직여보세요 ⚡',
      '조금만 더 견뎌보세요. 거의 다 왔어요 🔥',
      '도움을 요청하는 것도 용기예요. 혼자 지지 마세요 🤝',
      '호기심을 따라가보세요. 새로운 발견이 있을 거예요 🌱',
      '지금은 행동할 때예요. 과감히 나아가세요 🐎',
      '따뜻한 마음으로 주변을 감싸안아보세요 💛',
      '큰 비전을 품고 자신 있게 이끌어보세요 👑',
    ],
  ),
  'cups': (
    [
      '새로운 감정, 사랑의 시작을 의미합니다.',
      '관계의 조화, 파트너십을 나타냅니다.',
      '우정과 축하, 즐거운 만남이 있습니다.',
      '권태와 불만, 새로운 시각이 필요합니다.',
      '상실과 슬픔, 하지만 남은 것에 감사할 때입니다.',
      '과거의 추억, 향수와 순수한 행복입니다.',
      '환상과 선택, 현실을 직시해야 합니다.',
      '과거를 뒤로하고 새로운 길을 찾을 때입니다.',
      '소원 성취, 감정적 만족을 느끼게 됩니다.',
      '가정의 행복, 감정적 충만함을 의미합니다.',
      '감성적이고 창의적인 메시지가 오고 있습니다.',
      '로맨틱하고 이상적인 제안이 다가옵니다.',
      '직관과 감성으로 상황을 바라보세요.',
      '감정적 균형과 관대함을 베풀 때입니다.',
    ],
    [
      '마음을 열어보세요. 새로운 인연이 찾아올 거예요 💗',
      '소중한 사람과의 관계를 깊이 가꿔보세요 💑',
      '즐거운 시간을 만끽하세요. 행복은 나눌수록 커져요 🥂',
      '일상에서 벗어나 새로운 경험을 해보세요 🔄',
      '슬프더라도 남은 소중한 것들을 바라봐주세요 🙏',
      '좋았던 기억을 떠올리며 미소 지어보세요 📸',
      '꿈도 좋지만 현실적인 선택이 필요해요 👁️',
      '미련 없이 앞으로 나아가는 용기를 내세요 🚶',
      '마음속 소원을 이룰 수 있는 시기예요! 🌠',
      '가족과 사랑하는 사람들에게 감사를 전하세요 🏠',
      '감성을 살려 표현해보세요. 빛날 거예요 🎨',
      '낭만적인 제안에 마음을 열어보세요 🌹',
      '직감을 믿고 따라가보세요. 맞을 확률이 높아요 🧿',
      '넓은 마음으로 주변을 감싸안아보세요 💙',
    ],
  ),
  'swords': (
    [
      '진실의 발견, 새로운 아이디어가 떠오릅니다.',
      '결정을 미루고 있는 상태, 균형이 필요합니다.',
      '마음의 상처, 슬픔이 있지만 치유가 가능합니다.',
      '휴식과 회복, 재충전이 필요한 시기입니다.',
      '갈등과 패배감, 하지만 배울 점이 있습니다.',
      '어려운 시기를 지나 평온한 곳으로 이동합니다.',
      '전략과 지혜가 필요한 상황입니다.',
      '제약과 한계, 하지만 탈출구가 있습니다.',
      '불안과 걱정, 마음을 다스려야 합니다.',
      '끝과 마무리, 새벽 전 가장 어두운 밤입니다.',
      '호기심과 경계심, 진실을 파헤칠 때입니다.',
      '빠른 행동과 결단, 직진할 때입니다.',
      '냉철한 판단과 독립적 사고가 필요합니다.',
      '지적 권위와 명확한 소통이 중요합니다.',
    ],
    [
      '명확한 생각으로 진실을 바라보세요 💡',
      '결정을 서두르지 말고 충분히 고민해보세요 🤔',
      '아픔도 시간이 지나면 치유돼요. 자신에게 친절하세요 💐',
      '충분한 휴식을 취하세요. 쉬는 것도 능력이에요 😴',
      '실패에서 교훈을 찾으면 성장할 수 있어요 📝',
      '힘든 시기를 지나고 있어요. 곧 평화가 올 거예요 ⛵',
      '머리를 써서 전략적으로 접근해보세요 🧠',
      '스스로 만든 한계를 벗어날 방법을 찾아보세요 🗝️',
      '걱정은 해결책이 아니에요. 하나씩 대처해보세요 🌤️',
      '끝이 있어야 새로운 시작도 있어요. 놓아주세요 🕊️',
      '궁금한 건 직접 확인해보세요. 진실이 기다리고 있어요 🔍',
      '망설이지 말고 빠르게 행동하세요 ⚔️',
      '감정보다 이성으로 판단해야 할 때예요 👤',
      '분명하고 정직하게 소통하세요 🎯',
    ],
  ),
  'pentacles': (
    [
      '새로운 기회, 물질적 시작을 의미합니다.',
      '균형 잡기, 여러 일을 동시에 관리해야 합니다.',
      '협력과 팀워크, 기술 향상의 시기입니다.',
      '안정과 보수, 소유에 대한 집착을 조심하세요.',
      '경제적 어려움, 하지만 도움의 손길이 있습니다.',
      '관대함과 나눔, 주고받는 조화가 필요합니다.',
      '인내와 투자, 장기적 관점이 필요합니다.',
      '장인 정신, 꾸준한 노력이 열매를 맺습니다.',
      '풍요와 자립, 노력의 보상을 누릴 때입니다.',
      '가문과 유산, 안정적인 기반이 완성됩니다.',
      '학습과 새로운 기술, 성실한 시작입니다.',
      '꾸준함과 인내, 목표를 향해 한 걸음씩 나아갑니다.',
      '풍요로운 환경을 만들어가는 능력이 있습니다.',
      '물질적 성공과 안정을 이루었습니다.',
    ],
    [
      '좋은 기회가 왔어요. 꼭 잡으세요! 🌱',
      '우선순위를 정해서 하나씩 해결해보세요 ⚖️',
      '함께하면 더 좋은 결과를 얻을 수 있어요 🤝',
      '가진 것에 감사하되 너무 집착하지 마세요 🏡',
      '어려울 때 주변에 도움을 요청하세요 🆘',
      '베풀 수 있을 때 베풀어보세요. 돌아올 거예요 🎁',
      '당장 결과가 안 나와도 꾸준히 해보세요 🌿',
      '디테일에 신경 쓰면 더 좋은 결과가 나와요 ✨',
      '노력한 만큼 보상받을 자격이 있어요 🍇',
      '안정적인 기반 위에서 꿈을 키워보세요 🏰',
      '배움에는 끝이 없어요. 호기심을 유지하세요 📖',
      '포기하지 마세요. 꾸준함이 최고의 무기예요 🐢',
      '풍요로운 마음으로 주변을 가꿔보세요 🌺',
      '당신의 노력이 만든 결실을 즐기세요 💰',
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
