import 'dart:convert';
import 'dart:io';

/// 일주: 1984-01-31 = 甲子(갑자) 기준 (양력 date만 사용)
void main() {
  final base = DateTime.utc(1984, 1, 31);
  const stemsKo = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  const branchesKo = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

  String dayGanji(DateTime d) {
    final t = DateTime.utc(d.year, d.month, d.day);
    final delta = t.difference(base).inDays;
    return '${stemsKo[delta % 10]}${branchesKo[delta % 12]}';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayG = dayGanji(today);

  print('=== 기준: 1984-01-31 = 갑자일 ===');
  print(
      '오늘(로컬): ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
  print('일간: $todayG');
  print('병오일 여부: ${todayG == '병오' ? '예 (丙午)' : '아니오 (丙午 아님)'}');
  print('');

  // 10년치: 올해 1월 1일부터 365*10일
  final startYear = today.year;
  final rangeStart = DateTime(startYear, 1, 1);
  const days = 365 * 10;
  final out = StringBuffer();
  var bingWuCount = 0;

  for (var i = 0; i < days; i++) {
    final d = rangeStart.add(Duration(days: i));
    final g = dayGanji(d);
    final line =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} : $g';
    out.writeln(line);
    if (g == '병오') bingWuCount++;
  }

  final path = 'ganji_10years_from_${startYear}_01_01.txt';
  File(path).writeAsStringSync(out.toString(), encoding: utf8);

  print('=== ${startYear}-01-01부터 ${days}일 (약 10년) ===');
  print('파일 저장: $path');
  print('그 구간 안 丙午(병오)일 수: $bingWuCount회 (60일마다 1회)');
  print('');

  // 오늘이 구간 안에 있으면 파일에서 같은 줄이 있는지 요약
  final todayLine =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')} : $todayG';
  print('오늘 줄 미리보기: $todayLine');
}
