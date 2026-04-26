/// Pure-Dart utility for converting between hex colour strings and ARGB integers.
///
/// Keeping this logic out of data-model constructors means:
///  - Models stay "dumb" (no conversion logic).
///  - This file has zero Flutter UI imports — you can test it in a plain Dart
///    CLI without a Flutter engine.
abstract final class ColorMapper {
  /// Parses a CSS/backend hex colour string to an ARGB integer.
  ///
  /// Accepts:
  ///  - 6-digit RGB  →  `"FF6B2C"` or `"#FF6B2C"`
  ///  - 8-digit ARGB →  `"FFFF6B2C"` or `"#FFFF6B2C"`
  ///
  /// Returns [defaultArgb] when the string cannot be parsed.
  static int hexToArgb(String hex, {int defaultArgb = 0xFFFF6B2C}) {
    final cleaned = hex.replaceAll('#', '').trim();
    final normalised = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return int.tryParse(normalised, radix: 16) ?? defaultArgb;
  }

  /// Serialises an ARGB integer back to a 6-digit RGB hex string (no `#`).
  ///
  /// The leading alpha byte is dropped because most backends store colours as
  /// plain `#RRGGBB`.
  static String argbToHex(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}
