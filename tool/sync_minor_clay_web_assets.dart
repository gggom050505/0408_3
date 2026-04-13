// ignore_for_file: avoid_print
//
// 마이너 클레이 일러를 **웹 친화 경로** 두 갈래로 복사합니다.
// - 숫자(에이스~10): `assets/cards/minor_number_clay/{suit}/{rank}.png` (40장)
// - 궁정(페이지~킹 + 확장 Son/Daughter 4장): `assets/cards/minor_court_clay/...` (20장)
//
// 소스: `assets/minor/`(한글 파일명) — 프로젝트 루트에서
// `dart run tool/sync_minor_clay_web_assets.dart`

import 'dart:convert';
import 'dart:io';

const _legacyDir = 'assets/minor';
const _destNumber = 'assets/cards/minor_number_clay';
const _destCourt = 'assets/cards/minor_court_clay';

const _fnRank = <String>[
  'ace',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'page',
  'knight',
  'queen',
  'king',
];

const _suits = ['wands', 'cups', 'swords', 'pentacles'];

/// [minor_clay_assets.dart] 동기화용 — 구 `assets/minor/` 파일명.
const _legacyFileById = <int, String>{
  22: '나무 1.png',
  23: '나무 2.png',
  24: '나무 3.png',
  25: '나무 4.png',
  26: '나무 5.png',
  27: '나무 6.png',
  28: '나무 7.png',
  29: '나무 8.png',
  30: '나무 9.png',
  31: '나무 10.png',
  32: '소년 나무.png',
  33: '나무 기사.png',
  34: '나무 여왕.png',
  35: '나무 왕.png',
  36: '컵 1.png',
  37: '컵 2.png',
  38: '컵 3.png',
  39: '컵 4.png',
  40: '컵 5.png',
  41: '컵 6.png',
  42: '컵 7.png',
  43: '컵 8.png',
  44: '컵 9.png',
  45: '컵 10.png',
  46: '컵 소년.png',
  47: '컵 기사.png',
  48: '컵 여왕.png',
  49: '컵 왕.png',
  50: '검 1.png',
  51: '검 2.png',
  52: '검 3.png',
  53: '검 4.png',
  54: '검 5.png',
  55: '검 6.png',
  56: '검 7.png',
  57: '검 8.png',
  58: '검 9.png',
  59: '검 10.png',
  60: '검 소년.png',
  61: '검 기사.png',
  62: '검 여왕.png',
  63: '검 왕.png',
  64: '펜타클 1.png',
  65: '동전 2.png',
  66: '동전 3.png',
  67: '동전 4.png',
  68: '동전 5.png',
  69: '동전 6.png',
  70: '동전 7.png',
  71: '동전 8.png',
  72: '동전 9.png',
  73: '동전 10.png',
  74: '동전 소년.png',
  75: 'Daughter of Pentacles.png',
  76: '동전 여왕.png',
  77: '동전 왕.png',
  78: 'Son of Wands.png',
  79: 'Daughter of Pentacles.png',
  80: 'Daughter of Cups.png',
  81: 'Son of Swords.png',
};

void _writeManifest(String rootDir, String publicPrefix, List<Map<String, Object?>> cards) {
  cards.sort((a, b) => (a['id']! as int).compareTo(b['id']! as int));
  File('$rootDir${Platform.pathSeparator}manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'assetRoot': rootDir.replaceAll(r'\', '/'),
      'publicPathPrefix': publicPrefix,
      'cards': cards,
    }),
  );
}

void main() {
  final root = Directory.current;
  final legacy = Directory.fromUri(root.uri.resolve(_legacyDir));
  if (!legacy.existsSync()) {
    stderr.writeln('Missing $_legacyDir — run from project root.');
    exitCode = 1;
    return;
  }

  final numberRoot = Directory.fromUri(root.uri.resolve(_destNumber));
  final courtRoot = Directory.fromUri(root.uri.resolve(_destCourt));
  numberRoot.createSync(recursive: true);
  courtRoot.createSync(recursive: true);

  final numberManifest = <Map<String, Object?>>[];
  final courtManifest = <Map<String, Object?>>[];
  var nCopied = 0;
  var cCopied = 0;

  for (var id = 22; id <= 77; id++) {
    final off = id - 22;
    final suit = _suits[off ~/ 14];
    final rankIdx = off % 14;
    final rank = _fnRank[rankIdx];
    final srcName = _legacyFileById[id]!;
    final src = File(
      '${legacy.path}${Platform.pathSeparator}${srcName.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!src.existsSync()) {
      stderr.writeln('Missing source: ${src.path}');
      exitCode = 1;
      return;
    }

    if (rankIdx < 10) {
      final rel = '$suit/$rank.png';
      final destPath =
          '${numberRoot.path}${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}';
      File(destPath).parent.createSync(recursive: true);
      src.copySync(destPath);
      nCopied++;
      numberManifest.add({
        'id': id,
        'kind': 'number',
        'suit': suit,
        'rank': rank,
        'path': '$_destNumber/$rel',
        'publicPath': '/cards/minor_number_clay/$rel',
      });
    } else {
      final rel = '$suit/$rank.png';
      final destPath =
          '${courtRoot.path}${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}';
      File(destPath).parent.createSync(recursive: true);
      src.copySync(destPath);
      cCopied++;
      courtManifest.add({
        'id': id,
        'kind': 'court',
        'suit': suit,
        'rank': rank,
        'path': '$_destCourt/$rel',
        'publicPath': '/cards/minor_court_clay/$rel',
      });
    }
  }

  const specials = <int, (String rel, String legacyName)>{
    78: ('special/son_of_wands.png', 'Son of Wands.png'),
    79: ('special/daughter_of_pentacles.png', 'Daughter of Pentacles.png'),
    80: ('special/daughter_of_cups.png', 'Daughter of Cups.png'),
    81: ('special/son_of_swords.png', 'Son of Swords.png'),
  };

  for (final e in specials.entries) {
    final id = e.key;
    final rel = e.value.$1;
    final srcName = e.value.$2;
    final destPath =
        '${courtRoot.path}${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}';
    final src = File(
      '${legacy.path}${Platform.pathSeparator}${srcName.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!src.existsSync()) {
      stderr.writeln('Missing source: ${src.path}');
      exitCode = 1;
      return;
    }
    File(destPath).parent.createSync(recursive: true);
    src.copySync(destPath);
    cCopied++;
    courtManifest.add({
      'id': id,
      'kind': 'court',
      'suit': 'special',
      'rank': rel.replaceFirst('special/', '').replaceAll('.png', ''),
      'path': '$_destCourt/$rel',
      'publicPath': '/cards/minor_court_clay/$rel',
    });
  }

  _writeManifest(numberRoot.path, '/cards/minor_number_clay/', numberManifest);
  _writeManifest(courtRoot.path, '/cards/minor_court_clay/', courtManifest);

  print(
    'Minor clay: $nCopied number → $_destNumber/, '
    '$cCopied court → $_destCourt/ (+ manifest.json each)',
  );
}
