import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/emoticon_offline.dart';
import 'package:gggom_tarot/data/card_themes.dart';

void main() {
  test('빈 imageUrl + 번들 emoticonId → assets 경로', () {
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'emo_asset_01'),
      'assets/emoticon/emo_01.png',
    );
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'emo_asset_61'),
      'assets/emoticon/emo_61.png',
    );
  });

  test('알 수 없는 ID는 빈 문자열', () {
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'unknown-id'),
      '',
    );
  });

  test('/assets/... 선행 슬래시는 번들 키로 정규화 (웹 네트워크 404 방지)', () {
    expect(
      resolveEmoticonImageSrc(
        remoteImageUrl: '/assets/emoticon/emo_01.png',
        emoticonId: 'emo_asset_01',
      ),
      'assets/emoticon/emo_01.png',
    );
  });

  test('대소문자만 다른 emo_asset ID 도 매칭', () {
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'EMO_ASSET_05'),
      'assets/emoticon/emo_05.png',
    );
  });

test('resolvePublicAssetUrl: /assets/ 는 웹 번들 경로로 오리진과 결합', () {
    expect(
      resolvePublicAssetUrl(
      '/assets/koreacard/korean majors(0).png',
        'https://www.example.com',
      ),
    'https://www.example.com/assets/assets/koreacard/korean majors(0).png',
    );
  });
}
