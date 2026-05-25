import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campuschow/providers/store_provider.dart';
import 'package:campuschow/models/menu_item.dart';
import 'package:campuschow/constants/app_colors.dart';
import 'package:campuschow/widgets/responsive_layout.dart';
import 'package:campuschow/screens/store/item_detail_screen.dart';
import 'package:campuschow/widgets/common/universal_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveHistory(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 8) _history.removeLast();
    await prefs.setStringList('search_history', _history);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() => _history = []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // AppColors
    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final searchFieldBg = isDark
        ? AppColors.darkSurface2.withValues(alpha: 0.6)
        : AppColors.lightSurface.withValues(alpha: 0.7);
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;

    final results = _query.isEmpty
        ? <MenuItem>[]
        : storeProvider.menuItems.where((item) {
            final matchesQuery =
                item.name.toLowerCase().contains(_query.toLowerCase()) ||
                item.description.toLowerCase().contains(_query.toLowerCase()) ||
                item.category.toLowerCase().contains(_query.toLowerCase());
            final isNotStandaloneOption =
                item.category != 'Meat' && item.category != 'Salad';
            return matchesQuery && isNotStandaloneOption;
          }).toList();

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          leadingWidth: 40.w,
          leading: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 20.sp,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          title: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: searchFieldBg,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 14.sp),
              onChanged: (val) => setState(() => _query = val),
              onSubmitted: _saveHistory,
              decoration: InputDecoration(
                hintText: 'Search for food...',
                hintStyle: TextStyle(
                  color: mutedColor.withValues(alpha: 0.6),
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: mutedColor.withValues(alpha: 0.6),
                  size: 20.sp,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: mutedColor.withValues(alpha: 0.6),
                          size: 18.sp,
                        ),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ),
        body: _query.isEmpty ? _buildHistory() : _buildResults(results, accent),
      ),
    );
  }

  Widget _buildHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final chipBg = isDark
        ? AppColors.darkSurface2.withValues(alpha: 0.6)
        : AppColors.lightSurface.withValues(alpha: 0.6);
    final chipBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80.sp,
              color: mutedColor.withValues(alpha: 0.15),
            ),
            SizedBox(height: 16.h),
            Text(
              'Search for your cravings',
              style: TextStyle(
                color: mutedColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT SEARCHES',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: mutedColor,
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: Text(
                'Clear All',
                style: TextStyle(color: Colors.redAccent, fontSize: 12.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _history
              .map(
                (h) => _HistoryChip(
                  label: h,
                  onTap: () {
                    _controller.text = h;
                    setState(() => _query = h);
                  },
                  backgroundColor: chipBg,
                  borderColor: chipBorder,
                  textColor: textColor,
                ),
              )
              .toList(),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildResults(List<MenuItem> results, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80.sp,
              color: mutedColor.withValues(alpha: 0.15),
            ),
            SizedBox(height: 16.h),
            Text(
              'No results found for "$_query"',
              style: TextStyle(
                color: mutedColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.r),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _ResultCard(
          item: item,
          accent: accent,
          mutedColor: mutedColor,
          onTap: () {
            _saveHistory(_query);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ItemDetailScreen(id: item.id),
            );
          },
        );
      },
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MenuItem item;
  final Color accent;
  final Color mutedColor;
  final VoidCallback onTap;

  const _ResultCard({
    required this.item,
    required this.accent,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: UniversalImage(
                    imageUrl: item.image,
                    width: 70.w,
                    height: 70.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '₦${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: accent,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: mutedColor.withValues(alpha: 0.4),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
