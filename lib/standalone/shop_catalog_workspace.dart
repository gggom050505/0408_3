import 'shop_catalog_workspace_stub.dart'
    if (dart.library.io) 'shop_catalog_workspace_io.dart' as impl;

Future<String?> tryReadShopCatalogFromWorkspace() =>
    impl.tryReadShopCatalogFromWorkspace();
