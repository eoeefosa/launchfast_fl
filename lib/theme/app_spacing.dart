import 'package:flutter/material.dart';

/// Standard spacing and padding constants to avoid magic numbers in the UI.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(20, 16, 20, 24);
}

/// Standard shadows to avoid magic numbers in the UI.
abstract final class AppShadows {
  static final softCard = BoxShadow(
    blurRadius: 20, 
    offset: const Offset(0, 6), 
    color: Colors.black.withValues(alpha: 0.05),
  );
  
  static BoxShadow primary(Color color) => BoxShadow(
    color: color.withValues(alpha: 0.4),
    blurRadius: 16,
    offset: const Offset(0, 6),
  );
}
