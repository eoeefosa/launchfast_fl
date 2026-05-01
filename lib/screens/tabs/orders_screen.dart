import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../widgets/orders/active_order_tracker.dart';
import '../../widgets/orders/order_history_card.dart';
import '../../widgets/orders/login_required_view.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static bool get _isIOS => Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _OrdersAppBar(isIOS: _isIOS),
        body: const LoginRequiredView(),
      );
    }

    final activeOrder = _resolveActiveOrder(orderProvider.orders);
    final hasActiveOrder = _isActive(activeOrder);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _OrdersAppBar(isIOS: _isIOS),
      body: _OrdersBody(
        orderProvider: orderProvider,
        orders: orderProvider.orders,
        activeOrder: activeOrder,
        hasActiveOrder: hasActiveOrder,
        isIOS: _isIOS,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Order _resolveActiveOrder(List<Order> orders) {
    return orders.firstWhere(
      (o) =>
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled,
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
      order.status != OrderStatus.delivered;
}

// ─── App Bar ──────────────────────────────────────────────────────────────

class _OrdersAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _OrdersAppBar({required this.isIOS});

  final bool isIOS;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoNavigationBar(
        middle: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        border: null,
      );
    }

    return AppBar(
      title: const Text(
        'My Orders',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          letterSpacing: -1,
        ),
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────

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

  List<Widget> get _children => [
    if (hasActiveOrder) ...[
      const _SectionLabel('Active Delivery'),
      const SizedBox(height: 16),
      ActiveOrderTracker(order: activeOrder),
      const SizedBox(height: 40),
    ],
    if (orders.isEmpty)
      const _EmptyState()
    else ...[
      const _SectionLabel('Past Orders', animationDelay: 200),
      const SizedBox(height: 16),
      ...orders.map((o) => OrderHistoryCard(order: o)),
      const SizedBox(height: 40),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return _IOSScrollView(orderProvider: orderProvider, children: _children);
    }
    return _AndroidScrollView(
      orderProvider: orderProvider,
      children: _children,
    );
  }
}

// ─── Scroll Views ─────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: children,
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.animationDelay = 0});

  final String text;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animationDelay))
        .slideX(begin: -0.1);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'When you place an order, it will appear here.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
