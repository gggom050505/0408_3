/// 오늘의 타로용 풀 덱 — 숫자 40 + 궁정 20 + 클레이 메이저 24 + 한국전통 메이저 22 = **106장**.
library;

import 'card_collection_grade.dart';
import 'card_themes.dart' show getBundledSiteCardAssetPath, majorClayThemeId;
import 'korea_traditional_major_assets.dart';
import 'major_clay_assets.dart'
    show kMajorClayTarotCardIds, majorClayAssetPathForTarotCardId;
import 'minor_clay_assets.dart';
import 'tarot_cards.dart';

/// 풀에서 한 장 (뽑기 후 앞면 표시·점수에 사용).
class TodayTarotDeckEntry {
  const TodayTarotDeckEntry({
    required this.poolIndex,
    required this.grade,
    required this.points,
    required this.assetPath,
    required this.labelKo,
    required this.tarotId,
  });

  /// 0~105, 팬 레이아웃·키 안정화.
  final int poolIndex;

  final CardCollectionGrade grade;
  final int points;
  final String assetPath;
  final String labelKo;

  /// RW [TarotCard.id] (한국전통도 동일 번호 0~21).
  final int tarotId;
}

TarotCard _card(int id) => tarotDeck.firstWhere((c) => c.id == id);

int _pointsFor(CardCollectionGrade g) => switch (g) {
      CardCollectionGrade.minorNumber => 1,
      CardCollectionGrade.minorCourt => 2,
      CardCollectionGrade.majorArcana => 3,
      CardCollectionGrade.koreaTraditionalMajor => 4,
    };

/// 등급·점수·번들 경로가 채워진 106장 (순서 고정). 셔플은 화면에서 [List.shuffle].
List<TodayTarotDeckEntry> buildTodayTarotDeckEntries() {
  final out = <TodayTarotDeckEntry>[];
  var idx = 0;

  for (final id in [...kMinorNumberClayTarotCardIds]..sort()) {
    final path = getBundledSiteCardAssetPath(
      themeId: majorClayThemeId,
      cardId: id,
    );
    final c = _card(id);
    out.add(
      TodayTarotDeckEntry(
        poolIndex: idx++,
        grade: CardCollectionGrade.minorNumber,
        points: _pointsFor(CardCollectionGrade.minorNumber),
        assetPath: path ??
            minorNumberClayAssetPathForTarotCardId(id)!,
        labelKo: '${c.nameKo} · ${CardCollectionGrade.minorNumber.labelKo}',
        tarotId: id,
      ),
    );
  }
  for (final id in [...kMinorCourtClayTarotCardIds]..sort()) {
    final path = getBundledSiteCardAssetPath(
      themeId: majorClayThemeId,
      cardId: id,
    );
    final c = _card(id);
    out.add(
      TodayTarotDeckEntry(
        poolIndex: idx++,
        grade: CardCollectionGrade.minorCourt,
        points: _pointsFor(CardCollectionGrade.minorCourt),
        assetPath: path ?? minorCourtClayAssetPathForTarotCardId(id)!,
        labelKo: '${c.nameKo} · ${CardCollectionGrade.minorCourt.labelKo}',
        tarotId: id,
      ),
    );
  }
  for (final id in [...kMajorClayTarotCardIds]..sort()) {
    final path = getBundledSiteCardAssetPath(
      themeId: majorClayThemeId,
      cardId: id,
    );
    final c = _card(id);
    out.add(
      TodayTarotDeckEntry(
        poolIndex: idx++,
        grade: CardCollectionGrade.majorArcana,
        points: _pointsFor(CardCollectionGrade.majorArcana),
        assetPath: path ?? majorClayAssetPathForTarotCardId(id)!,
        labelKo: '${c.nameKo} · ${CardCollectionGrade.majorArcana.labelKo}',
        tarotId: id,
      ),
    );
  }
  for (var id = 0; id <= 21; id++) {
    final path = koreaTraditionalMajorAssetPath(id);
    final c = _card(id);
    out.add(
      TodayTarotDeckEntry(
        poolIndex: idx++,
        grade: CardCollectionGrade.koreaTraditionalMajor,
        points: _pointsFor(CardCollectionGrade.koreaTraditionalMajor),
        assetPath: path!,
        labelKo: '${c.nameKo} · ${CardCollectionGrade.koreaTraditionalMajor.labelKo}',
        tarotId: id,
      ),
    );
  }
  assert(out.length == 106, 'today tarot pool = 106, got ${out.length}');
  return out;
}
