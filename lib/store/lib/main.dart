import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campuschow/store/lib/core/providers/notification_provider.dart';
import 'package:campuschow/store/lib/core/providers/theme_provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/features/orders/presentation/cart_provider.dart';
import 'package:campuschow/store/lib/features/orders/presentation/order_provider.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/router.dart' show getRouter;

import 'locator.dart';

void main() async {
  debugPrint('--- Starting App ---');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- Flutter Binding Initialized ---');

  // Handle Flutter errors
  FlutterError.onError = (details) {
    debugPrint('--- Flutter Error ---');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack?.toString());
    FlutterError.presentError(details);
  };

  // Handle platform errors (async)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('--- Platform Error ---');
    debugPrint(error.toString());
    debugPrint(stack.toString());
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  debugPrint('--- System Orientations Set ---');

  debugPrint('--- Setting up Locator ---');
  setupLocator();
  debugPrint('--- Locator Ready ---');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          debugPrint('--- Creating AuthProvider ---');
          return AuthProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('--- Creating StoreProvider ---');
          return StoreProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('--- Creating CartProvider ---');
          return CartProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('--- Creating OrderProvider ---');
          return OrderProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('--- Creating NotificationProvider ---');
          return NotificationProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('--- Creating ThemeProvider ---');
          return ThemeProvider();
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ── Shared text theme helper ────────────────────────────────────────────────

  static TextTheme _textTheme([Brightness brightness = Brightness.light]) =>
      GoogleFonts.interTextTheme(
        brightness == Brightness.dark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme,
      );

  // ── Light theme ─────────────────────────────────────────────────────────────

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    textTheme: _textTheme(),
    scaffoldBackgroundColor: AppColors.lightScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: AppColors.lightBorder),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightScaffold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    ),
  );
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1C1C1E),
    ),
    textTheme: _textTheme(Brightness.dark),
    scaffoldBackgroundColor: AppColors.darkScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      surfaceTintColor: Color(0xFF1C1C1E),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: AppColors.darkBorder),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Read AuthProvider here so the router instance is tied to the same
    // object that drives refreshListenable — mandatory for auth-guard redirects.
    final auth = context.read<AuthProvider>();

    // FIX: Sync the system UI overlay (status bar, nav bar) with the active
    // theme. Without this, a white status bar sits on a dark scaffold (or
    // vice versa) and looks broken.
    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.darkScaffold,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.lightScaffold,
            ),
    );

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Lunch Fast',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: themeProvider.themeMode,
          // FIX: Use the auth-aware router so 401-triggered logouts
          // automatically redirect to /login from anywhere in the app.
          routerConfig: getRouter(auth),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.2,
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
