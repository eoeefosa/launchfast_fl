import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Responsive expanded height (was 280, now 240)
const double _kAppBarExpandedHeight = 240;

class StoreAppBar extends StatelessWidget {
  const StoreAppBar({
    super.key,
    required this.store,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.errorColor,
  });

  final dynamic store;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    final accentColor = store.accentColor as Color;

    return SliverAppBar(
      expandedHeight: _kAppBarExpandedHeight.h,
      pinned: true,
      stretch: true,
      backgroundColor: surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 2,
      leadingWidth: 70.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: Center(
          child: CircleIconButton(
            icon: Icons.arrow_back_rounded,
            backgroundColor: surfaceColor.withValues(alpha: 0.9),
            iconColor: textColor,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Builder(
            builder: (buttonContext) => CircleIconButton(
              icon: Icons.share_rounded,
              backgroundColor: surfaceColor.withValues(alpha: 0.9),
              iconColor: textColor,
              onPressed: () async {
                final renderObject = buttonContext.findRenderObject();
                final box = renderObject is RenderBox ? renderObject : null;
                final String name = store.name as String;
                final String tagline = store.tagline as String;
                await SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Check out $name on CampusChow! $tagline\n\n'
                        'Order your favorite meals now!',
                    subject: 'Delicious food from $name',
                    sharePositionOrigin: box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: AppBarBackground(
          accentColor: accentColor,
          isOpen: store.isOpen as bool,
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          errorColor: errorColor,
        ),
      ),
    );
  }
}

class AppBarBackground extends StatelessWidget {
  const AppBarBackground({
    super.key,
    required this.accentColor,
    required this.isOpen,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.errorColor,
  });

  final Color accentColor;
  final bool isOpen;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accentColor, accentColor.withValues(alpha: 0.6)],
            ),
          ),
          child: Center(
            child:
                Icon(
                  Icons.storefront_rounded,
                  size: 80.sp, // reduced from 100
                  color: Colors.white.withValues(alpha: 0.2),
                ).animate().scale(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                ),
          ),
        ),
        // Bottom dark overlay
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x4D000000)],
            ),
          ),
        ),
        // Closed overlay
        if (!isOpen)
          ColoredBox(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.4),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D000000), blurRadius: 20),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Text(
                    'CLOSED',
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 18.sp), // tightened icon size
        onPressed: onPressed,
        padding: EdgeInsets.all(10.r), // ensures tap target
        constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
      ),
    );
  }
}
