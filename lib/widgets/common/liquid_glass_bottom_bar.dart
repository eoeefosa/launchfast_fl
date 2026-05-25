import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class LiquidGlassNavItem {
  const LiquidGlassNavItem({
    required this.icon,
    required this.activeIcon,
    this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;

  /// Short label rendered below the icon. Pass `null` to hide.
  final String? label;

  /// When > 0 a glowing error-coloured badge is drawn over the icon corner.
  final int? badgeCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// A premium floating bottom navigation bar with a draggable liquid-glass pill.
///
/// The pill slides between tabs with spring physics and morphs (stretches) as
/// it travels — giving a tactile, liquid feel. Drag anywhere on the bar to
/// move the pill; it snaps to the nearest tab on release.
///
/// Requires [Scaffold.extendBody] = true so the bar floats above the body.
class LiquidGlassBottomBar extends StatefulWidget {
  const LiquidGlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : assert(
         items.length >= 2 && items.length <= 5,
         'LiquidGlassBottomBar requires 2–5 items.',
       );

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar>
    with SingleTickerProviderStateMixin {
  // Fractional tab index where the pill sits (e.g. 1.5 = midway between tabs 1 & 2).
  // This IS the AnimationController's value when spring-driven.
  late AnimationController _ctrl;

  bool _isDragging = false;
  double _barWidth = 0.0;

  // Last index that triggered haptic — avoids repeat fires on the same boundary.
  int _lastHapticIndex = -1;

  double get _position => _ctrl.value;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Bounds match the actual fractional-index range so spring overshoots
      // are not clamped to [0, 1].
      lowerBound: 0.0,
      upperBound: (widget.items.length - 1).toDouble(),
      value: widget.currentIndex.toDouble(),
    )..addListener(() => setState(() {}));

    _lastHapticIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(LiquidGlassBottomBar old) {
    super.didUpdateWidget(old);
    if (!_isDragging && old.currentIndex != widget.currentIndex) {
      _springTo(widget.currentIndex.toDouble(), velocity: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Spring physics ─────────────────────────────────────────────────────────

  void _springTo(double target, {required double velocity}) {
    _ctrl.stop();
    const desc = SpringDescription(
      mass: 1.0,
      stiffness: 480.0, // snappy but not jarring
      damping: 26.0, // slight overshoot gives a lively feel
    );
    _ctrl.animateWith(SpringSimulation(desc, _position, target, velocity));
  }

  // ── Geometry ───────────────────────────────────────────────────────────────

  double get _tabWidth => _barWidth / widget.items.length;

  /// X coordinate of the pill's centre for the current fractional position.
  double get _pillCenterX => _tabWidth * (_position + 0.5);

  /// Pill width morphs as it travels between tabs.
  ///
  /// At rest on a tab: [_kBasePillWidth].
  /// Midway between two tabs: [_kBasePillWidth] + [_kMaxStretch].
  double get _pillWidth {
    const kBasePillWidth = 62.0;
    const kMaxStretch = 32.0;
    final frac = _position - _position.floorToDouble();
    return kBasePillWidth + math.sin(math.pi * frac) * kMaxStretch;
  }

  /// How "activated" tab [index] is, from 0→1, based on pill proximity.
  double _proximity(int index) =>
      (1.0 - (_position - index).abs()).clamp(0.0, 1.0);

  // ── Gesture handlers ───────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    _isDragging = true;
    _ctrl.stop();
    _lastHapticIndex = _position.round();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = (details.primaryDelta ?? 0) / _tabWidth;
    _ctrl.value = (_position + delta).clamp(0.0, widget.items.length - 1.0);

    // Haptic tick each time the pill crosses a tab centre.
    final nearest = _position.round();
    if (nearest != _lastHapticIndex) {
      HapticFeedback.selectionClick();
      _lastHapticIndex = nearest;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = (details.primaryVelocity ?? 0) / _tabWidth;
    final newIndex = _position.round().clamp(0, widget.items.length - 1);

    _springTo(newIndex.toDouble(), velocity: velocity);

    if (newIndex != widget.currentIndex) {
      widget.onTap(newIndex);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding + 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _barWidth = constraints.maxWidth;

          return GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: _BarSurface(
              isDark: isDark,
              child: SizedBox(
                height: 74,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Glass pill ──────────────────────────────────────────
                    _GlassPill(
                      centerX: _pillCenterX,
                      width: _pillWidth,
                      activeColor: scheme.primary,
                      isDark: isDark,
                    ),

                    // ── Tab tiles ───────────────────────────────────────────
                    Row(
                      children: List.generate(widget.items.length, (i) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTap(i);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: _NavTile(
                              item: widget.items[i],
                              proximity: _proximity(i),
                              activeColor: scheme.primary,
                              inactiveColor: isDark
                                  ? Colors.white.withValues(alpha: 0.42)
                                  : Colors.black.withValues(alpha: 0.36),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar surface — frosted glass container
// ─────────────────────────────────────────────────────────────────────────────

class _BarSurface extends StatelessWidget {
  const _BarSurface({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const br = BorderRadius.all(Radius.circular(34));

    return DecoratedBox(
      // Outer shadows — depth + subtle primary tint at bottom
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.13),
            blurRadius: 56,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              // Vertical gradient gives a subtle 3-D curvature illusion.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.13),
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.58),
                      ],
              ),
              border: Border(
                // Bright specular edge at top (simulates light from above)
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.95),
                  width: 1.0,
                ),
                left: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.55),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.55),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass pill — the sliding, morphing indicator
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.centerX,
    required this.width,
    required this.activeColor,
    required this.isDark,
  });

  final double centerX;
  final double width;
  final Color activeColor;
  final bool isDark;

  static const double _pillH = 54.0;
  static const double _barH = 74.0;
  static const double _topOffset = (_barH - _pillH) / 2;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _topOffset,
      // Pin by centre so morphing expands symmetrically.
      left: centerX - width / 2,
      width: width,
      height: _pillH,
      child: _PillSurface(activeColor: activeColor, isDark: isDark),
    );
  }
}

class _PillSurface extends StatelessWidget {
  const _PillSurface({required this.activeColor, required this.isDark});

  final Color activeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Border radius tracks width so it stays stadium-shaped during morphing.
    const br = BorderRadius.all(Radius.circular(22));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          // Coloured glow — the premium signature
          BoxShadow(
            color: activeColor.withValues(alpha: isDark ? 0.42 : 0.28),
            blurRadius: 22,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
          // Crisp drop shadow for lift
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 14,
            spreadRadius: -1,
            offset: const Offset(0, 5),
          ),
          // Inset-like edge on the left (gives 3-D depth)
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(-1, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          // Extra blur inside the pill for a double-frosted look.
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              // Primary-tinted gradient: top-left light → bottom-right deeper
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.55, 1.0],
                colors: isDark
                    ? [
                        activeColor.withValues(alpha: 0.34),
                        activeColor.withValues(alpha: 0.20),
                        activeColor.withValues(alpha: 0.12),
                      ]
                    : [
                        activeColor.withValues(alpha: 0.22),
                        activeColor.withValues(alpha: 0.12),
                        activeColor.withValues(alpha: 0.06),
                      ],
              ),
              border: Border(
                // Specular highlight at the very top edge
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.90),
                  width: 0.8,
                ),
                left: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.60),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.28),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.14),
                  width: 0.5,
                ),
              ),
            ),
            // Inner specular shimmer — bright gradient at top of pill
            child: Column(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.20 : 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav tile — icon + label, interpolated from inactive → active
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.proximity, // 0.0 = fully inactive, 1.0 = fully active
    required this.activeColor,
    required this.inactiveColor,
  });

  final LiquidGlassNavItem item;
  final double proximity;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = Color.lerp(inactiveColor, activeColor, proximity)!;
    // Use the filled icon variant as the pill approaches.
    final iconData = proximity > 0.5 ? item.activeIcon : item.icon;
    // Subtle grow as the pill arrives.
    final iconScale = 1.0 + (proximity * 0.16);
    final hasBadge = (item.badgeCount ?? 0) > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: iconScale,
              child: Icon(iconData, color: iconColor, size: 23),
            ),
            if (hasBadge)
              Positioned(
                right: -9,
                top: -5,
                child: _Badge(count: item.badgeCount!),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (item.label != null)
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: proximity > 0.5 ? FontWeight.w700 : FontWeight.w500,
              color: iconColor.withValues(
                // Labels fade in as the pill approaches, out as it leaves.
                alpha: 0.38 + (proximity * 0.62),
              ),
              letterSpacing: 0.12,
            ),
            child: Text(item.label!),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(10),
        // Semi-transparent white border reads correctly on any glass surface
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.error.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: -1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onError,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
