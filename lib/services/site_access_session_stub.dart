/// 비웹: [SiteAccessGate]는 [AppConfig.siteAccessPinRequired]가 웹에서만 true라 호출되지 않습니다.
Future<bool> isSiteAccessSessionOk() async => false;

Future<void> setSiteAccessSessionOk() async {}
