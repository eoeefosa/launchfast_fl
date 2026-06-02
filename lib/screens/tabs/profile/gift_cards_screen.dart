import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/gift_card.dart';
import '../../../../repositories/wallet_repository.dart';
import '../../../../services/api_service.dart';

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<GiftCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cards = await WalletRepository().fetchGiftCards();
      if (mounted) setState(() => _cards = cards);
    } catch (e) {
      if (mounted) setState(() => _error = ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<GiftCard> get _active =>
      _cards.where((c) => c.isActive).toList();

  List<GiftCard> get _usedOrExpired =>
      _cards.where((c) => c.isUsed || c.isExpired).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110.h,
            elevation: 0,
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding:
                  const EdgeInsets.only(bottom: 52),
              title: Text(
                'My Gift Cards',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      surfaceColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade500,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Used / Expired'),
                ],
              ),
              surfaceColor,
            ),
          ),
        ],
        body: _isLoading
            ? _SkeletonGrid(isDark: isDark)
            : _error != null
                ? _ErrorView(
                    error: _error!,
                    textColor: textColor,
                    onRetry: _fetch,
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _CardGrid(
                        cards: _active,
                        isDark: isDark,
                        onRefresh: _fetch,
                        emptyMessage: 'No active gift cards.\nBuy one from your profile!',
                        emptyIcon: Icons.card_giftcard_outlined,
                      ),
                      _CardGrid(
                        cards: _usedOrExpired,
                        isDark: isDark,
                        onRefresh: _fetch,
                        emptyMessage: 'No used or expired gift cards yet.',
                        emptyIcon: Icons.history_rounded,
                        dimmed: true,
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ─── Card grid ────────────────────────────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  final List<GiftCard> cards;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool dimmed;

  const _CardGrid({
    required this.cards,
    required this.isDark,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptyIcon,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return _EmptyState(
        message: emptyMessage,
        icon: emptyIcon,
        isDark: isDark,
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.r, 20.r, 16.r, 100.r),
        itemCount: cards.length,
        itemBuilder: (context, i) => _GiftCardTile(
          card: cards[i],
          isDark: isDark,
          dimmed: dimmed,
        )
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0, duration: 300.ms),
      ),
    );
  }
}

// ─── Gift card tile ───────────────────────────────────────────────────────────

class _GiftCardTile extends StatelessWidget {
  final GiftCard card;
  final bool isDark;
  final bool dimmed;

  const _GiftCardTile({
    required this.card,
    required this.isDark,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = dimmed ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: dimmed
              ? LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF2A2A2D),
                          const Color(0xFF1E1E21),
                        ]
                      : [
                          Colors.grey.shade200,
                          Colors.grey.shade100,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFF6B2C), Color(0xFFFF9A5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: dimmed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'CampusChow Gift Card',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      _StatusBadge(status: card.status),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // amount
                  Text(
                    '₦${NumberFormat('#,##0.00').format(card.amount)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // divider
                  Divider(
                    color: Colors.white.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  SizedBox(height: 12.h),
                  // code row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CODE',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.6),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _formatCode(card.code),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!dimmed) ...[
                        _IconBtn(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          onTap: () => _copy(context, card.code),
                        ),
                        SizedBox(width: 8.w),
                        _IconBtn(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: () => _share(card),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // dates row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DateLabel(
                        label: 'PURCHASED',
                        value: _fmtDate(card.createdAt),
                      ),
                      if (card.usedAt != null)
                        _DateLabel(
                          label: 'REDEEMED',
                          value: _fmtDate(card.usedAt!),
                        )
                      else if (card.expiresAt != null)
                        _DateLabel(
                          label: 'EXPIRES',
                          value: _fmtDate(card.expiresAt!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats code like ABCD-1234-WXYZ-5678
  String _formatCode(String code) {
    final clean = code.replaceAll('-', '').replaceAll(' ', '');
    if (clean.length < 8) return code;
    final parts = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      parts.add(clean.substring(i, (i + 4).clamp(0, clean.length)));
    }
    return parts.join('-');
  }

  String _fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  void _copy(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gift card code copied!'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _share(GiftCard c) {
    final msg =
        '🎁 Here\'s a CampusChow gift card worth ₦${NumberFormat('#,##0').format(c.amount)}!\n\n'
        'Code: ${_formatCode(c.code)}\n\n'
        'Redeem it on the CampusChow app to order delicious food on campus. 🍔🍕';
    SharePlus.instance.share(
      ShareParams(
        text: msg,
        subject: 'CampusChow Gift Card – ₦${NumberFormat('#,##0').format(c.amount)}',
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final GiftCardStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      GiftCardStatus.active => 'Active',
      GiftCardStatus.used => 'Used',
      GiftCardStatus.expired => 'Expired',
    };
    final bg = switch (status) {
      GiftCardStatus.active =>
        Colors.white.withValues(alpha: 0.25),
      GiftCardStatus.used => Colors.black.withValues(alpha: 0.25),
      GiftCardStatus.expired => Colors.black.withValues(alpha: 0.2),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small icon button on card ────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date label ───────────────────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final String label;
  final String value;

  const _DateLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isDark;

  const _EmptyState({
    required this.message,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                icon,
                size: 36.sp,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMuted,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final Color textColor;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.textColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            SizedBox(height: 16.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton loading ─────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  final bool isDark;
  const _SkeletonGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.r, 20.r, 16.r, 100.r),
      itemCount: 3,
      itemBuilder: (_, i) => Container(
        height: 180.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20.r),
        ),
      )
          .animate(delay: Duration(milliseconds: i * 80))
          .shimmer(duration: 1200.ms, color: highlight)
          .fadeIn(duration: 300.ms),
    );
  }
}

// ─── Sliver tab bar delegate ──────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: backgroundColor, child: _tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
