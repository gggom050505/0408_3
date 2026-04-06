import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/opening_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('assets/opening 에 번들된 이미지가 목록에 포함됨', () async {
    final list = await loadOpeningImageAssetPaths();
    expect(list, isNotEmpty);
    expect(list.first, startsWith(kOpeningAssetDirPrefix));
    expect(list, contains('assets/opening/opening_1.png'));
  });
}
