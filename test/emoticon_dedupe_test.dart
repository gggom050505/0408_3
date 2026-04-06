import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/emoticon_offline.dart';
import 'package:gggom_tarot/models/emoticon_models.dart';

EmoticonRow _row(String id, String url) => EmoticonRow(
      id: id,
      name: id,
      imageUrl: url,
      packId: null,
      price: 0,
      sortOrder: 0,
      isActive: true,
    );

void main() {
  test('같은 최종 이미지 URL은 피커에서 한 행만', () {
    // 2번팩_06·3번팩_01 → 매핑식상 둘 다 emo_01_11
    final rows = <EmoticonRow>[
      _row('a', '/emoticon/2번팩/emo_02_06.png'),
      _row('b', '/emoticon/3번팩/emo_03_01.png'),
      _row('c', '/emoticon/1번팩/emo_01_11.png'),
    ];
    final srcA = resolveEmoticonImageSrc(remoteImageUrl: rows[0].imageUrl);
    final srcB = resolveEmoticonImageSrc(remoteImageUrl: rows[1].imageUrl);
    expect(srcA, equals(srcB));

    final d = dedupeEmoticonsForPicker(rows);
    expect(d.length, 1);
    expect(d.single.id, 'a');
  });

  test('이미지 URL 비어 있으면(id별) 중복 제거 안 함', () {
    final rows = <EmoticonRow>[
      _row('x', ''),
      _row('y', ''),
    ];
    expect(dedupeEmoticonsForPicker(rows).length, 2);
  });
}
