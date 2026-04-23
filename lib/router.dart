import 'package:go_router/go_router.dart';
import 'package:launchfast_fl/screens/auth/forgot_password_screen.dart';
import 'package:launchfast_fl/screens/auth/login_screen.dart';
import 'package:launchfast_fl/screens/auth/register_screen.dart';
import 'package:launchfast_fl/screens/dashboards/rider/main_rider.dart';
import 'package:launchfast_fl/screens/dashboards/store/store_main_nav.dart';
import 'package:launchfast_fl/screens/dashboards/worker/worker_main_nav.dart';
import 'package:launchfast_fl/screens/stores_screen.dart';
import 'package:launchfast_fl/screens/tabs/home_screen.dart';
import 'package:launchfast_fl/screens/tabs/orders_screen.dart';
import 'package:launchfast_fl/screens/tabs/profile_screen.dart';
import 'package:launchfast_fl/screens/tabs/tabs_shell.dart';
import 'screens/tabs/cart_screen.dart';
import 'screens/store/store_detail_screen.dart';
import 'screens/store/item_detail_screen.dart';
import 'screens/checkout_screen.dart';
import 'package:launchfast_fl/screens/dashboards/admin/admin_main_nav.dart';
import 'package:launchfast_fl/screens/notifications_screen.dart';
import 'package:launchfast_fl/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LaunchFastSplashScreen(),
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
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
      path: '/admin/dashboard',
      builder: (context, state) => const AdminMainNav(),
    ),

    GoRoute(
      path: '/rider',
      builder: (context, state) => const MainNavigation(),
    ),
    GoRoute(path: '/store', builder: (context, state) => const StoreMainNav()),
    GoRoute(
      path: '/worker',
      builder: (context, state) => const WorkerMainNav(),
    ),
  ],
);
