import 'package:go_router/go_router.dart';
import 'package:launchfast_fl/screens/auth/login_screen.dart';
import 'package:launchfast_fl/screens/auth/register_screen.dart';
import 'package:launchfast_fl/screens/tabs/home_screen.dart';
import 'package:launchfast_fl/screens/tabs/orders_screen.dart';
import 'package:launchfast_fl/screens/tabs/profile_screen.dart';
import 'package:launchfast_fl/screens/tabs/tabs_shell.dart';
import 'screens/tabs/cart_screen.dart';
import 'screens/store/store_detail_screen.dart';
import 'screens/store/item_detail_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_menu_screen.dart';
import 'screens/stores_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          TabsShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/store/:id',
      builder: (context, state) =>
          StoreDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) =>
          ItemDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/stores', builder: (context, state) => const StoresScreen()),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/admin/menu',
      builder: (context, state) => const AdminMenuScreen(),
    ),
  ],
);
