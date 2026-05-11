// ─────────────────────────────────────────────────────────────────────────────
// BRIDGE FILE — do NOT add logic here.
//
// The store's AblyService is the canonical, feature-complete implementation.
// Re-exporting it here means any file that imports this path (e.g. the main
// AuthProvider, HomeScreen) gets the same singleton as the store screens.
//
// There is now exactly ONE Ably connection for the whole app.
//
// To add Ably functionality, edit:
//   lib/store/lib/core/services/ably_service.dart
// ─────────────────────────────────────────────────────────────────────────────

export 'package:campuschow/store/lib/core/services/ably_service.dart'
    show AblyService, ablyService;