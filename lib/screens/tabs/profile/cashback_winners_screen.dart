import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../repositories/platform_repository.dart';
import '../../../services/api_service.dart';

class CashbackWinnersScreen extends StatefulWidget {
  const CashbackWinnersScreen({super.key});

  @override
  State<CashbackWinnersScreen> createState() => _CashbackWinnersScreenState();
}

class _CashbackWinnersScreenState extends State<CashbackWinnersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _dailyWinners = [];
  List<dynamic> _overallLeaderboard = [];
  String _date = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await PlatformRepository().getCashbackLeaderboard();
      if (mounted) {
        setState(() {
          _dailyWinners = data['dailyWinners'] ?? [];
          _overallLeaderboard = data['overallLeaderboard'] ?? [];
          _date = data['date'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiService.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            foregroundColor: textColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Cashback Winners',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withValues(alpha: 0.1), scaffoldBg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor:
                    isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                indicatorColor: primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp),
                tabs: const [
                  Tab(text: 'Daily Winners'),
                  Tab(text: 'All-Time Leaders'),
                ],
              ),
              isDark ? AppColors.darkSurface : Colors.white,
            ),
          ),
        ],
        body: _isLoading
            ? _SkeletonList(isDark: isDark)
            : _error != null
                ? _ErrorView(
                    error: _error!,
                    textColor: textColor,
                    primaryColor: primaryColor,
                    onRetry: _fetchData,
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _WinnersList(
                        items: _dailyWinners,
                        onRefresh: _fetchData,
                        emptyMessage: 'No winners drawn for $_date yet.',
                        isDark: isDark,
                        textColor: textColor,
                        buildTile: (item, index) => _WinnerTile(
                          name: _safeName(item['user']),
                          imageUrl: item['user']?['image'] as String?,
                          amount: (item['amount'] as num).toDouble(),
                          rank: index + 1,
                          subtitle: 'Won on $_date',
                          isDark: isDark,
                          textColor: textColor,
                        ),
                      ),
                      _WinnersList(
                        items: _overallLeaderboard,
                        onRefresh: _fetchData,
                        emptyMessage: 'No leaderboard data available.',
                        isDark: isDark,
                        textColor: textColor,
                        buildTile: (item, index) => _WinnerTile(
                          name: _safeName(item['user']),
                          imageUrl: item['user']?['image'] as String?,
                          amount: (item['totalAmount'] as num).toDouble(),
                          rank: index + 1,
                          subtitle: '${item['winCount']} times winner',
                          isDark: isDark,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  /// Returns the user's actual name, or falls back to email prefix, never "Unknown Student".
  String _safeName(dynamic user) {
    if (user == null) return 'CampusChow User';
    final name = user['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final email = user['email'] as String?;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'CampusChow User';
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  final bool isDark;
  const _SkeletonList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 80.r),
      itemCount: 6,
      itemBuilder: (_, i) => _SkeletonTile(isDark: isDark, delay: i * 80),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  final bool isDark;
  final int delay;
  const _SkeletonTile({required this.isDark, required this.delay});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // rank badge
          _Bone(width: 28.w, height: 28.w, radius: 14, base: base),
          SizedBox(width: 12.w),
          // avatar
          _Bone(width: 48.r, height: 48.r, radius: 24, base: base),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: double.infinity, height: 13.h, radius: 6, base: base),
                SizedBox(height: 6.h),
                _Bone(width: 100.w, height: 11.h, radius: 6, base: base),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          _Bone(width: 60.w, height: 16.h, radius: 6, base: base),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .shimmer(
          duration: 1200.ms,
          color: highlight,
          delay: Duration(milliseconds: delay),
        )
        .fadeIn(duration: 300.ms);
  }
}

class _Bone extends StatelessWidget {
  final double width, height, radius;
  final Color base;
  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    required this.base,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─── Error view ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final Color textColor, primaryColor;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.error,
    required this.textColor,
    required this.primaryColor,
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
                backgroundColor: primaryColor,
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

// ─── Winners list ─────────────────────────────────────────────────────────────

class _WinnersList extends StatelessWidget {
  final List<dynamic> items;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final bool isDark;
  final Color textColor;
  final Widget Function(dynamic item, int index) buildTile;

  const _WinnersList({
    required this.items,
    required this.onRefresh,
    required this.emptyMessage,
    required this.isDark,
    required this.textColor,
    required this.buildTile,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64,
                color: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(emptyMessage,
                style:
                    TextStyle(color: textColor.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 80.r),
        itemCount: items.length,
        itemBuilder: (context, index) => buildTile(items[index], index)
            .animate(delay: Duration(milliseconds: index * 60))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.08, end: 0, duration: 300.ms),
      ),
    );
  }
}

// ─── Winner tile ─────────────────────────────────────────────────────────────

class _WinnerTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double amount;
  final int rank;
  final String subtitle;
  final bool isDark;
  final Color textColor;

  const _WinnerTile({
    required this.name,
    this.imageUrl,
    required this.amount,
    required this.rank,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          SizedBox(width: 12.w),
          _Avatar(name: name, imageUrl: imageUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '₦${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24.r,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: 48.r,
            height: 48.r,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(color: AppColors.primary.withValues(alpha: 0.1)),
            errorWidget: (ctx, url, err) => Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24.r,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey.shade400
            : rank == 3
                ? Colors.orange.shade300
                : Colors.transparent;

    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: rank > 3
            ? Border.all(color: Colors.grey.withValues(alpha: 0.3))
            : null,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.white : Colors.grey,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

// ─── Sliver tab bar delegate ──────────────────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, this.backgroundColor);

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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
