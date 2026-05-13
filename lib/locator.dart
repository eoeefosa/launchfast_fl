import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// The store's locator registers ALL the shared services (AblyService,
// repositories). The main app just calls it and adds the app-level repos.
import 'package:campuschow/store/lib/locator.dart' as store_locator;

// Main-app–only repositories (not needed by the store screens).
import 'repositories/auth_repository.dart';
import 'repositories/menu_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/payment_repository.dart';

final locator = GetIt.instance;

void setupLocator() {
  debugPrint('[Locator] Setting up services...');

  // Delegate to the store's locator first so the better AblyService
  // and shared repositories are available to everyone.
  store_locator.setupLocator();

  // Main-app–specific repositories (customer-facing).
  if (!locator.isRegistered<AuthRepository>()) {
    locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  }
  if (!locator.isRegistered<MenuRepository>()) {
    locator.registerLazySingleton<MenuRepository>(() => MenuRepository());
  }
  if (!locator.isRegistered<OrderRepository>()) {
    locator.registerLazySingleton<OrderRepository>(() => OrderRepository());
  }
  if (!locator.isRegistered<LocationRepository>()) {
    locator.registerLazySingleton<LocationRepository>(
      () => LocationRepository(),
    );
  }
  if (!locator.isRegistered<PaymentRepository>()) {
    locator.registerLazySingleton<PaymentRepository>(() => PaymentRepository());
  }

  debugPrint('[Locator] Setup complete.');
}
