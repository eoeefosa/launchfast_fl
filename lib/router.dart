import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';

// ── Customer screens ──────────────────────────────────────────────────────────
import 'splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

import 'screens/tabs/tabs_shell.dart';
import 'screens/tabs/home_screen.dart';
import 'screens/tabs/cart_screen.dart';
import 'screens/tabs/orders_screen.dart';
import 'screens/tabs/profile/profile_screen.dart';

import 'screens/store/store_detail_screen.dart';
import 'screens/store/item_detail_screen.dart';

import 'screens/checkout/checkout_screen.dart';

import 'screens/search_screen.dart';
import 'screens/stores_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/payment_callback_screen.dart';


// ── Store-owner / worker screens ─────────────────────────────────────────────
import 'package:campuschow/store/lib/features/dashboard/presentation/store_main_nav.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/worker_main_nav.dart';

import 'package:campuschow/store/lib/features/auth/presentation/awaiting_approval_screen.dart';

import 'package:campuschow/store/lib/features/auth/presentation/register_screen.dart'
    as store_register;

// ─────────────────────────────────────────────────────────────────────────────
// Route constants
// ─────────────────────────────────────────────────────────────────────────────

// Splash
const routeSplash = '/';

// Auth
const routeLogin = '/login';
const routeRegister = '/register';
const routeForgotPassword = '/forgot-password';

// Customer tabs
const routeHome = '/home';
const routeCart = '/cart';
const routeOrders = '/orders';
const routeProfile = '/profile';

// Customer misc
const routeSearch = '/search';
const routeNotifications = '/notifications';
const routeStores = '/stores';
const routeCheckout = '/checkout';

// Dynamic customer routes
const routeStoreDetails = '/store/:id';
const routeItemDetails = '/item/:id';

// Payment callback (Paystack deep link)
const routePaymentCallback = '/payment/callback';

// Store owner / worker dashboards
const routeStoreDashboard = '/dashboard';
const routeWorkerDashboard = '/worker';

// Approval
const routeAwaitingApproval = '/awaiting-approval';

// Store registration
const routeStoreRegister = '/store-register';

// ─────────────────────────────────────────────────────────────────────────────
// Route groups
// ─────────────────────────────────────────────────────────────────────────────

const _authOnlyRoutes = {routeLogin, routeRegister, routeForgotPassword};

const _customerRoutes = {
  routeHome,
  routeCart,
  routeOrders,
  routeProfile,
  routeSearch,
  routeNotifications,
  routeStores,
  routeCheckout,
};

const _protectedExactRoutes = {
  routeStoreDashboard,
  routeWorkerDashboard,
  routeAwaitingApproval,
};

// ─────────────────────────────────────────────────────────────────────────────
// Router factory
// ─────────────────────────────────────────────────────────────────────────────

