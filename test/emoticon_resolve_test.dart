import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/emoticon_offline.dart';

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
}
