// 오행(목·화·토·금·수) 참고 문구 — 간지 달력 안내용.

/// 한 줄 요약: 기운이 강할 때 자주 쓰는 비유.
const String kFiveElementsOneLinerKo = ''
    '목(木)이 강하면 시작·확장의 기세가 나타나고, '
    '화(火)가 강하면 가시화·충돌·전쟁처럼 터져 나오기 쉬우며, '
    '토(土)가 강하면 구조·제도·현실의 틀이 바뀌고, '
    '금(金)이 강하면 잘리고 무너지며 단속·정리가 두드러지고, '
    '수(水)가 강하면 흐름·정보·외교가 바뀌며 유연하게 빠져나가기 쉽습니다.';

class FiveElementSection {
  const FiveElementSection({
    required this.symbolHan,
    required this.nameKo,
    required this.natureKo,
    required this.traitsKo,
  });

  final String symbolHan;
  final String nameKo;
  final String natureKo;
  final String traitsKo;
}

/// 표시 순서: 목생화 → 화생토 → 토생금 → 금생수 → 수생목.
const List<FiveElementSection> kFiveElementsSectionsOrdered = [
  FiveElementSection(
    symbolHan: '木',
    nameKo: '목(木)',
    natureKo: '생장·시작·뻗어나감',
    traitsKo: '새로 시작하고 자라나며 방향을 트는 기운. '
        '간지에서는 천간 갑·을, 지지 인·묘 등과 연결해 읽기도 합니다.',
  ),
  FiveElementSection(
    symbolHan: '火',
    nameKo: '화(火)',
    natureKo: '가시화·확산·열매·충돌',
    traitsKo: '열매가 익고 밖으로 드러나며, 갈등·전쟁·사건도 “불이 붙듯” 도드라질 수 있어요. '
        '병·정, 사·오 등과 맞닿아 해석합니다.',
  ),
  FiveElementSection(
    symbolHan: '土',
    nameKo: '토(土)',
    natureKo: '구조·안정·경계·현실의 틀',
    traitsKo: '땅·제도·조직 같은 “받침”이 바뀌거나 묶이는 흐름. '
        '무·기, 진·술·축·미로 상징되는 경우가 많아요.',
  ),
  FiveElementSection(
    symbolHan: '金',
    nameKo: '금(金)',
    natureKo: '절단·정리·규범·굳어짐',
    traitsKo: '칼·도시·법—날카롭게 자르고 단속하는 기운. '
        '경·신, 신·유와 함께 “잘리고 무너진다”는 비유가 나옵니다.',
  ),
  FiveElementSection(
    symbolHan: '水',
    nameKo: '수(水)',
    natureKo: '흐름·정보·침투·유연함',
    traitsKo: '물길·말·조약·밀수 같은 “흐름”이 바뀝니다. '
        '임·계, 자·해에서 외교·정세 변화로 읽기도 합니다.',
  ),
];

const String kGanjiDisclaimerShortKo = ''
    '역사 사건의 이름(임진왜란, 갑오개혁 등)은 대부분 그 해의 간지(연간)를 가리킵니다. '
    '같은 한자를 가진 일간(일진)은 “그날의 기운 패턴”을 이해하는 데 참고하되, '
    '날짜마다 별도의 사건이 정해져 있는 것은 아닙니다.';
