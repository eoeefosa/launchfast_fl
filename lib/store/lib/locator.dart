import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'core/services/ably_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/store/data/menu_repository.dart';
import 'features/orders/data/order_repository.dart';
import 'features/store/data/store_repository.dart';

final locator = GetIt.instance;

void setupLocator() {
  debugPrint('--- Registering Services ---');
  // Services
  locator.registerLazySingleton<AblyService>(() {
    debugPrint('--- Initializing AblyService ---');
    return AblyService.instance;
  });

  debugPrint('--- Registering Repositories ---');
  // Repositories
  locator.registerLazySingleton<AuthRepository>(() {
    debugPrint('--- Initializing AuthRepository ---');
    return AuthRepository();
  });
  locator.registerLazySingleton<MenuRepository>(() {
    debugPrint('--- Initializing MenuRepository ---');
    return MenuRepository();
  });
  locator.registerLazySingleton<OrderRepository>(() {
    debugPrint('--- Initializing OrderRepository ---');
    return OrderRepository();
  });
  locator.registerLazySingleton<StoreRepository>(() {
    debugPrint('--- Initializing StoreRepository ---');
    return StoreRepository();
  });
}
