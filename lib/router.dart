import 'package:go_router/go_router.dart';
import 'package:campuschow/screens/auth/forgot_password_screen.dart';
import 'package:campuschow/screens/auth/login_screen.dart';
import 'package:campuschow/screens/auth/register_screen.dart';
import 'package:campuschow/screens/stores_screen.dart';
import 'package:campuschow/screens/tabs/home_screen.dart';
import 'package:campuschow/screens/tabs/orders_screen.dart';
import 'package:campuschow/screens/tabs/profile/profile_screen.dart';
import 'package:campuschow/screens/tabs/tabs_shell.dart';
import 'screens/tabs/cart_screen.dart';
import 'screens/store/store_detail_screen.dart';
import 'screens/store/item_detail_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/search_screen.dart';
import 'package:campuschow/screens/notifications_screen.dart';
import 'package:campuschow/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CampusChowSplashScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          TabsShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
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
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
  ],
);
