import 'dart:math' as math;
import 'dart:ui';

import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import your color constants

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
  final String? label;
  final int? badgeCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

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
  late AnimationController _ctrl;

  bool _isDragging = false;
  double _barWidth = 0.0;
  int _lastHapticIndex = -1;

  double get _position => _ctrl.value;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
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
    const desc = SpringDescription(mass: 1.0, stiffness: 480.0, damping: 26.0);
    _ctrl.animateWith(SpringSimulation(desc, _position, target, velocity));
  }

  // ── Geometry ───────────────────────────────────────────────────────────────

  double get _tabWidth => _barWidth / widget.items.length;
  double get _pillCenterX => _tabWidth * (_position + 0.5);

  double get _pillWidth {
    final basePx = 62.w;
    final maxStretchPx = 30.w;
    final frac = _position - _position.floorToDouble();
    return basePx + math.sin(math.pi * frac) * maxStretchPx;
  }

  double _proximity(int index) =>
      (1.0 - (_position - index).abs()).clamp(0.0, 1.0);

  // ── Drag handlers ──────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    _isDragging = true;
    _ctrl.stop();
    _lastHapticIndex = _position.round();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = (details.primaryDelta ?? 0) / _tabWidth;
    _ctrl.value = (_position + delta).clamp(0.0, widget.items.length - 1.0);

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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // ── Active pill colour from AppColors ──────────────────────────────────
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    // Inactive icon colour (solid, no extra alpha)
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, bottomPadding + 14.h),
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
                height: 72.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Sliding glass pill
                    _GlassPill(
                      centerX: _pillCenterX,
                      width: _pillWidth,
                      barHeight: 72.h,
                      activeColor: activeColor,
                      isDark: isDark,
                    ),
                    // Icon + label tiles
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
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
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
// Bar surface – frosted glass background
// ─────────────────────────────────────────────────────────────────────────────

class _BarSurface extends StatelessWidget {
  const _BarSurface({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(34.r);
    final br = BorderRadius.all(radius);

    // ── Colour palette from AppColors ──────────────────────────────────────
    final gradientTop = isDark
        ? AppColors.darkSurface2.withValues(alpha: 0.92)
        : AppColors.lightBackground;
    final gradientMid = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.86)
        : AppColors.lightSurface.withValues(alpha: 0.96);
    final gradientBot = isDark
        ? AppColors.darkBackground.withValues(alpha: 0.90)
        : AppColors.lightScaffold.withValues(alpha: 0.94);

    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.5)
        : AppColors.lightBorder.withValues(alpha: 0.45);

    final shadowAlpha1 = isDark ? 0.55 : 0.13;
    final shadowAlpha2 = isDark ? 0.22 : 0.05;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha1),
            blurRadius: 56,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha2),
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 1.0],
                colors: [gradientTop, gradientMid, gradientBot],
              ),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass pill – sliding active indicator
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.centerX,
    required this.width,
    required this.barHeight,
    required this.activeColor,
    required this.isDark,
  });

  final double centerX;
  final double width;
  final double barHeight;
  final Color activeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pillH = 54.h;
    final topOffset = (barHeight - pillH) / 2;

    return Positioned(
      top: topOffset,
      left: centerX - width / 2,
      width: width,
      height: pillH,
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
    final br = BorderRadius.all(Radius.circular(22.r));

    // ── Pill gradient – tinted with activeColor ───────────────────────────
    final pillGradStart = activeColor.withValues(alpha: isDark ? 0.38 : 0.26);
    final pillGradMid = activeColor.withValues(alpha: isDark ? 0.22 : 0.14);
    final pillGradEnd = activeColor.withValues(alpha: isDark ? 0.12 : 0.08);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.70);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          // Brand-colour glow
          BoxShadow(
            color: activeColor.withValues(alpha: isDark ? 0.42 : 0.28),
            blurRadius: 22,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
          // Lift shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 14,
            spreadRadius: -1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.55, 1.0],
                colors: [pillGradStart, pillGradMid, pillGradEnd],
              ),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            // Inner specular highlight at top
            child: Column(
              children: [
                Container(
                  height: 14.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22.r),
                      topRight: Radius.circular(22.r),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.16 : 0.50),
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
// Nav tile – icon + optional label
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.proximity,
    required this.activeColor,
    required this.inactiveColor,
  });

  final LiquidGlassNavItem item;
  final double proximity; // 0.0 (inactive) → 1.0 (active)
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = Color.lerp(inactiveColor, activeColor, proximity)!;
    final iconData = proximity > 0.5 ? item.activeIcon : item.icon;
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
              child: Icon(iconData, color: iconColor, size: 23.sp),
            ),
            if (hasBadge)
              Positioned(
                right: -9.w,
                top: -5.h,
                child: _Badge(count: item.badgeCount!),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        if (item.label != null)
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: proximity > 0.5 ? FontWeight.w700 : FontWeight.w500,
              color: iconColor.withValues(alpha: 0.38 + (proximity * 0.62)),
              letterSpacing: 0.12,
            ),
            child: Text(item.label!),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge – uses brand primary for a clean, unified look
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Instead of error, we use the primary colour for a cohesive badge.
    final badgeColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: -1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.5.sp,
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
