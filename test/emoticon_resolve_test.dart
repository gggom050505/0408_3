import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/emoticon_offline.dart';
import 'package:gggom_tarot/data/card_themes.dart';

void main() {
  test('빈 imageUrl + 번들 emoticonId → assets 경로', () {
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'emo_asset_01'),
      'assets/emoticon/emoticon(1).png',
    );
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'emo_asset_61'),
      'assets/emoticon/emoticon(61).png',
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
        remoteImageUrl: '/assets/emoticon/emoticon(1).png',
        emoticonId: 'emo_asset_01',
      ),
      'assets/emoticon/emoticon(1).png',
    );
  });

  test('대소문자만 다른 emo_asset ID 도 매칭', () {
    expect(
      resolveEmoticonImageSrc(remoteImageUrl: '', emoticonId: 'EMO_ASSET_05'),
      'assets/emoticon/emoticon(5).png',
    );
  });

  test('resolvePublicAssetUrl: /assets/ 는 오리진과 붙이지 않음', () {
    expect(
      resolvePublicAssetUrl(
        '/assets/koreacard/majors(0).png',
        'https://www.example.com',
      ),
      'assets/koreacard/majors(0).png',
    );
  });
}
