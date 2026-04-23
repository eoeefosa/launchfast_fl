import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../constants/app_colors.dart';
import '../../widgets/orders/active_order_tracker.dart';
import '../../widgets/orders/order_history_card.dart';
import '../../widgets/orders/login_required_view.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;
    final isIOS = Platform.isIOS;

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context, isIOS),
        body: const LoginRequiredView(),
      );
    }

    final activeOrder = orders.firstWhere(
      (o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled,
      orElse: () => Order(
        id: '',
        items: [],
        total: 0,
        status: OrderStatus.cancelled,
        date: '',
        stores: [],
        isPriority: false,
      ),
    );

    final hasActiveOrder = activeOrder.id.isNotEmpty &&
        activeOrder.status != OrderStatus.cancelled &&
        activeOrder.status != OrderStatus.delivered;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, isIOS),
      body: _OrdersBody(
        orderProvider: orderProvider,
        orders: orders,
        activeOrder: activeOrder,
        hasActiveOrder: hasActiveOrder,
        isIOS: isIOS,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isIOS) {
    if (isIOS) {
      return CupertinoNavigationBar(
        middle: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        border: null,
      );
    }

    return AppBar(
      title: const Text(
        'My Orders',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
      ),
      centerTitle: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
    );
  }
}

class _OrdersBody extends StatelessWidget {
  final OrderProvider orderProvider;
  final List<Order> orders;
  final Order activeOrder;
  final bool hasActiveOrder;
  final bool isIOS;

  const _OrdersBody({
    required this.orderProvider,
    required this.orders,
    required this.activeOrder,
    required this.hasActiveOrder,
    required this.isIOS,
  });

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        if (hasActiveOrder) ...[
          const Text(
            'Active Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 16),
          ActiveOrderTracker(order: activeOrder),
          const SizedBox(height: 40),
        ],
        
        if (orders.isEmpty)
          const _EmptyState()
        else ...[
          const Text(
            'Past Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),
          ...orders.map((o) => OrderHistoryCard(order: o)),
          const SizedBox(height: 40),
        ],
      ],
    );

    if (isIOS) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => orderProvider.refreshOrders(),
          ),
          SliverToBoxAdapter(child: content),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => orderProvider.refreshOrders(),
      child: content,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.lightSurface),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'When you place an order, it will appear here.',
            style: TextStyle(color: AppColors.lightMuted),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

