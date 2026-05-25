import 'dart:io';
import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart' as import_go_router;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../widgets/orders/active_order_tracker.dart';
import '../../widgets/orders/order_history_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static bool get _isIOS => Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;

    final activeOrder = _resolveActiveOrder(orderProvider.orders);
    final hasActiveOrder = _isActive(activeOrder);

    final now = DateTime.now();
    final todayOrders = orderProvider.orders.where((o) {
      try {
        final orderDate = DateTime.parse(o.date);
        return orderDate.year == now.year &&
            orderDate.month == now.month &&
            orderDate.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _OrdersAppBar(isIOS: _isIOS),
      body: Column(
        children: [
          if (!auth.isAuthenticated && orderProvider.orders.isNotEmpty)
            _GuestBanner(),
          Expanded(
            child: _OrdersBody(
              orderProvider: orderProvider,
              orders: todayOrders,
              activeOrder: activeOrder,
              hasActiveOrder: hasActiveOrder,
              isIOS: _isIOS,
            ),
          ),
        ],
      ),
    );
  }

  static Order _resolveActiveOrder(List<Order> orders) {
    return orders.firstWhere(
      (o) =>
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled &&
          o.status != OrderStatus.pendingPayment,
      orElse: () => Order(
        id: 'EMPTY',
        items: [],
        subtotal: 0,
        serviceFee: 0,
        deliveryFee: 0,
        platformDeliveryProfit: 0,
        walletDeduction: 0,
        total: 0,
        deliveryType: 'pickup',
        status: OrderStatus.cancelled,
        date: '',
        stores: [],
        isPriority: false,
      ),
    );
  }

  static bool _isActive(Order order) =>
      order.id.isNotEmpty &&
      order.status != OrderStatus.cancelled &&
      order.status != OrderStatus.delivered &&
      order.status != OrderStatus.pendingPayment;
}

class _OrdersAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _OrdersAppBar({required this.isIOS});

  final bool isIOS;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (isIOS) {
      return CupertinoNavigationBar(
        middle: Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
            fontSize: 17.sp,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.clock,
            size: 20.sp,
            color: mutedColor,
          ), // smaller
          onPressed: () =>
              import_go_router.GoRouter.of(context).push('/orders/history'),
        ),
        backgroundColor: surfaceColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      );
    }

    return AppBar(
      title: Text(
        'My Orders',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22.sp, // slightly smaller
          letterSpacing: -1,
          color: textColor,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              import_go_router.GoRouter.of(context).push('/orders/history'),
          icon: Icon(
            Icons.history_rounded,
            size: 22.sp,
            color: textColor,
          ), // smaller
          tooltip: 'Order History',
        ),
        SizedBox(width: 8.w),
      ],
      centerTitle: false,
      backgroundColor: surfaceColor,
      surfaceTintColor: surfaceColor,
      elevation: 0,
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody({
    required this.orderProvider,
    required this.orders,
    required this.activeOrder,
    required this.hasActiveOrder,
    required this.isIOS,
  });

  final OrderProvider orderProvider;
  final List<Order> orders;
  final Order activeOrder;
  final bool hasActiveOrder;
  final bool isIOS;

  List<Widget> _getChildren(BuildContext context) {
    return [
      if (hasActiveOrder) ...[
        const _SectionLabel('Active Delivery'),
        SizedBox(height: 12.h), // reduced
        GestureDetector(
          onTap: () {
            import_go_router.GoRouter.of(
              context,
            ).push('/orders/${activeOrder.id}', extra: activeOrder);
          },
          child: ActiveOrderTracker(order: activeOrder),
        ),
        SizedBox(height: 32.h), // reduced
      ],
      if (orders.isEmpty)
        const _EmptyState()
      else ...[
        const _SectionLabel("Today's Orders", animationDelay: 200),
        SizedBox(height: 12.h), // reduced
        ...orders.map((o) => OrderHistoryCard(order: o)),
        SizedBox(height: 32.h), // reduced
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return _IOSScrollView(
        orderProvider: orderProvider,
        children: _getChildren(context),
      );
    }
    return _AndroidScrollView(
      orderProvider: orderProvider,
      children: _getChildren(context),
    );
  }
}

class _IOSScrollView extends StatelessWidget {
  const _IOSScrollView({required this.orderProvider, required this.children});

  final OrderProvider orderProvider;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: orderProvider.refreshOrders),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 20.h,
          ), // less vertical
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
  }
}

class _AndroidScrollView extends StatelessWidget {
  const _AndroidScrollView({
    required this.orderProvider,
    required this.children,
  });

  final OrderProvider orderProvider;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: orderProvider.refreshOrders,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 20.h,
        ), // less vertical
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.animationDelay = 0});

  final String text;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Text(
          text,
          style: TextStyle(
            fontSize: 16.sp, // slightly smaller
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: textColor,
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animationDelay))
        .slideX(begin: -0.1);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final surfaceContainer = isDark
        ? AppColors.darkSurface2.withValues(alpha: 0.4)
        : AppColors.lightSurface.withValues(alpha: 0.5);

    return Center(
      child: Column(
        children: [
          SizedBox(height: 60.h), // reduced
          Icon(
            Icons.receipt_long_rounded,
            size: 64.sp, // reduced
            color: surfaceContainer,
          ),
          SizedBox(height: 20.h), // reduced
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18.sp, // slightly smaller
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          SizedBox(height: 6.h), // reduced
          Text(
            'When you place an order, it will appear here.',
            style: TextStyle(color: mutedColor, fontSize: 13.sp), // smaller
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _GuestBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0), // tighter
      padding: EdgeInsets.all(12.r), // reduced
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14.r), // slightly smaller
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: primaryColor,
            size: 18.sp,
          ), // smaller
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Sign in to sync your orders across all your devices.',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp, // smaller
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }
}
