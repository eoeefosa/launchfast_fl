import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../widgets/orders/order_history_card.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.select<OrderProvider, List<Order>>(
      (provider) => provider.orders,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // AppColors adapters
    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Filter past orders (anything not from today)
    final now = DateTime.now();
    final pastOrders = orders.where((o) {
      try {
        final orderDate = DateTime.parse(o.date);
        return !(orderDate.year == now.year &&
            orderDate.month == now.month &&
            orderDate.day == now.day);
      } catch (_) {
        return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Order History',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22.sp,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: surfaceColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: mutedColor,
          labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ALL PAST'),
            Tab(text: 'TOP ORDERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllPastOrders(orders: pastOrders),
          _TopOrders(orders: orders),
        ],
      ),
    );
  }
}

class _AllPastOrders extends StatelessWidget {
  final List<Order> orders;
  const _AllPastOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyHistory();
    }
    return ListView.builder(
      padding: EdgeInsets.all(20.r),
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderHistoryCard(order: orders[index]),
    );
  }
}

class _TopOrders extends StatelessWidget {
  final List<Order> orders;
  const _TopOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _EmptyHistory();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    final Map<String, List<Order>> groupedOrders = {};

    for (var order in orders) {
      final itemKeys = order.items.map((i) => '${i.id}:${i.quantity}').toList()
        ..sort();
      final key = itemKeys.join('|');

      if (groupedOrders.containsKey(key)) {
        groupedOrders[key]!.add(order);
      } else {
        groupedOrders[key] = [order];
      }
    }

    final sortedKeys = groupedOrders.keys.toList()
      ..sort(
        (a, b) => groupedOrders[b]!.length.compareTo(groupedOrders[a]!.length),
      );

    final topOrders = sortedKeys.map((k) => groupedOrders[k]!.first).toList();

    return ListView.builder(
      padding: EdgeInsets.all(20.r),
      itemCount: topOrders.length,
      itemBuilder: (context, index) {
        final order = topOrders[index];
        final frequency = groupedOrders[sortedKeys[index]]!.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (frequency > 1)
              Padding(
                padding: EdgeInsets.only(left: 12.w, bottom: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Ordered $frequency times',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            OrderHistoryCard(order: order),
            SizedBox(height: 8.h),
          ],
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64.sp,
            color: mutedColor.withValues(alpha: 0.2),
          ),
          SizedBox(height: 16.h),
          Text(
            'No past orders yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
