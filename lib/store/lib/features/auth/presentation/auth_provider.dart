// ─────────────────────────────────────────────────────────────────────────────
// BRIDGE FILE — do NOT add logic here.
//
// All store screens import this path. By re-exporting the main AuthProvider we
// eliminate the duplicate-provider / sync problem: there is now ONE source of
// truth for authentication throughout the entire app.
//
// If you need to add store-specific auth functionality, add it to:
//   lib/providers/auth_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

export 'package:campuschow/providers/auth_provider.dart' show AuthProvider;