GoRouter createRouter(AuthProvider auth) {
  debugPrint('[Router] Creating router');

  return GoRouter(
    initialLocation: routeSplash,

    refreshListenable: auth,

    debugLogDiagnostics: kDebugMode,

    redirect: (context, state) {
      final loc = state.uri.path;

      final isLoading = auth.isLoading;
      final isAuthed = auth.isAuthenticated;

      final isStoreOwner = auth.isStoreOwner;
      final isWorker = auth.isWorker;
      final isAdmin = auth.isAdmin;

      final isApproved = auth.isStoreApproved;

      debugPrint('''
[Router Redirect]
location: $loc
loading: $isLoading
authenticated: $isAuthed
role: ${auth.user?.role}
approved: $isApproved
''');

      // ─────────────────────────────────────────────────────────────
      // 1. App boot/loading protection
      // ─────────────────────────────────────────────────────────────

      if (!auth.initialized) {
        // Prevent navigating away during auth bootstrap
        return loc == routeSplash ? null : routeSplash;
      }

      // ─────────────────────────────────────────────────────────────
      // 2. Splash redirect after loading
      // ─────────────────────────────────────────────────────────────

      if (loc == routeSplash) {
        return isAuthed ? _roleHomePage(auth) : routeHome;
      }

      // ─────────────────────────────────────────────────────────────
      // 3. Protected route guard
      // ─────────────────────────────────────────────────────────────

      if (!isAuthed && _isProtectedRoute(loc)) {
        debugPrint('[Router] Blocked unauthenticated access');

        return routeLogin;
      }

      // ─────────────────────────────────────────────────────────────
      // 4. Logged-in users cannot access auth pages
      // ─────────────────────────────────────────────────────────────

      if (isAuthed && _authOnlyRoutes.contains(loc)) {
        return _roleHomePage(auth);
      }

      // ─────────────────────────────────────────────────────────────
      // 5. Store approval enforcement
      // ─────────────────────────────────────────────────────────────

      if (isAuthed &&
          isStoreOwner &&
          !isApproved &&
          loc != routeAwaitingApproval) {
        debugPrint('[Router] Store owner awaiting approval');

        return routeAwaitingApproval;
      }

      // Approved store owner should NOT stay there
      if (isAuthed &&
          isStoreOwner &&
          isApproved &&
          loc == routeAwaitingApproval) {
        return routeStoreDashboard;
      }

      // ─────────────────────────────────────────────────────────────
      // 6. Prevent role dashboard crossover
      // ─────────────────────────────────────────────────────────────

      if (isWorker && loc == routeStoreDashboard) {
        return routeWorkerDashboard;
      }

      if ((isStoreOwner || isAdmin) && loc == routeWorkerDashboard) {
        return routeStoreDashboard;
      }

      // ─────────────────────────────────────────────────────────────
      // 7. Prevent store/worker users from customer UI
      // ─────────────────────────────────────────────────────────────

      if ((isStoreOwner || isAdmin) && _customerRoutes.contains(loc)) {
        return routeStoreDashboard;
      }

      if (isWorker && _customerRoutes.contains(loc)) {
        return routeWorkerDashboard;
      }

      // ─────────────────────────────────────────────────────────────
      // 8. No redirect needed
      // ─────────────────────────────────────────────────────────────

      return null;
    },

    routes: [
      // ───────────────────────────────────────────────────────────
      // Splash
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeSplash,
        builder: (_, _) => const CampusChowSplashScreen(),
      ),

      // ───────────────────────────────────────────────────────────
      // Auth
      // ───────────────────────────────────────────────────────────
      GoRoute(path: routeLogin, builder: (_, _) => const LoginScreen()),

      GoRoute(path: routeRegister, builder: (_, _) => const RegisterScreen()),

      GoRoute(
        path: routeForgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),

      // ───────────────────────────────────────────────────────────
      // Store registration
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeStoreRegister,
        builder: (_, _) => const store_register.RegisterScreen(),
      ),

      // ───────────────────────────────────────────────────────────
      // Customer shell
      // ───────────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return TabsShell(navigationShell: shell);
        },

        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(path: routeHome, builder: (_, _) => const HomeScreen()),
            ],
          ),

          // Cart
          StatefulShellBranch(
            routes: [
              GoRoute(path: routeCart, builder: (_, _) => const CartScreen()),
            ],
          ),

          // Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: routeOrders,
                builder: (_, _) => const OrdersScreen(),
              ),
            ],
          ),

          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: routeProfile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ───────────────────────────────────────────────────────────
      // Customer misc
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeNotifications,
        builder: (_, _) => const NotificationsScreen(),
      ),

      GoRoute(path: routeStores, builder: (_, _) => const StoresScreen()),

      GoRoute(path: routeSearch, builder: (_, _) => const SearchScreen()),

      GoRoute(path: routeCheckout, builder: (_, _) => const CheckoutScreen()),

      // ───────────────────────────────────────────────────────────
      // Payment callback — called by Paystack via deep link
      // campuschow://payment/callback?reference=REF&orderId=ID&type=TYPE
      // NOT auth-guarded: guest orders must also be able to complete payment.
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routePaymentCallback,
        builder: (_, state) {
          final reference = state.uri.queryParameters['reference'] ?? '';
          final orderId   = state.uri.queryParameters['orderId'];
          final type      = state.uri.queryParameters['type'];
          return PaymentCallbackScreen(
            reference: reference,
            orderId:   orderId,
            type:      type,
          );
        },
      ),

      // ───────────────────────────────────────────────────────────
      // Dynamic routes
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeStoreDetails,
        builder: (_, state) {
          final id = state.pathParameters['id']!;

          return StoreDetailScreen(id: id);
        },
      ),

      GoRoute(
        path: routeItemDetails,
        builder: (_, state) {
          final id = state.pathParameters['id']!;

          return ItemDetailScreen(id: id);
        },
      ),

      // ───────────────────────────────────────────────────────────
      // Store dashboard
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeStoreDashboard,
        builder: (_, _) => const StoreMainNav(),
      ),

      // ───────────────────────────────────────────────────────────
      // Worker dashboard
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeWorkerDashboard,
        builder: (_, _) => const WorkerMainNav(),
      ),

      // ───────────────────────────────────────────────────────────
      // Awaiting approval
      // ───────────────────────────────────────────────────────────
      GoRoute(
        path: routeAwaitingApproval,
        builder: (_, _) => const AwaitingApprovalScreen(),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Protected route helper
// ─────────────────────────────────────────────────────────────────────────────

bool _isProtectedRoute(String loc) {
  // Exact protected routes
  if (_protectedExactRoutes.contains(loc)) {
    return true;
  }

  return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Role homepage resolver
// ─────────────────────────────────────────────────────────────────────────────

String _roleHomePage(AuthProvider auth) {
  if (auth.isAdmin) {
    return routeStoreDashboard;
  }

  if (auth.isStoreOwner) {
    return auth.isStoreApproved ? routeStoreDashboard : routeAwaitingApproval;
  }

  if (auth.isWorker) {
    return routeWorkerDashboard;
  }

  return routeHome;
}
