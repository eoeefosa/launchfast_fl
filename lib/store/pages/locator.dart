import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'core/services/ably_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/store/data/menu_repository.dart';
import 'features/orders/data/order_repository.dart';
import 'features/store/data/store_repository.dart';

// All store-specific code shares the same GetIt instance as the main app.
// This locator only registers services that are NOT already registered by
// lib/locator.dart (the main app's locator).
final locator = GetIt.instance;

void setupLocator() {
  debugPrint('[StoreLocator] Registering store services...');

  // AblyService — use the store's (more feature-complete) singleton.
  // Guard: only register if not already registered by the main locator.
  if (!locator.isRegistered<AblyService>()) {
    locator.registerLazySingleton<AblyService>(() {
      debugPrint('[StoreLocator] Initializing AblyService');
      return AblyService.instance;
    });
  }

  // Repositories — safe to register unconditionally (they're stateless).
  if (!locator.isRegistered<AuthRepository>()) {
    locator.registerLazySingleton<AuthRepository>(() {
      debugPrint('[StoreLocator] Initializing AuthRepository');
      return AuthRepository();
    });
  }
  if (!locator.isRegistered<MenuRepository>()) {
    locator.registerLazySingleton<MenuRepository>(() {
      debugPrint('[StoreLocator] Initializing MenuRepository');
      return MenuRepository();
    });
  }
  if (!locator.isRegistered<OrderRepository>()) {
    locator.registerLazySingleton<OrderRepository>(() {
      debugPrint('[StoreLocator] Initializing OrderRepository');
      return OrderRepository();
    });
  }
  if (!locator.isRegistered<StoreRepository>()) {
    locator.registerLazySingleton<StoreRepository>(() {
      debugPrint('[StoreLocator] Initializing StoreRepository');
      return StoreRepository();
    });
  }

  debugPrint('[StoreLocator] Done.');
}
