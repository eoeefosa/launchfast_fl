import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:campuschow/store/lib/features/auth/presentation/forgot_password_screen.dart';
import 'package:campuschow/store/lib/features/auth/presentation/login_screen.dart';
import 'package:campuschow/store/lib/features/auth/presentation/register_screen.dart';
import 'package:campuschow/store/lib/features/auth/presentation/awaiting_approval_screen.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/store_main_nav.dart';
import 'package:campuschow/store/lib/features/dashboard/presentation/worker_main_nav.dart';
import 'package:campuschow/store/lib/splash_screen.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';

/// Routes that require the user to be authenticated.
const _protectedRoutes = {'/store', '/worker', '/awaiting-approval'};

/// Routes that should NOT be accessible once authenticated.
const _authOnlyRoutes = {'/login', '/register', '/forgot-password'};

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    // Rebuild the redirect whenever AuthProvider notifies — this is what makes
    // a mid-session 401 automatically navigate back to /login.
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthed = auth.isAuthenticated;

      debugPrint(
        '[Router] $loc | authed=$isAuthed | loading=${auth.isLoading}',
      );

      // Let the splash handle its own navigation during initial load.
      if (loc == '/') return null;

      // Unauthenticated user trying to reach a protected route → login.
      if (!isAuthed && _protectedRoutes.contains(loc)) {
        debugPrint('[Router] Unauthenticated — redirecting to /login');
        return '/login';
      }

      // Authenticated user on a login/register page → send to correct home.
      if (isAuthed && _authOnlyRoutes.contains(loc)) {
        final user = auth.user;
        if (auth.isStoreOwner) {
          return auth.isStoreApproved ? '/store' : '/awaiting-approval';
        }
        if (user?.role == 'STORE_WORKER') return '/worker';
        return '/store';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StoreLaunchfastSplashScreen(),
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
        path: '/store',
        builder: (context, state) => const StoreMainNav(),
      ),
      GoRoute(
        path: '/worker',
        builder: (context, state) => const WorkerMainNav(),
      ),
      GoRoute(
        path: '/awaiting-approval',
        builder: (context, state) => const AwaitingApprovalScreen(),
      ),
    ],
  );
}

/// Convenience accessor used by [MyApp].
/// Created lazily after [AuthProvider] is available in the widget tree.
GoRouter? _routerInstance;
GoRouter getRouter(AuthProvider auth) => _routerInstance ??= buildRouter(auth);
