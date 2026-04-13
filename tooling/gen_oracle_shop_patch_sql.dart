// 프로젝트 루트에서: dart run tooling/gen_oracle_shop_patch_sql.dart
import 'dart:io';

import 'package:gggom_tarot/data/oracle_assets.dart';

void main() {
  final b = StringBuffer()
    ..writeln('-- 오라클 80종: 상점 표시명·썸네일 URL 패치 (www.gggom0505.kr / Flutter 웹 공통)')
    ..writeln('-- SQL 에디터에서 실행. id 기준으로만 갱신(가격 등 다른 컬럼은 유지).')
    ..writeln(
        '-- DB에 행이 없으면 앱이 번들 카탈로그를 쓰고, 행이 있으면 여기 값이 노출됩니다.')
    ..writeln();

  for (var i = 1; i <= kBundledOracleCardCount; i++) {
    final id = 'oracle-card-${i.toString().padLeft(2, '0')}';
    final name = bundledOracleShopDisplayName(i).replaceAll("'", "''");
    final thumb = bundledOracleCatalogThumbnailPath(i);
    b.writeln(
      "UPDATE shop_items SET name = '$name', thumbnail_url = '$thumb', type = 'oracle_card', is_active = true WHERE id = '$id';",
    );
  }

  final out = File('tooling/oracle_shop_items_patch.sql');
  out.writeAsStringSync(b.toString());
  stdout.writeln('Wrote ${out.path} (${out.lengthSync()} bytes)');
}
