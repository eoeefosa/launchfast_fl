import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../repositories/platform_repository.dart';

class CashbackWinnersScreen extends StatefulWidget {
  const CashbackWinnersScreen({super.key});

  @override
  State<CashbackWinnersScreen> createState() => _CashbackWinnersScreenState();
}

class _CashbackWinnersScreenState extends State<CashbackWinnersScreen> with SingleTickerProviderStateMixin {
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
          _error = e.toString();
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
                    colors: [
                      primaryColor.withValues(alpha: 0.1),
                      scaffoldBg,
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
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                indicatorColor: primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp),
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
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                          SizedBox(height: 16.h),
                          Text(
                            'Failed to load winners\n$_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: _fetchData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDailyWinnersList(textColor, isDark, primaryColor),
                      _buildOverallLeaderboardList(textColor, isDark, primaryColor),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDailyWinnersList(Color textColor, bool isDark, Color primaryColor) {
    if (_dailyWinners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            SizedBox(height: 16.h),
            Text('No winners drawn for $_date yet.', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 80.r),
        itemCount: _dailyWinners.length,
        itemBuilder: (context, index) {
          final winner = _dailyWinners[index];
          final user = winner['user'];
          return _WinnerTile(
            name: user['name'] ?? 'Unknown Student',
            imageUrl: user['image'],
            amount: (winner['amount'] as num).toDouble(),
            rank: index + 1,
            subtitle: 'Won on $_date',
          );
        },
      ),
    );
  }

  Widget _buildOverallLeaderboardList(Color textColor, bool isDark, Color primaryColor) {
    if (_overallLeaderboard.isEmpty) {
      return const Center(child: Text('No leaderboard data available.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 80.r),
        itemCount: _overallLeaderboard.length,
        itemBuilder: (context, index) {
          final leader = _overallLeaderboard[index];
          final user = leader['user'];
          return _WinnerTile(
            name: user['name'] ?? 'Unknown Student',
            imageUrl: user['image'],
            amount: (leader['totalAmount'] as num).toDouble(),
            rank: index + 1,
            subtitle: '${leader['winCount']} times winner',
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _WinnerTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double amount;
  final int rank;
  final String subtitle;

  const _WinnerTile({
    required this.name,
    this.imageUrl,
    required this.amount,
    required this.rank,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

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
          _buildRankBadge(rank),
          SizedBox(width: 12.w),
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: textColor)),
                Text(subtitle, style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            '₦${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = Colors.amber;
    } else if (rank == 2) {
      badgeColor = Colors.grey.shade400;
    } else if (rank == 3) {
      badgeColor = Colors.orange.shade300;
    } else {
      badgeColor = Colors.transparent;
    }

    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: rank > 3 ? Border.all(color: Colors.grey.withValues(alpha: 0.3)) : null,
      ),
      child: Center(
        child: Text(
          rank.toString(),
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
