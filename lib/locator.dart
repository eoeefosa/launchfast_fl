import 'package:get_it/get_it.dart';

import 'services/ably_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/menu_repository.dart';
import 'repositories/order_repository.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<AblyService>(() => AblyService());
  
  // Repositories
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  locator.registerLazySingleton<MenuRepository>(() => MenuRepository());
  locator.registerLazySingleton<OrderRepository>(() => OrderRepository());
}
